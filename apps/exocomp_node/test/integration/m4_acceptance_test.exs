# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Integration.M4AcceptanceTest do
  @moduledoc """
  M4 acceptance coverage for the automatic failed-service recovery path.

  Proves both the direct `FailedService.recover/2` contract (fixture-free,
  runs in the ordinary gate) and the complete authenticated A2A task workflow
  through the node A2A router (also fixture-free).

  The privileged systemd fixture remains available through `make
  test-integration`; this suite proves the shipped orchestration, exact action,
  audit boundary, one-attempt invariant, dual health requirement, and terminal
  artifact in the ordinary repository gate.
  """

  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias Exocomp.A2A.DataPart
  alias Exocomp.Node.A2ARouter
  alias Exocomp.Node.Recovery.FailedService
  alias Exocomp.Node.TaskRegistry
  alias Exocomp.Recovery.Evidence

  @moduletag :m4_acceptance
  @now ~U[2026-07-25 14:00:00Z]
  @service "exocomp-fixture.service"
  @node_id "node-m4"

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp evidence(active, sub, health, id, opts \\ []) do
    collected_at = Keyword.get(opts, :collected_at, @now)

    Evidence.new(
      @node_id,
      @service,
      %{
        "active_state" => active,
        "sub_state" => sub,
        "health" => health,
        "unit_name" => @service
      },
      evidence_id: id,
      collected_at: collected_at
    )
  end

  defp evidence_map(active, sub, health, id, opts \\ []) do
    ev = evidence(active, sub, health, id, opts)

    %{
      "evidence_id" => ev.evidence_id,
      "collected_at" => DateTime.to_iso8601(ev.collected_at),
      "node_id" => ev.node_id,
      "service" => ev.service,
      "collector_version" => ev.collector_version,
      "data" => ev.data
    }
  end

  defp start_registry do
    name = :"registry_m4_#{System.unique_integer([:positive])}"
    start_supervised!({TaskRegistry, name: name})
    name
  end

  defp authenticated_conn(method, path, body \\ nil) do
    method
    |> conn(path, body)
    |> put_peer_data(%{ssl_cert: <<1>>})
    |> put_req_header("a2a-version", "1.0")
  end

  defp json_conn(method, path, body) do
    method
    |> authenticated_conn(path, Jason.encode!(body))
    |> put_req_header("content-type", "application/json")
  end

  defp assert_task_state(task_id, registry, expected_state, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    result =
      Enum.reduce_while(Stream.repeatedly(fn -> :poll end), :waiting, fn _tick, _acc ->
        case TaskRegistry.get(task_id, registry) do
          {:ok, %{status: %{state: ^expected_state}}} ->
            {:halt, :done}

          {:ok, %{status: %{state: :failed}}} when expected_state == :completed ->
            {:halt, :unexpected_failure}

          {:ok, _other} ->
            if System.monotonic_time(:millisecond) >= deadline do
              {:halt, :timeout}
            else
              Process.sleep(10)
              {:cont, :waiting}
            end

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)

    case result do
      :done ->
        :ok

      :timeout ->
        {:ok, task} = TaskRegistry.get(task_id, registry)

        flunk(
          "Task #{task_id} did not reach #{expected_state} within #{timeout_ms}ms; " <>
            "current: #{task.status.state}"
        )

      :unexpected_failure ->
        {:ok, task} = TaskRegistry.get(task_id, registry)

        flunk(
          "Task #{task_id} failed unexpectedly; message: #{inspect(task.status.message)}"
        )

      {:error, reason} ->
        flunk("TaskRegistry.get failed: #{inspect(reason)}")
    end
  end

  # ---------------------------------------------------------------------------
  # M4-CRIT-2: direct FailedService.recover (pre-existing fixture-free coverage)
  # ---------------------------------------------------------------------------

  test "M4-CRIT-2/4/5/7: failed fixture completes one audited stable restart" do
    {:ok, audits} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> 0 end)

    evidence = evidence("failed", "failed", "unhealthy", "observed")
    refreshed = evidence("failed", "failed", "unhealthy", "refreshed")
    healthy = evidence("active", "running", "healthy", "healthy")

    opts = [
      task_id: "m4-acceptance-episode",
      allow_list: [@service],
      now_fun: fn -> @now end,
      audit_fun: fn event ->
        Agent.update(audits, &(&1 ++ [event]))
        :ok
      end,
      refresh_fun: fn _, _ -> {:ok, refreshed} end,
      verify_fun: fn _, _ -> {:ok, healthy} end,
      executor: fn :restart_service, @service, allow_list ->
        assert allow_list == [@service]
        Agent.update(executions, &(&1 + 1))
        {:ok, %{exit_code: 0, argv: ["systemctl", "restart", @service]}}
      end,
      stability_samples: 2,
      verification_attempts: 2
    ]

    assert {:ok, result} = FailedService.recover(evidence, opts)
    assert result.machine.state == :completed
    assert result.task.status.state == :completed
    assert Agent.get(executions, & &1) == 1
    assert length(result.task.artifacts) == 1

    assert Enum.map(Agent.get(audits, & &1), & &1.event_tag) == [
             :unhealthy_observation,
             :evidence_complete,
             :validate,
             :failed_and_allowed,
             :execution_complete,
             :stable_health
           ]
  end

  # ---------------------------------------------------------------------------
  # M4-CRIT-2 through A2A: recovery dispatched via the node A2A router
  # ---------------------------------------------------------------------------

  test "M4-CRIT-2 A2A: exocomp.service.recover delivered through node A2A router completes recovery" do
    {:ok, executions} = Agent.start_link(fn -> 0 end)
    {:ok, audits} = Agent.start_link(fn -> [] end)

    # Use fresh timestamps so FailedService's 300-second freshness check passes.
    now = DateTime.utc_now()
    refreshed = evidence("failed", "failed", "unhealthy", "refreshed", collected_at: now)
    healthy = evidence("active", "running", "healthy", "healthy", collected_at: now)

    # Inject test callbacks via Application config (restored after test)
    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn event ->
      Agent.update(audits, &(&1 ++ [event]))
      :ok
    end)

    Application.put_env(:exocomp_node, :service_recover_refresh_fun, fn _, _ ->
      {:ok, refreshed}
    end)

    Application.put_env(:exocomp_node, :service_recover_verify_fun, fn _, _ ->
      {:ok, healthy}
    end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn :restart_service,
                                                                       @service,
                                                                       _allow_list ->
      Agent.update(executions, &(&1 + 1))
      {:ok, %{exit_code: 0, argv: ["systemctl", "restart", @service]}}
    end)

    try do
      registry = start_registry()
      opts = A2ARouter.init(node_id: @node_id, registry: registry)

      message_body = %{
        "role" => "user",
        "parts" => [
          %{
            "type" => "data",
            "data" => %{
              "skill" => "exocomp.service.recover",
              "service" => @service,
              "node_id" => @node_id,
              "allow_list" => [@service],
              "task_id" => "m4-a2a-acceptance-episode",
              "evidence" => evidence_map("failed", "failed", "unhealthy", "a2a-obs", collected_at: now)
            }
          }
        ]
      }

      # POST /message:send — authenticated A2A request
      submit_conn =
        :post
        |> json_conn("/message:send", message_body)
        |> A2ARouter.call(opts)

      assert submit_conn.status == 202
      response = Jason.decode!(submit_conn.resp_body)
      assert is_binary(response["id"])
      assert response["status"]["state"] == "submitted"

      task_id = response["id"]

      # Wait for the async worker to complete the recovery
      assert_task_state(task_id, registry, :completed, 5_000)

      # Retrieve the completed task via GET /tasks/:id
      get_conn =
        :get
        |> authenticated_conn("/tasks/#{task_id}")
        |> A2ARouter.call(opts)

      assert get_conn.status == 200
      completed_task = Jason.decode!(get_conn.resp_body)
      assert completed_task["status"]["state"] == "completed"

      # The artifact must be present and carry the recovery outcome
      assert [artifact] = completed_task["artifacts"]
      assert artifact["name"] == "service-recover"
      [part] = artifact["parts"]
      assert part["data"]["outcome"] == "completed"
      assert part["data"]["service"] == @service
      assert part["data"]["execution_attempted"] == true

      # Exactly one execution occurred through the A2A path
      assert Agent.get(executions, & &1) == 1

      # Audit trail includes the full sequence
      audit_tags = Enum.map(Agent.get(audits, & &1), & &1.event_tag)

      assert Enum.member?(audit_tags, :unhealthy_observation)
      assert Enum.member?(audit_tags, :failed_and_allowed)
      assert Enum.member?(audit_tags, :execution_complete)
      assert Enum.member?(audit_tags, :stable_health)

      # Confirm skill is in the agent card
      card_conn =
        :get
        |> authenticated_conn("/.well-known/agent-card.json")
        |> A2ARouter.call(opts)

      assert card_conn.status == 200
      card = Jason.decode!(card_conn.resp_body)
      skill_ids = Enum.map(card["skills"], & &1["id"])
      assert "exocomp.service.recover" in skill_ids
    after
      Application.delete_env(:exocomp_node, :service_recover_audit_fun)
      Application.delete_env(:exocomp_node, :service_recover_refresh_fun)
      Application.delete_env(:exocomp_node, :service_recover_verify_fun)
      Application.delete_env(:exocomp_node, :service_recover_executor)
    end
  end

  test "M4-CRIT-2 A2A: recovery skill with missing evidence returns failed task" do
    registry = start_registry()
    opts = A2ARouter.init(node_id: @node_id, registry: registry)

    message_body = %{
      "role" => "user",
      "parts" => [
        %{
          "type" => "data",
          "data" => %{
            "skill" => "exocomp.service.recover",
            "service" => @service,
            "node_id" => @node_id
            # evidence is intentionally missing
          }
        }
      ]
    }

    submit_conn =
      :post
      |> json_conn("/message:send", message_body)
      |> A2ARouter.call(opts)

    assert submit_conn.status == 202
    task_id = Jason.decode!(submit_conn.resp_body)["id"]

    # Missing evidence → invalid_params → task transitions to :failed
    assert_task_state(task_id, registry, :failed, 2_000)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :failed
  end

  test "M4-CRIT-2 A2A: recovery of non-allowed service returns failed task" do
    registry = start_registry()
    opts = A2ARouter.init(node_id: @node_id, registry: registry)
    now = DateTime.utc_now()

    message_body = %{
      "role" => "user",
      "parts" => [
        %{
          "type" => "data",
          "data" => %{
            "skill" => "exocomp.service.recover",
            "service" => @service,
            "node_id" => @node_id,
            "allow_list" => ["other-service.service"],
            "task_id" => "m4-disallowed-test",
            "evidence" => evidence_map("failed", "failed", "unhealthy", "disallowed-obs", collected_at: now)
          }
        }
      ]
    }

    submit_conn =
      :post
      |> json_conn("/message:send", message_body)
      |> A2ARouter.call(opts)

    assert submit_conn.status == 202
    task_id = Jason.decode!(submit_conn.resp_body)["id"]

    # Service not in allow_list → recovery_failed → task transitions to :failed
    assert_task_state(task_id, registry, :failed, 2_000)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :failed
  end
end
