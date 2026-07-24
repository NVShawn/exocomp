defmodule Exocomp.Node.Safety.ActionDefinitionTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.{ActionDefinition, RiskRank}

  @minimal_risk %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}

  @valid_opts [
    schema_version: "1",
    action_id: "systemd.service.restart",
    action_class: :restart,
    target_type: :systemd_unit,
    data_classification: :system_data,
    reversibility: :reversible,
    risk_rank: @minimal_risk,
    required_evidence: ["systemd.service.status"],
    max_evidence_age_secs: 30,
    requires_approval: true,
    cooldown_secs: 300,
    max_retries: 3,
    timeout_secs: 60
  ]

  # ── schema_version/0 ──────────────────────────────────────────────────

  test "schema_version/0 returns '1'" do
    assert ActionDefinition.schema_version() == "1"
  end

  # ── build/1 — valid input ─────────────────────────────────────────────

  test "build/1 returns {:ok, ActionDefinition} for valid opts" do
    assert {:ok, %ActionDefinition{} = ad} = ActionDefinition.build(@valid_opts)
    assert ad.schema_version == "1"
    assert ad.action_id == "systemd.service.restart"
    assert ad.action_class == :restart
    assert ad.target_type == :systemd_unit
    assert ad.data_classification == :system_data
    assert ad.reversibility == :reversible
    assert %RiskRank{} = ad.risk_rank
    assert ad.required_evidence == ["systemd.service.status"]
    assert ad.max_evidence_age_secs == 30
    assert ad.requires_approval == true
    assert ad.cooldown_secs == 300
    assert ad.max_retries == 3
    assert ad.timeout_secs == 60
  end

  test "build/1 accepts :maintenance action_class" do
    opts = Keyword.put(@valid_opts, :action_class, :maintenance)
    assert {:ok, %ActionDefinition{action_class: :maintenance}} = ActionDefinition.build(opts)
  end

  test "build/1 accepts :deletion action_class targeting :system_data" do
    opts =
      @valid_opts
      |> Keyword.put(:action_class, :deletion)
      |> Keyword.put(:data_classification, :system_data)
      |> Keyword.put(:reversibility, :irreversible)

    assert {:ok, %ActionDefinition{action_class: :deletion, data_classification: :system_data}} =
             ActionDefinition.build(opts)
  end

  test "build/1 defaults missing data_classification to :protected_user_data" do
    opts = Keyword.delete(@valid_opts, :data_classification)
    # This is a :restart action, not :deletion, so the fail-closed default is valid here
    assert {:ok, %ActionDefinition{data_classification: :protected_user_data}} =
             ActionDefinition.build(opts)
  end

  test "build/1 defaults cooldown_secs to 0" do
    opts = Keyword.delete(@valid_opts, :cooldown_secs)
    assert {:ok, %ActionDefinition{cooldown_secs: 0}} = ActionDefinition.build(opts)
  end

  test "build/1 defaults max_retries to 0" do
    opts = Keyword.delete(@valid_opts, :max_retries)
    assert {:ok, %ActionDefinition{max_retries: 0}} = ActionDefinition.build(opts)
  end

  test "build/1 defaults required_evidence to []" do
    opts = Keyword.delete(@valid_opts, :required_evidence)
    assert {:ok, %ActionDefinition{required_evidence: []}} = ActionDefinition.build(opts)
  end

  # ── Deletion-ineligibility invariant ─────────────────────────────────

  describe "user-data deletion ineligibility invariant" do
    test "deletion action targeting :protected_user_data is rejected" do
      opts =
        @valid_opts
        |> Keyword.put(:action_class, :deletion)
        |> Keyword.put(:data_classification, :protected_user_data)

      assert {:error, :user_data_deletion_ineligible} = ActionDefinition.build(opts)
    end

    test "deletion action with nil data_classification is rejected (defaults to protected)" do
      opts =
        @valid_opts
        |> Keyword.put(:action_class, :deletion)
        |> Keyword.delete(:data_classification)

      assert {:error, :user_data_deletion_ineligible} = ActionDefinition.build(opts)
    end

    test "deletion action with unknown classification string is rejected (fail-closed)" do
      opts =
        @valid_opts
        |> Keyword.put(:action_class, :deletion)
        |> Keyword.put(:data_classification, "totally_unknown")

      assert {:error, :user_data_deletion_ineligible} = ActionDefinition.build(opts)
    end

    test "restart action targeting :protected_user_data is allowed" do
      opts = Keyword.put(@valid_opts, :data_classification, :protected_user_data)
      assert {:ok, %ActionDefinition{}} = ActionDefinition.build(opts)
    end

    test "maintenance action targeting :protected_user_data is allowed" do
      opts =
        @valid_opts
        |> Keyword.put(:action_class, :maintenance)
        |> Keyword.put(:data_classification, :protected_user_data)

      assert {:ok, %ActionDefinition{}} = ActionDefinition.build(opts)
    end
  end

  # ── Forbidden action_id patterns ─────────────────────────────────────

  describe "generic command action forbidden patterns" do
    @forbidden_ids [
      "shell.execute",
      "exec.command",
      "cmd.run",
      "delete.user.data",
      "rm.logs",
      "action.*"
    ]

    for id <- @forbidden_ids do
      test "action_id '#{id}' is rejected" do
        opts = Keyword.put(@valid_opts, :action_id, unquote(id))
        assert {:error, :generic_command_action_forbidden} = ActionDefinition.build(opts)
      end
    end
  end

  # ── Schema version validation ─────────────────────────────────────────

  test "build/1 rejects missing schema_version" do
    opts = Keyword.delete(@valid_opts, :schema_version)
    assert {:error, :missing_schema_version} = ActionDefinition.build(opts)
  end

  test "build/1 rejects unknown schema_version '2'" do
    opts = Keyword.put(@valid_opts, :schema_version, "2")
    assert {:error, {:unknown_schema_version, "2"}} = ActionDefinition.build(opts)
  end

  # ── Unknown action_class ──────────────────────────────────────────────

  test "build/1 rejects unknown action_class" do
    opts = Keyword.put(@valid_opts, :action_class, :unknown_class)
    assert {:error, {:unknown_action_class, :unknown_class}} = ActionDefinition.build(opts)
  end

  # ── Numeric field validation ──────────────────────────────────────────

  test "build/1 rejects max_evidence_age_secs of 0" do
    opts = Keyword.put(@valid_opts, :max_evidence_age_secs, 0)
    assert {:error, {:invalid_field, :max_evidence_age_secs, 0}} = ActionDefinition.build(opts)
  end

  test "build/1 rejects negative timeout_secs" do
    opts = Keyword.put(@valid_opts, :timeout_secs, -1)
    assert {:error, {:invalid_field, :timeout_secs, -1}} = ActionDefinition.build(opts)
  end

  test "build/1 rejects negative cooldown_secs" do
    opts = Keyword.put(@valid_opts, :cooldown_secs, -1)
    assert {:error, {:invalid_field, :cooldown_secs, -1}} = ActionDefinition.build(opts)
  end

  test "build/1 rejects negative max_retries" do
    opts = Keyword.put(@valid_opts, :max_retries, -1)
    assert {:error, {:invalid_field, :max_retries, -1}} = ActionDefinition.build(opts)
  end

  test "build/1 rejects missing timeout_secs" do
    opts = Keyword.delete(@valid_opts, :timeout_secs)
    assert {:error, {:missing_field, :timeout_secs}} = ActionDefinition.build(opts)
  end

  test "build/1 rejects non-boolean requires_approval" do
    opts = Keyword.put(@valid_opts, :requires_approval, "yes")
    assert {:error, {:invalid_field, :requires_approval, "yes"}} = ActionDefinition.build(opts)
  end

  # ── risk_rank from map ───────────────────────────────────────────────

  test "build/1 accepts a risk_rank as a parsed string-key map" do
    opts =
      Keyword.put(@valid_opts, :risk_rank, %{
        "data_loss" => "none",
        "work_loss" => "minimal",
        "disruption" => "none",
        "scope" => "none"
      })

    assert {:ok, %ActionDefinition{risk_rank: %RiskRank{work_loss: :minimal}}} =
             ActionDefinition.build(opts)
  end

  test "build/1 rejects risk_rank with unknown level" do
    opts = Keyword.put(@valid_opts, :risk_rank, %{"data_loss" => "galaxy_brain"})

    assert {:error, {:unknown_risk_level, :data_loss, "galaxy_brain"}} =
             ActionDefinition.build(opts)
  end
end
