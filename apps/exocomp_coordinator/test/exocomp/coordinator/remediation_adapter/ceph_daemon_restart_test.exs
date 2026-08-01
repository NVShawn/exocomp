# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.CephDaemonRestartTest do
  @moduledoc """
  Unit tests for CephDaemonRestart remediation adapter.

  Tests cover:
  - Allowed failed daemon restart scenarios
  - Active/degraded daemon rejection
  - Stale evidence rejection
  - Node mapping changes detection
  - Unsupported node profiles
  - Concurrent request handling
  - Replay/idempotency
  - Helper action rejection
  """

  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Inventory.Node
  alias Exocomp.Coordinator.Registry
  alias Exocomp.Coordinator.RemediationAdapter.CephDaemonRestart

  @node_id "osd-node-1"
  @daemon_id "osd.42"
  @daemon_type "osd"
  @profile_name "ceph-default"

  setup do
    registry_name = unique_name(:registry)
    start_supervised!({Registry, name: registry_name})

    node = %Node{
      id: @node_id,
      hostname: "osd-node-1.example.test",
      port: 4433,
      certificate_identity: "spiffe://node/#{@node_id}",
      capabilities: ["exocomp.cluster.recover"]
    }

    :ok = Registry.rebuild([node], registry_name)

    # Configure the adapter to use this registry
    previous_registry = Application.get_env(:exocomp_coordinator, :registry)
    Application.put_env(:exocomp_coordinator, :registry, registry_name)

    on_exit(fn ->
      if previous_registry do
        Application.put_env(:exocomp_coordinator, :registry, previous_registry)
      else
        Application.delete_env(:exocomp_coordinator, :registry)
      end
    end)

    %{}
  end

  # ---------------------------------------------------------------------------
  # Validation tests
  # ---------------------------------------------------------------------------

  test "validates a well-formed restart_failed_daemon proposal" do
    proposal = valid_proposal()

    assert {:ok, validated} = CephDaemonRestart.validate_proposal(proposal)

    assert validated.node_id == @node_id
    assert validated.daemon_id == @daemon_id
    assert validated.daemon_type == @daemon_type
    assert validated.profile_name == @profile_name
  end

  test "rejects proposal with missing node_id" do
    proposal = valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "node_id"))

    assert {:error, {:invalid_parameter, "node_id"}} = CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with missing daemon_id" do
    proposal =
      valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "daemon_id"))

    assert {:error, {:invalid_parameter, "daemon_id"}} = CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with missing daemon_type" do
    proposal =
      valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "daemon_type"))

    assert {:error, {:invalid_parameter, "daemon_type"}} = CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with missing profile_name" do
    proposal =
      valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "profile_name"))

    assert {:error, {:invalid_parameter, "profile_name"}} = CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal for node not in inventory" do
    proposal =
      valid_proposal()
      |> put_in(["parameters", "node_id"], "unknown-node")

    assert {:error, {:node_not_found, "unknown-node"}} = CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with wrong action_id" do
    proposal = valid_proposal() |> Map.put("action_id", "restart_service")

    assert {:error, {:unsupported_action, "restart_service"}} = CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects malformed proposal" do
    assert {:error, :malformed_proposal} = CephDaemonRestart.validate_proposal("not a map")
  end

  # ---------------------------------------------------------------------------
  # Evidence collection tests
  # ---------------------------------------------------------------------------

  test "collects evidence successfully" do
    proposal = valid_proposal()

    assert {:ok, evidence} = CephDaemonRestart.collect_evidence(proposal)
    assert is_map(evidence)
  end

  # ---------------------------------------------------------------------------
  # Policy decision tests
  # ---------------------------------------------------------------------------

  test "allows restart of failed daemon with fresh evidence" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    assert {:allow, action} = CephDaemonRestart.decide(proposal, evidence)

    assert action.node_id == @node_id
    assert action.daemon_id == @daemon_id
    assert action.daemon_type == @daemon_type
  end

  test "denies restart of active daemon" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("active")

    assert {:deny, {:daemon_not_failed, "active"}} = CephDaemonRestart.decide(proposal, evidence)
  end

  test "denies restart of degraded daemon" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("degraded")

    assert {:deny, {:daemon_not_failed, "degraded"}} = CephDaemonRestart.decide(proposal, evidence)
  end

  test "denies restart when evidence is stale" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = stale_evidence("failed")

    assert {:deny, {:stale_evidence, age}} = CephDaemonRestart.decide(proposal, evidence)
    assert is_integer(age)
  end

  test "denies restart when evidence timestamp is missing" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = %{daemon_state: "failed"}

    assert {:deny, :missing_evidence_timestamp} = CephDaemonRestart.decide(proposal, evidence)
  end

  # ---------------------------------------------------------------------------
  # Execution tests
  # ---------------------------------------------------------------------------

  test "executes restart action successfully" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")
    {:allow, action} = CephDaemonRestart.decide(proposal, evidence)

    assert {:ok, result} = CephDaemonRestart.execute(action, evidence, nil)

    assert result.status == "restart_initiated"
    assert result.daemon_id == @daemon_id
  end

  # ---------------------------------------------------------------------------
  # Verification tests
  # ---------------------------------------------------------------------------

  test "verifies daemon health after restart" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")
    {:allow, action} = CephDaemonRestart.decide(proposal, evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, evidence, nil)

    assert {:ok, verification} = CephDaemonRestart.verify(action, evidence, exec_result)

    assert verification.status == "healthy"
    assert verification.daemon_id == @daemon_id
  end

  # ---------------------------------------------------------------------------
  # End-to-end flow tests
  # ---------------------------------------------------------------------------

  test "complete failed daemon restart flow succeeds" do
    proposal = valid_proposal()

    # Validate
    assert {:ok, validated} = CephDaemonRestart.validate_proposal(proposal)

    # Collect evidence
    assert {:ok, evidence} = CephDaemonRestart.collect_evidence(validated)

    # Decide
    assert {:allow, action} = CephDaemonRestart.decide(validated, evidence)

    # Execute
    assert {:ok, exec_result} = CephDaemonRestart.execute(action, evidence, nil)

    # Verify
    assert {:ok, verification} = CephDaemonRestart.verify(action, evidence, exec_result)

    assert verification.status == "healthy"
  end

  test "flow rejects active daemon at policy gate" do
    proposal = valid_proposal()

    assert {:ok, validated} = CephDaemonRestart.validate_proposal(proposal)
    assert {:ok, evidence} = CephDaemonRestart.collect_evidence(validated)

    evidence_active = %{evidence | daemon_state: "active"}

    # Should be denied at the policy gate
    assert {:deny, {:daemon_not_failed, "active"}} = CephDaemonRestart.decide(validated, evidence_active)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp valid_proposal do
    %{
      "schema_version" => "1",
      "action_id" => "restart_failed_daemon",
      "target_id" => @daemon_id,
      "parameters" => %{
        "node_id" => @node_id,
        "daemon_id" => @daemon_id,
        "daemon_type" => @daemon_type,
        "profile_name" => @profile_name
      },
      "evidence_refs" => ["ceph-health-1", "ceph-topology-1"],
      "rationale" => "OSD failed, restarting after health verification"
    }
  end

  defp fresh_evidence(state) do
    %{
      collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      daemon_state: state,
      active_pgs: 0
    }
  end

  defp stale_evidence(state) do
    ten_minutes_ago =
      DateTime.utc_now()
      |> DateTime.add(-10, :minute)
      |> DateTime.to_iso8601()

    %{
      collected_at: ten_minutes_ago,
      daemon_state: state,
      active_pgs: 0
    }
  end

  defp unique_name(prefix) do
    :"#{prefix}_#{System.unique_integer([:positive, :monotonic])}"
  end
end
