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
  Ecto schema records only `inserted_at` (there is no `updated_at`), and the
  repository context enforces read-only access for normal application flows.
  A database trigger independently rejects direct updates and deletes.

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

  # Persist through the redacting, organization-scoped context
  {:ok, stored_event} = AuditEvents.record(org_id, Map.from_struct(event))
  ```
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Exocomp.MissionControl.{Organization, Redaction}

  @primary_key {:event_id, :string, autogenerate: false}
  @foreign_key_type :binary_id

  schema "audit_events" do
    belongs_to(:organization, Organization)
    field(:cluster_id, Ecto.UUID)
    field(:actor_type, Ecto.Enum, values: [:operator, :system, :cluster])
    field(:actor_sub, :string)
    field(:actor_display_name, :string)
    field(:event_type, :string)
    field(:target, :map)
    field(:outcome, Ecto.Enum, values: [:ok, :error])
    field(:outcome_details, :map)
    field(:correlation_id, :string)
    field(:occurred_at, :utc_datetime_usec)

    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

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

  @cast_fields [
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
    :occurred_at
  ]

  @doc "Builds the insert-only database changeset used by the audit context."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event, attrs) when is_map(attrs) do
    event
    |> ensure_generated_fields()
    |> cast(attrs, @cast_fields)
    |> validate_required([
      :event_id,
      :organization_id,
      :actor_type,
      :event_type,
      :target,
      :outcome,
      :correlation_id,
      :occurred_at
    ])
    |> validate_length(:event_id, max: 64)
    |> validate_length(:correlation_id, max: 128)
    |> validate_length(:event_type, min: 1, max: 200)
    |> validate_length(:actor_sub, max: 500)
    |> validate_length(:actor_display_name, max: 500)
    |> validate_actor_identity()
    |> foreign_key_constraint(:organization_id)
    |> unique_constraint(:event_id, name: :audit_events_pkey)
    |> check_constraint(:actor_type, name: :audit_events_actor_type_check)
    |> check_constraint(:outcome, name: :audit_events_outcome_check)
    |> check_constraint(:actor_sub, name: :audit_events_actor_identity_check)
    |> check_constraint(:cluster_id, name: :audit_events_cluster_identity_check)
  end

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

  defp ensure_generated_fields(%__MODULE__{} = event) do
    %{
      event
      | event_id: event.event_id || generate_event_id(),
        correlation_id: event.correlation_id || generate_correlation_id(),
        occurred_at: event.occurred_at || DateTime.utc_now()
    }
  end

  defp validate_actor_identity(changeset) do
    actor_type = get_field(changeset, :actor_type)
    actor_sub = get_field(changeset, :actor_sub)
    actor_display_name = get_field(changeset, :actor_display_name)
    cluster_id = get_field(changeset, :cluster_id)

    changeset
    |> require_operator_subject(actor_type, actor_sub)
    |> reject_non_operator_identity(actor_type, actor_sub, actor_display_name)
    |> require_cluster_identity(actor_type, cluster_id)
  end

  defp require_operator_subject(changeset, :operator, actor_sub)
       when actor_sub in [nil, ""],
       do: add_error(changeset, :actor_sub, "is required for operator audit events")

  defp require_operator_subject(changeset, _actor_type, _actor_sub), do: changeset

  defp reject_non_operator_identity(changeset, actor_type, actor_sub, actor_display_name)
       when actor_type in [:system, :cluster] do
    changeset
    |> reject_present(:actor_sub, actor_sub, "is only valid for operator audit events")
    |> reject_present(
      :actor_display_name,
      actor_display_name,
      "is only valid for operator audit events"
    )
  end

  defp reject_non_operator_identity(changeset, _actor_type, _actor_sub, _actor_display_name),
    do: changeset

  defp require_cluster_identity(changeset, :cluster, cluster_id) when cluster_id in [nil, ""],
    do: add_error(changeset, :cluster_id, "is required for cluster audit events")

  defp require_cluster_identity(changeset, _actor_type, _cluster_id), do: changeset

  defp reject_present(changeset, _field, value, _message) when value in [nil, ""],
    do: changeset

  defp reject_present(changeset, field, _value, message), do: add_error(changeset, field, message)

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
  to strings. The result is redacted and JSON-safe, so webhook serialization
  cannot bypass the same redaction boundary used by audit persistence.
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
    |> Redaction.redact()
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
