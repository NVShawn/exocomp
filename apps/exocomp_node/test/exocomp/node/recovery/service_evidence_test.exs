# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.ServiceEvidenceTest do
  use ExUnit.Case, async: false

  alias Exocomp.Node.Recovery.ServiceEvidence

  setup do
    on_exit(fn ->
      Application.delete_env(:exocomp_node, :service_health_checks)
      Application.delete_env(:exocomp_node, :service_recover_health_request)
      Application.delete_env(:exocomp_node, :service_recover_systemd_collector)
    end)

    :ok
  end

  test "combines systemd state with the configured application health endpoint" do
    Application.put_env(
      :exocomp_node,
      :service_recover_systemd_collector,
      systemd_collector("active", "running")
    )

    Application.put_env(
      :exocomp_node,
      :service_health_checks,
      %{"fixture.service" => "http://127.0.0.1:8877/health"}
    )

    Application.put_env(:exocomp_node, :service_recover_health_request, fn url ->
      assert url == "http://127.0.0.1:8877/health"
      {:ok, "healthy"}
    end)

    assert {:ok, evidence} = ServiceEvidence.collect("node-1", "fixture.service")
    assert evidence.data.active_state == "active"
    assert evidence.data.sub_state == "running"
    assert evidence.data.health == "healthy"
  end

  test "fails closed when an active service has no application health check" do
    Application.put_env(
      :exocomp_node,
      :service_recover_systemd_collector,
      systemd_collector("active", "running")
    )

    assert {:error, {:health_check_not_configured, "fixture.service"}} =
             ServiceEvidence.collect("node-1", "fixture.service")
  end

  test "records failed systemd state without probing an unavailable application" do
    Application.put_env(
      :exocomp_node,
      :service_recover_systemd_collector,
      systemd_collector("failed", "failed")
    )

    assert {:ok, evidence} = ServiceEvidence.collect("node-1", "fixture.service")
    assert evidence.data.health == "unhealthy"
  end

  defp systemd_collector(active_state, sub_state) do
    fn ["fixture.service"] ->
      %{
        measurements: %{
          fixture_service_activestate: %{value: active_state, unit: "string"},
          fixture_service_substate: %{value: sub_state, unit: "string"}
        }
      }
    end
  end
end
