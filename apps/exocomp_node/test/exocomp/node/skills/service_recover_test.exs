# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceRecoverTest do
  @moduledoc """
  Unit tests for `Exocomp.Node.Skills.ServiceRecover`.

  Uses fully injected callbacks via Application config so no real systemd,
  executor, or persistent ledger is needed.
  """

  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.ServiceRecover
  alias Exocomp.Recovery.Evidence

  @service "exocomp-fixture.service"
  @node_id "node-test"

  setup do
    previous = Application.get_env(:exocomp_node, :allowed_services)
    Application.put_env(:exocomp_node, :allowed_services, [@service])

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:exocomp_node, :allowed_services)
      else
        Application.put_env(:exocomp_node, :allowed_services, previous)
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Always generate evidence with a fresh collected_at so the FailedService
  # freshness check (max 300s) does not reject it.
  defp evidence_map(active \\ "failed", sub \\ "failed", health \\ "unhealthy") do
    ev =
      Evidence.new(
        @node_id,
        @service,
        %{
          "active_state" => active,
          "sub_state" => sub,
          "health" => health,
          "unit_name" => @service
        },
        evidence_id: "ev-test-#{System.unique_integer([:positive])}",
        collected_at: DateTime.utc_now()
      )

    %{
      "evidence_id" => ev.evidence_id,
      "collected_at" => DateTime.to_iso8601(ev.collected_at),
      "node_id" => ev.node_id,
      "service" => ev.service,
      "collector_version" => ev.collector_version,
      "data" => ev.data
    }
  end

  defp healthy_evidence_map do
    evidence_map("active", "running", "healthy")
  end

  defp failed_params(extra \\ %{}) do
    Map.merge(
      %{
        "service" => @service,
        "node_id" => @node_id,
        "evidence" => evidence_map()
      },
      extra
    )
  end

  defp install_success_callbacks(audit_agent, exec_agent) do
    healthy = healthy_evidence_map()
    failed = evidence_map()

    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn event ->
      Agent.update(audit_agent, &(&1 ++ [event]))
      :ok
    end)

    Application.put_env(:exocomp_node, :service_recover_refresh_fun, fn _, _ ->
      {:ok,
       Evidence.new(@node_id, @service, failed["data"],
         evidence_id: "refreshed",
         collected_at: DateTime.utc_now()
       )}
    end)

    Application.put_env(:exocomp_node, :service_recover_verify_fun, fn _, _ ->
      {:ok,
       Evidence.new(@node_id, @service, healthy["data"],
         evidence_id: "verified",
         collected_at: DateTime.utc_now()
       )}
    end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn :restart_service,
                                                                     _service,
                                                                     _allow_list ->
      Agent.update(exec_agent, &(&1 + 1))
      {:ok, %{exit_code: 0, argv: ["systemctl", "restart", @service]}}
    end)
  end

  defp cleanup_callbacks do
    Application.delete_env(:exocomp_node, :service_recover_audit_fun)
    Application.delete_env(:exocomp_node, :service_recover_refresh_fun)
    Application.delete_env(:exocomp_node, :service_recover_verify_fun)
    Application.delete_env(:exocomp_node, :service_recover_executor)
  end

  # ---------------------------------------------------------------------------
  # Happy path
  # ---------------------------------------------------------------------------

  test "returns a service-recover artifact when recovery completes successfully" do
    {:ok, audits} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> 0 end)
    install_success_callbacks(audits, executions)

    try do
      params = failed_params()
      suffix = System.unique_integer([:positive, :monotonic])
      task_id = "node-task-#{suffix}"
      correlation_id = "workflow-#{suffix}"
      context = %{task_id: task_id, correlation_id: correlation_id}
      assert {:ok, %Artifact{} = artifact} = ServiceRecover.execute(params, context)

      assert artifact.name == "service-recover"
      assert [%DataPart{data: data}] = artifact.parts
      assert data["outcome"] == "completed"
      assert data["service"] == @service
      assert data["execution_attempted"] == true
      assert data["schema_version"] == "1"
      assert data["skill"] == "exocomp.service.recover"
      assert data["episode_id"] == task_id
      assert data["correlation_id"] == correlation_id
      assert is_list(data["inner_artifacts"])
    after
      cleanup_callbacks()
    end
  end

  test "exactly one executor invocation on the happy path" do
    {:ok, audits} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> 0 end)
    install_success_callbacks(audits, executions)

    try do
      ServiceRecover.execute(failed_params(), %{})
      assert Agent.get(executions, & &1) == 1
    after
      cleanup_callbacks()
    end
  end

  test "audit trail contains the full event sequence" do
    {:ok, audits} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> 0 end)
    install_success_callbacks(audits, executions)

    try do
      ServiceRecover.execute(failed_params(), %{})

      tags = Enum.map(Agent.get(audits, & &1), & &1.event_tag)
      assert :unhealthy_observation in tags
      assert :failed_and_allowed in tags
      assert :execution_complete in tags
      assert :stable_health in tags
    after
      cleanup_callbacks()
    end
  end

  # ---------------------------------------------------------------------------
  # Param validation
  # ---------------------------------------------------------------------------

  test "returns invalid_params when service is missing" do
    params = %{
      "node_id" => @node_id,
      "evidence" => evidence_map()
    }

    assert {:error, :invalid_params} = ServiceRecover.execute(params, %{})
  end

  test "returns invalid_params when node_id is missing" do
    params = %{
      "service" => @service,
      "evidence" => evidence_map()
    }

    assert {:error, :invalid_params} = ServiceRecover.execute(params, %{})
  end

  test "returns invalid_params when evidence is missing" do
    params = %{
      "service" => @service,
      "node_id" => @node_id
    }

    assert {:error, :invalid_params} = ServiceRecover.execute(params, %{})
  end

  test "returns error when evidence is malformed (missing evidence_id)" do
    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn _ -> :ok end)

    Application.put_env(:exocomp_node, :service_recover_refresh_fun, fn _, _ ->
      {:error, :noop}
    end)

    Application.put_env(:exocomp_node, :service_recover_verify_fun, fn _, _ -> {:error, :noop} end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn _, _, _ ->
      {:error, :noop}
    end)

    try do
      bad_evidence = Map.delete(evidence_map(), "evidence_id")

      params = %{
        "service" => @service,
        "node_id" => @node_id,
        "evidence" => bad_evidence
      }

      assert {:error, _} = ServiceRecover.execute(params, %{})
    after
      cleanup_callbacks()
    end
  end

  # ---------------------------------------------------------------------------
  # Allow-list rejection
  # ---------------------------------------------------------------------------

  test "caller cannot broaden the configured service allow-list" do
    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn _ -> :ok end)

    Application.put_env(:exocomp_node, :service_recover_refresh_fun, fn _, _ ->
      {:error, :noop}
    end)

    Application.put_env(:exocomp_node, :service_recover_verify_fun, fn _, _ -> {:error, :noop} end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn _, _, _ ->
      {:error, :noop}
    end)

    Application.put_env(:exocomp_node, :allowed_services, ["other-service.service"])

    try do
      params = failed_params(%{"allow_list" => [@service]})

      assert {:error, {:recovery_failed, {:service_not_allowed, @service}}} =
               ServiceRecover.execute(params, %{})
    after
      cleanup_callbacks()
    end
  end

  # ---------------------------------------------------------------------------
  # Non-failed service rejection
  # ---------------------------------------------------------------------------

  test "returns recovery_failed when evidence shows active service" do
    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn _ -> :ok end)

    Application.put_env(:exocomp_node, :service_recover_refresh_fun, fn _, _ ->
      {:error, :noop}
    end)

    Application.put_env(:exocomp_node, :service_recover_verify_fun, fn _, _ -> {:error, :noop} end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn _, _, _ ->
      {:error, :noop}
    end)

    try do
      params = %{
        "service" => @service,
        "node_id" => @node_id,
        "evidence" => evidence_map("active", "running", "healthy")
      }

      assert {:error, {:recovery_failed, {:not_failed_service, "active"}}} =
               ServiceRecover.execute(params, %{})
    after
      cleanup_callbacks()
    end
  end

  test "fails closed when the durable audit sink is unavailable" do
    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn _ ->
      {:error, :audit_sink_not_configured}
    end)

    assert {:error, {:recovery_failed, {:audit_unavailable, :audit_sink_not_configured}}} =
             ServiceRecover.execute(failed_params(), %{})
  end
end
