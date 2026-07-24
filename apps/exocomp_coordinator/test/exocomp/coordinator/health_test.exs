defmodule Exocomp.Coordinator.HealthTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Health

  test "returns a structured snapshot for every coordinator subsystem" do
    assert %{
             status: status,
             audit: %{healthy: audit_healthy},
             inventory: %{node_count: node_count},
             registry: %{node_count: node_count}
           } = Health.check()

    assert status in [:healthy, :degraded]
    assert is_boolean(audit_healthy)
    assert is_integer(node_count)
  end
end
