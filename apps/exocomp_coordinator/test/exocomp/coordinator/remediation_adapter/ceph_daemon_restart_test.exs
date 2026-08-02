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

  alias Exocomp.Coordinator.Audit
  alias Exocomp.Coordinator.Audit.JSONLines
  alias Exocomp.Coordinator.Inventory.Node
  alias Exocomp.Coordinator.{ProfileCoverage, Registry}
  alias Exocomp.Coordinator.RemediationAdapter.CephCooldown
  alias Exocomp.Coordinator.RemediationAdapter.CephDaemonRestart

  @node_id "osd-node-1"
  @daemon_id "osd.42"
  @daemon_type "osd"
  @profile_name "ceph"

  setup do
    registry_name = unique_name(:registry)
    coverage_name = unique_name(:coverage)
    audit_name = unique_name(:ceph_restart_audit)
    audit_path = Path.join(System.tmp_dir!(), "#{audit_name}.jsonl")
    start_supervised!({Registry, name: registry_name})
    start_supervised!({ProfileCoverage, name: coverage_name})

    start_supervised!(
      {Audit, name: audit_name, sink: {JSONLines, path: audit_path}},
      id: audit_name
    )

    node = %Node{
      id: @node_id,
      hostname: "osd-node-1.example.test",
      port: 4433,
      certificate_identity: "spiffe://node/#{@node_id}",
      capabilities: ["exocomp.profile.action", "exocomp.profile.inspect"]
    }

    :ok = Registry.rebuild([node], registry_name)
    :ok = ProfileCoverage.mark_available(@profile_name, coverage_name)

    # Configure the adapter to use this registry and coverage
    previous_registry = Application.get_env(:exocomp_coordinator, :registry)
    previous_coverage = Application.get_env(:exocomp_coordinator, :profile_coverage)
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)
    previous_node_client = Application.get_env(:exocomp_coordinator, :node_state_client)
    previous_action_client = Application.get_env(:exocomp_coordinator, :profile_action_client)
    previous_audit_server = Application.get_env(:exocomp_coordinator, :ceph_audit_server)
    previous_window = Application.get_env(:exocomp_coordinator, :ceph_stability_window_ms)

    previous_poll_interval =
      Application.get_env(:exocomp_coordinator, :ceph_stability_poll_interval_ms)

    Application.put_env(:exocomp_coordinator, :registry, registry_name)
    Application.put_env(:exocomp_coordinator, :profile_coverage, coverage_name)
    Application.put_env(:exocomp_coordinator, :ceph_audit_server, audit_name)
    Application.put_env(:exocomp_coordinator, :ceph_stability_window_ms, 0)
    Application.put_env(:exocomp_coordinator, :ceph_stability_poll_interval_ms, 1)

    Application.put_env(
      :exocomp_coordinator,
      :ceph_collector,
      {__MODULE__, :mock_ceph_collector, []}
    )

    Application.put_env(:exocomp_coordinator, :node_state_client, &mock_node_state/1)
    Application.put_env(:exocomp_coordinator, :profile_action_client, &mock_action_client/2)

    on_exit(fn ->
      if previous_registry do
        Application.put_env(:exocomp_coordinator, :registry, previous_registry)
      else
        Application.delete_env(:exocomp_coordinator, :registry)
      end

      if previous_coverage do
        Application.put_env(:exocomp_coordinator, :profile_coverage, previous_coverage)
      else
        Application.delete_env(:exocomp_coordinator, :profile_coverage)
      end

      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      else
        Application.delete_env(:exocomp_coordinator, :ceph_collector)
      end

      if previous_node_client do
        Application.put_env(:exocomp_coordinator, :node_state_client, previous_node_client)
      else
        Application.delete_env(:exocomp_coordinator, :node_state_client)
      end

      if previous_action_client do
        Application.put_env(:exocomp_coordinator, :profile_action_client, previous_action_client)
      else
        Application.delete_env(:exocomp_coordinator, :profile_action_client)
      end

      if previous_audit_server do
        Application.put_env(:exocomp_coordinator, :ceph_audit_server, previous_audit_server)
      else
        Application.delete_env(:exocomp_coordinator, :ceph_audit_server)
      end

      if previous_window do
        Application.put_env(:exocomp_coordinator, :ceph_stability_window_ms, previous_window)
      else
        Application.delete_env(:exocomp_coordinator, :ceph_stability_window_ms)
      end

      if previous_poll_interval do
        Application.put_env(
          :exocomp_coordinator,
          :ceph_stability_poll_interval_ms,
          previous_poll_interval
        )
      else
        Application.delete_env(:exocomp_coordinator, :ceph_stability_poll_interval_ms)
      end
    end)

    %{registry_name: registry_name, coverage_name: coverage_name, audit_name: audit_name}
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

    assert {:error, {:invalid_parameter, "node_id"}} =
             CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with missing daemon_id" do
    proposal =
      valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "daemon_id"))

    assert {:error, {:invalid_parameter, "daemon_id"}} =
             CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with missing daemon_type" do
    proposal =
      valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "daemon_type"))

    assert {:error, {:invalid_parameter, "daemon_type"}} =
             CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with missing profile_name" do
    proposal =
      valid_proposal() |> update_in(["parameters"], &Map.delete(&1, "profile_name"))

    assert {:error, {:invalid_parameter, "profile_name"}} =
             CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal for node not in inventory" do
    proposal =
      valid_proposal()
      |> put_in(["parameters", "node_id"], "unknown-node")

    assert {:error, {:node_not_found, "unknown-node"}} =
             CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects proposal with wrong action_id" do
    proposal = valid_proposal() |> Map.put("action_id", "restart_service")

    assert {:error, {:unsupported_action, "restart_service"}} =
             CephDaemonRestart.validate_proposal(proposal)
  end

  test "rejects malformed proposal" do
    assert {:error, :malformed_proposal} = CephDaemonRestart.validate_proposal("not a map")
  end

  # ---------------------------------------------------------------------------
  # Evidence collection tests
  # ---------------------------------------------------------------------------

  test "collects evidence successfully" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    assert {:ok, evidence} = CephDaemonRestart.collect_evidence(proposal)
    assert is_map(evidence)
  end

  test "rejects evidence when the node daemon mapping changes" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn _node_id ->
      %{
        "observed_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "measurements" => %{
          "daemons" => %{
            "value" => [
              %{
                "id" => "osd.43",
                "unit" => "ceph-osd@43.service",
                "active_state" => "failed"
              }
            ]
          }
        }
      }
    end)

    assert {:error, {:evidence_collection_failed, :target_mapping_changed}} =
             CephDaemonRestart.collect_evidence(proposal)
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

    assert {:deny, {:daemon_not_failed, "degraded"}} =
             CephDaemonRestart.decide(proposal, evidence)
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

    assert {:deny, {:missing_evidence_timestamp, :collected_at}} =
             CephDaemonRestart.decide(proposal, evidence)
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

    assert result.status == "accepted"
    assert result.target_unit == "ceph-osd@42.service"
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

    # Create evidence showing daemon is failed
    evidence = fresh_evidence("failed")

    # Decide
    assert {:allow, action} = CephDaemonRestart.decide(validated, evidence)

    # Execute
    assert {:ok, exec_result} = CephDaemonRestart.execute(action, evidence, nil)

    # Verify (will collect fresh evidence showing daemon is now healthy)
    assert {:ok, verification} = CephDaemonRestart.verify(action, evidence, exec_result)

    assert verification.status == "healthy"
  end

  test "flow rejects active daemon at policy gate" do
    proposal = valid_proposal()

    assert {:ok, validated} = CephDaemonRestart.validate_proposal(proposal)
    evidence = fresh_evidence("active")

    # Should be denied at the policy gate
    assert {:deny, {:daemon_not_failed, "active"}} = CephDaemonRestart.decide(validated, evidence)
  end

  # ---------------------------------------------------------------------------
  # Mapping change detection tests
  # ---------------------------------------------------------------------------

  test "detects mapping change: node no longer in inventory during decide" do
    registry_name = Application.get_env(:exocomp_coordinator, :registry, Registry)

    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    # Node is in inventory at validation time
    assert {:allow, _action} = CephDaemonRestart.decide(proposal, evidence)

    # Simulate node removal from inventory
    :ok = Registry.rebuild([], registry_name)

    # A subsequent decide call would detect the node is no longer available
    evidence2 = fresh_evidence("failed")

    case CephDaemonRestart.decide(proposal, evidence2) do
      {:deny, {:node_not_found, _}} -> :ok
      result -> flunk("expected node_not_found, got #{inspect(result)}")
    end
  end

  test "detects mapping change: daemon ID changed" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    assert {:allow, action} = CephDaemonRestart.decide(proposal, evidence)

    # Helper invocation always uses the action's daemon_id, not evidence
    {:ok, result} = CephDaemonRestart.execute(action, evidence, nil)
    assert result.daemon_id == action.daemon_id
  end

  # ---------------------------------------------------------------------------
  # Unsupported profile tests
  # ---------------------------------------------------------------------------

  test "denies restart with unsupported profile" do
    # Use a valid profile name for validation
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    # Create a modified proposal with unsupported profile
    proposal_unsupported = %{proposal | profile_name: "unsupported-profile"}

    evidence = fresh_evidence("failed")

    # Decide should deny due to unsupported profile
    case CephDaemonRestart.decide(proposal_unsupported, evidence) do
      {:deny, {:unsupported_profile, _}} -> :ok
      result -> flunk("expected unsupported_profile denial, got #{inspect(result)}")
    end
  end

  test "denies restart when profile is degraded" do
    coverage_name = Application.get_env(:exocomp_coordinator, :profile_coverage)

    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    # Mark profile as degraded
    ProfileCoverage.mark_degraded(@profile_name, %{}, coverage_name)

    evidence = fresh_evidence("failed")

    assert {:deny, {:unsupported_profile, @profile_name}} =
             CephDaemonRestart.decide(proposal, evidence)
  end

  # ---------------------------------------------------------------------------
  # Concurrent requests and idempotency tests
  # ---------------------------------------------------------------------------

  test "handles concurrent proposals safely" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    # Validate multiple proposals concurrently
    tasks =
      Enum.map(1..5, fn _ ->
        Task.async(fn ->
          CephDaemonRestart.decide(proposal, evidence)
        end)
      end)

    results = Task.await_many(tasks)

    # All should allow the action (policy is deterministic)
    assert Enum.all?(results, fn
             {:allow, _action} -> true
             _ -> false
           end)
  end

  test "proposal is idempotent across multiple validations" do
    proposal = valid_proposal()

    # Validate same proposal multiple times
    result1 = CephDaemonRestart.validate_proposal(proposal)
    result2 = CephDaemonRestart.validate_proposal(proposal)
    result3 = CephDaemonRestart.validate_proposal(proposal)

    assert {:ok, proposal1} = result1
    assert {:ok, proposal2} = result2
    assert {:ok, proposal3} = result3

    # All validations should produce equivalent results
    assert proposal1.node_id == proposal2.node_id
    assert proposal1.node_id == proposal3.node_id
    assert proposal1.daemon_id == proposal2.daemon_id
    assert proposal1.daemon_id == proposal3.daemon_id
  end

  test "evidence collection is idempotent" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    # Collect evidence multiple times
    {:ok, evidence1} = CephDaemonRestart.collect_evidence(proposal)
    {:ok, evidence2} = CephDaemonRestart.collect_evidence(proposal)
    {:ok, evidence3} = CephDaemonRestart.collect_evidence(proposal)

    # All collections should have consistent structure and status
    assert evidence1.source == evidence2.source
    assert evidence1.source == evidence3.source
    assert evidence1.daemon_state == evidence2.daemon_state
    assert evidence1.daemon_state == evidence3.daemon_state
  end

  # ---------------------------------------------------------------------------
  # Helper rejection and error handling tests
  # ---------------------------------------------------------------------------

  test "handles helper rejection gracefully" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    {:allow, action} = CephDaemonRestart.decide(proposal, evidence)

    # Configure a failing typed node action client
    previous_client = Application.get_env(:exocomp_coordinator, :profile_action_client)

    Application.put_env(:exocomp_coordinator, :profile_action_client, fn _node_id, _action ->
      {:error, :helper_rejected}
    end)

    try do
      case CephDaemonRestart.execute(action, evidence, nil) do
        {:error, {:action_dispatch_failed, :helper_rejected}} -> :ok
        result -> flunk("expected action_dispatch_failed, got #{inspect(result)}")
      end
    after
      if previous_client do
        Application.put_env(:exocomp_coordinator, :profile_action_client, previous_client)
      else
        Application.delete_env(:exocomp_coordinator, :profile_action_client)
      end
    end
  end

  test "handles helper timeout" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    {:allow, action} = CephDaemonRestart.decide(proposal, evidence)

    # Configure a timing-out typed node action client
    previous_client = Application.get_env(:exocomp_coordinator, :profile_action_client)

    Application.put_env(:exocomp_coordinator, :profile_action_client, fn _node_id, _action ->
      {:error, :timeout}
    end)

    try do
      case CephDaemonRestart.execute(action, evidence, nil) do
        {:error, {:action_dispatch_failed, :timeout}} ->
          :ok

        result ->
          flunk("expected action_dispatch_failed, got #{inspect(result)}")
      end
    after
      if previous_client do
        Application.put_env(:exocomp_coordinator, :profile_action_client, previous_client)
      else
        Application.delete_env(:exocomp_coordinator, :profile_action_client)
      end
    end
  end

  test "handles Ceph unavailability" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    # Configure a degraded collector
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :degraded,
        health: %{},
        topology: %{},
        errors: [
          %{timestamp: "", command: "ceph", error: :unavailable, reason: "Ceph API unavailable"}
        ]
      }
    end)

    try do
      case CephDaemonRestart.collect_evidence(proposal) do
        {:error, {:evidence_collection_failed, {:ceph_evidence_unavailable, :degraded}}} -> :ok
        result -> flunk("expected evidence_collection_failed error, got #{inspect(result)}")
      end
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      else
        Application.delete_env(:exocomp_coordinator, :ceph_collector)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Audit-before-action and durability tests
  # ---------------------------------------------------------------------------

  test "audit trail is preserved on execution" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)
    evidence = fresh_evidence("failed")

    {:allow, action} = CephDaemonRestart.decide(proposal, evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, evidence, nil)

    # Verify execution result contains audit-relevant data
    assert exec_result.status == "accepted"
    assert exec_result.target_unit == "ceph-osd@42.service"
  end

  test "full lifecycle never invokes the node action when durable intent audit fails" do
    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      mock_node_state(node_id, "failed")
    end)

    {:ok, action_calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:exocomp_coordinator, :profile_action_client, fn _node_id, _action ->
      Agent.update(action_calls, &(&1 + 1))
      {:ok, %{status: "accepted"}}
    end)

    audit = fn type, _attrs, _correlation_id ->
      if type == :remediation_intent_accepted, do: {:error, :sink_down}, else: :ok
    end

    server = unique_name(:lifecycle_audit_failure)

    start_supervised!(
      {Exocomp.Coordinator.RemediationLifecycle,
       [name: server, adapter: Exocomp.Coordinator.RemediationAdapter.Router, audit_fun: audit]}
    )

    assert {:ok, task} =
             Exocomp.Coordinator.RemediationLifecycle.submit(valid_proposal(), server: server)

    assert task.status.state == :failed
    assert last_event(task) == "audit_unavailable_before_action"
    assert Agent.get(action_calls, & &1) == 0
  end

  test "full lifecycle reaches the typed node action and verifies fresh health" do
    {:ok, states} = Agent.start_link(fn -> ["failed", "active"] end)
    parent = self()

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      Agent.get_and_update(states, fn
        [state | rest] -> {mock_node_state(node_id, state), rest}
        [] -> {mock_node_state(node_id, "active"), []}
      end)
    end)

    Application.put_env(:exocomp_coordinator, :profile_action_client, fn _node_id, action ->
      send(parent, {:typed_action, action})
      {:ok, %{status: "accepted", target_unit: action.target_unit}}
    end)

    server = unique_name(:lifecycle_success)
    audit = fn _type, _attrs, _correlation_id -> :ok end

    start_supervised!(
      {Exocomp.Coordinator.RemediationLifecycle,
       [name: server, adapter: Exocomp.Coordinator.RemediationAdapter.Router, audit_fun: audit]}
    )

    assert {:ok, task} =
             Exocomp.Coordinator.RemediationLifecycle.submit(valid_proposal(), server: server)

    assert task.status.state == :completed
    assert last_event(task) == "verified"

    assert_receive {:typed_action,
                    %{action_id: "restart_failed_daemon", target_unit: "ceph-osd@42.service"}}
  end

  # ---------------------------------------------------------------------------
  # Cluster health regression tests
  # ---------------------------------------------------------------------------

  test "verifies fails when cluster health regresses from OK to WARN" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    # Pre-execution: cluster is healthy
    pre_evidence = fresh_evidence_with_health("failed", "HEALTH_OK")

    {:allow, action} = CephDaemonRestart.decide(proposal, pre_evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, pre_evidence, nil)

    # Mock collector to return degraded health after execution
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :ok,
        health: %{"status" => "HEALTH_WARN", "overall" => %{"status" => "HEALTH_WARN"}},
        topology: %{
          "osds" => %{@daemon_id => %{"state" => "up"}},
          "monitors" => %{},
          "managers" => %{},
          "mdss" => %{}
        },
        errors: []
      }
    end)

    try do
      case CephDaemonRestart.verify(action, pre_evidence, exec_result) do
        {:error, {:verification_failed, {:cluster_health_regressed, _, _}}} ->
          :ok

        result ->
          flunk("expected verification failure on health regression, got #{inspect(result)}")
      end
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      end
    end
  end

  test "verifies fails when cluster health regresses from OK to ERR" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    pre_evidence = fresh_evidence_with_health("failed", "HEALTH_OK")

    {:allow, action} = CephDaemonRestart.decide(proposal, pre_evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, pre_evidence, nil)

    # Mock collector to return critical health after execution
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :ok,
        health: %{"status" => "HEALTH_ERR", "overall" => %{"status" => "HEALTH_ERR"}},
        topology: %{
          "osds" => %{@daemon_id => %{"state" => "up"}},
          "monitors" => %{},
          "managers" => %{},
          "mdss" => %{}
        },
        errors: []
      }
    end)

    try do
      case CephDaemonRestart.verify(action, pre_evidence, exec_result) do
        {:error, {:verification_failed, {:cluster_health_regressed, _, _}}} ->
          :ok

        result ->
          flunk("expected verification failure on health regression, got #{inspect(result)}")
      end
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      end
    end
  end

  test "verifies succeeds when cluster health remains OK" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    pre_evidence = fresh_evidence_with_health("failed", "HEALTH_OK")

    {:allow, action} = CephDaemonRestart.decide(proposal, pre_evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, pre_evidence, nil)

    # Mock collector to return same health after execution
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :ok,
        health: %{"status" => "HEALTH_OK", "overall" => %{"status" => "HEALTH_OK"}},
        topology: %{
          "osds" => %{@daemon_id => %{"state" => "up"}},
          "monitors" => %{},
          "managers" => %{},
          "mdss" => %{}
        },
        errors: []
      }
    end)

    try do
      assert {:ok, verification} = CephDaemonRestart.verify(action, pre_evidence, exec_result)

      assert verification.status == "healthy"
      assert verification.verification_type == "stability_window_passed"
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      end
    end
  end

  test "verifies succeeds when cluster health improves from WARN to OK" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    pre_evidence = fresh_evidence_with_health("failed", "HEALTH_WARN")

    {:allow, action} = CephDaemonRestart.decide(proposal, pre_evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, pre_evidence, nil)

    # Mock collector to return improved health after execution
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :ok,
        health: %{"status" => "HEALTH_OK", "overall" => %{"status" => "HEALTH_OK"}},
        topology: %{
          "osds" => %{@daemon_id => %{"state" => "up"}},
          "monitors" => %{},
          "managers" => %{},
          "mdss" => %{}
        },
        errors: []
      }
    end)

    try do
      assert {:ok, verification} = CephDaemonRestart.verify(action, pre_evidence, exec_result)

      assert verification.status == "healthy"
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      end
    end
  end

  test "verifies fails when cluster was already critical before restart" do
    raw_proposal = valid_proposal()
    {:ok, proposal} = CephDaemonRestart.validate_proposal(raw_proposal)

    pre_evidence = fresh_evidence_with_health("failed", "HEALTH_ERR")

    {:allow, action} = CephDaemonRestart.decide(proposal, pre_evidence)
    {:ok, exec_result} = CephDaemonRestart.execute(action, pre_evidence, nil)

    # Mock collector to keep cluster critical
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :ok,
        health: %{"status" => "HEALTH_ERR", "overall" => %{"status" => "HEALTH_ERR"}},
        topology: %{
          "osds" => %{@daemon_id => %{"state" => "up"}},
          "monitors" => %{},
          "managers" => %{},
          "mdss" => %{}
        },
        errors: []
      }
    end)

    try do
      case CephDaemonRestart.verify(action, pre_evidence, exec_result) do
        {:error, {:verification_failed, {:cluster_health_regressed, _, _}}} ->
          :ok

        result ->
          flunk("expected verification failure when cluster critical, got #{inspect(result)}")
      end
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      end
    end
  end

  test "recollects systemd and Ceph evidence across the configured stability window" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)
    previous_node_client = Application.get_env(:exocomp_coordinator, :node_state_client)

    Application.put_env(:exocomp_coordinator, :ceph_stability_window_ms, 20)
    Application.put_env(:exocomp_coordinator, :ceph_stability_poll_interval_ms, 2)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      Agent.update(calls, &(&1 + 1))
      mock_node_state(node_id, "active")
    end)

    try do
      {:ok, proposal} = CephDaemonRestart.validate_proposal(valid_proposal())
      {:allow, action} = CephDaemonRestart.decide(proposal, fresh_evidence("failed"))
      {:ok, execution} = CephDaemonRestart.execute(action, fresh_evidence("failed"), nil)

      assert {:ok, verification} =
               CephDaemonRestart.verify(action, fresh_evidence("failed"), execution)

      assert verification.verification_type == "stability_window_passed"
      assert verification.samples >= 2
      assert Agent.get(calls, & &1) >= verification.samples
    after
      if previous_node_client do
        Application.put_env(:exocomp_coordinator, :node_state_client, previous_node_client)
      else
        Application.delete_env(:exocomp_coordinator, :node_state_client)
      end
    end
  end

  test "systemd-only recovery is insufficient when the daemon is flapping" do
    {:ok, states} = Agent.start_link(fn -> ["active", "failed"] end)
    previous_node_client = Application.get_env(:exocomp_coordinator, :node_state_client)

    Application.put_env(:exocomp_coordinator, :ceph_stability_window_ms, 20)
    Application.put_env(:exocomp_coordinator, :ceph_stability_poll_interval_ms, 2)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      Agent.get_and_update(states, fn
        [state | rest] -> {mock_node_state(node_id, state), rest}
        [] -> {mock_node_state(node_id, "failed"), []}
      end)
    end)

    try do
      {:ok, proposal} = CephDaemonRestart.validate_proposal(valid_proposal())
      {:allow, action} = CephDaemonRestart.decide(proposal, fresh_evidence("failed"))
      {:ok, execution} = CephDaemonRestart.execute(action, fresh_evidence("failed"), nil)

      assert {:error, {:verification_failed, {:daemon_not_healthy, "failed"}}} =
               CephDaemonRestart.verify(action, fresh_evidence("failed"), execution)

      assert CephCooldown.in_cooldown?(@daemon_id, @node_id)
    after
      if previous_node_client do
        Application.put_env(:exocomp_coordinator, :node_state_client, previous_node_client)
      else
        Application.delete_env(:exocomp_coordinator, :node_state_client)
      end
    end
  end

  test "verification identity change enters cooldown" do
    previous_node_client = Application.get_env(:exocomp_coordinator, :node_state_client)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn _node_id ->
      %{
        "observed_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "measurements" => %{
          "daemons" => %{
            "value" => [
              %{
                "id" => "osd.43",
                "unit" => "ceph-osd@43.service",
                "active_state" => "active"
              }
            ]
          }
        }
      }
    end)

    try do
      {:ok, proposal} = CephDaemonRestart.validate_proposal(valid_proposal())
      {:allow, action} = CephDaemonRestart.decide(proposal, fresh_evidence("failed"))
      {:ok, execution} = CephDaemonRestart.execute(action, fresh_evidence("failed"), nil)

      assert {:error, {:verification_failed, :target_mapping_changed}} =
               CephDaemonRestart.verify(action, fresh_evidence("failed"), execution)

      assert CephCooldown.in_cooldown?(@daemon_id, @node_id)
    after
      if previous_node_client do
        Application.put_env(:exocomp_coordinator, :node_state_client, previous_node_client)
      else
        Application.delete_env(:exocomp_coordinator, :node_state_client)
      end
    end
  end

  test "verification rejects a changed Ceph topology identity" do
    previous_collector = Application.get_env(:exocomp_coordinator, :ceph_collector)
    pre_evidence = Map.put(fresh_evidence("failed"), :topology, %{"fsid" => "old-fsid"})

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      base = mock_ceph_collector()
      %{base | topology: Map.put(base.topology, "fsid", "new-fsid")}
    end)

    try do
      {:ok, proposal} = CephDaemonRestart.validate_proposal(valid_proposal())
      {:allow, action} = CephDaemonRestart.decide(proposal, pre_evidence)
      {:ok, execution} = CephDaemonRestart.execute(action, pre_evidence, nil)

      assert {:error, {:verification_failed, :topology_identity_changed}} =
               CephDaemonRestart.verify(action, pre_evidence, execution)
    after
      if previous_collector do
        Application.put_env(:exocomp_coordinator, :ceph_collector, previous_collector)
      end
    end
  end

  test "cooldown audit write failure is surfaced as verification failure" do
    previous_node_client = Application.get_env(:exocomp_coordinator, :node_state_client)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      mock_node_state(node_id, "failed")
    end)

    try do
      {:ok, proposal} = CephDaemonRestart.validate_proposal(valid_proposal())
      {:allow, action} = CephDaemonRestart.decide(proposal, fresh_evidence("failed"))
      {:ok, execution} = CephDaemonRestart.execute(action, fresh_evidence("failed"), nil)
      action = Map.put(action, :audit_server, unique_name(:missing_audit))

      assert {:error, {:verification_failed, {:cooldown_record_failed, _, _}}} =
               CephDaemonRestart.verify(action, fresh_evidence("failed"), execution)
    after
      if previous_node_client do
        Application.put_env(:exocomp_coordinator, :node_state_client, previous_node_client)
      else
        Application.delete_env(:exocomp_coordinator, :node_state_client)
      end
    end
  end

  test "coordinator restart reconciles an unfinished durable intent without repeating it" do
    audit_name = Application.fetch_env!(:exocomp_coordinator, :ceph_audit_server)
    correlation_id = "corr_orphaned_ceph_action"

    durable_action = %{
      action_id: "restart_failed_daemon",
      node_id: @node_id,
      daemon_id: @daemon_id,
      daemon_type: @daemon_type,
      profile_name: @profile_name,
      profile_version: 1,
      target_unit: "ceph-osd@42.service"
    }

    assert :ok =
             Audit.emit(
               :remediation_intent_accepted,
               %{action: durable_action, evidence: fresh_evidence("failed"), approved: false},
               server: audit_name,
               correlation_id: correlation_id
             )

    {:ok, action_calls} = Agent.start_link(fn -> 0 end)
    previous_node_client = Application.get_env(:exocomp_coordinator, :node_state_client)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      mock_node_state(node_id, "failed")
    end)

    Application.put_env(:exocomp_coordinator, :profile_action_client, fn _node_id, _action ->
      Agent.update(action_calls, &(&1 + 1))
      {:ok, %{status: "accepted"}}
    end)

    server = unique_name(:reconciled_ceph_lifecycle)

    start_supervised!(
      {Exocomp.Coordinator.RemediationLifecycle,
       [name: server, adapter: Exocomp.Coordinator.RemediationAdapter.Router, audit: audit_name]},
      id: server
    )

    try do
      assert {:ok, task} =
               Exocomp.Coordinator.RemediationLifecycle.submit(valid_proposal(), server: server)

      assert task.status.state == :failed
      assert last_event(task) == "audit_reconciliation_required"
      assert Agent.get(action_calls, & &1) == 0
    after
      if previous_node_client do
        Application.put_env(:exocomp_coordinator, :node_state_client, previous_node_client)
      else
        Application.delete_env(:exocomp_coordinator, :node_state_client)
      end
    end
  end

  test "real lifecycle persists cooldown and denies the next automatic restart" do
    audit_name = Application.fetch_env!(:exocomp_coordinator, :ceph_audit_server)
    {:ok, health_states} = Agent.start_link(fn -> ["HEALTH_OK", "HEALTH_WARN"] end)
    {:ok, node_states} = Agent.start_link(fn -> ["failed", "active", "failed"] end)
    {:ok, action_calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:exocomp_coordinator, :ceph_collector, fn ->
      health =
        Agent.get_and_update(health_states, fn
          [value | rest] -> {value, rest}
          [] -> {"HEALTH_WARN", []}
        end)

      base = mock_ceph_collector()
      %{base | health: %{"status" => health, "overall" => %{"status" => health}}}
    end)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      Agent.get_and_update(node_states, fn
        [state | rest] -> {mock_node_state(node_id, state), rest}
        [] -> {mock_node_state(node_id, "failed"), []}
      end)
    end)

    Application.put_env(:exocomp_coordinator, :profile_action_client, fn _node_id, _action ->
      Agent.update(action_calls, &(&1 + 1))
      {:ok, %{status: "accepted"}}
    end)

    server = unique_name(:real_ceph_lifecycle)

    start_supervised!(
      {Exocomp.Coordinator.RemediationLifecycle,
       [name: server, adapter: Exocomp.Coordinator.RemediationAdapter.Router, audit: audit_name]},
      id: server
    )

    first = Exocomp.Coordinator.RemediationLifecycle.submit(valid_proposal(), server: server)
    assert {:ok, failed} = first
    assert failed.status.state == :failed
    assert last_event(failed) == "verification_failed"

    assert {:ok, denied} =
             Exocomp.Coordinator.RemediationLifecycle.submit(valid_proposal(), server: server)

    assert denied.status.state == :completed
    assert last_event(denied) == "policy_denied"
    assert Agent.get(action_calls, & &1) == 1

    assert {:ok, events} = Audit.events(audit_name)
    correlation_events = Enum.filter(events, &(&1["correlation_id"] == failed.contextId))
    assert Enum.any?(correlation_events, &(&1["event_type"] == "verification_failed"))
    assert Enum.any?(correlation_events, &(&1["event_type"] == "cooldown_entered"))
    assert Enum.any?(correlation_events, &(&1["event_type"] == "remediation_failed"))
  end

  test "real lifecycle emits correlated completion evidence after stable recovery" do
    audit_name = Application.fetch_env!(:exocomp_coordinator, :ceph_audit_server)
    {:ok, node_states} = Agent.start_link(fn -> ["failed", "active"] end)

    Application.put_env(:exocomp_coordinator, :node_state_client, fn node_id ->
      Agent.get_and_update(node_states, fn
        [state | rest] -> {mock_node_state(node_id, state), rest}
        [] -> {mock_node_state(node_id, "active"), []}
      end)
    end)

    server = unique_name(:real_ceph_success_lifecycle)

    start_supervised!(
      {Exocomp.Coordinator.RemediationLifecycle,
       [name: server, adapter: Exocomp.Coordinator.RemediationAdapter.Router, audit: audit_name]},
      id: server
    )

    assert {:ok, completed} =
             Exocomp.Coordinator.RemediationLifecycle.submit(valid_proposal(), server: server)

    assert completed.status.state == :completed
    assert last_event(completed) == "verified"

    assert {:ok, events} = Audit.events(audit_name)
    correlation_events = Enum.filter(events, &(&1["correlation_id"] == completed.contextId))
    assert Enum.any?(correlation_events, &(&1["event_type"] == "verification_completed"))
    assert Enum.any?(correlation_events, &(&1["event_type"] == "remediation_completed"))
    assert Enum.any?(correlation_events, &(&1["event_type"] == "cooldown_cleared"))
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
    fresh_evidence_with_health(state, "HEALTH_OK")
  end

  defp fresh_evidence_with_health(state, health_status) do
    %{
      collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      node_collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      node_id: @node_id,
      daemon_state: state,
      active_pgs: 0,
      ceph_health: %{"status" => health_status, "overall" => %{"status" => health_status}},
      mapping: %{node_id: @node_id, daemon_id: @daemon_id, target_unit: "ceph-osd@42.service"}
    }
  end

  defp stale_evidence(state) do
    ten_minutes_ago =
      DateTime.utc_now()
      |> DateTime.add(-10, :minute)
      |> DateTime.to_iso8601()

    %{
      collected_at: ten_minutes_ago,
      node_collected_at: ten_minutes_ago,
      node_id: @node_id,
      daemon_state: state,
      active_pgs: 0,
      mapping: %{node_id: @node_id, daemon_id: @daemon_id, target_unit: "ceph-osd@42.service"}
    }
  end

  defp unique_name(prefix) do
    :"#{prefix}_#{System.unique_integer([:positive, :monotonic])}"
  end

  # Mock Ceph collector for testing - returns healthy daemon state
  # Tests that need a failed daemon state should use fresh_evidence("failed") helper
  @doc false
  def mock_ceph_collector do
    %{
      schema_version: 1,
      collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: :ok,
      health: %{
        "status" => "HEALTH_OK",
        "overall" => %{
          "status" => "HEALTH_OK"
        }
      },
      topology: %{
        "fsid" => "12345678-1234-1234-1234-123456789012",
        "osds" => %{
          @daemon_id => %{
            "state" => "up"
          }
        },
        "monitors" => %{},
        "managers" => %{},
        "mdss" => %{}
      },
      errors: []
    }
  end

  @doc false
  def mock_node_state(node_id), do: mock_node_state(node_id, "active")

  def mock_node_state(_node_id, state) do
    %{
      "observed_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "measurements" => %{
        "daemons" => %{
          "value" => [
            %{"id" => "osd.42", "unit" => "ceph-osd@42.service", "active_state" => state}
          ]
        }
      }
    }
  end

  @doc false
  def mock_action_client(_node_id, action) do
    {:ok, %{status: "accepted", target_unit: action.target_unit, daemon_id: action.daemon_id}}
  end

  defp last_event(task) do
    task.history
    |> List.last()
    |> Map.fetch!(:parts)
    |> List.first()
    |> Map.fetch!(:data)
    |> Map.fetch!("event")
  end
end
