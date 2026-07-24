defmodule Exocomp.Node.Safety.PolicyEngineTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.{
    ActionDefinition,
    Evidence,
    PolicyContext,
    PolicyEngine,
    Proposal,
    RiskRank,
    ValidatorResult
  }

  @now ~U[2026-07-24 01:00:00Z]

  describe "evaluate/4 decisions" do
    test "allows a single eligible candidate that does not require approval" do
      action = action("service.reload")

      assert %ValidatorResult{
               decision: :allow,
               action_id: "service.reload",
               evidence_refs: [],
               reason: reason
             } = evaluate([action])

      assert reason =~ "service.reload"
      assert_risk_audit(reason, action)
    end

    test "requires approval for a single eligible candidate configured for approval" do
      action = action("service.restart", requires_approval: true)

      assert %ValidatorResult{
               decision: :approval_required,
               action_id: "service.restart",
               reason: reason
             } = evaluate([action])

      assert_risk_audit(reason, action)
    end

    test "denies an empty catalog" do
      assert %ValidatorResult{
               decision: :deny,
               action_id: nil,
               evidence_refs: [],
               reason: reason
             } = evaluate([])

      assert reason =~ "no eligible"
    end

    test "denies when all candidates are filtered and audits every rejection" do
      unauthorized = action("service.reload")
      missing_evidence = action("service.restart", required_evidence: ["service.status"])

      result =
        PolicyEngine.evaluate(
          proposal(),
          [unauthorized, missing_evidence],
          [],
          context(["service.restart"])
        )

      assert result.decision == :deny
      assert result.action_id == nil
      assert result.reason =~ "service.reload"
      assert result.reason =~ "action not authorized"
      assert result.reason =~ "service.restart"
      assert result.reason =~ "missing required evidence: service.status"

      assert string_index(result.reason, "service.reload") <
               string_index(result.reason, "service.restart")
    end

    test "selects the lowest risk of three candidates repeatably" do
      low = action("service.low", risk_rank: risk(disruption: :minimal))
      medium = action("service.medium", risk_rank: risk(work_loss: :minimal))
      high = action("service.high", risk_rank: risk(data_loss: :minimal))
      catalog = [high, low, medium]

      results = for _ <- 1..25, do: evaluate(catalog)

      assert Enum.uniq(Enum.map(results, & &1.action_id)) == ["service.low"]
      assert Enum.uniq(Enum.map(results, & &1.reason)) |> length() == 1

      reason = hd(results).reason
      assert_ordered(reason, ["service.low", "service.medium", "service.high"])
      Enum.each(catalog, &assert_risk_audit(reason, &1))
    end

    test "breaks equal-risk ties by action_id alphabetically" do
      rank = risk(disruption: :moderate)
      alpha = action("service.alpha", risk_rank: rank)
      zulu = action("service.zulu", risk_rank: rank)

      result = evaluate([zulu, alpha])

      assert result.decision == :allow
      assert result.action_id == "service.alpha"
      assert_ordered(result.reason, ["service.alpha", "service.zulu"])
    end

    test "filters a stale candidate and selects the remaining fresh candidate" do
      stale_action =
        action("service.alpha", required_evidence: ["alpha.status"], max_evidence_age_secs: 60)

      safe_action =
        action("service.beta", required_evidence: ["beta.status"], max_evidence_age_secs: 60)

      evidence = [
        evidence("ev-stale", "alpha.status", DateTime.add(@now, -61, :second)),
        evidence("ev-fresh", "beta.status", @now)
      ]

      result = evaluate([stale_action, safe_action], evidence)

      assert result.decision == :allow
      assert result.action_id == "service.beta"
      assert result.evidence_refs == ["ev-fresh"]
      assert result.reason =~ "service.alpha"
      assert result.reason =~ "stale evidence: ev-stale"
      assert result.reason =~ "service.beta"
    end

    test "denies a nil catalog rather than treating policy unavailability as permission" do
      assert %ValidatorResult{decision: :deny, action_id: nil, reason: reason} =
               PolicyEngine.evaluate(proposal(), nil, [], context([]))

      assert reason != ""
    end

    test "never escalates while a lower-risk eligible candidate remains" do
      high =
        action("service.destructive",
          risk_rank: risk(data_loss: :critical),
          requires_approval: true
        )

      low = action("service.observe", risk_rank: risk(scope: :minimal))

      for catalog <- [[high, low], [low, high]] do
        result = evaluate(catalog)
        assert result.decision == :allow
        assert result.action_id == "service.observe"
      end
    end

    test "requires every collector and returns all evidence used by the selected action" do
      incomplete =
        action("service.incomplete", required_evidence: ["service.status", "service.metrics"])

      complete =
        action("service.complete", required_evidence: ["service.status", "service.config"])

      evidence = [
        evidence("ev-status", "service.status"),
        evidence("ev-config", "service.config")
      ]

      result = evaluate([incomplete, complete], evidence)

      assert result.decision == :allow
      assert result.action_id == "service.complete"
      assert result.evidence_refs == ["ev-status", "ev-config"]
      assert result.reason =~ "service.incomplete"
      assert result.reason =~ "missing required evidence: service.metrics"
    end

    test "accepts a single Evidence struct as specified by the public API" do
      action = action("service.inspect", required_evidence: ["service.status"])
      evidence = evidence("ev-one", "service.status")

      assert %ValidatorResult{
               decision: :allow,
               action_id: "service.inspect",
               evidence_refs: ["ev-one"]
             } = evaluate([action], evidence)
    end
  end

  describe "evaluate/4 safety and determinism" do
    test "the same inputs always produce the identical ValidatorResult" do
      alpha = action("service.alpha", risk_rank: risk(disruption: :minimal))
      beta = action("service.beta", risk_rank: risk(work_loss: :minimal))
      inputs = {proposal(), [beta, alpha], [], context(["service.alpha", "service.beta"])}

      results =
        for _ <- 1..100 do
          {proposal, catalog, evidence, policy_context} = inputs
          PolicyEngine.evaluate(proposal, catalog, evidence, policy_context)
        end

      assert Enum.uniq(results) == [hd(results)]
      assert hd(results).action_id == "service.alpha"
      assert hd(results).decision == :allow
    end

    test "an exception in filtering is caught and denied as an internal policy error" do
      # A malformed catalog member makes EXOCOMP-73's filter pattern matching
      # raise. The public evaluator must contain that implementation failure.
      assert %ValidatorResult{
               decision: :deny,
               action_id: nil,
               evidence_refs: [],
               reason: "internal policy error"
             } = PolicyEngine.evaluate(proposal(), [:malformed], [], context(["service.alpha"]))
    end

    test "nil and unexpected inputs all fail closed" do
      valid = {proposal(), [action("service.alpha")], [], context(["service.alpha"])}

      for args <- [
            {nil, elem(valid, 1), elem(valid, 2), elem(valid, 3)},
            {elem(valid, 0), elem(valid, 1), nil, elem(valid, 3)},
            {elem(valid, 0), elem(valid, 1), elem(valid, 2), nil},
            {:unexpected, elem(valid, 1), elem(valid, 2), elem(valid, 3)}
          ] do
        assert %ValidatorResult{decision: :deny, action_id: nil} =
                 apply(PolicyEngine, :evaluate, Tuple.to_list(args))
      end
    end
  end

  defp evaluate(catalog, evidence \\ []) do
    ids = Enum.map(catalog, & &1.action_id)
    PolicyEngine.evaluate(proposal(), catalog, evidence, context(ids))
  end

  defp proposal do
    %Proposal{
      schema_version: Proposal.schema_version(),
      action_id: "service.request",
      target_id: "example.service",
      parameters: %{},
      evidence_refs: [],
      rationale: "restore service health"
    }
  end

  defp context(authorized_action_ids) do
    %PolicyContext{
      authorized_action_ids: MapSet.new(authorized_action_ids),
      cooldown_state: %{},
      retry_counts: %{},
      now: @now
    }
  end

  defp action(action_id, overrides \\ []) do
    defaults = [
      schema_version: ActionDefinition.schema_version(),
      action_id: action_id,
      action_class: :maintenance,
      target_type: :systemd_unit,
      data_classification: :system_data,
      reversibility: :reversible,
      risk_rank: risk(),
      required_evidence: [],
      max_evidence_age_secs: 300,
      requires_approval: false,
      cooldown_secs: 0,
      max_retries: 0,
      timeout_secs: 30
    ]

    struct!(ActionDefinition, Keyword.merge(defaults, overrides))
  end

  defp evidence(evidence_id, collector, observed_at \\ @now) do
    %Evidence{
      schema_version: Evidence.schema_version(),
      evidence_id: evidence_id,
      collector: collector,
      collector_version: "1.0.0",
      target_id: "example.service",
      observed_at: observed_at,
      values: %{},
      integrity_hash: String.duplicate("a", 64)
    }
  end

  defp risk(overrides \\ []) do
    defaults = [
      data_loss: :none,
      work_loss: :none,
      disruption: :none,
      scope: :none
    ]

    struct!(RiskRank, Keyword.merge(defaults, overrides))
  end

  defp assert_risk_audit(reason, action) do
    assert reason =~ action.action_id
    assert reason =~ inspect(action.risk_rank)
  end

  defp assert_ordered(reason, action_ids) do
    indexes = Enum.map(action_ids, &string_index(reason, &1))
    assert indexes == Enum.sort(indexes)
  end

  defp string_index(string, fragment) do
    {index, _length} = :binary.match(string, fragment)
    index
  end
end
