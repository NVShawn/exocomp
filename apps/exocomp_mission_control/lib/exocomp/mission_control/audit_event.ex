# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuditEvent do
  @moduledoc """
  Immutable audit event recording for Mission Control operations.

  Every mutation in Mission Control—including operator actions (approvals,
  denials, assignments, resolutions), cluster events (connections,
  disconnections, status changes), commands (issued, acknowledged, expired),
  proposals (created, executed), decisions (approved, denied), and
  administrative changes (enrollment, revocation)—is recorded as an
  immutable AuditEvent.

  Events are organization-scoped and immutable by design. They may never be
  updated or deleted through normal application contexts; this immutability
  is enforced at the database level via schema constraints and application
  policy.

  ## Fields

  - `:event_id` — a unique identifier for this event, suitable for deduplication
    across delivery retries and for webhook event IDs.
  - `:organization_id` — the organization under which this event occurred.
    Required; enforces multi-tenant isolation at the schema level.
  - `:cluster_id` — the cluster affected by this event. Optional; some events
    (e.g., administrative changes or system events) may not be cluster-specific.
  - `:actor_type` — the type of entity that performed or triggered this event.
    One of `:operator` (human decision), `:system` (automatic action or cluster
    event), or `:cluster` (cluster-initiated). The actor_type determines which
    other actor fields are populated.
  - `:actor_sub` — the stable OIDC subject ID of an operator (only when
    `actor_type` is `:operator`). Null for other actor types.
  - `:actor_display_name` — the human-readable name or email of an operator
    at the time of the event (only when `actor_type` is `:operator`). Stored
    for readability; null if OIDC token did not include a display name.
  - `:event_type` — a categorized string describing what kind of change or event
    occurred. Examples: `"cluster.connected"`, `"alert.opened"`, `"approval.granted"`,
    `"enrollment.created"`, `"command.issued"`. Event types are used for filtering,
    retention windows, and webhook routing.
  - `:target` — a description of what was affected. Typically a compact JSON
    object (stored as a map) identifying the resource, its type, and identity.
    Examples: `%{"type" => "incident", "id" => "..."}`,
    `%{"type" => "proposal", "id" => "...", "node_id" => "..."}`.
  - `:outcome` — the result of the action: `:ok` or `:error`. Used for
    filtering audit trails by success/failure.
  - `:outcome_details` — an optional map with additional context about the
    outcome. For successful actions, may include counts, duration, or created
    resource IDs. For errors, may include error reason and context.
  - `:correlation_id` — a stable identifier linking this event to other events
    from the same logical operation (e.g., an approval decision, a
    conversation thread, a cluster connection session). Callers typically
    provide a correlation ID; if not supplied, one is generated. Correlation
    IDs use the format `"corr_" <> Base.url_encode64(random_bytes, padding: false)`.
  - `:occurred_at` — the UTC timestamp when this event occurred, as a DateTime.
  - `:inserted_at` — the timestamp when this record was persisted to the
    database (handled by the repository).

  ## Immutability

  AuditEvent records are inserted exactly once and are never modified. The
  Ecto schema includes `timestamps: false` with manual `inserted_at` handling
  (no `updated_at`), and the repository context enforces read-only access
  for normal application flows. Audit records can only be deleted by
  time-bounded retention jobs that operate on partitioned tables.

  ## Actor Types

  - `:operator` — a human operator authenticated via OIDC. Fields `actor_sub`
    and `actor_display_name` identify the operator.
  - `:system` — an automatic action initiated by Mission Control logic (e.g.,
    auto-resolve after health recovery, command expiry). No actor sub; other
    actor fields are nil.
  - `:cluster` — a cluster-initiated event (e.g., alert, status change, message).
    No actor sub; cluster_id identifies the source.

  ## Usage

  ```elixir
  # Operator action: approval
  event = AuditEvent.new(
    organization_id: org_id,
    cluster_id: cluster_id,
    actor_type: :operator,
    actor_sub: operator.sub,
    actor_display_name: operator.display_name,
    event_type: "approval.granted",
    target: %{"type" => "proposal", "id" => proposal_id},
    outcome: :ok,
    correlation_id: request_correlation_id
  )

  # Cluster event: alert opened
  event = AuditEvent.new(
    organization_id: org_id,
    cluster_id: cluster_id,
    actor_type: :cluster,
    event_type: "alert.opened",
    target: %{"type" => "alert", "id" => alert_id, "severity" => "critical"},
    outcome: :ok,
    correlation_id: cluster_event_correlation_id
  )

  # System action: auto-resolve
  event = AuditEvent.new(
    organization_id: org_id,
    cluster_id: cluster_id,
    actor_type: :system,
    event_type: "incident.auto_resolved",
    target: %{"type" => "incident", "id" => incident_id},
    outcome: :ok,
    correlation_id: incident_correlation_id
  )

  # Insert via repo
  {:ok, stored_event} = Repo.insert(event)
  ```
  """

  @type actor_type :: :operator | :system | :cluster

  @type outcome_result :: :ok | :error

  @type t :: %__MODULE__{
          event_id: String.t(),
          organization_id: String.t(),
          cluster_id: String.t() | nil,
          actor_type: actor_type(),
          actor_sub: String.t() | nil,
          actor_display_name: String.t() | nil,
          event_type: String.t(),
          target: map(),
          outcome: outcome_result(),
          outcome_details: map() | nil,
          correlation_id: String.t(),
          occurred_at: DateTime.t(),
          inserted_at: DateTime.t() | nil
        }

  defstruct [
    :event_id,
    :organization_id,
    :cluster_id,
    :actor_type,
    :actor_sub,
    :actor_display_name,
    :event_type,
    :target,
    :outcome,
    :outcome_details,
    :correlation_id,
    :occurred_at,
    :inserted_at
  ]

  @doc """
  Creates a new audit event.

  Requires at minimum:
  - `organization_id` — the organization scoping this event
  - `actor_type` — the type of actor (`:operator`, `:system`, or `:cluster`)
  - `event_type` — the kind of event
  - `target` — what was affected (as a map)
  - `outcome` — `:ok` or `:error`

  Optional fields default as follows:
  - `cluster_id` — nil
  - `actor_sub` — nil (should only be populated if actor_type is :operator)
  - `actor_display_name` — nil
  - `outcome_details` — nil
  - `correlation_id` — generated if not supplied
  - `occurred_at` — current UTC time

  An `event_id` is always generated using `:crypto.strong_rand_bytes/1` and
  formatted as url-safe base64 with the prefix `"evt_"`.

  Raises `ArgumentError` if required fields are missing or if actor_type
  constraints are violated (e.g., `actor_sub` provided but `actor_type` is
  not `:operator`).
  """
  @spec new(Keyword.t()) :: t()
  def new(opts) when is_list(opts) do
    organization_id = Keyword.fetch!(opts, :organization_id)
    actor_type = Keyword.fetch!(opts, :actor_type)
    event_type = Keyword.fetch!(opts, :event_type)
    target = Keyword.fetch!(opts, :target)
    outcome = Keyword.fetch!(opts, :outcome)

    # Validate actor_type
    unless actor_type in [:operator, :system, :cluster] do
      raise ArgumentError,
            "actor_type must be one of :operator, :system, :cluster; got #{inspect(actor_type)}"
    end

    # Validate outcome
    unless outcome in [:ok, :error] do
      raise ArgumentError, "outcome must be :ok or :error; got #{inspect(outcome)}"
    end

    cluster_id = Keyword.get(opts, :cluster_id)
    actor_sub = Keyword.get(opts, :actor_sub)
    actor_display_name = Keyword.get(opts, :actor_display_name)
    outcome_details = Keyword.get(opts, :outcome_details)
    correlation_id = Keyword.get(opts, :correlation_id) || generate_correlation_id()
    occurred_at = Keyword.get(opts, :occurred_at, DateTime.utc_now())

    # Enforce actor_type invariants
    if actor_type != :operator and not is_nil(actor_sub) do
      raise ArgumentError,
            "actor_sub should only be set when actor_type is :operator; got #{inspect(actor_type)}"
    end

    if actor_type != :operator and not is_nil(actor_display_name) do
      raise ArgumentError,
            "actor_display_name should only be set when actor_type is :operator; got #{inspect(actor_type)}"
    end

    %__MODULE__{
      event_id: generate_event_id(),
      organization_id: organization_id,
      cluster_id: cluster_id,
      actor_type: actor_type,
      actor_sub: actor_sub,
      actor_display_name: actor_display_name,
      event_type: event_type,
      target: target,
      outcome: outcome,
      outcome_details: outcome_details,
      correlation_id: correlation_id,
      occurred_at: occurred_at,
      inserted_at: nil
    }
  end

  @doc """
  Generates a unique event ID.

  Format: `"evt_"` followed by URL-safe base64 encoding of 16 random bytes.
  Example: `"evt_7vBKfMNg2JQpXw3hTL5cAQ"`.
  """
  @spec generate_event_id() :: String.t()
  def generate_event_id do
    "evt_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end

  @doc """
  Generates a unique correlation ID.

  Format: `"corr_"` followed by URL-safe base64 encoding of 16 random bytes.
  Example: `"corr_7vBKfMNg2JQpXw3hTL5cAQ"`.

  Correlation IDs link related events across different operations and
  transactions. Callers should typically use a single correlation ID for
  all events arising from one logical operation (e.g., an approval flow).
  """
  @spec generate_correlation_id() :: String.t()
  def generate_correlation_id do
    "corr_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end

  @doc """
  Returns this audit event as a plain map suitable for JSON serialization.

  All DateTime values are converted to ISO8601 strings. Atoms are converted
  to strings. The result is JSON-safe.

  Note: caller is responsible for calling `Redaction.redact/1` before
  serialization if sensitive fields may be present in target or outcome_details.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = event) do
    %{
      "event_id" => event.event_id,
      "organization_id" => event.organization_id,
      "cluster_id" => event.cluster_id,
      "actor_type" => to_string(event.actor_type),
      "actor_sub" => event.actor_sub,
      "actor_display_name" => event.actor_display_name,
      "event_type" => event.event_type,
      "target" => json_safe(event.target),
      "outcome" => to_string(event.outcome),
      "outcome_details" => json_safe(event.outcome_details),
      "correlation_id" => event.correlation_id,
      "occurred_at" => DateTime.to_iso8601(event.occurred_at),
      "inserted_at" =>
        if(is_nil(event.inserted_at), do: nil, else: DateTime.to_iso8601(event.inserted_at))
    }
  end

  # Private helpers

  defp json_safe(nil), do: nil
  defp json_safe(%_{} = struct), do: struct |> Map.from_struct() |> json_safe()

  defp json_safe(map) when is_map(map),
    do: Map.new(map, fn {k, v} -> {to_string(k), json_safe(v)} end)

  defp json_safe(list) when is_list(list), do: Enum.map(list, &json_safe/1)
  defp json_safe(atom) when is_atom(atom), do: to_string(atom)
  defp json_safe(val) when is_binary(val) or is_number(val), do: val
  defp json_safe(val), do: inspect(val)
end
