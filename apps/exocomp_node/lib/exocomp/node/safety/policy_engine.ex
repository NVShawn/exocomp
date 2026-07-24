defmodule Exocomp.Node.Safety.PolicyEngine do
  @moduledoc """
  Policy engine: eligibility filter pipeline and risk-ordered candidate selection.

  `PolicyEngine` provides two public entry points:

  - `filter/4` — first-stage eligibility filter for a single proposal action.
  - `evaluate/4` — second-stage selection: evaluates all catalog candidates,
    sorts eligible ones by risk rank (lowest first), and returns an auditable
    `ValidatorResult`.

  ## filter/4 pipeline order

  Checks are applied in the order below. The first failing check produces the
  deny reason; subsequent checks are not evaluated.

  1. **Unauthorized** — action ID not in `PolicyContext.authorized_action_ids`
  2. **Inapplicable** — action ID not in the supplied catalog
  3. **Unsafe data classification** — `:deletion` action on `:protected_user_data`
  4. **Missing evidence** — required collector has no matching `Evidence` record
     *for the proposal's `target_id`*
  5. **Stale evidence** — evidence `observed_at` too old relative to `context.now`
  6. **Cooldown** — last execution was too recent
  7. **Retry exhausted** — consecutive failure count at or above the configured max

  ## evaluate/4 selection

  `evaluate/4` runs `filter/4` independently for each candidate in the catalog,
  then:

  1. Collects eligible and rejected candidates.
  2. If no candidates are eligible, returns `ValidatorResult.deny/1` with an
     auditable summary of all rejection reasons.
  3. Sorts eligible candidates by `RiskRank.compare/2` (data_loss → work_loss
     → disruption → scope), with alphabetical `action_id` as tiebreaker.
  4. Selects the lowest-risk candidate and maps it to a `ValidatorResult`:
     - `requires_approval: false` → `:allow`
     - `requires_approval: true` → `:approval_required`

  ## Evidence scoping

  Evidence is scoped to `proposal.target_id` **and** to the candidate's
  `required_evidence` collectors during per-candidate evaluation. This prevents
  unrelated stale evidence from rejecting an otherwise-eligible candidate and
  prevents evidence from one resource being accepted as proof about a different
  resource.

  ## Fail-closed behaviour

  Any `nil`, structurally invalid, or otherwise unexpected input causes the
  result to be **denied**, never silently permitted. Any exception inside the
  filter or selection logic is caught and returned as
  `ValidatorResult.deny("internal policy error")`.
  """

  alias Exocomp.Node.Safety.{
    ActionDefinition,
    Evidence,
    PolicyContext,
    Proposal,
    RiskRank,
    ValidatorResult
  }

  defmodule FilterResult do
    @moduledoc """
    Output of `PolicyEngine.filter/4`.

    `eligible` contains `ActionDefinition` structs that passed all checks.
    `rejected` contains `{ActionDefinition.t() | nil, String.t()}` tuples for
    every candidate that failed at least one check.

    When a proposal's `action_id` has no matching catalog entry, the rejection
    is represented as `{nil, deny_reason}` because there is no `ActionDefinition`
    to return.
    """

    @type deny_reason :: String.t()

    @type t :: %__MODULE__{
            eligible: [ActionDefinition.t()],
            rejected: [{ActionDefinition.t() | nil, deny_reason}]
          }

    defstruct eligible: [], rejected: []
  end

  @doc """
  Runs the eligibility filter pipeline for a single `proposal`.

  ## Parameters

  - `proposal` — a `%Proposal{}` from the LLM inference client (untrusted).
  - `catalog` — list of trusted `%ActionDefinition{}` structs available on
    this node.
  - `evidence` — list of `%Evidence{}` structs collected for this evaluation
    round. Only evidence whose `target_id` matches `proposal.target_id` is
    considered for presence and staleness checks.
  - `context` — `%PolicyContext{}` holding operator allow-list and runtime
    state.

  ## Returns

  `%FilterResult{}` with `eligible` and `rejected` fields populated.

  Any structurally invalid argument causes all candidates to be denied
  (fail-closed). A `nil` proposal, context, evidence list, or catalog is
  treated as an immediate deny.
  """
  @spec filter(
          Proposal.t() | nil,
          [ActionDefinition.t()],
          [Evidence.t()],
          PolicyContext.t() | nil
        ) :: FilterResult.t()
  def filter(%Proposal{} = proposal, catalog, evidence, %PolicyContext{} = context)
      when is_list(catalog) and is_list(evidence) do
    case validate_context(context) do
      {:error, reason} ->
        %FilterResult{eligible: [], rejected: build_rejected(catalog, reason)}

      :ok ->
        run_pipeline(proposal, catalog, evidence, context)
    end
  end

  def filter(nil, catalog, _evidence, _context) when is_list(catalog) do
    %FilterResult{
      eligible: [],
      rejected: build_rejected(catalog, "invalid proposal: nil")
    }
  end

  def filter(_proposal, _catalog, _evidence, _context) do
    %FilterResult{eligible: [], rejected: [{nil, "invalid filter arguments"}]}
  end

  # ── evaluate/4: risk-ordered candidate selection ──────────────────────────

  @doc """
  Evaluates all catalog candidates against the proposal and evidence, returning
  the lowest-risk eligible action as a `ValidatorResult`.

  ## Parameters

  - `proposal` — a `%Proposal{}` from the LLM inference client (untrusted).
  - `catalog` — list of trusted `%ActionDefinition{}` structs available on
    this node, or `nil` (treated as unavailable policy → deny).
  - `evidence` — one or more `%Evidence{}` structs. A single struct is
    normalised to a one-element list. `nil` is treated as invalid → deny.
  - `context` — `%PolicyContext{}` holding operator allow-list and runtime
    state.

  ## Returns

  `ValidatorResult.t()` with fields populated:
  - `decision` — `:allow`, `:approval_required`, or `:deny`
  - `action_id` — the selected action's ID, or `nil` on deny
  - `reason` — auditable human-readable string with ordered candidate list
  - `evidence_refs` — IDs of evidence that satisfied required collectors for
    the selected action

  ## Fail-closed

  Any `nil`, unexpected, or structurally invalid input returns
  `ValidatorResult.deny/1`. Any exception inside the filter or selection logic
  is caught and returned as `ValidatorResult.deny("internal policy error")`.
  """
  @spec evaluate(
          Proposal.t() | nil,
          [ActionDefinition.t()] | nil,
          Evidence.t() | [Evidence.t()] | nil,
          PolicyContext.t() | nil
        ) :: ValidatorResult.t()

  # Normalize a single Evidence struct to a list and recurse.
  def evaluate(proposal, catalog, %Evidence{} = ev, context) do
    evaluate(proposal, catalog, [ev], context)
  end

  # Main implementation: valid proposal, list catalog, list evidence, valid context.
  def evaluate(%Proposal{} = proposal, catalog, evidence, %PolicyContext{} = context)
      when is_list(catalog) and is_list(evidence) do
    try do
      do_evaluate(proposal, catalog, evidence, context)
    rescue
      _ -> ValidatorResult.deny("internal policy error")
    catch
      _, _ -> ValidatorResult.deny("internal policy error")
    end
  end

  # Catchall: nil/unexpected inputs → fail closed.
  def evaluate(_proposal, _catalog, _evidence, _context) do
    ValidatorResult.deny("policy unavailable or invalid inputs")
  end

  # ── pipeline ──────────────────────────────────────────────────────────────

  defp run_pipeline(
         %Proposal{action_id: action_id, target_id: target_id} = _proposal,
         catalog,
         evidence,
         context
       ) do
    catalog_map = Map.new(catalog, fn %ActionDefinition{action_id: id} = ad -> {id, ad} end)

    # Evidence is scoped to the proposal's target — evidence for other targets
    # is treated as absent (never cross-accepted as proof of a different resource).
    scoped_evidence = Enum.filter(evidence, fn %Evidence{target_id: tid} -> tid == target_id end)

    # Steps 1–2 run before we resolve an ActionDefinition.
    with :ok <- step_authorized(action_id, context.authorized_action_ids),
         {:ok, definition} <- step_catalog(action_id, catalog_map),
         # Steps 3–7 run with the resolved ActionDefinition in scope.
         :ok <- step_data_classification(definition),
         :ok <- step_missing_evidence(definition, scoped_evidence),
         :ok <- step_stale_evidence(definition, scoped_evidence, context.now),
         :ok <- step_cooldown(action_id, target_id, definition.cooldown_secs, context, definition),
         :ok <-
           step_retry_exhausted(
             action_id,
             target_id,
             definition.max_retries,
             context,
             definition
           ) do
      %FilterResult{eligible: [definition], rejected: []}
    else
      {:deny, nil, reason} ->
        %FilterResult{eligible: [], rejected: [{nil, reason}]}

      {:deny, definition, reason} ->
        %FilterResult{eligible: [], rejected: [{definition, reason}]}
    end
  end

  # ── step 1: authorization ─────────────────────────────────────────────────

  defp step_authorized(_action_id, nil),
    do: {:deny, nil, "action not authorized"}

  defp step_authorized(action_id, %MapSet{} = authorized) do
    if MapSet.member?(authorized, action_id),
      do: :ok,
      else: {:deny, nil, "action not authorized"}
  end

  defp step_authorized(_action_id, _invalid),
    do: {:deny, nil, "action not authorized"}

  # ── step 2: catalog lookup ────────────────────────────────────────────────

  defp step_catalog(action_id, catalog_map) do
    case Map.fetch(catalog_map, action_id) do
      {:ok, definition} -> {:ok, definition}
      :error -> {:deny, nil, "action not in catalog"}
    end
  end

  # ── step 3: unsafe data classification ───────────────────────────────────

  defp step_data_classification(
         %ActionDefinition{
           action_class: :deletion,
           data_classification: :protected_user_data
         } = definition
       ) do
    {:deny, definition, "user data deletion ineligible"}
  end

  defp step_data_classification(%ActionDefinition{}), do: :ok

  # ── step 4: missing required evidence ────────────────────────────────────

  defp step_missing_evidence(
         %ActionDefinition{required_evidence: required} = definition,
         scoped_evidence
       ) do
    collector_set = MapSet.new(scoped_evidence, fn %Evidence{collector: c} -> c end)

    case Enum.find(required, &(not MapSet.member?(collector_set, &1))) do
      nil -> :ok
      missing -> {:deny, definition, "missing required evidence: #{missing}"}
    end
  end

  # ── step 5: stale evidence ────────────────────────────────────────────────

  defp step_stale_evidence(
         %ActionDefinition{max_evidence_age_secs: max_age} = definition,
         scoped_evidence,
         %DateTime{} = now
       )
       when is_integer(max_age) and max_age > 0 do
    stale =
      Enum.find(scoped_evidence, fn
        %Evidence{observed_at: %DateTime{} = observed_at} ->
          DateTime.diff(now, observed_at, :second) > max_age

        # Unparseable observed_at — treat as stale (fail closed)
        %Evidence{} ->
          true
      end)

    case stale do
      nil -> :ok
      %Evidence{evidence_id: eid} -> {:deny, definition, "stale evidence: #{eid}"}
    end
  end

  # If now is not a DateTime or max_age is not a valid positive integer,
  # we cannot evaluate staleness — skip this check.
  defp step_stale_evidence(_definition, _evidence, _now), do: :ok

  # ── step 6: cooldown ──────────────────────────────────────────────────────

  defp step_cooldown(_action_id, _target_id, 0, _context, _definition), do: :ok

  defp step_cooldown(
         action_id,
         target_id,
         cooldown_secs,
         %PolicyContext{cooldown_state: cooldown_state, now: %DateTime{} = now},
         definition
       )
       when is_integer(cooldown_secs) and cooldown_secs > 0 do
    case Map.get(cooldown_state, {action_id, target_id}) do
      %DateTime{} = last_at ->
        elapsed = DateTime.diff(now, last_at, :second)

        if elapsed < cooldown_secs,
          do: {:deny, definition, "action on cooldown"},
          else: :ok

      _ ->
        :ok
    end
  end

  defp step_cooldown(_action_id, _target_id, _cooldown_secs, _context, _definition), do: :ok

  # ── step 7: retry exhausted ───────────────────────────────────────────────

  defp step_retry_exhausted(_action_id, _target_id, 0, _context, _definition), do: :ok

  defp step_retry_exhausted(
         action_id,
         target_id,
         max_retries,
         %PolicyContext{retry_counts: retry_counts},
         definition
       )
       when is_integer(max_retries) and max_retries > 0 do
    count = Map.get(retry_counts, {action_id, target_id}, 0)

    if count >= max_retries,
      do: {:deny, definition, "retry limit exhausted"},
      else: :ok
  end

  defp step_retry_exhausted(_action_id, _target_id, _max_retries, _context, _definition),
    do: :ok

  # ── context validation ────────────────────────────────────────────────────

  defp validate_context(%PolicyContext{
         authorized_action_ids: ids,
         cooldown_state: cooldown,
         retry_counts: retries,
         now: now
       }) do
    cond do
      not is_struct(ids, MapSet) ->
        {:error, "invalid context: authorized_action_ids is not a MapSet"}

      not is_map(cooldown) ->
        {:error, "invalid context: cooldown_state is not a map"}

      not is_map(retries) ->
        {:error, "invalid context: retry_counts is not a map"}

      not is_struct(now, DateTime) ->
        {:error, "invalid context: now is not a DateTime"}

      true ->
        :ok
    end
  end

  # ── helpers ───────────────────────────────────────────────────────────────

  defp build_rejected([], reason), do: [{nil, reason}]
  defp build_rejected(catalog, reason), do: Enum.map(catalog, &{&1, reason})

  # ── evaluate/4 private helpers ─────────────────────────────────────────────

  # Core evaluate logic (called from the try block in evaluate/4).
  defp do_evaluate(%Proposal{target_id: target_id} = proposal, catalog, evidence, context) do
    # Evaluate each catalog candidate independently.
    # Accumulate eligible definitions and tagged rejection tuples.
    {eligible_rev, rejected} =
      Enum.reduce(catalog, {[], []}, fn candidate, {elig, rej} ->
        # Scope evidence to this candidate's required collectors AND the target.
        # This prevents unrelated stale evidence from penalising eligible candidates.
        candidate_evidence = scope_evidence_for_candidate(candidate, evidence, target_id)

        # Create a per-candidate proposal so the authorization check uses the
        # candidate's action_id, not the original proposal's action_id.
        candidate_proposal = %Proposal{proposal | action_id: candidate.action_id}

        case filter(candidate_proposal, [candidate], candidate_evidence, context) do
          %FilterResult{eligible: [definition]} ->
            {[definition | elig], rej}

          %FilterResult{eligible: [], rejected: rejections} ->
            # Replace {nil, reason} rejections with {candidate, reason} so the
            # candidate's action_id is available for the audit reason string.
            tagged =
              Enum.map(rejections, fn
                {nil, reason} -> {candidate, reason}
                other -> other
              end)

            {elig, rej ++ tagged}
        end
      end)

    # eligible_rev is in reverse order due to prepend — reverse to restore catalog order
    # before sorting (this does not affect correctness but aids determinism).
    eligible = Enum.reverse(eligible_rev)

    case eligible do
      [] ->
        # All candidates were filtered — build auditable deny reason.
        ValidatorResult.deny(build_deny_reason(rejected))

      _ ->
        # Sort eligible candidates by risk rank (lowest first), then alphabetically.
        sorted = sort_candidates(eligible)
        selected = hd(sorted)

        # Collect evidence IDs that satisfied the selected action's required collectors.
        refs = collect_evidence_refs(selected, evidence, target_id)

        # Build auditable allow/approval reason.
        reason = build_allow_reason(selected, sorted, rejected)

        if selected.requires_approval do
          ValidatorResult.approval_required(selected.action_id, reason, refs)
        else
          ValidatorResult.allow(selected.action_id, reason, refs)
        end
    end
  end

  # Filters evidence to only the records relevant to a specific candidate:
  # - target_id must match the proposal's target
  # - collector must be in the candidate's required_evidence list
  defp scope_evidence_for_candidate(candidate, evidence, target_id) do
    required = MapSet.new(candidate.required_evidence)

    Enum.filter(evidence, fn
      %Evidence{collector: c, target_id: tid} ->
        tid == target_id and MapSet.member?(required, c)

      _ ->
        false
    end)
  end

  # Sorts candidates by RiskRank (lowest first), with alphabetical action_id
  # as a deterministic tiebreaker.
  defp sort_candidates(candidates) do
    Enum.sort(candidates, fn a, b ->
      case RiskRank.compare(a.risk_rank, b.risk_rank) do
        :lt -> true
        :gt -> false
        :eq -> a.action_id <= b.action_id
      end
    end)
  end

  # Collects evidence IDs for evidence records whose collector satisfies a
  # required_evidence entry for the selected action and whose target matches.
  defp collect_evidence_refs(selected, evidence, target_id) do
    required = MapSet.new(selected.required_evidence)

    evidence
    |> Enum.filter(fn
      %Evidence{collector: c, target_id: tid} ->
        tid == target_id and MapSet.member?(required, c)

      _ ->
        false
    end)
    |> Enum.map(fn %Evidence{evidence_id: id} -> id end)
  end

  # Builds an auditable deny reason listing all rejected candidates in order.
  defp build_deny_reason(rejected) do
    if rejected == [] do
      "no eligible actions; catalog is empty"
    else
      items =
        Enum.map(rejected, fn
          {nil, reason} ->
            "unknown: #{reason}"

          {%ActionDefinition{action_id: id}, reason} ->
            "#{id}: #{reason}"
        end)

      "no eligible actions; rejections: #{Enum.join(items, "; ")}"
    end
  end

  # Builds an auditable allow/approval-required reason string that includes:
  # - the selected candidate and its risk rank
  # - the full ordered list of eligible candidates with risk ranks
  # - a summary of rejected candidates and their reasons
  defp build_allow_reason(selected, sorted_eligible, rejected) do
    eligible_parts =
      Enum.map(sorted_eligible, fn candidate ->
        "#{candidate.action_id} (risk: #{inspect(candidate.risk_rank)})"
      end)

    parts = [
      "selected #{selected.action_id} (risk: #{inspect(selected.risk_rank)})",
      "eligible by risk order: #{Enum.join(eligible_parts, ", ")}"
    ]

    parts =
      if rejected != [] do
        rejection_parts =
          Enum.map(rejected, fn
            {nil, reason} -> "unknown: #{reason}"
            {%ActionDefinition{action_id: id}, reason} -> "#{id} rejected: #{reason}"
          end)

        parts ++ ["rejected: #{Enum.join(rejection_parts, "; ")}"]
      else
        parts
      end

    Enum.join(parts, "; ")
  end
end
