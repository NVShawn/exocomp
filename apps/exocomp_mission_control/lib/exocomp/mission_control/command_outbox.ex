# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CommandOutbox do
  @moduledoc """
  Durable server-to-cluster command persistence and delivery boundary.

  The database is authoritative for every command transition. PubSub only
  wakes the replica currently holding a WebSocket; it never records delivery.
  Consequently a restart, missed notification, socket loss, or duplicate
  acknowledgement leaves an unambiguous durable state.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Exocomp.MissionControl.{Command, Repo}

  @default_ttl_seconds 300

  @type enqueue_attrs :: %{optional(atom() | String.t()) => term()}

  @doc "Returns the supported protocol command kinds."
  @spec valid_kinds() :: [String.t()]
  def valid_kinds, do: Command.valid_kinds()

  @doc "A stable PubSub topic for one organization/cluster pair."
  @spec topic(String.t(), String.t()) :: String.t()
  def topic(organization_id, cluster_id) do
    encoded = Base.url_encode64(organization_id <> <<0>> <> cluster_id, padding: false)
    "mission-control:command-outbox:" <> encoded
  end

  @doc "Persists a validated command under the authenticated organization and cluster."
  @spec enqueue(String.t(), String.t(), enqueue_attrs(), keyword()) ::
          {:ok, Command.t()} | {:error, Ecto.Changeset.t() | term()}
  def enqueue(organization_id, cluster_id, attrs, opts \\ [])
      when is_map(attrs) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, changeset} <- insert_changeset(organization_id, cluster_id, attrs, opts),
         {:ok, command} <- repo.insert(changeset) do
      _ = notify(command.organization_id, command.cluster_id, opts)
      {:ok, command}
    end
  end

  @doc "Compatibility form for trusted callers that already supply the scope."
  @spec enqueue(enqueue_attrs(), keyword()) ::
          {:ok, Command.t()} | {:error, Ecto.Changeset.t() | term()}
  def enqueue(attrs, opts \\ [])

  def enqueue(attrs, opts) when is_map(attrs) do
    with {:ok, organization_id} <- required_value(attrs, :organization_id),
         {:ok, cluster_id} <- required_value(attrs, :cluster_id) do
      enqueue(organization_id, cluster_id, attrs, opts)
    end
  end

  @doc "Builds the validated insert changeset without writing it."
  @spec insert_changeset(String.t(), String.t(), enqueue_attrs(), keyword()) ::
          {:ok, Ecto.Changeset.t()} | {:error, term()}
  def insert_changeset(organization_id, cluster_id, attrs, opts \\ []) when is_map(attrs) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with :ok <- validate_scope(organization_id, :organization_id),
         :ok <- validate_scope(cluster_id, :cluster_id),
         {:ok, normalized} <- normalize_attrs(organization_id, cluster_id, attrs, now),
         :ok <- validate_kind(normalized.kind) do
      {:ok, Command.changeset(%Command{}, normalized)}
    end
  end

  @doc "Adds command insertion to an existing transaction without publishing it early."
  @spec put_in_multi(Multi.t(), term(), String.t(), String.t(), enqueue_attrs(), keyword()) ::
          Multi.t()
  def put_in_multi(%Multi{} = multi, name, organization_id, cluster_id, attrs, opts \\ []) do
    case insert_changeset(organization_id, cluster_id, attrs, opts) do
      {:ok, changeset} -> Multi.insert(multi, name, changeset)
      {:error, reason} -> Multi.error(multi, name, reason)
    end
  end

  @doc "Lists pending, unexpired commands in deterministic delivery order."
  @spec pending(String.t(), String.t(), keyword()) :: [Command.t()]
  def pending(organization_id, cluster_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)
    now = Keyword.get(opts, :now, DateTime.utc_now())
    _ = expire(Keyword.merge(opts, organization_id: organization_id, cluster_id: cluster_id))

    from(command in Command,
      where:
        command.organization_id == ^organization_id and
          command.cluster_id == ^cluster_id and
          command.status == "pending" and command.expires_at > ^now,
      order_by: [asc: command.issued_at, asc: command.command_id]
    )
    |> repo.all()
  end

  @doc """
  Sends all pending commands through an active session.

  A successful sender result deliberately does not update the command row. The
  cluster acknowledgement is the only transition to `acknowledged`.
  """
  @spec deliver_pending(String.t(), String.t(), map() | nil, function(), keyword()) ::
          {:ok, %{sent: non_neg_integer(), failed: [{String.t(), term()}]}} | {:error, :offline}
  def deliver_pending(_organization_id, _cluster_id, nil, _sender, _opts), do: {:error, :offline}

  def deliver_pending(organization_id, cluster_id, session, sender, opts)
      when is_map(session) and is_function(sender) do
    {sent, failed} =
      Enum.reduce(pending(organization_id, cluster_id, opts), {0, []}, fn command,
                                                                          {sent, failed} ->
        case call_sender(sender, command, session) do
          :ok -> {sent + 1, failed}
          {:ok, _value} -> {sent + 1, failed}
          other -> {sent, [{command.command_id, other} | failed]}
        end
      end)

    {:ok, %{sent: sent, failed: Enum.reverse(failed)}}
  end

  def deliver_pending(_organization_id, _cluster_id, _session, _sender, _opts),
    do: {:error, :offline}

  @doc "Acknowledges one command only when it belongs to the authenticated cluster."
  @spec acknowledge(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, :acknowledged | :already_acknowledged} | {:error, :expired | :not_found | term()}
  def acknowledge(organization_id, cluster_id, command_id, opts \\ [])
      when is_binary(organization_id) and is_binary(cluster_id) and is_binary(command_id) do
    repo = Keyword.get(opts, :repo, Repo)
    now = Keyword.get(opts, :now, DateTime.utc_now())

    query =
      from(command in Command,
        where:
          command.command_id == ^command_id and
            command.organization_id == ^organization_id and
            command.cluster_id == ^cluster_id and
            command.status == "pending" and command.expires_at > ^now,
        update: [set: [status: "acknowledged", acknowledged_at: ^now, updated_at: ^now]]
      )

    case repo.update_all(query, []) do
      {1, _} -> {:ok, :acknowledged}
      {0, _} -> acknowledgement_result(repo, organization_id, cluster_id, command_id, now)
    end
  rescue
    error -> {:error, {:acknowledgement_failed, Exception.message(error)}}
  end

  @doc "Expires pending commands without treating them as acknowledged or executed."
  @spec expire(keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def expire(opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)
    now = Keyword.get(opts, :now, DateTime.utc_now())

    query =
      from(command in Command,
        where: command.status == "pending" and command.expires_at <= ^now,
        update: [set: [status: "expired", updated_at: ^now]]
      )
      |> maybe_scope(:organization_id, Keyword.get(opts, :organization_id))
      |> maybe_scope(:cluster_id, Keyword.get(opts, :cluster_id))
      |> maybe_scope(:command_id, Keyword.get(opts, :command_id))

    case repo.update_all(query, []) do
      {count, _} -> {:ok, count}
    end
  rescue
    error -> {:error, {:expiry_failed, Exception.message(error)}}
  end

  @doc "Returns the stored state for one organization-scoped command."
  @spec status(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, :not_found}
  def status(organization_id, cluster_id, command_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    from(command in Command,
      where:
        command.command_id == ^command_id and command.organization_id == ^organization_id and
          command.cluster_id == ^cluster_id,
      select: command.status
    )
    |> repo.one()
    |> case do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @doc "Notifies the connected replica after a command is committed."
  @spec notify(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def notify(organization_id, cluster_id, opts \\ []) do
    case Keyword.get(opts, :notifier) do
      notifier when is_function(notifier, 2) ->
        notifier.(organization_id, cluster_id)

      notifier when is_function(notifier, 1) ->
        notifier.({organization_id, cluster_id})

      nil ->
        Phoenix.PubSub.broadcast(
          Keyword.get(opts, :pubsub, Exocomp.MissionControl.PubSub),
          topic(organization_id, cluster_id),
          {:command_outbox, :deliver}
        )
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp normalize_attrs(organization_id, cluster_id, attrs, now) do
    issued_at = value(attrs, :issued_at) || now
    expires_at = value(attrs, :expires_at) || default_expiry(issued_at)

    normalized = %{
      command_id: value(attrs, :command_id) || Ecto.UUID.generate(),
      kind: value(attrs, :kind),
      issued_at: issued_at,
      expires_at: expires_at,
      organization_id: organization_id,
      cluster_id: cluster_id,
      payload: value(attrs, :payload),
      status: "pending"
    }

    cond do
      not is_binary(normalized.command_id) or normalized.command_id == "" ->
        {:error, :invalid_command_id}

      not is_binary(normalized.kind) ->
        {:error, :invalid_command_kind}

      not match?(%DateTime{}, normalized.issued_at) ->
        {:error, :invalid_issued_at}

      not match?(%DateTime{}, normalized.expires_at) ->
        {:error, :invalid_expires_at}

      DateTime.compare(normalized.expires_at, normalized.issued_at) != :gt ->
        {:error, :invalid_expiry}

      not is_map(normalized.payload) ->
        {:error, :invalid_payload}

      true ->
        {:ok, normalized}
    end
  end

  defp default_expiry(%DateTime{} = issued_at),
    do: DateTime.add(issued_at, @default_ttl_seconds, :second)

  defp default_expiry(_issued_at), do: nil

  defp validate_scope(value, _field) when is_binary(value) and byte_size(value) in 1..128 do
    if value == String.trim(value), do: :ok, else: {:error, :invalid_scope}
  end

  defp validate_scope(_value, field), do: {:error, {:invalid_scope, field}}

  defp validate_kind(kind) do
    if kind in Command.valid_kinds(), do: :ok, else: {:error, {:invalid_command_kind, kind}}
  end

  defp required_value(attrs, key) do
    case value(attrs, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _other -> {:error, {:missing_scope, key}}
    end
  end

  defp acknowledgement_result(repo, organization_id, cluster_id, command_id, now) do
    case status(organization_id, cluster_id, command_id, repo: repo) do
      {:ok, "acknowledged"} ->
        {:ok, :already_acknowledged}

      {:ok, "expired"} ->
        {:error, :expired}

      {:ok, "pending"} ->
        case expire(
               repo: repo,
               now: now,
               organization_id: organization_id,
               cluster_id: cluster_id,
               command_id: command_id
             ) do
          {:ok, _count} -> {:error, :expired}
          {:error, reason} -> {:error, reason}
        end

      {:ok, status} ->
        {:error, {:not_acknowledgeable, status}}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defp maybe_scope(query, _field, nil), do: query

  defp maybe_scope(query, field, value),
    do: where(query, [command], field(command, ^field) == ^value)

  defp value(attrs, key), do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

  defp call_sender(sender, command, session) do
    try do
      case :erlang.fun_info(sender, :arity) do
        {:arity, 1} -> sender.(command)
        {:arity, 2} -> sender.(command, session)
      end
    rescue
      error -> {:error, {:sender_failed, Exception.message(error)}}
    end
  end
end
