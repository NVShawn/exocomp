# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.QualificationProbe do
  @moduledoc """
  Opt-in coordinator workloads for shipped-artifact qualification.

  These functions are invoked over authenticated release RPC. They exercise
  the coordinator modules loaded from the installed artifact in isolated,
  temporary processes and return raw sample maps to the external harness.
  """

  alias Exocomp.Coordinator.{
    HealthPoller,
    Inventory.Node,
    Registry,
    RemediationLifecycle
  }

  @source "coordinator"
  @default_poll_timeout_ms 2_000

  defmodule RecoveryAdapter do
    @moduledoc false
    @behaviour Exocomp.Coordinator.RemediationAdapter

    @state __MODULE__

    @impl true
    def validate_proposal(proposal) do
      record(:validate)

      if Map.has_key?(proposal, "command") or Map.has_key?(proposal, "approval") do
        {:error, :bypass_field_rejected}
      else
        {:ok, %{action_id: "systemd.service.restart", target: "qualification-fixture.service"}}
      end
    end

    @impl true
    def collect_evidence(proposal) do
      record(:evidence)
      {:ok, %{id: "qualification-evidence", fresh: true, proposal: proposal}}
    end

    @impl true
    def decide(_proposal, _evidence) do
      record(:decision)
      {:allow, %{id: "systemd.service.restart", target: "qualification-fixture.service"}}
    end

    @impl true
    def execute(_action, _evidence, _approval) do
      record(:execute)
      Process.sleep(5)
      {:ok, %{exit_code: 0, fixture_only: true}}
    end

    @impl true
    def verify(_action, _evidence, _result) do
      record(:verify)
      Process.sleep(5)
      {:ok, %{service_state: "active", application_health: "ok"}}
    end

    defp record(stage),
      do: Agent.update(@state, &update_in(&1.calls[stage], fn n -> (n || 0) + 1 end))
  end

  @doc """
  Benchmarks mixed healthy, slow, and unreachable polling.

  Slow probes complete successfully but with an injected delay. Unreachable
  probes return a typed failure. The real Registry, HealthPoller, attempt-token
  logic, task isolation, timeout machinery, and mailbox are exercised.
  """
  @spec polling(keyword()) :: {:ok, [map()]} | {:error, term()}
  def polling(opts \\ []) do
    cycles = positive(Keyword.get(opts, :cycles, 5), :cycles)
    concurrency = positive(Keyword.get(opts, :concurrency, 3), :concurrency)
    slow_ms = positive(Keyword.get(opts, :slow_ms, 20), :slow_ms)
    # This is an orchestration deadline, not a performance budget. Keep enough
    # headroom for the shipped arm64 VM under full-system CPU emulation; the
    # measured cycle latency and exact reachability outcomes remain hard gates.
    timeout_ms =
      positive(Keyword.get(opts, :timeout_ms, @default_poll_timeout_ms), :timeout_ms)

    names = unique_names()

    with {:ok, task_supervisor} <- Task.Supervisor.start_link(name: names.task_supervisor),
         {:ok, registry} <-
           Registry.start_link(
             name: names.registry,
             # Explicitly marking all entries due below defines one measured
             # cycle. A short interval can make a completed node due again
             # before a slow/emulated cycle drains, causing endless refills.
             poll_interval_ms: 60_000,
             jitter_ms: 0
           ),
         :ok <- Registry.rebuild(mixed_nodes(), registry),
         {:ok, poller} <-
           HealthPoller.start_link(
             name: names.poller,
             registry_server: registry,
             task_supervisor: task_supervisor,
             interval_ms: 60_000,
             timeout_ms: timeout_ms,
             concurrency: concurrency,
             start_immediately: false,
             probe_adapter: probe_adapter(slow_ms)
           ) do
      try do
        samples =
          1..cycles
          |> Enum.flat_map(fn _cycle ->
            make_all_due(registry)
            started = System.monotonic_time(:millisecond)
            :ok = HealthPoller.poll_now(poller)

            with :ok <- await_idle(poller, timeout_ms * 4) do
              elapsed = System.monotonic_time(:millisecond) - started
              entries = Registry.all(registry)

              [
                sample("coordinator.poll.cycle_ms", elapsed, "ms"),
                sample("coordinator.poll.healthy.count", count(entries, :healthy), "count"),
                sample("coordinator.poll.slow.count", count(entries, :degraded), "count"),
                sample(
                  "coordinator.poll.unreachable.count",
                  count(entries, :unreachable),
                  "count"
                ),
                sample(
                  "coordinator.poll.in_flight.count",
                  length(HealthPoller.in_flight(poller)),
                  "count"
                ),
                sample("coordinator.poll.mailbox.depth", mailbox_depth(poller), "count")
              ]
            else
              {:error, reason} -> throw({:polling_failed, reason})
            end
          end)

        {:ok, samples}
      catch
        {:polling_failed, reason} -> {:error, reason}
      after
        safe_stop(poller)
        safe_stop(registry)
        safe_stop(task_supervisor)
      end
    end
  end

  @doc """
  Measures observation-to-verification latency and re-checks the durable-intent
  fail-closed boundary on the shipped remediation lifecycle.
  """
  @spec recovery(keyword()) :: {:ok, [map()]} | {:error, term()}
  def recovery(_opts \\ []) do
    state = RecoveryAdapter

    case Agent.start_link(fn -> %{calls: %{}, fail_intent: false, events: []} end, name: state) do
      {:ok, agent} ->
        try do
          run_recovery(agent)
        after
          if Process.alive?(agent), do: Agent.stop(agent)
        end

      {:error, {:already_started, pid}} ->
        {:error, {:recovery_already_running, pid}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp run_recovery(agent) do
    audit = fn type, _attributes, _correlation_id ->
      Agent.get_and_update(agent, fn state ->
        result =
          if type == :remediation_intent_accepted and state.fail_intent,
            do: {:error, :qualification_injected_audit_failure},
            else: :ok

        {result, %{state | events: state.events ++ [type]}}
      end)
    end

    with {:ok, lifecycle} <-
           RemediationLifecycle.start_link(
             name: unique_atom("recovery"),
             adapter: RecoveryAdapter,
             audit_fun: audit
           ) do
      try do
        observed_at = System.monotonic_time(:millisecond)

        {:ok, task} =
          RemediationLifecycle.submit(
            %{"proposal_id" => "restart_service", "fixture" => true},
            server: lifecycle
          )

        verified_at = System.monotonic_time(:millisecond)
        before_fail_closed = calls(agent, :execute)
        Agent.update(agent, &%{&1 | fail_intent: true})

        with {:ok, fail_closed} <-
               RemediationLifecycle.start_link(
                 name: unique_atom("fail_closed"),
                 adapter: RecoveryAdapter,
                 audit_fun: audit
               ) do
          try do
            {:ok, rejected} =
              RemediationLifecycle.submit(
                %{"proposal_id" => "restart_service", "fixture" => true},
                server: fail_closed
              )

            safety_pass =
              task.status.state == :completed and
                rejected.status.state == :failed and
                calls(agent, :execute) == before_fail_closed and
                calls(agent, :verify) == 1

            {:ok,
             [
               sample(
                 "recovery.observation_to_verification_ms",
                 verified_at - observed_at,
                 "ms"
               ),
               sample("recovery.execution.count", before_fail_closed, "count"),
               sample("recovery.verification.count", calls(agent, :verify), "count"),
               sample(
                 "recovery.audit_fail_closed",
                 bool(rejected.status.state == :failed),
                 "bool"
               ),
               sample("recovery.safety_pass", bool(safety_pass), "bool")
             ]}
          after
            safe_stop(fail_closed)
          end
        end
      after
        safe_stop(lifecycle)
      end
    end
  end

  defp probe_adapter(slow_ms) do
    fn
      %{labels: %{"qualification_kind" => "healthy"}} = entry, _opts ->
        successful(entry, :healthy)

      %{labels: %{"qualification_kind" => "slow"}} = entry, _opts ->
        Process.sleep(slow_ms)
        successful(entry, :degraded)

      %{labels: %{"qualification_kind" => "unreachable"}}, _opts ->
        :unreachable
    end
  end

  defp successful(entry, outcome) do
    %{
      outcome: outcome,
      node_id: entry.id,
      verified_addresses: ["192.0.2.1"],
      agent_card: %{"version" => "1.0", "skills" => ["diagnostics"]},
      health: %{"status" => if(outcome == :healthy, do: "ok", else: "degraded")},
      error_details: %{}
    }
  end

  defp mixed_nodes do
    for kind <- ~w(healthy slow unreachable) do
      %Node{
        id: "qualification-#{kind}",
        hostname: "#{kind}.qualification.invalid",
        port: 8_443,
        certificate_identity: "spiffe://qualification/#{kind}",
        capabilities: ["diagnostics"],
        labels: %{"qualification_kind" => kind}
      }
    end
  end

  defp make_all_due(registry) do
    due_at = DateTime.add(DateTime.utc_now(), -1, :second)

    Enum.each(Registry.all(registry), fn entry ->
      :ok = Registry.update(entry.id, %{next_eligible_poll_at: due_at}, registry)
    end)
  end

  defp await_idle(poller, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_await_idle(poller, deadline)
  end

  defp do_await_idle(poller, deadline) do
    if HealthPoller.in_flight(poller) == [] do
      :ok
    else
      remaining = deadline - System.monotonic_time(:millisecond)

      if remaining > 0 do
        Process.sleep(min(5, remaining))
        do_await_idle(poller, deadline)
      else
        {:error, :poll_timeout}
      end
    end
  end

  defp mailbox_depth(pid) do
    case Process.info(pid, :message_queue_len) do
      {:message_queue_len, depth} -> depth
      _other -> 0
    end
  end

  defp count(entries, reachability), do: Enum.count(entries, &(&1.reachability == reachability))
  defp calls(agent, stage), do: Agent.get(agent, &Map.get(&1.calls, stage, 0))
  defp bool(true), do: 1
  defp bool(false), do: 0

  defp sample(name, value, unit) do
    %{
      "timestamp" => System.system_time(:millisecond),
      "source" => @source,
      "metric_name" => name,
      "value" => value,
      "unit" => unit,
      "tags" => []
    }
  end

  defp safe_stop(pid) when is_pid(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid)
  catch
    :exit, _reason -> :ok
  end

  defp positive(value, _name) when is_integer(value) and value > 0, do: value

  defp positive(value, name),
    do: raise(ArgumentError, "#{name} must be positive, got #{inspect(value)}")

  defp unique_names do
    %{
      task_supervisor: unique_atom("poll_tasks"),
      registry: unique_atom("registry"),
      poller: unique_atom("poller")
    }
  end

  defp unique_atom(prefix),
    do: :"qualification_#{prefix}_#{System.unique_integer([:positive, :monotonic])}"
end
