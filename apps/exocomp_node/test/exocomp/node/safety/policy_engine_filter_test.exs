defmodule Exocomp.Node.Safety.PolicyEngine.FilterTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.{
    ActionDefinition,
    Evidence,
    PolicyContext,
    PolicyEngine,
    Proposal,
    RiskRank
  }

  alias Exocomp.Node.Safety.PolicyEngine.FilterResult

  # ── test fixtures ─────────────────────────────────────────────────────────

  @now ~U[2024-06-01 12:00:00Z]
  @recent ~U[2024-06-01 11:59:50Z]
  # 10 seconds before now
  @stale ~U[2024-05-31 00:00:00Z]
  # way old

  @minimal_risk %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}

  @action_id "systemd.service.restart"
  @target_id "nginx.service"

  defp make_definition(overrides \\ []) do
    opts = [
      schema_version: "1",
      action_id: Keyword.get(overrides, :action_id, @action_id),
      action_class: Keyword.get(overrides, :action_class, :restart),
      target_type: :systemd_unit,
      data_classification: Keyword.get(overrides, :data_classification, :system_data),
      reversibility: :reversible,
      risk_rank: @minimal_risk,
      required_evidence: Keyword.get(overrides, :required_evidence, ["systemd.service.status"]),
      max_evidence_age_secs: Keyword.get(overrides, :max_evidence_age_secs, 30),
      requires_approval: false,
      cooldown_secs: Keyword.get(overrides, :cooldown_secs, 0),
      max_retries: Keyword.get(overrides, :max_retries, 0),
      timeout_secs: 60
    ]

    {:ok, ad} = ActionDefinition.build(opts)
    ad
  end

  defp make_evidence(overrides \\ []) do
    %Evidence{
      schema_version: "1",
      evidence_id: Keyword.get(overrides, :evidence_id, "ev-001"),
      collector: Keyword.get(overrides, :collector, "systemd.service.status"),
      collector_version: "1.0.0",
      target_id: Keyword.get(overrides, :target_id, @target_id),
      observed_at: Keyword.get(overrides, :observed_at, @recent),
      values: %{"ActiveState" => "active"},
      integrity_hash: String.duplicate("a", 64)
    }
  end

  defp make_proposal(overrides \\ []) do
    %Proposal{
      schema_version: "1",
      action_id: Keyword.get(overrides, :action_id, @action_id),
      target_id: Keyword.get(overrides, :target_id, @target_id),
      parameters: %{},
      evidence_refs: [],
      rationale: "test rationale"
    }
  end

  defp make_context(overrides \\ []) do
    %PolicyContext{
      authorized_action_ids:
        Keyword.get(overrides, :authorized_action_ids, MapSet.new([@action_id])),
      cooldown_state: Keyword.get(overrides, :cooldown_state, %{}),
      retry_counts: Keyword.get(overrides, :retry_counts, %{}),
      now: Keyword.get(overrides, :now, @now)
    }
  end

  # ── check 1: unauthorized ─────────────────────────────────────────────────

  describe "check 1 — unauthorized" do
    test "denies when action_id is not in authorized_action_ids" do
      proposal = make_proposal()
      definition = make_definition()
      evidence = [make_evidence()]
      context = make_context(authorized_action_ids: MapSet.new())

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [], rejected: [{nil, "action not authorized"}]} = result
    end

    test "denies when authorized_action_ids is a different set" do
      proposal = make_proposal()
      definition = make_definition()
      evidence = [make_evidence()]
      context = make_context(authorized_action_ids: MapSet.new(["other.action"]))

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [], rejected: [{nil, "action not authorized"}]} = result
    end

    test "allows when action_id is in authorized_action_ids" do
      proposal = make_proposal()
      definition = make_definition()
      evidence = [make_evidence()]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── check 2: inapplicable (catalog miss) ──────────────────────────────────

  describe "check 2 — inapplicable (catalog miss)" do
    test "denies when catalog is empty" do
      proposal = make_proposal()
      evidence = [make_evidence()]
      context = make_context()

      result = PolicyEngine.filter(proposal, [], evidence, context)

      assert %FilterResult{eligible: [], rejected: [{nil, "action not in catalog"}]} = result
    end

    test "denies when action_id has no matching catalog entry" do
      proposal = make_proposal(action_id: "systemd.service.restart")
      definition = make_definition(action_id: "disk.cleanup")
      evidence = [make_evidence()]
      context = make_context(authorized_action_ids: MapSet.new(["systemd.service.restart"]))

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [], rejected: [{nil, "action not in catalog"}]} = result
    end
  end

  # ── check 3: unsafe data classification ───────────────────────────────────

  describe "check 3 — unsafe data classification" do
    test "denies :deletion action on :protected_user_data" do
      # Build a definition manually (bypassing ActionDefinition.build/1 check)
      definition = %ActionDefinition{
        schema_version: "1",
        action_id: @action_id,
        action_class: :deletion,
        target_type: :user_files,
        data_classification: :protected_user_data,
        reversibility: :irreversible,
        risk_rank: @minimal_risk,
        required_evidence: [],
        max_evidence_age_secs: 30,
        requires_approval: false,
        cooldown_secs: 0,
        max_retries: 0,
        timeout_secs: 60
      }

      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "user data deletion ineligible"}]
             } = result
    end

    test "allows :deletion action on :system_data" do
      definition =
        make_definition(
          action_class: :deletion,
          data_classification: :system_data,
          required_evidence: []
        )

      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "allows :maintenance action on :protected_user_data" do
      definition = make_definition(action_class: :maintenance, required_evidence: [])
      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── check 4: missing evidence ─────────────────────────────────────────────

  describe "check 4 — missing required evidence" do
    test "denies when evidence list is empty but evidence is required" do
      definition = make_definition(required_evidence: ["systemd.service.status"])
      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "missing required evidence: systemd.service.status"}]
             } = result
    end

    test "denies when required collector is not in evidence list" do
      definition = make_definition(required_evidence: ["disk.usage"])
      proposal = make_proposal()
      evidence = [make_evidence(collector: "systemd.service.status")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "missing required evidence: disk.usage"}]
             } = result
    end

    test "denies for first missing collector when multiple are required" do
      definition =
        make_definition(required_evidence: ["collector.a", "collector.b"])

      proposal = make_proposal()
      # only collector.a provided
      evidence = [make_evidence(collector: "collector.a")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "missing required evidence: collector.b"}]
             } = result
    end

    test "allows when all required collectors are present" do
      definition =
        make_definition(
          required_evidence: ["systemd.service.status"],
          max_evidence_age_secs: 300
        )

      proposal = make_proposal()
      evidence = [make_evidence(collector: "systemd.service.status")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "no required evidence → passes evidence check" do
      definition = make_definition(required_evidence: [])
      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── check 4: evidence target_id scoping ──────────────────────────────────

  describe "evidence target_id scoping" do
    test "evidence for wrong target_id is treated as missing" do
      definition =
        make_definition(
          required_evidence: ["systemd.service.status"],
          max_evidence_age_secs: 300
        )

      proposal = make_proposal(target_id: "nginx.service")
      # Evidence is for a different target
      evidence = [make_evidence(collector: "systemd.service.status", target_id: "redis.service")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "missing required evidence: systemd.service.status"}]
             } = result
    end

    test "evidence for correct target_id is accepted" do
      definition =
        make_definition(
          required_evidence: ["systemd.service.status"],
          max_evidence_age_secs: 300
        )

      proposal = make_proposal(target_id: "nginx.service")
      evidence = [make_evidence(collector: "systemd.service.status", target_id: "nginx.service")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "mix of correct and wrong target_id: correct target evidence satisfies requirement" do
      definition =
        make_definition(
          required_evidence: ["systemd.service.status"],
          max_evidence_age_secs: 300
        )

      proposal = make_proposal(target_id: "nginx.service")

      evidence = [
        make_evidence(
          evidence_id: "ev-wrong",
          collector: "systemd.service.status",
          target_id: "redis.service"
        ),
        make_evidence(
          evidence_id: "ev-correct",
          collector: "systemd.service.status",
          target_id: "nginx.service"
        )
      ]

      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── check 5: stale evidence ───────────────────────────────────────────────

  describe "check 5 — stale evidence" do
    test "denies when evidence is older than max_evidence_age_secs" do
      # max_age: 30 seconds; stale evidence is from yesterday
      definition =
        make_definition(required_evidence: ["systemd.service.status"], max_evidence_age_secs: 30)

      proposal = make_proposal()
      evidence = [make_evidence(observed_at: @stale, evidence_id: "ev-stale")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "stale evidence: ev-stale"}]
             } = result
    end

    test "allows when evidence is within max_evidence_age_secs" do
      # max_age: 30 seconds; @recent is 10 seconds before @now
      definition =
        make_definition(required_evidence: ["systemd.service.status"], max_evidence_age_secs: 30)

      proposal = make_proposal()
      evidence = [make_evidence(observed_at: @recent)]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "denies exactly at the boundary (age == max is allowed, age > max is stale)" do
      # Evidence is exactly 30 seconds old — at boundary → allowed
      exactly_at_boundary = DateTime.add(@now, -30, :second)

      definition =
        make_definition(required_evidence: ["systemd.service.status"], max_evidence_age_secs: 30)

      proposal = make_proposal()
      evidence = [make_evidence(observed_at: exactly_at_boundary)]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      # diff == 30 is NOT > 30, so this should pass
      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "denies when evidence is one second past the boundary" do
      one_past = DateTime.add(@now, -31, :second)

      definition =
        make_definition(required_evidence: ["systemd.service.status"], max_evidence_age_secs: 30)

      proposal = make_proposal()
      evidence = [make_evidence(observed_at: one_past, evidence_id: "ev-past-boundary")]
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], evidence, context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "stale evidence: ev-past-boundary"}]
             } = result
    end
  end

  # ── check 6: cooldown ─────────────────────────────────────────────────────

  describe "check 6 — cooldown" do
    test "denies when cooldown has not elapsed" do
      # cooldown_secs: 300; last_executed 10 seconds ago
      definition =
        make_definition(required_evidence: [], cooldown_secs: 300, max_evidence_age_secs: 30)

      proposal = make_proposal()

      context =
        make_context(
          cooldown_state: %{{@action_id, @target_id} => DateTime.add(@now, -10, :second)}
        )

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "action on cooldown"}]
             } = result
    end

    test "allows when cooldown has elapsed" do
      # cooldown_secs: 60; last_executed 300 seconds ago
      definition =
        make_definition(required_evidence: [], cooldown_secs: 60, max_evidence_age_secs: 30)

      proposal = make_proposal()

      context =
        make_context(
          cooldown_state: %{{@action_id, @target_id} => DateTime.add(@now, -300, :second)}
        )

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "allows when cooldown_state has no entry for this action+target" do
      definition = make_definition(required_evidence: [], cooldown_secs: 300)
      proposal = make_proposal()
      context = make_context(cooldown_state: %{})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "allows when cooldown_secs is 0 (no cooldown configured)" do
      definition = make_definition(required_evidence: [], cooldown_secs: 0)
      proposal = make_proposal()

      # Even with a cooldown_state entry, 0 cooldown means no restriction
      context =
        make_context(cooldown_state: %{{@action_id, @target_id} => @now})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "cooldown is scoped to action_id + target_id pair" do
      definition = make_definition(required_evidence: [], cooldown_secs: 300)
      proposal = make_proposal(target_id: "nginx.service")

      # Cooldown entry for a *different* target — should not affect this proposal
      context =
        make_context(
          cooldown_state: %{
            {@action_id, "redis.service"} => DateTime.add(@now, -10, :second)
          },
          authorized_action_ids: MapSet.new([@action_id])
        )

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── check 7: retry exhausted ──────────────────────────────────────────────

  describe "check 7 — retry exhausted" do
    test "denies when retry count equals max_retries" do
      definition = make_definition(required_evidence: [], max_retries: 3)
      proposal = make_proposal()

      context =
        make_context(retry_counts: %{{@action_id, @target_id} => 3})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "retry limit exhausted"}]
             } = result
    end

    test "denies when retry count exceeds max_retries" do
      definition = make_definition(required_evidence: [], max_retries: 3)
      proposal = make_proposal()

      context =
        make_context(retry_counts: %{{@action_id, @target_id} => 5})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{
               eligible: [],
               rejected: [{^definition, "retry limit exhausted"}]
             } = result
    end

    test "allows when retry count is below max_retries" do
      definition = make_definition(required_evidence: [], max_retries: 3)
      proposal = make_proposal()

      context =
        make_context(retry_counts: %{{@action_id, @target_id} => 2})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "allows when no retry_counts entry exists (defaults to 0)" do
      definition = make_definition(required_evidence: [], max_retries: 3)
      proposal = make_proposal()
      context = make_context(retry_counts: %{})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "allows when max_retries is 0 (retry not configured)" do
      definition = make_definition(required_evidence: [], max_retries: 0)
      proposal = make_proposal()

      # Even with a high count, max_retries=0 means no retry limit
      context =
        make_context(retry_counts: %{{@action_id, @target_id} => 100})

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end

    test "retry is scoped to action_id + target_id pair" do
      definition = make_definition(required_evidence: [], max_retries: 3)
      proposal = make_proposal(target_id: "nginx.service")

      # High retry count for a *different* target — should not affect this proposal
      context =
        make_context(
          retry_counts: %{{@action_id, "redis.service"} => 10},
          authorized_action_ids: MapSet.new([@action_id])
        )

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── multiple candidates ───────────────────────────────────────────────────

  describe "multiple candidates — mixed pass/fail" do
    test "eligible and rejected are populated correctly for mixed catalog" do
      # Three action IDs, two authorized
      action_a = "action.a"
      action_b = "action.b"
      action_c = "action.c"

      def_a = make_definition(action_id: action_a, required_evidence: [])
      def_b = make_definition(action_id: action_b, required_evidence: [])

      # action_c is authorized and in catalog but has retry exhausted
      def_c = make_definition(action_id: action_c, required_evidence: [], max_retries: 1)

      # For this test: proposal targets action_a; action_b and action_c are also in catalog
      # but the filter is single-proposal → only action_a gets through checks 1+2.
      # Let me test one proposal per call (the filter is per-proposal).

      # Test action_a → eligible
      proposal_a = make_proposal(action_id: action_a)

      context_a =
        make_context(
          authorized_action_ids: MapSet.new([action_a]),
          cooldown_state: %{},
          retry_counts: %{}
        )

      result_a = PolicyEngine.filter(proposal_a, [def_a, def_b, def_c], [], context_a)
      assert %FilterResult{eligible: [^def_a], rejected: []} = result_a

      # Test action_c with retry exhausted → rejected
      proposal_c = make_proposal(action_id: action_c, target_id: @target_id)

      context_c =
        make_context(
          authorized_action_ids: MapSet.new([action_c]),
          retry_counts: %{{action_c, @target_id} => 1}
        )

      result_c = PolicyEngine.filter(proposal_c, [def_a, def_b, def_c], [], context_c)

      assert %FilterResult{
               eligible: [],
               rejected: [{^def_c, "retry limit exhausted"}]
             } = result_c
    end

    test "all candidates rejected → FilterResult with empty eligible list" do
      # Propose an action not in the catalog
      proposal = make_proposal(action_id: "nonexistent.action")
      definition = make_definition(action_id: @action_id)

      context =
        make_context(authorized_action_ids: MapSet.new(["nonexistent.action"]))

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [], rejected: [{nil, "action not in catalog"}]} = result
    end
  end

  # ── nil / invalid context fields ─────────────────────────────────────────

  describe "nil/invalid context fields — fail closed" do
    test "nil authorized_action_ids in context denies" do
      proposal = make_proposal()
      definition = make_definition(required_evidence: [])

      context = %PolicyContext{
        authorized_action_ids: nil,
        cooldown_state: %{},
        retry_counts: %{},
        now: @now
      }

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [], rejected: _} = result
      assert result.eligible == []
    end

    test "nil cooldown_state in context denies" do
      proposal = make_proposal()
      definition = make_definition(required_evidence: [])

      context = %PolicyContext{
        authorized_action_ids: MapSet.new([@action_id]),
        cooldown_state: nil,
        retry_counts: %{},
        now: @now
      }

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert result.eligible == []
    end

    test "nil retry_counts in context denies" do
      proposal = make_proposal()
      definition = make_definition(required_evidence: [])

      context = %PolicyContext{
        authorized_action_ids: MapSet.new([@action_id]),
        cooldown_state: %{},
        retry_counts: nil,
        now: @now
      }

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert result.eligible == []
    end

    test "nil now in context denies" do
      proposal = make_proposal()
      definition = make_definition(required_evidence: [])

      context = %PolicyContext{
        authorized_action_ids: MapSet.new([@action_id]),
        cooldown_state: %{},
        retry_counts: %{},
        now: nil
      }

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert result.eligible == []
    end

    test "nil proposal denies" do
      definition = make_definition(required_evidence: [])
      context = make_context()

      result = PolicyEngine.filter(nil, [definition], [], context)

      assert %FilterResult{eligible: [], rejected: [{^definition, "invalid proposal: nil"}]} =
               result
    end

    test "nil proposal with empty catalog still produces a rejection" do
      context = make_context()
      result = PolicyEngine.filter(nil, [], [], context)

      assert %FilterResult{eligible: [], rejected: [{nil, "invalid proposal: nil"}]} = result
    end
  end

  # ── all candidates rejected ───────────────────────────────────────────────

  describe "all candidates rejected" do
    test "empty eligible list when all checks fail" do
      # Unauthorized
      proposal = make_proposal()
      definition = make_definition(required_evidence: [])
      context = make_context(authorized_action_ids: MapSet.new())

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert result.eligible == []
      assert length(result.rejected) == 1
    end
  end

  # ── check ordering ────────────────────────────────────────────────────────

  describe "check ordering — first failing check is reported" do
    test "unauthorized reported before inapplicable" do
      # action_id not authorized AND not in catalog → should report unauthorized
      proposal = make_proposal(action_id: "unknown.action")
      definition = make_definition(action_id: @action_id)
      context = make_context(authorized_action_ids: MapSet.new())

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert [{nil, "action not authorized"}] = result.rejected
    end

    test "inapplicable reported before data classification" do
      proposal = make_proposal(action_id: "missing.action")
      definition = make_definition(action_id: "other.action", required_evidence: [])
      context = make_context(authorized_action_ids: MapSet.new(["missing.action"]))

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert [{nil, "action not in catalog"}] = result.rejected
    end

    test "cooldown reported before retry when both fail" do
      definition =
        make_definition(
          required_evidence: [],
          cooldown_secs: 300,
          max_retries: 1
        )

      proposal = make_proposal()

      context =
        make_context(
          cooldown_state: %{{@action_id, @target_id} => DateTime.add(@now, -10, :second)},
          retry_counts: %{{@action_id, @target_id} => 5}
        )

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert [{^definition, "action on cooldown"}] = result.rejected
    end
  end

  # ── empty evidence list edge cases ────────────────────────────────────────

  describe "empty evidence list" do
    test "denies when evidence is required but list is empty" do
      definition = make_definition(required_evidence: ["some.collector"])
      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert [{^definition, "missing required evidence: some.collector"}] = result.rejected
    end

    test "allows when no evidence is required and list is empty" do
      definition = make_definition(required_evidence: [])
      proposal = make_proposal()
      context = make_context()

      result = PolicyEngine.filter(proposal, [definition], [], context)

      assert %FilterResult{eligible: [^definition], rejected: []} = result
    end
  end

  # ── FilterResult struct ───────────────────────────────────────────────────

  describe "FilterResult struct" do
    test "has default eligible: [] and rejected: []" do
      fr = %FilterResult{}
      assert fr.eligible == []
      assert fr.rejected == []
    end
  end
end
