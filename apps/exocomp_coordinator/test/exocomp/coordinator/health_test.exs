# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.HealthTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Health

  test "returns a structured snapshot for every coordinator subsystem" do
    result = Health.check()

    assert %{
             status: status,
             audit: %{healthy: audit_healthy},
             inventory: %{node_count: _node_count},
             registry: %{node_count: _reg_count},
             pki: pki,
             listener: %{running: listener_running},
             enrollment_token: %{running: enrollment_running}
           } = result

    assert status in [:healthy, :degraded]
    assert is_boolean(audit_healthy)
    assert is_map(pki)
    assert is_boolean(listener_running)
    assert is_boolean(enrollment_running)
  end

  test "health is degraded when PKI components are absent (test mode)" do
    # In test mode, PKI.State, Listener, and EnrollmentToken are not started;
    # health must be :degraded and components reported as not running.
    result = Health.check()

    assert result.status == :degraded
    assert result.pki.error == :not_running
    assert result.listener.running == false
    assert result.enrollment_token.running == false
  end
end
