defmodule Exocomp.Node.ProposalSchemaTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.ProposalSchema

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp valid_proposal(id \\ :restart_service) do
    %{
      proposal_id: id,
      schema_version: "1",
      rationale: "Service exited with code 1 and has not recovered.",
      affected_resource: "nginx.service",
      confidence: 0.92
    }
  end

  # ---------------------------------------------------------------------------
  # schema_version/0 and valid_proposal_ids/0 accessors
  # ---------------------------------------------------------------------------

  test "schema_version/0 returns the current version string" do
    assert ProposalSchema.schema_version() == "1"
  end

  test "valid_proposal_ids/0 returns the closed list of known ids" do
    ids = ProposalSchema.valid_proposal_ids()
    assert :restart_service in ids
    assert :clear_disk_space in ids
    assert :rotate_logs in ids
    assert :increase_swap in ids
  end

  # ---------------------------------------------------------------------------
  # Valid proposals — one per known proposal_id
  # ---------------------------------------------------------------------------

  test "validates a proposal with proposal_id :restart_service" do
    assert {:ok, _} = ProposalSchema.validate(valid_proposal(:restart_service))
  end

  test "validates a proposal with proposal_id :clear_disk_space" do
    assert {:ok, _} = ProposalSchema.validate(valid_proposal(:clear_disk_space))
  end

  test "validates a proposal with proposal_id :rotate_logs" do
    assert {:ok, _} = ProposalSchema.validate(valid_proposal(:rotate_logs))
  end

  test "validates a proposal with proposal_id :increase_swap" do
    assert {:ok, _} = ProposalSchema.validate(valid_proposal(:increase_swap))
  end

  test "validates proposals with string keys" do
    proposal = %{
      "proposal_id" => "restart_service",
      "schema_version" => "1",
      "rationale" => "Service crashed.",
      "affected_resource" => "nginx.service",
      "confidence" => 0.88
    }

    assert {:ok, _} = ProposalSchema.validate(proposal)
  end

  # ---------------------------------------------------------------------------
  # Unknown schema_version
  # ---------------------------------------------------------------------------

  test "rejects a proposal with an unknown schema_version string" do
    proposal = valid_proposal() |> Map.put(:schema_version, "2")
    assert {:error, :unknown_schema_version} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with schema_version nil" do
    proposal = valid_proposal() |> Map.put(:schema_version, nil)
    assert {:error, :unknown_schema_version} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal missing schema_version entirely" do
    proposal = valid_proposal() |> Map.delete(:schema_version)
    assert {:error, :unknown_schema_version} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with schema_version integer 1 (wrong type)" do
    proposal = valid_proposal() |> Map.put(:schema_version, 1)
    assert {:error, :unknown_schema_version} = ProposalSchema.validate(proposal)
  end

  # ---------------------------------------------------------------------------
  # Unknown proposal_id
  # ---------------------------------------------------------------------------

  test "rejects an unknown proposal_id atom" do
    proposal = valid_proposal() |> Map.put(:proposal_id, :delete_files)
    assert {:error, :unknown_proposal_id} = ProposalSchema.validate(proposal)
  end

  test "rejects an unknown proposal_id string" do
    proposal = valid_proposal() |> Map.put(:proposal_id, "run_command")
    assert {:error, :unknown_proposal_id} = ProposalSchema.validate(proposal)
  end

  test "rejects a nil proposal_id" do
    proposal = valid_proposal() |> Map.put(:proposal_id, nil)
    assert {:error, :unknown_proposal_id} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal missing proposal_id entirely" do
    # schema_version is checked first so remove it to get to proposal_id check
    proposal =
      valid_proposal()
      |> Map.delete(:proposal_id)

    # proposal_id is a required field; missing it should surface as missing_field
    assert {:error, {:missing_field, :proposal_id}} = ProposalSchema.validate(proposal)
  end

  # ---------------------------------------------------------------------------
  # Missing required fields
  # ---------------------------------------------------------------------------

  test "rejects a proposal missing :rationale" do
    proposal = valid_proposal() |> Map.delete(:rationale)
    assert {:error, {:missing_field, :rationale}} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal missing :affected_resource" do
    proposal = valid_proposal() |> Map.delete(:affected_resource)
    assert {:error, {:missing_field, :affected_resource}} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal missing :confidence" do
    proposal = valid_proposal() |> Map.delete(:confidence)
    assert {:error, {:missing_field, :confidence}} = ProposalSchema.validate(proposal)
  end

  test "returns the specific missing field name in the error" do
    proposal = valid_proposal() |> Map.delete(:rationale)
    assert {:error, {:missing_field, :rationale}} = ProposalSchema.validate(proposal)
  end

  # ---------------------------------------------------------------------------
  # Forbidden fields (shell-command indicators)
  # ---------------------------------------------------------------------------

  test "rejects a proposal with an extra :cmd field" do
    proposal = valid_proposal() |> Map.put(:cmd, "systemctl restart nginx")
    assert {:error, :forbidden_field} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with an extra :command field" do
    proposal = valid_proposal() |> Map.put(:command, "rm -rf /tmp")
    assert {:error, :forbidden_field} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with an extra :exec field" do
    proposal = valid_proposal() |> Map.put(:exec, "/bin/bash")
    assert {:error, :forbidden_field} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with an extra :shell field" do
    proposal = valid_proposal() |> Map.put(:shell, true)
    assert {:error, :forbidden_field} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with an extra :script field" do
    proposal = valid_proposal() |> Map.put(:script, "#!/bin/sh")
    assert {:error, :forbidden_field} = ProposalSchema.validate(proposal)
  end

  test "rejects a proposal with a string 'command' key" do
    proposal =
      valid_proposal()
      |> Map.put("command", "do something dangerous")

    assert {:error, :forbidden_field} = ProposalSchema.validate(proposal)
  end

  test "accepts a proposal with an innocuous extra field (not shell-like)" do
    # Extra fields that are not forbidden are currently allowed (validation does
    # not enforce a strict allow-list of extra keys beyond the forbidden set).
    proposal = valid_proposal() |> Map.put(:notes, "low priority fix")
    assert {:ok, _} = ProposalSchema.validate(proposal)
  end
end
