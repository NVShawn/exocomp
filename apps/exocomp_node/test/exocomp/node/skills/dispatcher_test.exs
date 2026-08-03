# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.DispatcherTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.Artifact
  alias Exocomp.Node.Skills.Dispatcher

  # ---------------------------------------------------------------------------
  # Helpers — install fake collectors / client for each handler
  # ---------------------------------------------------------------------------

  defp fake_observation(source) do
    %{
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      source: source,
      collector_version: 1,
      duration_us: 50,
      measurements: %{test_field: %{value: 1, unit: "unit"}}
    }
  end

  defp install_system_fakes do
    collectors = %{
      cpu: fn -> fake_observation(Exocomp.Node.Collectors.CPU) end,
      memory: fn -> fake_observation(Exocomp.Node.Collectors.Memory) end,
      disk: fn -> fake_observation(Exocomp.Node.Collectors.Disk) end,
      uptime: fn -> fake_observation(Exocomp.Node.Collectors.Uptime) end
    }

    Application.put_env(:exocomp_node, :system_diagnose_collectors, collectors)
    on_exit(fn -> Application.delete_env(:exocomp_node, :system_diagnose_collectors) end)
  end

  defp install_service_fakes do
    Application.put_env(:exocomp_node, :allowed_services, ["sshd.service"])

    Application.put_env(:exocomp_node, :service_diagnose_systemd_collector, fn services ->
      fake_observation({:systemd, services})
    end)

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :allowed_services)
      Application.delete_env(:exocomp_node, :service_diagnose_systemd_collector)
    end)
  end

  defp install_observe_fakes do
    Application.put_env(:exocomp_node, :allowed_services, ["sshd.service"])

    Application.put_env(:exocomp_node, :service_observe_systemd_collector, fn services ->
      fake_observation({:systemd, services})
    end)

    Application.put_env(:exocomp_node, :service_observe_http_prober, fn _url, _timeout, _max ->
      {:ok, 200, 42, 512}
    end)

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :allowed_services)
      Application.delete_env(:exocomp_node, :service_observe_systemd_collector)
      Application.delete_env(:exocomp_node, :service_observe_http_prober)
    end)
  end

  defp install_remediation_fake do
    Application.put_env(:exocomp_node, :remediation_propose_client, fn _ctx ->
      {:ok,
       %{
         "schema_version" => "1",
         "proposal_id" => "restart_service",
         "rationale" => "Test",
         "affected_resource" => "nginx.service",
         "confidence" => 0.9
       }}
    end)

    on_exit(fn -> Application.delete_env(:exocomp_node, :remediation_propose_client) end)
  end

  defp install_recover_fakes do
    now = DateTime.utc_now()
    Application.put_env(:exocomp_node, :allowed_services, ["sshd.service"])

    healthy_data = %{
      "active_state" => "active",
      "sub_state" => "running",
      "health" => "healthy",
      "unit_name" => "sshd.service"
    }

    Application.put_env(:exocomp_node, :service_recover_audit_fun, fn _ev -> :ok end)

    Application.put_env(:exocomp_node, :service_recover_refresh_fun, fn _nid, _svc ->
      {:ok, Exocomp.Recovery.Evidence.new("n1", "sshd.service", healthy_data, collected_at: now)}
    end)

    Application.put_env(:exocomp_node, :service_recover_verify_fun, fn _nid, _svc ->
      {:ok, Exocomp.Recovery.Evidence.new("n1", "sshd.service", healthy_data, collected_at: now)}
    end)

    Application.put_env(:exocomp_node, :service_recover_executor, fn :restart_service,
                                                                     _svc,
                                                                     _al ->
      {:ok, %{exit_code: 0, argv: ["systemctl", "restart", "sshd.service"]}}
    end)

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :allowed_services)
      Application.delete_env(:exocomp_node, :service_recover_audit_fun)
      Application.delete_env(:exocomp_node, :service_recover_refresh_fun)
      Application.delete_env(:exocomp_node, :service_recover_verify_fun)
      Application.delete_env(:exocomp_node, :service_recover_executor)
    end)
  end

  # ---------------------------------------------------------------------------
  # Test: routes each known skill_id to the correct handler
  # ---------------------------------------------------------------------------

  test "routes 'exocomp.system.diagnose' to SystemDiagnose" do
    install_system_fakes()
    assert {:ok, %Artifact{}} = Dispatcher.dispatch("exocomp.system.diagnose")
  end

  test "routes 'exocomp.service.diagnose' to ServiceDiagnose" do
    install_service_fakes()

    assert {:ok, %Artifact{}} =
             Dispatcher.dispatch("exocomp.service.diagnose", %{"services" => ["sshd.service"]})
  end

  test "routes 'exocomp.service.observe' to ServiceObserve" do
    install_observe_fakes()

    assert {:ok, %Artifact{name: "service-observe"}} =
             Dispatcher.dispatch("exocomp.service.observe", %{"services" => ["sshd.service"]})
  end

  test "routes 'exocomp.service.observe' with probes to ServiceObserve" do
    install_observe_fakes()

    assert {:ok, %Artifact{name: "service-observe"}} =
             Dispatcher.dispatch("exocomp.service.observe", %{
               "services" => ["sshd.service"],
               "probes" => [%{"url" => "http://127.0.0.1:8080/health"}]
             })
  end

  test "routes 'exocomp.remediation.propose' to RemediationPropose" do
    install_remediation_fake()

    assert {:ok, %Artifact{}} =
             Dispatcher.dispatch("exocomp.remediation.propose", %{"cpu" => 90})
  end

  test "routes 'exocomp.service.recover' to ServiceRecover" do
    install_recover_fakes()
    now = DateTime.utc_now()

    evidence_map = %{
      "evidence_id" => "ev-disp-test",
      "collected_at" => DateTime.to_iso8601(now),
      "node_id" => "n1",
      "service" => "sshd.service",
      "collector_version" => "1.0",
      "data" => %{
        "active_state" => "failed",
        "sub_state" => "failed",
        "health" => "unhealthy",
        "unit_name" => "sshd.service"
      }
    }

    params = %{
      "service" => "sshd.service",
      "node_id" => "n1",
      "evidence" => evidence_map
    }

    assert {:ok, %Artifact{name: "service-recover"}} =
             Dispatcher.dispatch("exocomp.service.recover", params, %{
               task_id: "dispatcher-node-task",
               correlation_id: "dispatcher-workflow"
             })
  end

  # ---------------------------------------------------------------------------
  # Test: unknown skill → {:error, :unknown_skill}
  # ---------------------------------------------------------------------------

  test "unknown skill returns {:error, :unknown_skill}" do
    assert {:error, :unknown_skill} = Dispatcher.dispatch("exocomp.unknown.skill")
  end

  test "empty string skill_id returns {:error, :unknown_skill}" do
    assert {:error, :unknown_skill} = Dispatcher.dispatch("")
  end
end
