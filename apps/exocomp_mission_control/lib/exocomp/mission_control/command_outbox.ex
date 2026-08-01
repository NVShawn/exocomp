# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CommandOutbox do
  @moduledoc """
  Persistence and delivery boundary for server-to-cluster commands.

  Enqueue, acknowledgement, and expiry are database state transitions.  The
  delivery operation only reads pending rows and calls the active session's
  sender; it never marks a row as acknowledged.  This separation is what
  keeps a lost socket, a process restart, or a duplicate acknowledgement from
  turning an unexecuted command into a completed one.
  """

  import Ecto.Query

  alias Exocomp.MissionControl.{Command, Repo, SessionRegistry}

  @default_ttl 300
  @max_payload_bytes 65_536

  @command_kinds ~w(
    conversation.message
    conversation.request
    proposal.approve
    proposal.deny
    approval.execute
  )

  @type enqueue_attrs :: %{optional(atom() | String.t()) => term()}

  @spec valid_kinds() :: [String.t()]
  def valid_kinds, do: @command_kinds

  @spec enqueue(enqueue_attrs(), keyword()) :: {:ok, Command.t()} | {:error, term()}
  def enqueue(attrs, opts \\ []) when is_map(attrs) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, normalized} <- normalize_attrs(attrs, now),
         :ok <- validate_kind(normalized.kind, opts),
         :ok <- validate_payload_size(normalized.payload),
         {:ok, command} <- repo.insert(Command.changeset(%Command{}, normalized)) do
      {:ok, command}
    end
  end

  @doc "Enqueues a command with the tenant and cluster identity supplied by the session."
  def enqueue(organization_id, cluster_id, attrs, opts \\ [])
      when is_binary(organization_id) and is_binary(cluster_id) and is_map(attrs) do
    enqueue(Map.merge(attrs, %{organization_id: organization_id, cluster_id: cluster_id}), opts)
  end

  @spec pending(String.t(), String.t(), keyword()) :: [Command.t()]
  def pending(organization_id, cluster_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)
    now = Keyword.get(opts, :now, DateTime.utc_now())
    _ = expire(opts)

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
  Sends all currently pending commands through an active session.

  `sender` may be a one-argument function, a two-argument function receiving
  the session metadata, or a pid (which receives
  `{:mission_control_command, command}`).  A successful send does not
  acknowledge the row; the coordinator must call `acknowledge/2` separately.
  """
  @spec deliver_pending(String.t(), String.t(), map(), (Command.t() -> term()), keyword()) ::
          {:ok, %{sent: non_neg_integer(), failed: [term()]}} | {:error, :offline}
  def deliver_pending(organization_id, cluster_id, session, sender, opts \\ [])

  def deliver_pending(organization_id, cluster_id, session, sender, opts)
      when is_map(session) and is_function(sender) do
    commands = pending(organization_id, cluster_id, opts)

    {sent, failed} =
      Enum.reduce(commands, {0, []}, fn command, {sent, failed} ->
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

  @doc "Drains pending commands through the locally registered active session."
  @spec deliver_registered(String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, :offline}
  def deliver_registered(organization_id, cluster_id, opts \\ []) do
    registry = Keyword.get(opts, :registry, SessionRegistry)

    with {:ok, %{session_id: session_id, target: target}} <-
           lookup_owner(registry, organization_id, cluster_id),
         sender <- sender_for(target) do
      deliver_pending(organization_id, cluster_id, %{session_id: session_id}, sender, opts)
    end
  end

  @spec acknowledge(String.t(), keyword()) ::
          {:ok, :acknowledged | :already_acknowledged} | {:error, term()}
  def acknowledge(command_id, opts \\ []) when is_binary(command_id) do
    repo = Keyword.get(opts, :repo, Repo)
    now = Keyword.get(opts, :now, DateTime.utc_now())
    organization_id = Keyword.get(opts, :organization_id)
    cluster_id = Keyword.get(opts, :cluster_id)

    query =
      from(command in Command,
        where:
          command.command_id == ^command_id and command.status == "pending" and
            command.expires_at > ^now,
        update: [set: [status: "acknowledged", acknowledged_at: ^now, updated_at: ^now]]
      )

    query = maybe_scope(query, :organization_id, organization_id)
    query = maybe_scope(query, :cluster_id, cluster_id)

    case repo.update_all(query, []) do
      {1, _} -> {:ok, :acknowledged}
      {0, _} -> acknowledgement_result(repo, command_id, organization_id, cluster_id, now)
    end
  rescue
    error in Ecto.Query.CastError ->
      {:error, {:invalid_acknowledgement, Exception.message(error)}}
  end

  @doc "Acknowledges a command while explicitly scoping it to its authenticated session."
  def acknowledge(command_id, organization_id, cluster_id, opts \\ [])
      when is_binary(command_id) and is_binary(organization_id) and is_binary(cluster_id) do
    acknowledge(
      command_id,
      Keyword.merge(opts, organization_id: organization_id, cluster_id: cluster_id)
    )
  end

  @doc "Short alias for acknowledgement frame handlers."
  def ack(command_id, opts \\ []), do: acknowledge(command_id, opts)

  @doc "Alias used by transport handlers receiving an acknowledgement frame."
  def acknowledge_command(command_id, opts \\ []), do: acknowledge(command_id, opts)

  @spec expire(keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def expire(opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)
    now = Keyword.get(opts, :now, DateTime.utc_now())
    organization_id = Keyword.get(opts, :organization_id)
    cluster_id = Keyword.get(opts, :cluster_id)

    query =
      from(command in Command,
        where: command.status == "pending" and command.expires_at <= ^now,
        update: [set: [status: "expired", updated_at: ^now]]
      )

    query = maybe_scope(query, :organization_id, organization_id)
    query = maybe_scope(query, :cluster_id, cluster_id)

    case repo.update_all(query, []) do
      {count, _} -> {:ok, count}
    end
  rescue
    error -> {:error, {:expiry_failed, error}}
  end

  @doc "Returns the current terminal state without changing it."
  @spec status(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def status(command_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)
    organization_id = Keyword.get(opts, :organization_id)
    cluster_id = Keyword.get(opts, :cluster_id)

    query = from(command in Command, where: command.command_id == ^command_id)
    query = maybe_scope(query, :organization_id, organization_id)
    query = maybe_scope(query, :cluster_id, cluster_id)

    case repo.one(query) do
      nil -> {:error, :not_found}
      command -> {:ok, command.status}
    end
  end

  defp normalize_attrs(attrs, now) do
    command_id = value(attrs, :command_id) || Ecto.UUID.generate()
    kind = attrs |> value(:kind) |> normalize_string()
    organization_id = value(attrs, :organization_id) || value(attrs, :organization)
    cluster_id = value(attrs, :cluster_id) || value(attrs, :cluster)
    issued_at = value(attrs, :issued_at) || now
    expires_at = value(attrs, :expires_at)
    payload = value(attrs, :payload)

    expires_at =
      if match?(%DateTime{}, issued_at) do
        expires_at || DateTime.add(issued_at, @default_ttl, :second)
      else
        expires_at
      end

    normalized = %{
      command_id: command_id,
      kind: kind,
      issued_at: issued_at,
      expires_at: expires_at,
      organization_id: organization_id,
      cluster_id: cluster_id,
      payload: payload,
      status: "pending"
    }

    cond do
      not is_binary(command_id) or command_id == "" -> {:error, :invalid_command_id}
      not match?(%DateTime{}, issued_at) -> {:error, :invalid_issued_at}
      not match?(%DateTime{}, expires_at) -> {:error, :invalid_expires_at}
      DateTime.compare(expires_at, issued_at) != :gt -> {:error, :invalid_expiry}
      true -> {:ok, normalized}
    end
  end

  defp validate_kind(kind, opts) when is_binary(kind) do
    allowed = Keyword.get(opts, :valid_kinds, @command_kinds)

    if kind in allowed do
      :ok
    else
      {:error, {:invalid_command_kind, kind}}
    end
  end

  defp validate_kind(_kind, _opts), do: {:error, :invalid_command_kind}

  defp validate_payload_size(payload) when is_map(payload) do
    with {:ok, encoded} <- Jason.encode(payload),
         true <- byte_size(encoded) <= @max_payload_bytes do
      :ok
    else
      false -> {:error, :payload_too_large}
      {:error, _reason} -> {:error, :invalid_payload}
    end
  end

  defp validate_payload_size(_payload), do: {:error, :invalid_payload}

  defp acknowledgement_result(repo, command_id, organization_id, cluster_id, now) do
    case status(command_id,
           repo: repo,
           organization_id: organization_id,
           cluster_id: cluster_id
         ) do
      {:ok, "acknowledged"} ->
        {:ok, :already_acknowledged}

      {:ok, "expired"} ->
        {:error, :expired}

      {:ok, "pending"} ->
        case expire(
               repo: repo,
               now: now,
               organization_id: organization_id,
               cluster_id: cluster_id
             ) do
          {:ok, _count} -> {:error, :expired}
          {:error, reason} -> {:error, reason}
        end

      {:ok, other} ->
        {:error, {:not_acknowledgeable, other}}

      {:error, :not_found} ->
        {:error, :not_found}

      other ->
        other
    end
  end

  defp maybe_scope(query, _field, nil), do: query

  defp maybe_scope(query, field, value),
    do: where(query, [command], field(command, ^field) == ^value)

  defp lookup_owner(registry, organization_id, cluster_id) do
    if is_atom(registry) and is_pid(Process.whereis(registry)) do
      SessionRegistry.owner(organization_id, cluster_id, registry)
    else
      registry.owner(organization_id, cluster_id)
    end
  end

  defp value(attrs, key), do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

  defp normalize_string(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_string(value), do: value

  defp call_sender(sender, command, session) do
    case :erlang.fun_info(sender, :arity) do
      {:arity, 1} -> sender.(command)
      {:arity, 2} -> sender.(command, session)
    end
  end

  defp sender_for(target) when is_pid(target),
    do: fn command -> send(target, {:mission_control_command, command}) end

  defp sender_for(target) when is_function(target), do: target
end
