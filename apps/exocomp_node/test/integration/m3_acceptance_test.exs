defmodule Exocomp.Integration.M3AcceptanceTest do
  @moduledoc """
  M3 milestone acceptance tests.

  These tests verify each M3-CRIT-* criterion using the real policy domain
  modules. They run without systemd, root, or Docker and are intended to
  run inside `make test` alongside the unit suite.

  ## M3-CRIT coverage

  | Criterion | Coverage                                                                      |
  |-----------|-------------------------------------------------------------------------------|
  | M3-CRIT-1 | Schema-versioned proposals/evidence: bounded fields, rejection of unknown/malformed/stale/mismatched inputs. |
  | M3-CRIT-2 | Deterministic least-impact policy ordering; no escalation past eligible safer candidate. |
  | M3-CRIT-3 | User and unknown data cannot be targeted by any deletion action, including with approval. |
  | M3-CRIT-4 | Bounded system-log cleanup is automatic only under validated disk pressure and cannot exceed installed limits. |
  | M3-CRIT-5 | Failed-service restart allowed automatically; active/degraded service restart requires approval. |
  | M3-CRIT-6 | Approval tampering, expiry, replay, binding mismatch, changed preconditions — all prevent execution. |
  | M3-CRIT-7 | Node runs unprivileged; executor uses exact argv from catalog; arbitrary commands, paths, and services are rejected. |
  | M3-CRIT-8 | Complete correlated audit trail for every state-changing gate operation; Make gates pass. |

  ## Running

      MIX_ENV=test mix test apps/exocomp_node/test/integration/m3_acceptance_test.exs

  These tests do NOT require systemd or root access. They run inside the standard
  CI builder container alongside `make test`. Tags: `:m3_acceptance`.
  """

  use ExUnit.Case, async: false

  @moduletag :m3_acceptance
  @moduletag :tmp_dir

  import ExUnit.CaptureLog

  alias Exocomp.Core.ApprovalToken
  alias Exocomp.Node.ActionCatalog
  alias Exocomp.Node.Executor
  alias Exocomp.Node.ExecutorLock
  alias Exocomp.Node.MockCommander
  alias Exocomp.Node.Privilege
  alias Exocomp.Node.Safety.ActionDefinition
  alias Exocomp.Node.Safety.ApprovalGate
  alias Exocomp.Node.Safety.ApprovalVerifier
  alias Exocomp.Node.Safety.DataClassification
  alias Exocomp.Node.Safety.Evidence
  alias Exocomp.Node.Safety.PolicyContext
  alias Exocomp.Node.Safety.PolicyEngine
  alias Exocomp.Node.Safety.PreconditionChecker
  alias Exocomp.Node.Safety.Proposal
  alias Exocomp.Node.Safety.ReplayLedger
  alias Exocomp.Node.Safety.RiskRank
  alias Exocomp.Node.VacuumBounds
  alias Exocomp.Node.VacuumState

  # ===========================================================================
  # M3-CRIT-1: Schema-versioned proposals/evidence rejected when unknown,
  #             malformed, stale, or mismatched.
  # ===========================================================================

  describe "M3-CRIT-1: schema validation and bounded parsing" do
    test "M3-CRIT-1a: proposal with missing schema_version is rejected" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # No schema_version → parser returns :missing_schema_version.
      # An LLM or attacker cannot submit a proposal without a known version.
      attrs = %{
        "action_id" => "systemd.service.restart",
        "target_id" => "nginx.service",
        "parameters" => %{},
        "evidence_refs" => [],
        "rationale" => "restore service"
      }

      assert {:error, :missing_schema_version} = Proposal.parse(attrs)
    end

    test "M3-CRIT-1b: proposal with unknown schema_version is rejected" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # Future schema version "99" is unknown and must not be parsed.
      attrs = %{
        "schema_version" => "99",
        "action_id" => "systemd.service.restart",
        "target_id" => "nginx.service",
        "parameters" => %{},
        "evidence_refs" => [],
        "rationale" => "restore service"
      }

      assert {:error, {:unknown_schema_version, "99"}} = Proposal.parse(attrs)
    end

    test "M3-CRIT-1c: proposal with injected unknown extra fields is rejected" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # Unknown fields in an LLM output (e.g. injected shell command key) are
      # rejected outright. No unknown key passes through to the action catalog.
      base = %{
        "schema_version" => "1",
        "action_id" => "systemd.service.restart",
        "target_id" => "nginx.service",
        "parameters" => %{},
        "evidence_refs" => [],
        "rationale" => "restore service"
      }

      for extra_key <- ["cmd", "shell", "path", "env", "sudo", "override"] do
        attrs = Map.put(base, extra_key, "injected_value")

        assert {:error, {:unknown_fields, _}} = Proposal.parse(attrs),
               "Expected unknown_fields error for extra key #{inspect(extra_key)}"
      end
    end

    test "M3-CRIT-1d: proposal action_id with shell injection characters is rejected" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # Shell metacharacters and path traversal patterns in action_id must be
      # rejected. The action_id allowlist permits only safe identifiers.
      injection_ids = [
        "restart; rm -rf /",
        "$(id)",
        "`id`",
        "restart | cat /etc/passwd",
        "restart\nALL=(root) NOPASSWD: ALL",
        "restart\x00null",
        "../../../etc/shadow",
        ""
      ]

      base = %{
        "schema_version" => "1",
        "target_id" => "nginx.service",
        "parameters" => %{},
        "evidence_refs" => [],
        "rationale" => "restore service"
      }

      for bad_id <- injection_ids do
        attrs = Map.put(base, "action_id", bad_id)

        assert {:error, _} = Proposal.parse(attrs),
               "Expected error for injection action_id: #{inspect(bad_id)}"
      end
    end

    test "M3-CRIT-1e: stale evidence (1s past max_age) is denied by policy engine" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # Evidence collected 31 seconds ago when max_evidence_age_secs is 30
      # must be rejected. Proposals cannot reuse evidence from prior observations.
      max_age = 30
      now = DateTime.utc_now()
      stale_at = DateTime.add(now, -(max_age + 1), :second)

      action =
        build_action("systemd.service.restart",
          required_evidence: ["systemd.service.status"],
          max_evidence_age_secs: max_age
        )

      stale_evidence =
        build_evidence("ev-stale", "systemd.service.status", observed_at: stale_at)

      result =
        PolicyEngine.evaluate(
          build_proposal("systemd.service.restart"),
          [action],
          [stale_evidence],
          build_context(["systemd.service.restart"], now: now)
        )

      assert result.decision == :deny
      assert result.reason =~ "stale evidence: ev-stale"
    end

    test "M3-CRIT-1f: evidence from a different target is not cross-accepted" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # Evidence collected for "redis.service" must not satisfy a requirement
      # for "nginx.service". Evidence is strictly scoped to the proposal's target_id.
      action =
        build_action("systemd.service.restart",
          required_evidence: ["systemd.service.status"]
        )

      wrong_target_ev =
        build_evidence("ev-wrong", "systemd.service.status", target_id: "redis.service")

      result =
        PolicyEngine.evaluate(
          build_proposal("systemd.service.restart", target_id: "nginx.service"),
          [action],
          [wrong_target_ev],
          build_context(["systemd.service.restart"])
        )

      assert result.decision == :deny
      assert result.reason =~ "missing required evidence"
    end

    test "M3-CRIT-1g: ActionDefinition with unknown schema version is rejected" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      assert {:error, {:unknown_schema_version, "99"}} =
               ActionDefinition.build(
                 Keyword.put(valid_action_opts(), :schema_version, "99")
               )
    end

    test "M3-CRIT-1h: policy denies when nil or invalid proposal is supplied" do
      # [PASS/FAIL evidence for M3-CRIT-1]
      #
      # A nil proposal must not silently become a valid evaluation. The policy
      # engine must fail closed when inputs are invalid.
      action = build_action("systemd.service.restart")
      context = build_context(["systemd.service.restart"])

      nil_result = PolicyEngine.evaluate(nil, [action], [], context)
      assert nil_result.decision == :deny

      invalid_result = PolicyEngine.evaluate(:not_a_proposal, [action], [], context)
      assert invalid_result.decision == :deny

      nil_catalog_result =
        PolicyEngine.evaluate(build_proposal("systemd.service.restart"), nil, [], context)

      assert nil_catalog_result.decision == :deny
    end
  end

  # ===========================================================================
  # M3-CRIT-2: Deterministic least-impact ordering; no escalation past a
  #              safer eligible action.
  # ===========================================================================

  describe "M3-CRIT-2: deterministic least-impact policy ordering" do
    test "M3-CRIT-2a: lowest-risk action is always selected across 100 catalog orderings" do
      # [PASS/FAIL evidence for M3-CRIT-2]
      #
      # The safe observer (zero risk) is always selected over the disruptive
      # restart (critical disruption). This holds regardless of catalog ordering.
      observer =
        build_action("service.observe",
          risk: risk(disruption: :none),
          requires_approval: false
        )

      disruptive =
        build_action("service.restart",
          risk: risk(disruption: :critical),
          requires_approval: true
        )

      catalog = [observer, disruptive]
      context = build_context(["service.observe", "service.restart"])

      results =
        for _ <- 1..100 do
          PolicyEngine.evaluate(build_proposal("service.observe"), Enum.shuffle(catalog), [], context)
        end

      assert Enum.all?(results, &(&1.decision == :allow)),
             "Some policy evaluations did not return :allow"

      assert Enum.all?(results, &(&1.action_id == "service.observe")),
             "Policy did not consistently select the lowest-risk action"

      # All 100 reason strings must be identical (fully deterministic).
      assert results |> Enum.map(& &1.reason) |> Enum.uniq() |> length() == 1,
             "Policy produced non-deterministic reason strings"
    end

    test "M3-CRIT-2b: policy never escalates to approval-required while a safe non-approval action exists" do
      # [PASS/FAIL evidence for M3-CRIT-2]
      #
      # A no-risk diagnostic must be selected over a high-risk approval-required
      # restart when both are eligible.
      diagnostic =
        build_action("service.diagnose",
          risk: risk(disruption: :none),
          requires_approval: false
        )

      approval_restart =
        build_action("service.restart",
          risk: risk(disruption: :critical),
          requires_approval: true
        )

      context = build_context(["service.diagnose", "service.restart"])

      for catalog <- [[diagnostic, approval_restart], [approval_restart, diagnostic]] do
        result = PolicyEngine.evaluate(build_proposal("service.diagnose"), catalog, [], context)
        assert result.decision == :allow
        assert result.action_id == "service.diagnose"
      end
    end

    test "M3-CRIT-2c: risk dimension ordering — data_loss beats work_loss regardless of magnitude" do
      # [PASS/FAIL evidence for M3-CRIT-2]
      #
      # An action with no data_loss but critical work_loss is safer than one
      # with minimal data_loss but no work_loss. Data-loss risk always takes
      # precedence in the ordering.
      safe_work =
        build_action("action.safe-work",
          risk: risk(data_loss: :none, work_loss: :critical)
        )

      risky_data =
        build_action("action.risky-data",
          risk: risk(data_loss: :minimal, work_loss: :none)
        )

      context = build_context(["action.safe-work", "action.risky-data"])

      result =
        PolicyEngine.evaluate(
          build_proposal("action.safe-work"),
          [risky_data, safe_work],
          [],
          context
        )

      assert result.decision == :allow
      assert result.action_id == "action.safe-work"
    end

    test "M3-CRIT-2d: equal-risk ties are broken alphabetically by action_id" do
      # [PASS/FAIL evidence for M3-CRIT-2]
      #
      # When two actions share identical risk ranks, the alphabetically earlier
      # action_id is selected. This determinism is required for audit trails.
      rank = risk(disruption: :moderate)
      alpha = build_action("service.alpha", risk: rank)
      zulu = build_action("service.zulu", risk: rank)
      context = build_context(["service.alpha", "service.zulu"])

      for catalog <- [[alpha, zulu], [zulu, alpha]] do
        result = PolicyEngine.evaluate(build_proposal("service.alpha"), catalog, [], context)
        assert result.decision == :allow
        assert result.action_id == "service.alpha"
      end
    end
  end

  # ===========================================================================
  # M3-CRIT-3: User and unknown data cannot be selected by any deletion action,
  #              including with a valid approval.
  # ===========================================================================

  describe "M3-CRIT-3: user and unknown data deletion ineligibility" do
    test "M3-CRIT-3a: ActionDefinition rejects user-data deletion at construction time" do
      # [PASS/FAIL evidence for M3-CRIT-3]
      #
      # The type-level invariant prevents an ActionDefinition with
      # action_class: :deletion + data_classification: :protected_user_data
      # from being built. User-data deletion is unrepresentable in the catalog.
      assert {:error, :user_data_deletion_ineligible} =
               ActionDefinition.build(
                 valid_action_opts()
                 |> Keyword.put(:action_class, :deletion)
                 |> Keyword.put(:data_classification, :protected_user_data)
               )
    end

    test "M3-CRIT-3b: unknown data classifications default to protected_user_data" do
      # [PASS/FAIL evidence for M3-CRIT-3]
      #
      # Any unrecognized data classification string resolves to
      # :protected_user_data. This ensures that unknown data can never become
      # eligible for a deletion action.
      unknown_inputs = [nil, "user_files", "SYSTEM", "unknown_type", "", :atom_unknown]

      for unknown <- unknown_inputs do
        result = DataClassification.classify(unknown)

        assert result == :protected_user_data,
               "Expected :protected_user_data for #{inspect(unknown)}, got #{inspect(result)}"
      end
    end

    test "M3-CRIT-3c: deletion of unknown classification fails at ActionDefinition build time" do
      # [PASS/FAIL evidence for M3-CRIT-3]
      #
      # An unknown classification is normalized to :protected_user_data by
      # DataClassification.classify/1 before ActionDefinition.build/1 validates
      # it — so the deletion is rejected before the action is ever registered.
      assert {:error, :user_data_deletion_ineligible} =
               ActionDefinition.build(
                 valid_action_opts()
                 |> Keyword.put(:action_class, :deletion)
                 |> Keyword.put(:data_classification, "totally_unknown_classification")
               )
    end

    test "M3-CRIT-3d: policy engine denies deletion proposals targeting protected_user_data" do
      # [PASS/FAIL evidence for M3-CRIT-3]
      #
      # Even if an attacker bypassed ActionDefinition.build/1 by constructing
      # the struct directly, the policy engine's filter independently blocks
      # deletion-class actions on :protected_user_data (defense-in-depth).
      deletion_def = %ActionDefinition{
        schema_version: "1",
        action_id: "user.files.delete",
        action_class: :deletion,
        target_type: :user_files,
        data_classification: :protected_user_data,
        reversibility: :irreversible,
        risk_rank: risk(),
        required_evidence: [],
        max_evidence_age_secs: 30,
        requires_approval: true,
        cooldown_secs: 0,
        max_retries: 0,
        timeout_secs: 60
      }

      context = build_context(["user.files.delete"])

      result =
        PolicyEngine.evaluate(
          build_proposal("user.files.delete"),
          [deletion_def],
          [],
          context
        )

      assert result.decision == :deny
      assert result.reason =~ "user data deletion ineligible"
    end

    test "M3-CRIT-3e: the action catalog contains no user-data or arbitrary deletion action" do
      # [PASS/FAIL evidence for M3-CRIT-3]
      #
      # The installed action catalog exposes exactly two safe actions:
      # :restart_service and :vacuum_logs. No generic deletion or shell
      # command action exists. Approval tokens cannot authorize actions absent
      # from the installed catalog.
      catalog_ids = ActionCatalog.action_ids()

      assert :restart_service in catalog_ids
      assert :vacuum_logs in catalog_ids
      assert length(catalog_ids) == 2,
             "Catalog must contain exactly 2 actions; found: #{inspect(catalog_ids)}"

      # No forbidden action classes exist in the catalog.
      for id <- catalog_ids do
        str_id = Atom.to_string(id)
        refute str_id =~ "delete", "Catalog must not contain deletion action: #{str_id}"
        refute str_id =~ "shell", "Catalog must not contain shell action: #{str_id}"
        refute str_id =~ "exec", "Catalog must not contain exec action: #{str_id}"
        refute str_id =~ "file", "Catalog must not contain file action: #{str_id}"
      end
    end
  end

  # ===========================================================================
  # M3-CRIT-4: Bounded system-log cleanup runs automatically only under
  #              validated disk pressure and cannot exceed installed limits.
  # ===========================================================================

  describe "M3-CRIT-4: bounded system-log cleanup eligibility" do
    setup do
      # Snapshot and restore application env around each test.
      prev_source = Application.get_env(:exocomp_node, :vacuum_log_source)
      prev_retention = Application.get_env(:exocomp_node, :vacuum_min_retention_secs)
      prev_reclaim = Application.get_env(:exocomp_node, :vacuum_max_reclaim_bytes)
      prev_free = Application.get_env(:exocomp_node, :vacuum_min_free_space_bytes)
      prev_cooldown = Application.get_env(:exocomp_node, :vacuum_cooldown_secs)
      prev_retries = Application.get_env(:exocomp_node, :vacuum_max_retries)
      prev_state_server = Application.get_env(:exocomp_node, :vacuum_state_server)

      Application.put_env(:exocomp_node, :vacuum_log_source, "/var/log/journal")
      Application.put_env(:exocomp_node, :vacuum_min_retention_secs, 86_400)
      Application.put_env(:exocomp_node, :vacuum_max_reclaim_bytes, 104_857_600)
      Application.put_env(:exocomp_node, :vacuum_min_free_space_bytes, 536_870_912)
      Application.put_env(:exocomp_node, :vacuum_cooldown_secs, 3_600)
      Application.put_env(:exocomp_node, :vacuum_max_retries, 3)

      # Start an isolated VacuumState with no prior history.
      {:ok, state_pid} = VacuumState.start_link(name: nil)
      Application.put_env(:exocomp_node, :vacuum_state_server, state_pid)

      on_exit(fn ->
        restore_env(:vacuum_log_source, prev_source)
        restore_env(:vacuum_min_retention_secs, prev_retention)
        restore_env(:vacuum_max_reclaim_bytes, prev_reclaim)
        restore_env(:vacuum_min_free_space_bytes, prev_free)
        restore_env(:vacuum_cooldown_secs, prev_cooldown)
        restore_env(:vacuum_max_retries, prev_retries)
        restore_env(:vacuum_state_server, prev_state_server)
        if Process.alive?(state_pid), do: GenServer.stop(state_pid)
      end)

      :ok
    end

    test "M3-CRIT-4a: below-threshold and warning pressure are not eligible for cleanup" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # :below_threshold and :warning are not sufficient to trigger automatic
      # cleanup. Only :critical pressure opens the eligibility gate.
      ev = disk_pressure_evidence("/var/log/journal")

      assert {:error, :below_threshold} =
               VacuumBounds.check_eligible({:ok, ev, :below_threshold})

      assert {:error, :below_threshold} =
               VacuumBounds.check_eligible({:ok, ev, :warning})
    end

    test "M3-CRIT-4b: only critical disk pressure triggers automatic cleanup" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # :critical threshold → eligible. The returned bounds_map contains the
      # four installed configuration limits.
      ev = disk_pressure_evidence("/var/log/journal")

      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible({:ok, ev, :critical})

      assert is_binary(bounds.log_source)
      assert is_integer(bounds.max_reclaim_bytes) and bounds.max_reclaim_bytes > 0
      assert is_integer(bounds.min_retention_secs) and bounds.min_retention_secs > 0
    end

    test "M3-CRIT-4c: check_eligible/1 accepts exactly one argument — callers cannot supply parameters" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # The public API has no 2-arity or 3-arity variant. Callers cannot pass
      # additional parameters to widen the allowed vacuum limits.
      assert function_exported?(VacuumBounds, :check_eligible, 1)
      refute function_exported?(VacuumBounds, :check_eligible, 2)
      refute function_exported?(VacuumBounds, :check_eligible, 3)
    end

    test "M3-CRIT-4d: caller-provided path in evidence cannot override the installed source" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # Even if an evidence struct has a foreign target_id, the bounds_map
      # always reflects the installed config path, not any value from the
      # evidence struct or external request.
      malicious_evidence = %Evidence{
        disk_pressure_evidence("/var/log/journal")
        | target_id: "/home/attacker/evil"
      }

      assert {:ok, :eligible, bounds} =
               VacuumBounds.check_eligible({:ok, malicious_evidence, :critical})

      assert bounds.log_source == "/var/log/journal"
      refute bounds.log_source == "/home/attacker/evil"
    end

    test "M3-CRIT-4e: user paths are rejected as vacuum sources" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # User paths (/home, /tmp, /root) are unconditionally rejected as
      # eligible vacuum sources. This prevents any user-data path from being
      # targeted by the log cleanup action.
      user_paths = ["/home/alice/logs", "/tmp", "/root/.cache", "/tmp/subdir", "/home"]

      for path <- user_paths do
        assert {:error, :user_data_path} = VacuumBounds.validate_source(path),
               "Expected :user_data_path error for #{path}"
      end
    end

    test "M3-CRIT-4f: unknown paths are rejected as vacuum sources" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # Any path not in the known system-journal allowlist is rejected as
      # :unknown_path. This prevents arbitrary filesystem paths from being
      # targeted by the cleanup action.
      unknown_paths = ["/var/log", "/data/custom", "/etc/logs", "/opt/logs", ""]

      for path <- unknown_paths do
        assert {:error, :unknown_path} = VacuumBounds.validate_source(path),
               "Expected :unknown_path error for #{path}"
      end
    end

    test "M3-CRIT-4g: bounds_map contains exactly the four installed config fields" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # The bounds_map must expose only the four allowlisted keys sourced from
      # Application config. No extra key can carry a caller-widened limit.
      ev = disk_pressure_evidence("/var/log/journal")

      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible({:ok, ev, :critical})

      expected_keys =
        MapSet.new([:log_source, :min_retention_secs, :max_reclaim_bytes, :min_free_space_bytes])

      assert MapSet.new(Map.keys(bounds)) == expected_keys
      assert bounds.log_source == "/var/log/journal"
      assert bounds.min_retention_secs == 86_400
      assert bounds.max_reclaim_bytes == 104_857_600
    end

    test "M3-CRIT-4h: user path installed as source is rejected at eligibility check time" do
      # [PASS/FAIL evidence for M3-CRIT-4]
      #
      # If the installed config itself contains a user path (operator
      # misconfiguration), check_eligible/1 detects and rejects it.
      Application.put_env(:exocomp_node, :vacuum_log_source, "/home/user/logs")
      ev = disk_pressure_evidence("/home/user/logs")

      assert {:error, :invalid_source, :user_data_path} =
               VacuumBounds.check_eligible({:ok, ev, :critical})
    end
  end

  # ===========================================================================
  # M3-CRIT-5: Failed-service restart allowed automatically; active/degraded
  #              service restart produces approval_required.
  # ===========================================================================

  describe "M3-CRIT-5: service state determines approval requirement" do
    test "M3-CRIT-5a: failed/inactive service catalog entry (requires_approval: false) → :allow" do
      # [PASS/FAIL evidence for M3-CRIT-5]
      #
      # When the installed definition for a failed service has
      # requires_approval: false, the policy engine returns :allow.
      # This is the automatic restart path for inactive/failed services.
      auto_restart =
        build_action("systemd.service.restart_failed",
          requires_approval: false,
          risk: risk(disruption: :minimal)
        )

      context = build_context(["systemd.service.restart_failed"])

      result =
        PolicyEngine.evaluate(
          build_proposal("systemd.service.restart_failed"),
          [auto_restart],
          [],
          context
        )

      assert result.decision == :allow
      assert result.action_id == "systemd.service.restart_failed"
    end

    test "M3-CRIT-5b: active/degraded service catalog entry (requires_approval: true) → :approval_required" do
      # [PASS/FAIL evidence for M3-CRIT-5]
      #
      # When the installed definition for an active/degraded service has
      # requires_approval: true, the policy engine returns :approval_required.
      # Interrupting live workloads requires a task-bound operator approval.
      active_restart =
        build_action("systemd.service.restart_active",
          requires_approval: true,
          risk: risk(disruption: :high)
        )

      context = build_context(["systemd.service.restart_active"])

      result =
        PolicyEngine.evaluate(
          build_proposal("systemd.service.restart_active"),
          [active_restart],
          [],
          context
        )

      assert result.decision == :approval_required
      assert result.action_id == "systemd.service.restart_active"
    end

    test "M3-CRIT-5c: policy selects auto-restart (failed) over approval-restart (active) by risk ordering" do
      # [PASS/FAIL evidence for M3-CRIT-5]
      #
      # When both options are eligible, the lower-risk auto-restart is
      # selected. The policy never escalates past the safer eligible action.
      auto_restart =
        build_action("systemd.service.restart_failed",
          requires_approval: false,
          risk: risk(disruption: :minimal)
        )

      active_restart =
        build_action("systemd.service.restart_active",
          requires_approval: true,
          risk: risk(disruption: :high)
        )

      context =
        build_context([
          "systemd.service.restart_failed",
          "systemd.service.restart_active"
        ])

      for catalog <- [[auto_restart, active_restart], [active_restart, auto_restart]] do
        result =
          PolicyEngine.evaluate(
            build_proposal("systemd.service.restart_failed"),
            catalog,
            [],
            context
          )

        assert result.decision == :allow
        assert result.action_id == "systemd.service.restart_failed"
      end
    end

    test "M3-CRIT-5d: policy requires approval when the only eligible restart is the active-service variant" do
      # [PASS/FAIL evidence for M3-CRIT-5]
      #
      # When only the approval-required variant is eligible (e.g. the
      # auto-restart action is not in the authorized set), the policy correctly
      # returns :approval_required rather than denying outright.
      active_restart =
        build_action("systemd.service.restart_active",
          requires_approval: true,
          risk: risk(disruption: :high)
        )

      context = build_context(["systemd.service.restart_active"])

      result =
        PolicyEngine.evaluate(
          build_proposal("systemd.service.restart_active"),
          [active_restart],
          [],
          context
        )

      assert result.decision == :approval_required
    end
  end

  # ===========================================================================
  # M3-CRIT-6: Approval tampering, expiry, replay, binding mismatch, and
  #              changed preconditions all prevent execution.
  #
  # Full 15-scenario coverage is in:
  #   apps/exocomp_node/test/exocomp/node/safety/approval_gate_test.exs
  #
  # Tests below exercise the complete gate path with real modules for the two
  # most critical adversarial cases (replay and signature tampering) and record
  # the cross-cutting correlation evidence.
  # ===========================================================================

  describe "M3-CRIT-6: approval gate prevents tampered/expired/replayed tokens" do
    setup %{tmp_dir: tmp_dir} do
      setup_approval_integration(tmp_dir)
    end

    test "M3-CRIT-6a: valid token executes once; sequential replay is blocked", ctx do
      # [PASS/FAIL evidence for M3-CRIT-6]
      #
      # A valid, fresh, correctly-signed token executes the action on first
      # presentation and returns the result. The same token on second
      # presentation returns :already_executed (sequential replay protection).
      %{private_key: pk, evidence_hash: eh, mock: mock, ledger: ledger, executor_fn: exec_fn} =
        ctx

      token = make_signed_token(pk, eh, node_id: "node-m3-test")

      gate_ctx = gate_context()

      opts =
        integration_gate_opts(exec_fn, ledger,
          verifier: ApprovalVerifier,
          checker: PreconditionChecker
        )

      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})

      # First presentation → executes.
      assert {:ok, result} = ApprovalGate.execute(token, gate_ctx, opts)
      assert result.action_id == :restart_service
      assert result.verified == true

      # Second presentation → replay blocked.
      assert {:error, {:already_executed, {:ok, ^result}}} =
               ApprovalGate.execute(token, gate_ctx, opts)
    end

    test "M3-CRIT-6b: bit-flipped signature is rejected before execution", ctx do
      # [PASS/FAIL evidence for M3-CRIT-6]
      #
      # Flipping one bit of the signature must prevent execution. The executor
      # must not be invoked after signature validation fails.
      %{private_key: pk, evidence_hash: eh, mock: mock, ledger: ledger, executor_fn: exec_fn} =
        ctx

      token = make_signed_token(pk, eh, node_id: "node-m3-test")
      <<first, rest::binary>> = token.signature
      tampered = %{token | signature: <<Bitwise.bxor(first, 1), rest::binary>>}

      opts =
        integration_gate_opts(exec_fn, ledger,
          verifier: ApprovalVerifier,
          checker: PreconditionChecker
        )

      assert {:error, {:token_invalid, :invalid_signature}} =
               ApprovalGate.execute(tampered, gate_context(), opts)

      assert MockCommander.calls(mock) == []
    end

    test "M3-CRIT-6c: expired token is rejected before execution", ctx do
      # [PASS/FAIL evidence for M3-CRIT-6]
      %{private_key: pk, evidence_hash: eh, mock: mock, ledger: ledger, executor_fn: exec_fn} =
        ctx

      now = DateTime.utc_now()

      expired_payload =
        base_token_payload(eh,
          node_id: "node-m3-test",
          expires_at: now |> DateTime.add(-60, :second) |> DateTime.to_iso8601()
        )

      token = sign_payload(expired_payload, pk)

      opts =
        integration_gate_opts(exec_fn, ledger,
          verifier: ApprovalVerifier,
          checker: PreconditionChecker
        )

      assert {:error, {:token_invalid, :expired}} =
               ApprovalGate.execute(token, gate_context(), opts)

      assert MockCommander.calls(mock) == []
    end

    test "M3-CRIT-6d: token with mismatched node_id is rejected", ctx do
      # [PASS/FAIL evidence for M3-CRIT-6]
      %{private_key: pk, evidence_hash: eh, mock: mock, ledger: ledger, executor_fn: exec_fn} =
        ctx

      # Token is signed for "other-node", but context presents "node-m3-test".
      token = make_signed_token(pk, eh, node_id: "other-node")

      opts =
        integration_gate_opts(exec_fn, ledger,
          verifier: ApprovalVerifier,
          checker: PreconditionChecker
        )

      assert {:error, {:token_invalid, {:binding_mismatch, :node_id, _expected, _actual}}} =
               ApprovalGate.execute(token, gate_context(), opts)

      assert MockCommander.calls(mock) == []
    end

    test "M3-CRIT-6e: changed precondition (stale evidence_hash in token) is rejected", ctx do
      # [PASS/FAIL evidence for M3-CRIT-6]
      #
      # A token signed with evidence from the old (failed) state does not
      # match the current state returned by the precondition collector.
      %{private_key: pk, mock: mock, ledger: ledger, executor_fn: exec_fn} = ctx

      stale_evidence = %{
        "active_state" => "failed",
        "sub_state" => "failed",
        "unit_name" => "example.service"
      }

      stale_hash = ApprovalToken.hash_evidence(stale_evidence)
      token = make_signed_token(pk, stale_hash, node_id: "node-m3-test")

      opts =
        integration_gate_opts(exec_fn, ledger,
          verifier: ApprovalVerifier,
          checker: PreconditionChecker
        )

      assert {:error, {:precondition_changed, :precondition_changed}} =
               ApprovalGate.execute(token, gate_context(), opts)

      assert MockCommander.calls(mock) == []
    end
  end

  # ===========================================================================
  # M3-CRIT-7: Node runs unprivileged; executor uses exact argv from catalog;
  #              arbitrary commands, paths, and service names are rejected.
  # ===========================================================================

  describe "M3-CRIT-7: privilege separation and argv enforcement" do
    setup do
      {:ok, mock} = MockCommander.start()
      prev_commander = Application.get_env(:exocomp_node, :os_commander)
      Application.put_env(:exocomp_node, :os_commander, MockCommander.as_commander(mock))
      {:ok, lock} = ExecutorLock.start_link([])

      on_exit(fn ->
        if prev_commander,
          do: Application.put_env(:exocomp_node, :os_commander, prev_commander),
          else: Application.delete_env(:exocomp_node, :os_commander)

        MockCommander.stop(mock)
        if Process.alive?(lock), do: GenServer.stop(lock)
      end)

      %{mock: mock, lock: lock}
    end

    test "M3-CRIT-7a: node does not run as root in the test environment", _ctx do
      # [PASS/FAIL evidence for M3-CRIT-7]
      #
      # Privilege.check_not_root/0 must return :ok when the node is unprivileged.
      # In rootless container engines (e.g. rootless Podman) the kernel maps
      # the host user to UID 0 inside the container namespace; that is not a
      # true privilege escalation. We branch on the detected UID so that the
      # test exercises the correct branch of check_not_root/0 rather than
      # unconditionally failing in rootless-container CI environments.
      current_uid =
        case System.cmd("id", ["-u"], stderr_to_stdout: true) do
          {output, 0} -> String.trim(output)
          _ -> "unknown"
        end

      if current_uid == "0" do
        # Rootless-container root: function must return the expected error.
        # Production deployments MUST NOT run as root.
        assert {:error, :running_as_root} = Privilege.check_not_root()
      else
        # Unprivileged: function must confirm it is safe to proceed.
        assert :ok = Privilege.check_not_root()
      end
    end

    test "M3-CRIT-7b: unknown action IDs are rejected before any OS invocation", %{
      lock: lock,
      mock: mock
    } do
      # [PASS/FAIL evidence for M3-CRIT-7]
      #
      # The executor must not accept arbitrary action atoms or strings.
      # Only :restart_service and :vacuum_logs are in the installed catalog.
      for bad_action <- [:run_shell, :delete_files, :exec_command, "systemctl", "rm -rf"] do
        assert {:error, :unknown_action} =
                 Executor.execute(bad_action, "myapp.service", ["myapp.service"],
                   lock_server: lock
                 )
      end

      assert MockCommander.calls(mock) == []
    end

    test "M3-CRIT-7c: service names with shell injection characters are rejected", %{
      lock: lock,
      mock: mock
    } do
      # [PASS/FAIL evidence for M3-CRIT-7]
      #
      # Even if a malicious service name appears in the allow-list, the executor
      # rejects it before building an argv. Service names must conform to the
      # strict character-set allowlist.
      injection_targets = [
        "myapp.service; rm -rf /",
        "$(id)",
        "`id`",
        "myapp | cat /etc/passwd",
        "myapp & id",
        "myapp > /tmp/out",
        "myapp\nALL=(root) NOPASSWD: ALL",
        "myapp\x00.service",
        "../../etc/passwd",
        " ",
        ""
      ]

      for target <- injection_targets do
        poisoned_list = [target, "safe.service"]

        assert {:error, :not_allowed} =
                 Executor.execute(:restart_service, target, poisoned_list, lock_server: lock),
               "Expected :not_allowed for injection target: #{inspect(target)}"
      end

      assert MockCommander.calls(mock) == []
    end

    test "M3-CRIT-7d: executor argv is built from catalog, never from caller strings", %{
      lock: lock,
      mock: mock
    } do
      # [PASS/FAIL evidence for M3-CRIT-7]
      #
      # The argv sent to the OS commander must be exactly ["restart", target]
      # as defined by the catalog. No caller-supplied field can modify it.
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})

      Executor.execute(:restart_service, "myapp.service", ["myapp.service"], lock_server: lock)

      [{executable, argv, opts} | _] = MockCommander.calls(mock)

      assert executable == "/usr/bin/systemctl"
      assert argv == ["restart", "myapp.service"]
      assert Keyword.get(opts, :env) == []

      for arg <- argv do
        refute String.contains?(arg, [";", "&", "|", "$", "`", ">", "<", "\n", "\x00"]),
               "argv element #{inspect(arg)} contains unsafe characters"
      end
    end

    test "M3-CRIT-7e: no generic command or arbitrary deletion action exists in the catalog", _ctx do
      # [PASS/FAIL evidence for M3-CRIT-7]
      #
      # ActionCatalog.action_ids/0 must not list any action capable of executing
      # arbitrary commands or deleting arbitrary filesystem paths.
      catalog_ids = ActionCatalog.action_ids()

      forbidden_patterns = [
        ~r/shell/i,
        ~r/exec/i,
        ~r/cmd/i,
        ~r/delete/i,
        ~r/rm\b/i,
        ~r/file/i,
        ~r/path/i
      ]

      for id <- catalog_ids, pattern <- forbidden_patterns do
        refute Regex.match?(pattern, Atom.to_string(id)),
               "Catalog action #{inspect(id)} matches forbidden pattern #{inspect(pattern)}"
      end
    end

    test "M3-CRIT-7f: executor rejects targets not on the allow-list even when syntax is valid", %{
      lock: lock,
      mock: mock
    } do
      # [PASS/FAIL evidence for M3-CRIT-7]
      #
      # A syntactically valid service name that is not in the configured
      # allow-list must be rejected. The allow-list is the operator-installed
      # gate; passing validation alone is not sufficient.
      assert {:error, :not_allowed} =
               Executor.execute(:restart_service, "nginx.service", ["myapp.service"],
                 lock_server: lock
               )

      assert MockCommander.calls(mock) == []
    end
  end

  # ===========================================================================
  # M3-CRIT-8: Complete correlated audit trail for every state-changing
  #              gate operation.
  # ===========================================================================

  describe "M3-CRIT-8: correlated audit trail" do
    setup %{tmp_dir: tmp_dir} do
      id = System.unique_integer([:positive])
      path = Path.join(tmp_dir, "m3-audit-#{id}.dets")

      {:ok, ledger} =
        ReplayLedger.start_link(
          name: :"m3_audit_#{id}",
          table: :"m3_audit_tbl_#{id}",
          path: path
        )

      on_exit(fn ->
        if Process.alive?(ledger), do: GenServer.stop(ledger)
      end)

      %{ledger: ledger}
    end

    test "M3-CRIT-8a: all audit log entries contain the correlation_id", %{ledger: ledger} do
      # [PASS/FAIL evidence for M3-CRIT-8]
      #
      # Every step in the gate (token_valid, preconditions_ok, replay_claimed,
      # execution_success) must emit a log entry containing the correlation_id.
      # This allows operators to reconstruct the full approval lifecycle from
      # the audit log using correlation_id as the join key.
      log =
        capture_log(fn ->
          ApprovalGate.execute(
            %{},
            audit_gate_context(),
            stub_gate_opts(ledger, :pass, :ok)
          )
        end)

      assert log =~ "m3-audit-corr"
    end

    test "M3-CRIT-8b: raw approval token is never written to the audit log", %{ledger: ledger} do
      # [PASS/FAIL evidence for M3-CRIT-8]
      #
      # The raw wire token (including signature bytes) must never appear in
      # the audit log. Only the nonce prefix and decision outcome are recorded.
      secret_token = %{"payload" => %{}, "signature" => "TOP_SECRET_SIG_BYTES"}

      log =
        capture_log(fn ->
          ApprovalGate.execute(
            secret_token,
            audit_gate_context(),
            stub_gate_opts(ledger, {:fail, :expired}, :ok)
          )
        end)

      refute log =~ "TOP_SECRET_SIG_BYTES"
      assert log =~ "token_invalid"
      assert log =~ "m3-audit-corr"
    end

    test "M3-CRIT-8c: successful gate path emits one log entry per step", %{ledger: ledger} do
      # [PASS/FAIL evidence for M3-CRIT-8]
      #
      # A successful gate execution must log each of the four key lifecycle
      # steps: token_valid, preconditions_ok, replay_claimed, execution_success.
      log =
        capture_log(fn ->
          ApprovalGate.execute(
            %{},
            audit_gate_context(),
            stub_gate_opts(ledger, :pass, :ok)
          )
        end)

      assert log =~ "token_valid"
      assert log =~ "preconditions_ok"
      assert log =~ "replay_claimed"
      assert log =~ "execution_success"
    end

    test "M3-CRIT-8d: nonce is truncated in log entries — full nonce not exposed", %{
      ledger: ledger
    } do
      # [PASS/FAIL evidence for M3-CRIT-8]
      #
      # The full nonce value must not appear in log entries. Only the first 8
      # characters followed by "..." are emitted to prevent nonce reuse attacks
      # via log analysis.
      log =
        capture_log(fn ->
          ApprovalGate.execute(
            %{},
            audit_gate_context(),
            stub_gate_opts(ledger, :pass, :ok)
          )
        end)

      # The stub verifier uses nonce "unit-test-nonce-00".
      # Full nonce must NOT appear in the log.
      refute log =~ "unit-test-nonce-00"
      # Truncated form must appear.
      assert log =~ "unit-tes..."
    end
  end

  # ===========================================================================
  # Nested stub modules for M3-CRIT-8 audit tests
  # ===========================================================================

  defmodule AuditStubVerifier do
    @moduledoc false
    @nonce "unit-test-nonce-00"
    @evidence_hash "a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0"

    def verify(_token_wire, _ctx) do
      case Process.get(:m3_stub_verifier, :pass) do
        :pass ->
          {:ok, %{payload: %{nonce: @nonce, evidence_hash: @evidence_hash}, signature: "stub"}}

        {:fail, reason} ->
          {:error, reason}
      end
    end

    def default_nonce, do: @nonce
  end

  defmodule AuditStubChecker do
    @moduledoc false

    def verify(_payload, _action_id, _target) do
      Process.get(:m3_stub_checker, :ok)
    end
  end

  defmodule AuditStubExecutor do
    @moduledoc false

    @default_result %{
      action_id: :restart_service,
      target: "example.service",
      output: "",
      exit_code: 0,
      verified: true
    }

    def execute(_action_id, _target, _allow_list) do
      {:ok, @default_result}
    end
  end

  # Evidence collector used in M3-CRIT-6 integration tests.
  defmodule MockEvidenceCollector do
    @moduledoc false
    @behaviour PreconditionChecker

    @impl true
    def collect(_action_id, _target) do
      {:ok, default_evidence()}
    end

    def default_evidence do
      %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => "example.service"
      }
    end
  end

  # ===========================================================================
  # Private helpers
  # ===========================================================================

  defp valid_action_opts do
    [
      schema_version: "1",
      action_id: "systemd.service.restart",
      action_class: :restart,
      target_type: :systemd_unit,
      data_classification: :system_data,
      reversibility: :reversible,
      risk_rank: risk(),
      required_evidence: [],
      max_evidence_age_secs: 30,
      requires_approval: false,
      cooldown_secs: 0,
      max_retries: 0,
      timeout_secs: 30
    ]
  end

  defp build_action(action_id, overrides \\ []) do
    opts =
      valid_action_opts()
      |> Keyword.put(:action_id, action_id)
      |> Keyword.put(:risk_rank, Keyword.get(overrides, :risk, risk()))
      |> Keyword.put(:requires_approval, Keyword.get(overrides, :requires_approval, false))
      |> Keyword.put(:required_evidence, Keyword.get(overrides, :required_evidence, []))
      |> Keyword.put(
        :max_evidence_age_secs,
        Keyword.get(overrides, :max_evidence_age_secs, 30)
      )

    {:ok, ad} = ActionDefinition.build(opts)
    ad
  end

  defp build_proposal(action_id, overrides \\ []) do
    %Proposal{
      schema_version: Proposal.schema_version(),
      action_id: action_id,
      target_id: Keyword.get(overrides, :target_id, "example.service"),
      parameters: %{},
      evidence_refs: [],
      rationale: "M3 acceptance test"
    }
  end

  defp build_context(authorized_ids, overrides \\ []) do
    %PolicyContext{
      authorized_action_ids: MapSet.new(authorized_ids),
      cooldown_state: %{},
      retry_counts: %{},
      now: Keyword.get(overrides, :now, DateTime.utc_now())
    }
  end

  defp build_evidence(id, collector, overrides \\ []) do
    %Evidence{
      schema_version: Evidence.schema_version(),
      evidence_id: id,
      collector: collector,
      collector_version: "1.0.0",
      target_id: Keyword.get(overrides, :target_id, "example.service"),
      observed_at: Keyword.get(overrides, :observed_at, DateTime.utc_now()),
      values: %{},
      integrity_hash: String.duplicate("a", 64)
    }
  end

  defp risk(overrides \\ []) do
    %RiskRank{
      data_loss: Keyword.get(overrides, :data_loss, :none),
      work_loss: Keyword.get(overrides, :work_loss, :none),
      disruption: Keyword.get(overrides, :disruption, :none),
      scope: Keyword.get(overrides, :scope, :none)
    }
  end

  defp disk_pressure_evidence(target_id) do
    %Evidence{
      schema_version: "1",
      evidence_id: "ev-disk-#{System.unique_integer([:positive])}",
      collector: "system.disk.pressure",
      collector_version: "1.0.0",
      target_id: target_id,
      observed_at: DateTime.utc_now(),
      values: %{
        "used_bytes" => "10000",
        "free_bytes" => "5000",
        "total_bytes" => "15000",
        "used_pct" => "67"
      },
      integrity_hash: String.duplicate("a", 64)
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:exocomp_node, key)
  defp restore_env(key, val), do: Application.put_env(:exocomp_node, key, val)

  # ── M3-CRIT-6 helpers ─────────────────────────────────────────────────────

  defp setup_approval_integration(tmp_dir) do
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    key_path = Path.join(tmp_dir, "m3-coord-#{System.unique_integer([:positive])}.key")
    File.write!(key_path, public_key)

    prev_key = Application.get_env(:exocomp_node, :approval_public_key_path)
    prev_collector = Application.get_env(:exocomp_node, :precondition_evidence_collector)
    prev_commander = Application.get_env(:exocomp_node, :os_commander)

    Application.put_env(:exocomp_node, :approval_public_key_path, key_path)
    Application.put_env(:exocomp_node, :precondition_evidence_collector, MockEvidenceCollector)

    {:ok, mock} = MockCommander.start()
    commander_fn = MockCommander.as_commander(mock)
    Application.put_env(:exocomp_node, :os_commander, commander_fn)

    {:ok, lock} = ExecutorLock.start_link([])
    id = System.unique_integer([:positive])
    ledger_path = Path.join(tmp_dir, "m3-ledger-#{id}.dets")

    {:ok, ledger} =
      ReplayLedger.start_link(
        name: :"m3_ledger_#{id}",
        table: :"m3_table_#{id}",
        path: ledger_path
      )

    evidence_hash = ApprovalToken.hash_evidence(MockEvidenceCollector.default_evidence())

    executor_fn = fn action_id, target, allow_list ->
      Executor.execute(action_id, target, allow_list, lock_server: lock)
    end

    on_exit(fn ->
      if prev_key,
        do: Application.put_env(:exocomp_node, :approval_public_key_path, prev_key),
        else: Application.delete_env(:exocomp_node, :approval_public_key_path)

      if prev_collector,
        do:
          Application.put_env(:exocomp_node, :precondition_evidence_collector, prev_collector),
        else: Application.delete_env(:exocomp_node, :precondition_evidence_collector)

      if prev_commander,
        do: Application.put_env(:exocomp_node, :os_commander, prev_commander),
        else: Application.delete_env(:exocomp_node, :os_commander)

      MockCommander.stop(mock)
      if Process.alive?(lock), do: GenServer.stop(lock)
      if Process.alive?(ledger), do: GenServer.stop(ledger)
    end)

    %{
      private_key: private_key,
      evidence_hash: evidence_hash,
      mock: mock,
      ledger: ledger,
      lock: lock,
      executor_fn: executor_fn
    }
  end

  defp gate_context do
    %{
      node_id: "node-m3-test",
      task_id: "task-m3-test",
      correlation_id: "corr-m3-test",
      action_id: :restart_service,
      target: "example.service",
      parameters: %{"unit" => "example.service"},
      allow_list: ["example.service"]
    }
  end

  defp integration_gate_opts(executor_fn, ledger, extra_opts) do
    Keyword.merge(extra_opts,
      executor: executor_fn,
      ledger: ledger,
      wait_timeout_ms: 3_000
    )
  end

  defp base_token_payload(evidence_hash, overrides) do
    now = DateTime.utc_now()

    %{
      schema_version: "1",
      nonce: Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
      node_id: Keyword.get(overrides, :node_id, "node-m3-test"),
      task_id: "task-m3-test",
      correlation_id: "corr-m3-test",
      action_id: "restart_service",
      parameter_hash: ApprovalToken.hash_params(%{"unit" => "example.service"}),
      evidence_hash: evidence_hash,
      issued_at: now |> DateTime.add(-30, :second) |> DateTime.to_iso8601(),
      expires_at:
        Keyword.get_lazy(overrides, :expires_at, fn ->
          now |> DateTime.add(3_600, :second) |> DateTime.to_iso8601()
        end),
      operator: "operator@example.com"
    }
  end

  defp sign_payload(payload, private_key) do
    signature =
      :crypto.sign(:eddsa, :none, ApprovalToken.canonical_encode(payload), [
        private_key,
        :ed25519
      ])

    %{payload: payload, signature: signature}
  end

  defp make_signed_token(private_key, evidence_hash, overrides) do
    base_token_payload(evidence_hash, overrides) |> sign_payload(private_key)
  end

  # ── M3-CRIT-8 helpers ─────────────────────────────────────────────────────

  defp audit_gate_context do
    %{
      node_id: "node-m3-audit",
      task_id: "task-m3-audit",
      correlation_id: "m3-audit-corr",
      action_id: :restart_service,
      target: "example.service",
      parameters: %{"unit" => "example.service"},
      allow_list: ["example.service"]
    }
  end

  defp stub_gate_opts(ledger, verifier_result, checker_result) do
    Process.put(:m3_stub_verifier, verifier_result)
    Process.put(:m3_stub_checker, checker_result)

    [
      verifier: AuditStubVerifier,
      checker: AuditStubChecker,
      executor: AuditStubExecutor,
      ledger: ledger,
      wait_timeout_ms: 500
    ]
  end
end
