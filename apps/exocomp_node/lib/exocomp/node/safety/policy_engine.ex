defmodule Exocomp.Node.Safety.PolicyEngine do
  @moduledoc """
  First-stage policy engine: eligibility filter pipeline.

  `PolicyEngine` applies an ordered sequence of fail-closed checks to a
  `Proposal`, returning the eligible `ActionDefinition` from the supplied
  catalog along with an auditable deny reason for any rejection.

  ## Pipeline order

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

  ## Evidence target scoping

  Evidence is scoped to `proposal.target_id`. Evidence collected for a
  different target is treated as absent for the purpose of the missing-evidence
  and staleness checks. This prevents evidence from one resource being accepted
  as proof about a different resource.

  ## Fail-closed behaviour

  Any `nil`, structurally invalid, or otherwise unexpected input causes the
  candidate to be **denied**, never silently permitted.
  """

  alias Exocomp.Node.Safety.{ActionDefinition, Evidence, PolicyContext, Proposal}

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
end
