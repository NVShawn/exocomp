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

  test "routes 'exocomp.remediation.propose' to RemediationPropose" do
    install_remediation_fake()

    assert {:ok, %Artifact{}} =
             Dispatcher.dispatch("exocomp.remediation.propose", %{"cpu" => 90})
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
