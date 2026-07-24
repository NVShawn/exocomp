defmodule Exocomp.Coordinator.RemediationLifecycleTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.DataPart
  alias Exocomp.Coordinator.RemediationLifecycle

  defmodule Adapter do
    @behaviour Exocomp.Coordinator.RemediationAdapter

    def validate_proposal(proposal) do
      call(:validate, proposal)

      if Map.has_key?(proposal, "command") or Map.has_key?(proposal, "approval") do
        {:error, :bypass_field_rejected}
      else
        response(
          :validate,
          {:ok, %{action_id: "systemd.service.restart", target: "demo.service"}}
        )
      end
    end

    def collect_evidence(proposal) do
      call(:evidence, proposal)
      response(:evidence, {:ok, %{id: "evidence-1", fresh: true}})
    end

    def decide(proposal, evidence) do
      call(:decide, {proposal, evidence})
      response(:decision, {:allow, %{id: "systemd.service.restart", target: "demo.service"}})
    end

    def execute(action, evidence, approval) do
      call(:execute, {action, evidence, approval})
      response(:execute, {:ok, %{exit_code: 0, output_digest: "abc123"}})
    end

    def verify(action, evidence, result) do
      call(:verify, {action, evidence, result})
      response(:verify, {:ok, %{service_state: "active"}})
    end

    defp response(key, default), do: Agent.get(agent(), &Map.get(&1.responses, key, default))

    defp call(key, value) do
      Agent.update(agent(), fn state ->
        update_in(state.calls[key], fn calls -> (calls || []) ++ [value] end)
      end)
    end

    defp agent, do: Application.fetch_env!(:exocomp_coordinator, :remediation_test_agent)
  end

  setup do
    start_supervised!(
      {Agent, fn -> %{calls: %{}, responses: %{}, events: [], fail: MapSet.new()} end}
    )
    |> then(&Application.put_env(:exocomp_coordinator, :remediation_test_agent, &1))

    on_exit(fn -> Application.delete_env(:exocomp_coordinator, :remediation_test_agent) end)
    :ok
  end

  test "allow path audits intent before restricted execution and verifies" do
    {server, agent} = start_lifecycle()
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)

    assert task.status.state == :completed
    assert event_names(task) == ["validation_started", "execution_started", "verified"]
    assert call_count(agent, :execute) == 1
    assert call_count(agent, :verify) == 1

    events = Agent.get(agent, & &1.events)
    intent_index = Enum.find_index(events, &match?({:remediation_intent_accepted, _, _}, &1))
    execution_index = Enum.find_index(events, &match?({:execution_finished, _, _}, &1))
    assert intent_index < execution_index

    assert Enum.all?(events, fn {_type, _attrs, correlation_id} ->
             correlation_id == task.contextId
           end)
  end

  test "deny is terminal without execution" do
    {server, agent} = start_lifecycle(responses: %{decision: {:deny, :not_authorized}})
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)

    assert task.status.state == :completed
    assert last_event(task) == "policy_denied"
    assert call_count(agent, :execute) == 0
  end

  test "approval can be granted only through the separate approval API" do
    decision = {:approval_required, %{id: "systemd.service.restart"}, %{summary: "restart demo"}}
    {server, agent} = start_lifecycle(responses: %{decision: decision})

    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
    assert waiting.status.state == :input_required
    assert call_count(agent, :execute) == 0

    {:ok, completed} =
      RemediationLifecycle.approve(waiting.id, %{token: "signed-token"}, server: server)

    assert completed.status.state == :completed
    assert call_count(agent, :execute) == 1
    [{_action, _evidence, approval}] = calls(agent, :execute)
    assert approval == %{token: "signed-token"}
  end

  test "operator denial never executes" do
    decision = {:approval_required, %{id: "systemd.service.restart"}, %{summary: "restart demo"}}
    {server, agent} = start_lifecycle(responses: %{decision: decision})
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
    {:ok, denied} = RemediationLifecycle.deny(waiting.id, "operator denied", server: server)

    assert denied.status.state == :completed
    assert last_event(denied) == "approval_denied"
    assert call_count(agent, :execute) == 0
  end

  test "approval timeout fails closed" do
    decision = {:approval_required, %{id: "systemd.service.restart"}, %{summary: "restart demo"}}
    {server, agent} = start_lifecycle(responses: %{decision: decision}, approval_timeout_ms: 10)
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)

    eventually(fn ->
      {:ok, task} = RemediationLifecycle.get(waiting.id, server: server)
      task.status.state == :failed and last_event(task) == "approval_timeout"
    end)

    assert call_count(agent, :execute) == 0
  end

  test "stale or unavailable evidence fails closed" do
    {server, agent} = start_lifecycle(responses: %{evidence: {:error, :stale_evidence}})
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)

    assert task.status.state == :failed
    assert last_event(task) == "validation_failed"
    assert call_count(agent, :decide) == 0
    assert call_count(agent, :execute) == 0
  end

  test "durable intent audit failure prevents action" do
    {server, agent} = start_lifecycle(fail: [:remediation_intent_accepted])
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)

    assert task.status.state == :failed
    assert last_event(task) == "audit_unavailable_before_action"
    assert call_count(agent, :execute) == 0
  end

  test "post-action audit failure records reconciliation and never repeats action" do
    {server, agent} = start_lifecycle(fail: [:execution_finished])
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)

    assert task.status.state == :failed
    assert last_event(task) == "audit_reconciliation_required"
    assert call_count(agent, :execute) == 1
    assert call_count(agent, :verify) == 1

    assert {:error, :approval_not_pending} =
             RemediationLifecycle.approve(task.id, %{}, server: server)

    assert call_count(agent, :execute) == 1
  end

  test "waiting remediation can be canceled" do
    decision = {:approval_required, %{id: "systemd.service.restart"}, %{summary: "restart demo"}}
    {server, agent} = start_lifecycle(responses: %{decision: decision})
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
    {:ok, canceled} = RemediationLifecycle.cancel(waiting.id, server: server)

    assert canceled.status.state == :canceled

    assert {:error, :approval_not_pending} =
             RemediationLifecycle.approve(waiting.id, %{}, server: server)

    assert call_count(agent, :execute) == 0
  end

  test "malformed proposals and model bypass fields cannot reach policy or execution" do
    {server, agent} = start_lifecycle(responses: %{validate: {:error, :malformed}})
    {:ok, malformed} = RemediationLifecycle.submit(proposal(), server: server)
    assert malformed.status.state == :failed

    {server2, agent2} = start_lifecycle()

    {:ok, bypass} =
      RemediationLifecycle.submit(Map.put(proposal(), "command", "systemctl restart *"),
        server: server2
      )

    assert bypass.status.state == :failed
    assert call_count(agent, :execute) == 0
    assert call_count(agent2, :decide) == 0
    assert call_count(agent2, :execute) == 0

    assert {:error, :malformed_proposal} =
             RemediationLifecycle.submit("run this", server: server2)
  end

  test "model output is redacted and bounded before history and audit" do
    redactor = fn map -> map |> Map.put("rationale", "[REDACTED]") |> Map.delete("secret") end
    {server, agent} = start_lifecycle(redactor: redactor, model_output_bytes: 200)
    raw = proposal() |> Map.put("secret", "do-not-record") |> Map.put("rationale", "token=abc")
    {:ok, task} = RemediationLifecycle.submit(raw, server: server)

    [%DataPart{data: %{"proposal" => recorded}}] = hd(task.history).parts
    refute inspect(task) =~ "do-not-record"
    refute inspect(Agent.get(agent, & &1.events)) =~ "do-not-record"
    assert recorded["rationale"] == "[REDACTED]"
  end

  test "oversized model output is replaced by a digest" do
    {server, _agent} = start_lifecycle(model_output_bytes: 100)

    {:ok, task} =
      RemediationLifecycle.submit(Map.put(proposal(), "rationale", String.duplicate("x", 500)),
        server: server
      )

    [%DataPart{data: %{"proposal" => recorded}}] = hd(task.history).parts
    assert recorded["truncated"]
    assert byte_size(recorded["sha256"]) == 64
    refute inspect(task) =~ String.duplicate("x", 500)
  end

  test "history, audit, and terminal artifact share one correlation id" do
    {server, agent} = start_lifecycle()
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)

    assert Enum.all?(task.history, &(&1.contextId == task.contextId))
    assert Enum.all?(task.artifacts, &(&1.metadata["correlation_id"] == task.contextId))

    assert Enum.all?(Agent.get(agent, & &1.events), fn {_type, _attrs, id} ->
             id == task.contextId
           end)
  end

  defp start_lifecycle(opts \\ []) do
    agent = Application.fetch_env!(:exocomp_coordinator, :remediation_test_agent)

    Agent.update(agent, fn state ->
      %{
        state
        | responses: Keyword.get(opts, :responses, %{}),
          fail: MapSet.new(Keyword.get(opts, :fail, []))
      }
    end)

    audit_fun = fn type, attrs, correlation_id ->
      Agent.get_and_update(agent, fn state ->
        result = if MapSet.member?(state.fail, type), do: {:error, :sink_down}, else: :ok
        {result, %{state | events: state.events ++ [{type, attrs, correlation_id}]}}
      end)
    end

    name = :"remediation_lifecycle_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        {RemediationLifecycle,
         [
           name: name,
           adapter: Adapter,
           audit_fun: audit_fun,
           approval_timeout_ms: Keyword.get(opts, :approval_timeout_ms, 1_000),
           model_output_bytes: Keyword.get(opts, :model_output_bytes, 4_096),
           redactor: Keyword.get(opts, :redactor, &Exocomp.Coordinator.Audit.redact/1)
         ]},
        id: name
      )

    {pid, agent}
  end

  defp proposal do
    %{
      "schema_version" => "1",
      "action_id" => "systemd.service.restart",
      "target_id" => "demo.service",
      "parameters" => %{"unit" => "demo.service"},
      "evidence_refs" => ["diagnostic-1"],
      "rationale" => "restore service"
    }
  end

  defp calls(agent, key), do: Agent.get(agent, &Map.get(&1.calls, key, []))
  defp call_count(agent, key), do: length(calls(agent, key))

  defp event_names(task) do
    task.history
    |> tl()
    |> Enum.map(fn message ->
      [%DataPart{data: %{"event" => event}}] = message.parts
      event
    end)
  end

  defp last_event(task), do: task |> event_names() |> List.last()

  defp eventually(function, attempts \\ 50)
  defp eventually(function, 0), do: assert(function.())

  defp eventually(function, attempts) do
    if function.() do
      :ok
    else
      Process.sleep(5)
      eventually(function, attempts - 1)
    end
  end
end
