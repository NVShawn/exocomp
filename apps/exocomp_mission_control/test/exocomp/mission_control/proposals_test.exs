# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ProposalsTest do
  use ExUnit.Case

  alias Exocomp.MissionControl.{Proposal, Proposals}

  setup do
    catalog = %{
      "restart_service" => %{
        description: "Restart a systemd service",
        parameters_schema: %{"service_name" => %{"type" => "string"}}
      },
      "recover_node" => %{
        description: "Recover a degraded node",
        parameters_schema: %{}
      }
    }

    # Generate a unique server name for each test to avoid collisions
    unique_name = String.to_atom("test_proposals_#{:erlang.unique_integer()}")
    {:ok, server} = Proposals.start_link(catalog, name: unique_name)
    {:ok, server: server, catalog: catalog}
  end

  describe "create_proposal/3 valid cases" do
    test "creates a valid proposal", %{server: server, catalog: catalog} do
      org = "org_test"
      cluster = "cluster_123"
      evidence_hash = "abc123def456"

      attrs = %{
        cluster_id: cluster,
        catalog_action_id: "restart_service",
        parameters: %{"service_name" => "nginx"},
        evidence_hash: evidence_hash,
        policy_result: :approval_required,
        risk: :medium,
        rationale: "Service is unresponsive"
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)

      assert proposal.organization_id == org
      assert proposal.cluster_id == cluster
      assert proposal.catalog_action_id == "restart_service"
      assert proposal.parameters == %{"service_name" => "nginx"}
      assert proposal.evidence_hash == evidence_hash
      assert proposal.policy_result == :approval_required
      assert proposal.risk == :medium
      assert proposal.rationale == "Service is unresponsive"
      assert proposal.node_id == nil
      assert proposal.conversation_id == nil
      assert proposal.message_id == nil
      assert is_binary(proposal.id)
      assert String.starts_with?(proposal.id, "prop_")
    end

    test "creates proposal with all optional fields", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        node_id: "node_456",
        conversation_id: "conv_789",
        message_id: "msg_abc",
        task_id: "task_def",
        correlation_id: "corr_ghi",
        catalog_action_id: "restart_service",
        parameters: %{"service_name" => "nginx"},
        evidence_hash: "hash123",
        policy_result: :deny,
        risk: :low,
        expected_disruption: "30 seconds",
        rationale: "Testing",
        evidence_reference: %{
          organization_id: org,
          cluster_id: "cluster_123",
          evidence_id: "ev_123",
          node_id: "node_456",
          evidence_hash: "hash123",
          observed_at: DateTime.utc_now()
        }
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)

      assert proposal.node_id == "node_456"
      assert proposal.conversation_id == "conv_789"
      assert proposal.message_id == "msg_abc"
      assert proposal.task_id == "task_def"
      assert proposal.correlation_id == "corr_ghi"
      assert proposal.expected_disruption == "30 seconds"
      assert proposal.evidence_reference.evidence_id == "ev_123"
    end

    test "sets default expiry to 1 hour when not specified", %{server: server} do
      org = "org_test"
      now = DateTime.utc_now()

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)

      # Expiry should be approximately 1 hour from creation
      diff_seconds = DateTime.diff(proposal.expires_at, now, :second)
      assert diff_seconds >= 3599 and diff_seconds <= 3601
    end

    test "accepts custom expiry time", %{server: server} do
      org = "org_test"
      custom_expiry = DateTime.add(DateTime.utc_now(), 7200, :second)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        expires_at: custom_expiry
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert proposal.expires_at == custom_expiry
    end

    test "creates proposal with default risk level", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert proposal.risk == :medium
    end

    test "normalizes string values to atoms for risk and policy_result", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        risk: "high",
        policy_result: "approval_required"
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert proposal.risk == :high
      assert proposal.policy_result == :approval_required
    end
  end

  describe "create_proposal/3 error cases" do
    test "rejects proposal with unknown action", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "unknown_action",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:error, :unknown_action} = Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal without catalog_action_id", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:error, {:required, :catalog_action_id}} =
        Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal without cluster_id", %{server: server} do
      org = "org_test"

      attrs = %{
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:error, {:required, :cluster_id}} = Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal without evidence_hash", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        policy_result: :allow
      }

      {:error, {:required, :evidence_hash}} =
        Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal without policy_result", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123"
      }

      {:error, :policy_result_required} = Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal with invalid risk level", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        risk: :invalid_risk
      }

      {:error, {:invalid_risk, :invalid_risk}} =
        Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal with invalid policy_result", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :invalid
      }

      {:error, {:invalid_policy_result, :invalid}} =
        Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal with invalid parameters (not a map)", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: "not_a_map",
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:error, :invalid_parameters} = Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal with non-string parameter keys", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{key: "value"},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:error, :invalid_parameters} = Proposals.create_proposal(org, attrs, server: server)
    end

    test "rejects proposal with unsupported fields", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        command: "rm -rf /",
        path: "/sensitive/path"
      }

      {:error, {:unsupported_proposal_field, field}} =
        Proposals.create_proposal(org, attrs, server: server)

      assert field in [:command, :path]
    end

    test "rejects duplicate proposal ID", %{server: server} do
      org = "org_test"
      proposal_id = "prop_custom123"

      attrs1 = %{
        id: proposal_id,
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      attrs2 = %{
        id: proposal_id,
        cluster_id: "cluster_456",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash456",
        policy_result: :allow
      }

      {:ok, _proposal1} = Proposals.create_proposal(org, attrs1, server: server)
      {:error, :duplicate_proposal_id} = Proposals.create_proposal(org, attrs2, server: server)
    end

    test "rejects cross-organization proposal creation", %{server: server} do
      org1 = "org_123"
      org2 = "org_456"

      attrs = %{
        organization_id: org2,
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:error, :cross_organization} = Proposals.create_proposal(org1, attrs, server: server)
    end

    test "rejects invalid rationale field (too large)", %{server: server} do
      org = "org_test"
      large_rationale = String.duplicate("a", 2049)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        rationale: large_rationale
      }

      {:error, {:invalid_field, :rationale}} =
        Proposals.create_proposal(org, attrs, server: server)
    end
  end

  describe "get/3" do
    test "retrieves a non-expired proposal", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:ok, created_proposal} = Proposals.create_proposal(org, attrs, server: server)
      {:ok, retrieved_proposal} = Proposals.get(org, created_proposal.id, server: server)

      assert retrieved_proposal.id == created_proposal.id
    end

    test "returns not_found for non-existent proposal", %{server: server} do
      org = "org_test"
      {:error, :not_found} = Proposals.get(org, "prop_nonexistent", server: server)
    end

    test "prevents cross-organization access", %{server: server} do
      org1 = "org_123"
      org2 = "org_456"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:ok, proposal} = Proposals.create_proposal(org1, attrs, server: server)
      {:error, :not_found} = Proposals.get(org2, proposal.id, server: server)
    end

    test "returns error for expired proposal", %{server: server} do
      org = "org_test"
      past_time = DateTime.add(DateTime.utc_now(), -100, :second)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        expires_at: past_time
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      {:error, :expired} = Proposals.get(org, proposal.id, server: server)
    end
  end

  describe "list/2" do
    test "lists all non-expired proposals for an organization", %{server: server} do
      org = "org_test"

      # Create multiple proposals
      attrs1 = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash1",
        policy_result: :allow
      }

      attrs2 = %{
        cluster_id: "cluster_456",
        catalog_action_id: "recover_node",
        parameters: %{},
        evidence_hash: "hash2",
        policy_result: :allow
      }

      {:ok, _p1} = Proposals.create_proposal(org, attrs1, server: server)
      {:ok, _p2} = Proposals.create_proposal(org, attrs2, server: server)

      proposals = Proposals.list(org, server: server)
      assert length(proposals) == 2
    end

    test "filters out expired proposals from list", %{server: server} do
      org = "org_test"
      past_time = DateTime.add(DateTime.utc_now(), -100, :second)

      attrs_active = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash1",
        policy_result: :allow
      }

      attrs_expired = %{
        cluster_id: "cluster_456",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash2",
        policy_result: :allow,
        expires_at: past_time
      }

      {:ok, _p1} = Proposals.create_proposal(org, attrs_active, server: server)
      {:ok, _p2} = Proposals.create_proposal(org, attrs_expired, server: server)

      proposals = Proposals.list(org, server: server)
      assert length(proposals) == 1
    end

    test "prevents cross-organization listing", %{server: server} do
      org1 = "org_123"
      org2 = "org_456"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:ok, _p1} = Proposals.create_proposal(org1, attrs, server: server)

      proposals = Proposals.list(org2, server: server)
      assert proposals == []
    end
  end

  describe "list_by_cluster/3" do
    test "lists proposals for a specific cluster", %{server: server} do
      org = "org_test"

      attrs1 = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash1",
        policy_result: :allow
      }

      attrs2 = %{
        cluster_id: "cluster_456",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash2",
        policy_result: :allow
      }

      {:ok, _p1} = Proposals.create_proposal(org, attrs1, server: server)
      {:ok, _p2} = Proposals.create_proposal(org, attrs2, server: server)

      proposals = Proposals.list_by_cluster(org, "cluster_123", server: server)
      assert length(proposals) == 1
      assert Enum.all?(proposals, &(&1.cluster_id == "cluster_123"))
    end

    test "returns empty list for cluster with no proposals", %{server: server} do
      org = "org_test"
      proposals = Proposals.list_by_cluster(org, "cluster_no_proposals", server: server)
      assert proposals == []
    end
  end

  describe "list_by_conversation/3" do
    test "lists proposals for a specific conversation", %{server: server} do
      org = "org_test"

      attrs1 = %{
        cluster_id: "cluster_123",
        conversation_id: "conv_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash1",
        policy_result: :allow
      }

      attrs2 = %{
        cluster_id: "cluster_123",
        conversation_id: "conv_456",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash2",
        policy_result: :allow
      }

      {:ok, _p1} = Proposals.create_proposal(org, attrs1, server: server)
      {:ok, _p2} = Proposals.create_proposal(org, attrs2, server: server)

      proposals = Proposals.list_by_conversation(org, "conv_123", server: server)
      assert length(proposals) == 1
      assert Enum.all?(proposals, &(&1.conversation_id == "conv_123"))
    end
  end

  describe "Proposal.expired?/1" do
    test "returns true for expired proposal", %{server: server} do
      org = "org_test"
      past_time = DateTime.add(DateTime.utc_now(), -100, :second)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        expires_at: past_time
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert Proposal.expired?(proposal) == true
    end

    test "returns false for non-expired proposal", %{server: server} do
      org = "org_test"
      future_time = DateTime.add(DateTime.utc_now(), 3600, :second)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        expires_at: future_time
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert Proposal.expired?(proposal) == false
    end
  end

  describe "Proposal.evidence_stale?/2" do
    test "returns true when evidence reference is nil", %{server: server} do
      org = "org_test"

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        evidence_reference: nil
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert Proposal.evidence_stale?(proposal, 300_000) == true
    end

    test "returns true when evidence is older than freshness window", %{server: server} do
      org = "org_test"
      old_time = DateTime.add(DateTime.utc_now(), -600_000, :millisecond)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        evidence_reference: %{
          organization_id: org,
          cluster_id: "cluster_123",
          evidence_id: "ev_123",
          node_id: "node_123",
          evidence_hash: "hash123",
          observed_at: old_time
        }
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert Proposal.evidence_stale?(proposal, 300_000) == true
    end

    test "returns false when evidence is within freshness window", %{server: server} do
      org = "org_test"
      recent_time = DateTime.add(DateTime.utc_now(), -60_000, :millisecond)

      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow,
        evidence_reference: %{
          organization_id: org,
          cluster_id: "cluster_123",
          evidence_id: "ev_123",
          node_id: "node_123",
          evidence_hash: "hash123",
          observed_at: recent_time
        }
      }

      {:ok, proposal} = Proposals.create_proposal(org, attrs, server: server)
      assert Proposal.evidence_stale?(proposal, 300_000) == false
    end
  end

  describe "set_catalog/2" do
    test "updates the action catalog", %{server: server} do
      org = "org_test"

      # Create proposal with initial catalog
      attrs = %{
        cluster_id: "cluster_123",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash123",
        policy_result: :allow
      }

      {:ok, _proposal} = Proposals.create_proposal(org, attrs, server: server)

      # Update catalog to remove the action
      new_catalog = %{"recover_node" => %{description: "Recover a node"}}
      :ok = Proposals.set_catalog(new_catalog, server: server)

      # Attempt to create proposal with now-unknown action should fail
      attrs2 = %{
        cluster_id: "cluster_456",
        catalog_action_id: "restart_service",
        parameters: %{},
        evidence_hash: "hash456",
        policy_result: :allow
      }

      {:error, :unknown_action} = Proposals.create_proposal(org, attrs2, server: server)
    end
  end
end
