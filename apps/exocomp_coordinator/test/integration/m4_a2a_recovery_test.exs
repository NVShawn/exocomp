# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Integration.M4A2ARecoveryTest do
  @moduledoc """
  Complete M4-CRIT-2 A2A recovery coverage.

  The request enters through the authenticated coordinator router, is
  authorized against coordinator inventory, crosses the real
  `DiagnosticClient` boundary, enters the authenticated node router, executes
  the node recovery skill, and returns the nested terminal artifact through
  the coordinator task.
  """

  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias Exocomp.Coordinator.A2ARouter, as: CoordinatorRouter
  alias Exocomp.Coordinator.Inventory.Node
  alias Exocomp.Coordinator.Registry, as: CoordinatorRegistry
  alias Exocomp.Coordinator.TaskRegistry, as: CoordinatorTaskRegistry
  alias Exocomp.Node.A2ARouter, as: NodeRouter
  alias Exocomp.Node.Safety.ReplayLedger
  alias Exocomp.Node.TaskRegistry, as: NodeTaskRegistry
  alias Exocomp.Recovery.Evidence

  @node_id "node-m4-a2a"
  @service "exocomp-fixture.service"

  defmodule RouterTransport do
    @moduledoc false

    @behaviour Exocomp.Coordinator.A2A.Transport

    @impl true
    def request(request, opts) do
      conn =
        request.method
        |> Plug.Test.conn(request.path, request.body)
        |> Plug.Test.put_peer_data(%{ssl_cert: <<1>>})
        |> put_headers(request.headers)
        |> maybe_put_content_type(request.method)
        |> Exocomp.Node.A2ARouter.call(Keyword.fetch!(opts, :router_opts))

      {:ok, conn.status, conn.resp_headers, conn.resp_body}
    end

    defp put_headers(conn, headers) do
      Enum.reduce(headers, conn, fn {key, value}, current ->
        Plug.Conn.put_req_header(current, key, value)
      end)
    end

    defp maybe_put_content_type(conn, :post),
      do: Plug.Conn.put_req_header(conn, "content-type", "application/json")

    defp maybe_put_content_type(conn, _method), do: conn
  end

  setup do
    node_registry = unique_name(:node_tasks)
    coordinator_tasks = unique_name(:coordinator_tasks)
    coordinator_registry = unique_name(:coordinator_registry)
    ledger = unique_name(:recovery_ledger)
    ledger_path = Path.join(System.tmp_dir!(), "#{ledger}.dets")

    start_supervised!({NodeTaskRegistry, name: node_registry})

    start_supervised!({ReplayLedger, name: ledger, table: ledger, path: ledger_path})

    start_supervised!({CoordinatorTaskRegistry, name: coordinator_tasks})
    start_supervised!({CoordinatorRegistry, name: coordinator_registry})

    node = %Node{
      id: @node_id,
      hostname: "node-m4-a2a.example.test",
      port: 4433,
      certificate_identity: "spiffe://node/#{@node_id}",
      capabilities: ["exocomp.service.diagnose", "exocomp.service.recover"]
    }

    :ok = CoordinatorRegistry.rebuild([node], coordinator_registry)

    :ok =
      CoordinatorRegistry.update(@node_id, %{addresses: ["192.0.2.126"]}, coordinator_registry)

    node_router_opts = NodeRouter.init(node_id: @node_id, registry: node_registry)

    put_app_env(:exocomp_node, :allowed_services, [@service])
    put_app_env(:exocomp_node, :service_recover_ledger, ledger)

    put_app_env(
      :exocomp_coordinator,
      :cluster_recover_client_opts,
      registry: coordinator_registry,
      transport: RouterTransport,
      transport_opts: [router_opts: node_router_opts]
    )

    put_app_env(:exocomp_coordinator, :cluster_recover_poll_interval_ms, 5)
    put_app_env(:exocomp_coordinator, :cluster_recover_timeout_ms, 5_000)
    put_app_env(:exocomp_coordinator, :authorized_node_ids, [@node_id])

    on_exit(fn -> File.rm(ledger_path) end)

    %{
      coordinator_router_opts:
        CoordinatorRouter.init(
          coordinator_id: "coordinator-m4",
          registry: coordinator_tasks
        )
    }
  end

  test "failed service recovers through coordinator and node A2A tasks", context do
    {:ok, audits} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> [] end)
    now = DateTime.utc_now()

    failed = evidence("failed", "failed", "unhealthy", "fresh-failed", now)
    healthy = evidence("active", "running", "healthy", "stable-healthy", now)

    put_app_env(:exocomp_node, :service_recover_audit_fun, fn event ->
      Agent.update(audits, &(&1 ++ [event]))
      :ok
    end)

    put_app_env(:exocomp_node, :service_recover_refresh_fun, fn _, _ -> {:ok, failed} end)
    put_app_env(:exocomp_node, :service_recover_verify_fun, fn _, _ -> {:ok, healthy} end)

    put_app_env(:exocomp_node, :service_recover_executor, fn action, service, allow_list ->
      Agent.update(executions, &(&1 ++ [{action, service, allow_list}]))
      {:ok, %{exit_code: 0, argv: ["systemctl", "restart", service]}}
    end)

    body = %{
      "role" => "user",
      "parts" => [
        %{
          "type" => "data",
          "data" => %{
            "skill" => "exocomp.cluster.recover",
            "node_id" => @node_id,
            "service" => @service,
            "evidence" => encode_evidence(failed)
          }
        }
      ]
    }

    submit =
      :post
      |> authenticated_json_conn("/message:send", body)
      |> CoordinatorRouter.call(context.coordinator_router_opts)

    assert submit.status == 202
    coordinator_task_id = Jason.decode!(submit.resp_body)["id"]
    assert_terminal(coordinator_task_id, context.coordinator_router_opts)

    result =
      :get
      |> authenticated_conn("/tasks/#{coordinator_task_id}")
      |> CoordinatorRouter.call(context.coordinator_router_opts)
      |> Map.fetch!(:resp_body)
      |> Jason.decode!()

    assert result["status"]["state"] == "completed"
    assert length(result["history"]) == 1
    assert [cluster_artifact] = result["artifacts"]
    assert cluster_artifact["name"] == "cluster-recover"
    assert [%{"data" => cluster_data}] = cluster_artifact["parts"]

    node_result = cluster_data["node_result"]
    assert node_result["status"] == "completed"
    assert node_result["history_length"] == 1
    assert [node_artifact] = node_result["artifacts"]
    assert node_artifact["name"] == "service-recover"
    assert [%{"data" => recovery}] = node_artifact["parts"]
    assert recovery["outcome"] == "completed"
    assert recovery["episode_id"] == node_result["task_id"]
    assert recovery["correlation_id"] == coordinator_task_id
    assert recovery["execution_attempted"] == true

    assert Agent.get(executions, & &1) == [
             {:restart_service, @service, [@service]}
           ]

    events = Agent.get(audits, & &1)

    assert Enum.map(events, & &1.event_tag) == [
             :unhealthy_observation,
             :evidence_complete,
             :validate,
             :failed_and_allowed,
             :execution_complete,
             :stable_health
           ]

    assert Enum.all?(events, &(&1.episode_id == node_result["task_id"]))
    assert Enum.all?(events, &(&1.correlation_id == coordinator_task_id))
  end

  defp authenticated_json_conn(method, path, body) do
    method
    |> authenticated_conn(path, Jason.encode!(body))
    |> put_req_header("content-type", "application/json")
  end

  defp authenticated_conn(method, path, body \\ nil) do
    method
    |> conn(path, body)
    |> put_peer_data(%{ssl_cert: <<1>>})
    |> put_req_header("a2a-version", "1.0")
  end

  defp assert_terminal(task_id, router_opts) do
    deadline = System.monotonic_time(:millisecond) + 5_000

    Stream.repeatedly(fn -> :poll end)
    |> Enum.reduce_while(nil, fn _, _ ->
      response =
        :get
        |> authenticated_conn("/tasks/#{task_id}")
        |> CoordinatorRouter.call(router_opts)
        |> Map.fetch!(:resp_body)
        |> Jason.decode!()

      case response["status"]["state"] do
        state when state in ["completed", "failed", "canceled"] ->
          {:halt, state}

        _state ->
          if System.monotonic_time(:millisecond) >= deadline do
            flunk("coordinator task #{task_id} did not reach a terminal state")
          else
            Process.sleep(10)
            {:cont, nil}
          end
      end
    end)
    |> then(&assert(&1 == "completed"))
  end

  defp evidence(active_state, sub_state, health, evidence_id, collected_at) do
    Evidence.new(
      @node_id,
      @service,
      %{
        "active_state" => active_state,
        "sub_state" => sub_state,
        "health" => health,
        "unit_name" => @service
      },
      evidence_id: evidence_id,
      collected_at: collected_at
    )
  end

  defp encode_evidence(evidence) do
    %{
      "evidence_id" => evidence.evidence_id,
      "collected_at" => DateTime.to_iso8601(evidence.collected_at),
      "node_id" => evidence.node_id,
      "service" => evidence.service,
      "collector_version" => evidence.collector_version,
      "data" => evidence.data
    }
  end

  defp put_app_env(app, key, value) do
    previous = Application.get_env(app, key)
    Application.put_env(app, key, value)

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(app, key)
      else
        Application.put_env(app, key, previous)
      end
    end)
  end

  defp unique_name(prefix) do
    :"#{prefix}_#{System.unique_integer([:positive, :monotonic])}"
  end
end
