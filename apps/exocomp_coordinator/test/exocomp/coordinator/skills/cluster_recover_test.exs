# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Skills.ClusterRecoverTest do
  @moduledoc """
  Unit tests for `Exocomp.Coordinator.Skills.ClusterRecover`.

  Uses injectable `:cluster_recover_node_client` so no real node agent
  or transport is needed.
  """

  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart, Task, TaskStatus}
  alias Exocomp.Coordinator.Skills.ClusterRecover

  @node_id "node-1"
  @service "exocomp-fixture.service"

  # ---------------------------------------------------------------------------
  # Fake node clients
  # ---------------------------------------------------------------------------

  defmodule TerminalNodeClient do
    @moduledoc "Immediately returns a terminal completed task."

    def send(_node_id, "exocomp.service.recover", _params, _opts \\ []) do
      {:ok,
       %Task{
         id: "node-task-1",
         status: %TaskStatus{state: :completed, timestamp: "2026-07-25T14:00:00Z"},
         artifacts: [],
         history: [],
         metadata: %{}
       }}
    end

    def get_task(_node_id, _task_id, _opts \\ []) do
      {:error, :should_not_poll}
    end
  end

  defmodule WorkingThenCompleted do
    @moduledoc "Returns :working on send, :completed on poll."

    def send(_node_id, "exocomp.service.recover", _params, _opts \\ []) do
      {:ok,
       %Task{
         id: "node-task-working",
         status: %TaskStatus{state: :working, timestamp: "2026-07-25T14:00:00Z"},
         artifacts: [],
         history: [],
         metadata: %{}
       }}
    end

    def get_task(_node_id, "node-task-working", _opts \\ []) do
      {:ok,
       %Task{
         id: "node-task-working",
         status: %TaskStatus{state: :completed, timestamp: "2026-07-25T14:00:01Z"},
         artifacts: [],
         history: [],
         metadata: %{}
       }}
    end
  end

  defmodule FailedNodeClient do
    @moduledoc "Returns a transport error from send."

    def send(_node_id, "exocomp.service.recover", _params, _opts \\ []) do
      {:error, :transport_error}
    end

    def get_task(_node_id, _task_id, _opts \\ []), do: {:error, :should_not_poll}
  end

  defmodule ForwardingCapture do
    @moduledoc "Stores the forwarded params in the process dictionary for assertion."

    def send(_node_id, "exocomp.service.recover", params, opts \\ []) do
      # Notify the caller (test process) via process dictionary key written
      # before the call — use :erlang.send to avoid naming ambiguity.
      owner = Process.get(:capture_owner)
      if owner, do: :erlang.send(owner, {:captured_request, params, opts})

      {:ok,
       %Task{
         id: "node-task-cap",
         status: %TaskStatus{state: :completed, timestamp: "2026-07-25T14:00:00Z"},
         artifacts: [],
         history: [],
         metadata: %{}
       }}
    end

    def get_task(_node_id, _task_id, _opts \\ []), do: {:error, :should_not_poll}
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp base_params do
    %{
      "node_id" => @node_id,
      "service" => @service,
      "evidence" => %{
        "evidence_id" => "ev-1",
        "collected_at" => "2026-07-25T14:00:00Z",
        "node_id" => @node_id,
        "service" => @service,
        "collector_version" => "1.0",
        "data" => %{"active_state" => "failed"}
      }
    }
  end

  defp put_client(client) do
    Application.put_env(:exocomp_coordinator, :cluster_recover_node_client, client)
    Application.put_env(:exocomp_coordinator, :cluster_recover_poll_interval_ms, 10)

    on_exit(fn ->
      Application.delete_env(:exocomp_coordinator, :cluster_recover_node_client)
      Application.delete_env(:exocomp_coordinator, :cluster_recover_poll_interval_ms)
    end)
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "returns a cluster-recover artifact when node task is immediately terminal" do
    put_client(TerminalNodeClient)

    assert {:ok, %Artifact{} = artifact} = ClusterRecover.execute(base_params(), %{})

    assert artifact.name == "cluster-recover"
    assert [%DataPart{data: data}] = artifact.parts
    assert data["skill"] == "exocomp.cluster.recover"
    assert data["node_id"] == @node_id
    assert data["schema_version"] == "1"
    assert is_map(data["node_result"])
    assert data["node_result"]["status"] == "completed"
  end

  test "polls until the node task reaches a terminal state" do
    put_client(WorkingThenCompleted)

    assert {:ok, %Artifact{} = artifact} = ClusterRecover.execute(base_params(), %{})

    assert artifact.name == "cluster-recover"
    [%DataPart{data: data}] = artifact.parts
    assert data["node_result"]["status"] == "completed"
  end

  test "returns error when node client fails to send" do
    put_client(FailedNodeClient)

    assert {:error, {:node_recovery_failed, @node_id, :transport_error}} =
             ClusterRecover.execute(base_params(), %{})
  end

  test "returns invalid_params when node_id is missing" do
    put_client(TerminalNodeClient)

    params = Map.delete(base_params(), "node_id")
    assert {:error, :invalid_params} = ClusterRecover.execute(params, %{})
  end

  test "returns invalid_params when service is missing" do
    put_client(TerminalNodeClient)

    params = Map.delete(base_params(), "service")
    assert {:error, :invalid_params} = ClusterRecover.execute(params, %{})
  end

  test "returns invalid_params when evidence is missing" do
    put_client(TerminalNodeClient)

    params = Map.delete(base_params(), "evidence")
    assert {:error, :invalid_params} = ClusterRecover.execute(params, %{})
  end

  test "forwards only the target and evidence while propagating trusted workflow context" do
    put_client(ForwardingCapture)
    # Register self as the capture owner so ForwardingCapture can notify us.
    Process.put(:capture_owner, self())

    params =
      Map.merge(base_params(), %{
        "allow_list" => [@service],
        "task_id" => "custom-episode"
      })

    assert {:ok, _artifact} = ClusterRecover.execute(params, %{})

    assert_receive {:captured_request, forwarded, opts}, 1_000
    refute Map.has_key?(forwarded, "allow_list")
    refute Map.has_key?(forwarded, "task_id")
    assert forwarded["service"] == @service
    assert forwarded["node_id"] == @node_id
    refute Keyword.has_key?(opts, :context_id)

    assert {:ok, _artifact} =
             ClusterRecover.execute(params, %{
               task_id: "coordinator-task",
               correlation_id: "workflow-correlation"
             })

    assert_receive {:captured_request, _forwarded, correlated_opts}, 1_000
    assert correlated_opts[:context_id] == "workflow-correlation"
  end
end
