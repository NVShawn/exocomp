# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceRecoverDefaultsTest do
  use ExUnit.Case, async: false

  alias Exocomp.Node.Skills.ServiceRecover
  alias Exocomp.Recovery.Evidence

  @service "fixture.service"

  @keys ~w[
    allowed_services
    service_health_checks
    service_recover_audit_fun
    service_recover_executor
    service_recover_health_request
    service_recover_refresh_fun
    service_recover_systemd_collector
    service_recover_verify_fun
    service_recover_wait_fun
  ]a

  setup do
    on_exit(fn -> Enum.each(@keys, &Application.delete_env(:exocomp_node, &1)) end)
    :ok
  end

  test "production defaults refresh, audit, execute once, and verify application health" do
    {:ok, state} = Agent.start_link(fn -> :failed end)
    test_pid = self()

    Application.put_env(:exocomp_node, :allowed_services, [@service])

    Application.put_env(:exocomp_node, :service_health_checks, %{
      @service => "http://127.0.0.1/health"
    })

    Application.put_env(:exocomp_node, :service_recover_systemd_collector, fn [@service] ->
      case Agent.get(state, & &1) do
        :failed -> observation("failed", "failed")
        :healthy -> observation("active", "running")
      end
    end)

    Application.put_env(:exocomp_node, :service_recover_health_request, fn _url ->
      {:ok, "healthy"}
    end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn
      :restart_service, @service, [@service] ->
        send(test_pid, :executed)
        Agent.update(state, fn _ -> :healthy end)
        {:ok, %{exit_code: 0, verified: true}}
    end)

    Application.put_env(:exocomp_node, :service_recover_wait_fun, fn -> :ok end)

    initial = Evidence.new("node-1", @service, failed_data(), evidence_id: "initial-default")

    params = %{
      "node_id" => "node-1",
      "service" => @service,
      "evidence" => %{
        "evidence_id" => initial.evidence_id,
        "collected_at" => DateTime.to_iso8601(initial.collected_at),
        "node_id" => initial.node_id,
        "service" => initial.service,
        "collector_version" => initial.collector_version,
        "data" => initial.data
      }
    }

    assert {:ok, artifact} =
             ServiceRecover.execute(params, %{
               task_id: "default-task-#{System.unique_integer([:positive])}"
             })

    assert artifact.name == "service-recover"
    assert_received :executed
    refute_received :executed
    assert [%Exocomp.A2A.DataPart{data: %{"outcome" => "completed"}}] = artifact.parts
  end

  defp observation(active_state, sub_state) do
    %{
      measurements: %{
        fixture_service_activestate: %{value: active_state, unit: "string"},
        fixture_service_substate: %{value: sub_state, unit: "string"}
      }
    }
  end

  defp failed_data do
    %{active_state: "failed", sub_state: "failed", health: "unhealthy"}
  end
end
