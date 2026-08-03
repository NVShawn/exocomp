# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuditEvents do
  @moduledoc """
  Insert-only, organization-scoped persistence for Mission Control audit events.

  This is the only normal application write boundary for audit records. Every
  payload is redacted before a changeset is built, and every read includes an
  explicit organization predicate. Mutation functions fail closed; the
  database independently rejects direct updates and deletes.
  """

  import Ecto.Query

  alias Ecto.Multi

  alias Exocomp.MissionControl.{
    AuditEvent,
    OrganizationScope,
    Redaction,
    Repo
  }

  @doc "Persists one redacted audit event under exactly one organization."
  @spec record(term(), map() | keyword(), keyword()) ::
          {:ok, AuditEvent.t()} | {:error, Ecto.Changeset.t()}
  def record(organization_id, attrs, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    organization_id
    |> insert_changeset(attrs)
    |> repo.insert()
  end

  @doc "Adds a redacted audit insert to an existing transaction."
  @spec put_in_multi(Multi.t(), term(), term(), map() | keyword()) :: Multi.t()
  def put_in_multi(%Multi{} = multi, name, organization_id, attrs) do
    Multi.insert(multi, name, insert_changeset(organization_id, attrs))
  end

  @doc "Builds the insert changeset without writing, for transactional composition."
  @spec insert_changeset(term(), map() | keyword()) :: Ecto.Changeset.t()
  def insert_changeset(organization_id, attrs) when is_list(attrs) do
    insert_changeset(organization_id, Map.new(attrs))
  end

  def insert_changeset(organization_id, attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Redaction.redact()
      |> put_default(:correlation_id, AuditEvent.generate_correlation_id())
      |> put_default(:occurred_at, DateTime.utc_now())

    %AuditEvent{}
    |> AuditEvent.changeset(attrs)
    |> OrganizationScope.put(organization_id)
  end

  @doc "Fetches an event only when it belongs to the supplied organization."
  @spec get(term(), String.t(), keyword()) ::
          AuditEvent.t() | nil | {:error, :organization_required}
  def get(organization_id, event_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, organization_id} <- OrganizationScope.require_id(organization_id) do
      AuditEvent
      |> OrganizationScope.query(organization_id)
      |> where([event], event.event_id == ^event_id)
      |> repo.one()
    end
  end

  @doc "Lists one organization's events in stable chronological order."
  @spec list(term(), keyword()) ::
          [AuditEvent.t()] | {:error, :organization_required}
  def list(organization_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, organization_id} <- OrganizationScope.require_id(organization_id) do
      AuditEvent
      |> OrganizationScope.query(organization_id)
      |> chronological()
      |> repo.all()
    end
  end

  @doc "Lists one organization's events for a correlation ID in stable order."
  @spec by_correlation(term(), String.t(), keyword()) ::
          [AuditEvent.t()] | {:error, :organization_required}
  def by_correlation(organization_id, correlation_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, organization_id} <- OrganizationScope.require_id(organization_id) do
      AuditEvent
      |> OrganizationScope.query(organization_id)
      |> where([event], event.correlation_id == ^correlation_id)
      |> chronological()
      |> repo.all()
    end
  end

  @doc "Audit events are immutable through the normal context."
  @spec update(term(), term(), map(), keyword()) :: {:error, :immutable}
  def update(_organization_id, _event_id, _attrs, _opts \\ []), do: {:error, :immutable}

  @doc "Audit events are immutable through the normal context."
  @spec delete(term(), term(), keyword()) :: {:error, :immutable}
  def delete(_organization_id, _event_id, _opts \\ []), do: {:error, :immutable}

  defp chronological(query) do
    order_by(query, [event],
      asc: event.occurred_at,
      asc: event.inserted_at,
      asc: event.event_id
    )
  end

  defp put_default(attrs, key, value) do
    string_key = Atom.to_string(key)

    cond do
      Map.has_key?(attrs, key) -> attrs
      Map.has_key?(attrs, string_key) -> attrs
      true -> Map.put(attrs, key, value)
    end
  end
end
