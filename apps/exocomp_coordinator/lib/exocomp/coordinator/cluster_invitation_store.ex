# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterInvitationStore do
  @moduledoc """
  Durable store for organization-scoped cluster invitations.

  The GenServer serializes create and consume operations. Consumption checks
  expiry and the consumed marker, writes the new marker, and only then
  replies, so concurrent callers cannot both consume an invitation. The
  optional file store is written through a staged rename and contains no
  invitation plaintext.
  """

  use GenServer

  alias Exocomp.Coordinator.{Audit, Cluster, ClusterInvitation, Error}

  @default_lifetime 600
  @min_lifetime 1
  @token_prefix "cinv_"
  @token_bytes 32
  @id_bytes 16

  @type option ::
          {:name, GenServer.name()}
          | {:store_path, Path.t() | nil}
          | {:now_fn, (-> integer())}
          | {:rand_fn, (pos_integer() -> binary())}
          | {:audit_server, GenServer.server() | nil}
          | {:max_lifetime, pos_integer()}

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Creates an invitation and returns its plaintext exactly once."
  @spec create(map(), keyword()) ::
          {:ok, ClusterInvitation.t(), String.t()} | {:error, Error.t()}
  def create(attrs, opts \\ []) when is_map(attrs) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:create, attrs})
  end

  @doc "Convenience form of `create/2` for an organization and cluster name."
  @spec issue(String.t(), String.t(), map(), keyword()) ::
          {:ok, ClusterInvitation.t(), String.t()} | {:error, Error.t()}
  def issue(organization_id, cluster_name), do: issue(organization_id, cluster_name, %{}, [])

  def issue(organization_id, cluster_name, opts) when is_list(opts) do
    labels = Keyword.get(opts, :labels, %{})
    issue(organization_id, cluster_name, labels, opts)
  end

  def issue(organization_id, cluster_name, labels) when is_map(labels) do
    issue(organization_id, cluster_name, labels, [])
  end

  def issue(organization_id, cluster_name, labels, opts) when is_map(labels) do
    create(
      %{organization_id: organization_id, name: cluster_name, labels: labels},
      opts
    )
  end

  @doc "Consumes an invitation for the expected organization."
  @spec consume(String.t(), String.t(), keyword()) ::
          {:ok, ClusterInvitation.t()} | {:error, Error.t()}
  def consume(token, organization_id, opts \\ [])
      when is_binary(token) and is_binary(organization_id) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:consume, token, organization_id})
  end

  @doc "Alias used by enrollment callers."
  @spec consume_invitation(String.t(), String.t(), keyword()) ::
          {:ok, ClusterInvitation.t()} | {:error, Error.t()}
  def consume_invitation(token, organization_id, opts \\ []),
    do: consume(token, organization_id, opts)

  @doc "Alias for callers that name the issuance operation explicitly."
  @spec create_invitation(map(), keyword()) ::
          {:ok, ClusterInvitation.t(), String.t()} | {:error, Error.t()}
  def create_invitation(attrs, opts \\ []), do: create(attrs, opts)

  @doc "Fetches an invitation by its public ID within an organization."
  @spec get(String.t(), String.t(), keyword()) ::
          {:ok, ClusterInvitation.t()} | {:error, Error.t()}
  def get(id, organization_id, opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:get, id, organization_id})
  end

  @doc "Lists invitations belonging to an organization."
  @spec list(String.t(), keyword()) :: [ClusterInvitation.t()]
  def list(organization_id, opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:list, organization_id})
  end

  @doc "Prunes expired invitations without reopening replay windows."
  @spec prune(keyword()) :: {:ok, non_neg_integer()}
  def prune(opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, :prune)
  end

  @doc "Returns non-secret store counters."
  @spec status(keyword()) :: map()
  def status(opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, :status)
  end

  @impl true
  def init(opts) do
    with {:ok, max_lifetime} <-
           validate_lifetime(Keyword.get(opts, :max_lifetime, @default_lifetime)) do
      state = %{
        clusters: %{},
        invitations: %{},
        store_path: Keyword.get(opts, :store_path),
        now_fn: Keyword.get(opts, :now_fn, &default_now/0),
        rand_fn: Keyword.get(opts, :rand_fn, &:crypto.strong_rand_bytes/1),
        audit_server: Keyword.get(opts, :audit_server),
        max_lifetime: max_lifetime
      }

      case load_persisted(state) do
        {:ok, loaded} -> {:ok, loaded}
        {:error, error} -> {:stop, {:storage_unavailable, error.code}}
      end
    else
      {:error, error} -> {:stop, {:invalid_configuration, error.code}}
    end
  end

  @impl true
  def handle_call({:create, attrs}, _from, state) do
    case do_create(attrs, state) do
      {:ok, invitation, token, new_state} ->
        {:reply, {:ok, invitation, token}, new_state}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:consume, token, organization_id}, _from, state) do
    case do_consume(token, organization_id, state) do
      {:ok, invitation, new_state} ->
        {:reply, {:ok, invitation}, new_state}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:get, id, organization_id}, _from, state) do
    reply =
      state.invitations
      |> Map.values()
      |> Enum.find(&(&1.id == id and &1.organization_id == organization_id))
      |> case do
        %ClusterInvitation{} = invitation -> {:ok, invitation}
        nil -> {:error, Error.new(:invitation_not_found, "invitation was not found")}
      end

    {:reply, reply, state}
  end

  def handle_call({:list, organization_id}, _from, state) do
    invitations =
      state.invitations
      |> Map.values()
      |> Enum.filter(&(&1.organization_id == organization_id))
      |> Enum.sort_by(& &1.inserted_at, :desc)

    {:reply, invitations, state}
  end

  def handle_call(:prune, _from, state) do
    now = state.now_fn.()

    {invitations, pruned_count} =
      Enum.reduce(state.invitations, {%{}, 0}, fn {digest, invitation}, {kept, count} ->
        if ClusterInvitation.expired?(invitation, now) do
          {kept, count + 1}
        else
          {Map.put(kept, digest, invitation), count}
        end
      end)

    new_state = %{state | invitations: invitations}
    _ = persist(new_state)
    {:reply, {:ok, pruned_count}, new_state}
  end

  def handle_call(:status, _from, state) do
    now = state.now_fn.()

    active =
      Enum.count(state.invitations, fn {_digest, invitation} ->
        not ClusterInvitation.expired?(invitation, now) and
          not ClusterInvitation.consumed?(invitation)
      end)

    consumed =
      Enum.count(state.invitations, fn {_digest, invitation} -> invitation.consumed_at != nil end)

    {:reply,
     %{
       cluster_count: map_size(state.clusters),
       invitation_count: map_size(state.invitations),
       active_count: active,
       consumed_count: consumed,
       store_path: state.store_path
     }, state}
  end

  @impl true
  def format_status(status) do
    Map.update(status, :state, %{}, &redact_state/1)
  end

  # ---------------------------------------------------------------------------
  # Create / consume
  # ---------------------------------------------------------------------------

  defp do_create(attrs, state) do
    with {:ok, organization_id} <- required_string(attrs, :organization_id),
         {:ok, cluster_name} <- cluster_name(attrs),
         :ok <- ensure_unique_cluster(state.clusters, organization_id, cluster_name),
         {:ok, labels} <- labels(attrs),
         {:ok, lifetime} <- requested_lifetime(attrs, state.max_lifetime),
         {:ok, cluster_id} <- unique_id(state),
         {:ok, token} <- generate_token(state.rand_fn),
         digest <- :crypto.hash(:sha256, token),
         now <- state.now_fn.(),
         {:ok, cluster} <-
           Cluster.new(%{
             id: cluster_id,
             organization_id: organization_id,
             name: cluster_name,
             labels: labels,
             inserted_at: now
           }),
         {:ok, invitation} <-
           ClusterInvitation.new(%{
             id: "cinv_" <> cluster_id,
             organization_id: organization_id,
             cluster_id: cluster.id,
             cluster_name: cluster.name,
             labels: labels,
             token_digest: digest,
             expires_at: now + lifetime,
             inserted_at: now
           }) do
      new_state = %{
        state
        | clusters: Map.put(state.clusters, cluster.id, cluster),
          invitations: Map.put(state.invitations, digest, invitation)
      }

      case persist(new_state) do
        :ok ->
          emit_audit(state, :cluster_invitation_issued, %{
            organization_id: organization_id,
            cluster_id: cluster.id,
            cluster_name: cluster.name
          })

          {:ok, invitation, token, new_state}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp do_consume(token, organization_id, state) do
    with {:ok, digest} <- token_digest(token),
         {:ok, invitation} <- fetch_invitation(state.invitations, digest),
         :ok <- verify_digest(digest, invitation.token_digest),
         :ok <- verify_organization(invitation.organization_id, organization_id),
         now <- state.now_fn.(),
         :ok <- verify_expiry(invitation, now),
         :ok <- verify_unused(invitation) do
      consumed = %{invitation | consumed_at: now}
      new_state = %{state | invitations: Map.put(state.invitations, digest, consumed)}

      case persist(new_state) do
        :ok ->
          emit_audit(state, :cluster_invitation_consumed, %{
            organization_id: organization_id,
            cluster_id: invitation.cluster_id
          })

          {:ok, consumed, new_state}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp ensure_unique_cluster(clusters, organization_id, name) do
    if Enum.any?(clusters, fn {_id, cluster} ->
         cluster.organization_id == organization_id and cluster.name == name
       end) do
      {:error, Error.new(:duplicate_cluster_name, "cluster name already exists in organization")}
    else
      :ok
    end
  end

  defp unique_id(state) do
    with {:ok, bytes} <- random_bytes(state.rand_fn, @id_bytes),
         id <- Base.url_encode64(bytes, padding: false),
         false <- Map.has_key?(state.clusters, id) do
      {:ok, id}
    else
      true -> {:error, Error.new(:cluster_id_collision, "cluster ID collision")}
      {:error, error} -> {:error, error}
    end
  end

  defp generate_token(rand_fn) do
    with {:ok, bytes} <- random_bytes(rand_fn, @token_bytes) do
      {:ok, @token_prefix <> Base.url_encode64(bytes, padding: false)}
    end
  end

  defp token_digest(@token_prefix <> encoded) do
    case Base.url_decode64(encoded, padding: false) do
      {:ok, bytes} when byte_size(bytes) == @token_bytes ->
        {:ok, :crypto.hash(:sha256, @token_prefix <> encoded)}

      _ ->
        {:error, Error.new(:invalid_invitation_format, "invitation format is invalid")}
    end
  end

  defp token_digest(_token),
    do: {:error, Error.new(:invalid_invitation_format, "invitation format is invalid")}

  defp fetch_invitation(invitations, digest) do
    case Map.fetch(invitations, digest) do
      {:ok, invitation} -> {:ok, invitation}
      :error -> {:error, Error.new(:invitation_not_found, "invitation was not found")}
    end
  end

  defp verify_digest(digest, stored_digest) do
    if :crypto.hash_equals(digest, stored_digest) do
      :ok
    else
      {:error, Error.new(:invitation_not_found, "invitation was not found")}
    end
  end

  defp verify_organization(expected, expected), do: :ok

  defp verify_organization(_bound, _claimed),
    do: {:error, Error.new(:organization_mismatch, "invitation belongs to another organization")}

  defp verify_expiry(invitation, now) do
    if ClusterInvitation.expired?(invitation, now) do
      {:error, Error.new(:invitation_expired, "invitation has expired")}
    else
      :ok
    end
  end

  defp verify_unused(%ClusterInvitation{consumed_at: nil}), do: :ok

  defp verify_unused(_invitation),
    do: {:error, Error.new(:invitation_already_consumed, "invitation has already been used")}

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  defp required_string(attrs, key) do
    case fetch(attrs, key) do
      value when is_binary(value) ->
        value = String.trim(value)

        if value == "",
          do: {:error, Error.new(:invalid_organization_id, "organization ID must not be empty")},
          else: {:ok, value}

      _ ->
        {:error,
         Error.new(:invalid_organization_id, "organization ID must be a non-empty string")}
    end
  end

  defp cluster_name(attrs) do
    case fetch(attrs, :name, fetch(attrs, :cluster_name)) do
      value when is_binary(value) ->
        value = String.trim(value)

        if value == "",
          do: {:error, Error.new(:invalid_cluster_name, "cluster name must not be empty")},
          else: {:ok, value}

      _ ->
        {:error, Error.new(:invalid_cluster_name, "cluster name must be a non-empty string")}
    end
  end

  defp labels(attrs) do
    case fetch(attrs, :labels, %{}) do
      labels when is_map(labels) ->
        if Enum.all?(labels, fn {key, value} -> is_binary(key) and is_binary(value) end) do
          {:ok, labels}
        else
          {:error,
           Error.new(:invalid_cluster_labels, "cluster labels must be string key/value pairs")}
        end

      _ ->
        {:error, Error.new(:invalid_cluster_labels, "cluster labels must be a map")}
    end
  end

  defp requested_lifetime(attrs, max_lifetime) do
    case fetch(attrs, :expires_in, max_lifetime) do
      lifetime
      when is_integer(lifetime) and lifetime >= @min_lifetime and lifetime <= max_lifetime ->
        {:ok, lifetime}

      _ ->
        {:error,
         Error.new(:invalid_invitation_lifetime, "invitation lifetime must be a positive integer")}
    end
  end

  defp validate_lifetime(value)
       when is_integer(value) and value >= @min_lifetime and value <= @default_lifetime,
       do: {:ok, value}

  defp validate_lifetime(_value),
    do: {:error, Error.new(:invalid_invitation_lifetime, "invitation lifetime is invalid")}

  defp random_bytes(rand_fn, size) do
    bytes = rand_fn.(size)

    if is_binary(bytes) and byte_size(bytes) == size do
      {:ok, bytes}
    else
      {:error, Error.new(:randomness_unavailable, "secure randomness is unavailable")}
    end
  rescue
    _error -> {:error, Error.new(:randomness_unavailable, "secure randomness is unavailable")}
  end

  defp fetch(attrs, key, default \\ nil) do
    Map.get(attrs, key, Map.get(attrs, Atom.to_string(key), default))
  end

  # ---------------------------------------------------------------------------
  # Persistence
  # ---------------------------------------------------------------------------

  defp load_persisted(%{store_path: nil} = state), do: {:ok, state}

  defp load_persisted(%{store_path: path} = state) do
    case File.read(store_file(path)) do
      {:error, :enoent} ->
        {:ok, state}

      {:ok, contents} ->
        decode_store(contents, state)

      {:error, reason} ->
        {:error,
         Error.new(:invitation_storage_unavailable, "invitation store cannot be read", %{
           reason: sanitize_reason(reason)
         })}
    end
  end

  defp decode_store(contents, state) do
    with {:ok, decoded} <- decode_json(contents),
         {:ok, clusters} <- decode_clusters(Map.get(decoded, "clusters", [])),
         {:ok, invitations} <- decode_invitations(Map.get(decoded, "invitations", [])) do
      {:ok, %{state | clusters: clusters, invitations: invitations}}
    else
      _ -> {:error, Error.new(:invitation_storage_corrupt, "invitation store is corrupt")}
    end
  end

  defp decode_json(contents) do
    case :json.decode(contents) do
      %{"version" => 1} = decoded -> {:ok, decoded}
      _ -> {:error, :invalid_format}
    end
  rescue
    _ -> {:error, :invalid_json}
  end

  defp decode_clusters(clusters) when is_list(clusters) do
    Enum.reduce_while(clusters, {:ok, %{}}, fn attrs, {:ok, acc} ->
      case Cluster.new(attrs) do
        {:ok, cluster} -> {:cont, {:ok, Map.put(acc, cluster.id, cluster)}}
        {:error, _} -> {:halt, {:error, :invalid_cluster}}
      end
    end)
  end

  defp decode_clusters(_), do: {:error, :invalid_clusters}

  defp decode_invitations(invitations) when is_list(invitations) do
    Enum.reduce_while(invitations, {:ok, %{}}, fn attrs, {:ok, acc} ->
      with {:ok, digest} <- decode_digest(Map.get(attrs, "token_digest")),
           attrs <- Map.put(attrs, "token_digest", digest),
           {:ok, invitation} <- ClusterInvitation.new(attrs) do
        {:cont, {:ok, Map.put(acc, digest, invitation)}}
      else
        _ -> {:halt, {:error, :invalid_invitation}}
      end
    end)
  end

  defp decode_invitations(_), do: {:error, :invalid_invitations}

  defp decode_digest(value) when is_binary(value) do
    case Base.decode64(value, padding: false) do
      {:ok, digest} when byte_size(digest) == 32 -> {:ok, digest}
      _ -> {:error, :invalid_digest}
    end
  end

  defp decode_digest(_), do: {:error, :invalid_digest}

  defp persist(%{store_path: nil}), do: :ok

  defp persist(%{store_path: path, clusters: clusters, invitations: invitations}) do
    file = store_file(path)
    stage = file <> ".tmp"

    result =
      with :ok <- ensure_store_dir(path),
           {:ok, encoded} <- encode_store(clusters, invitations),
           :ok <- File.write(stage, encoded, [:binary]),
           :ok <- File.chmod(stage, 0o600),
           :ok <- File.rename(stage, file) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end

    case result do
      :ok ->
        :ok

      {:error, _reason} ->
        _ = File.rm(stage)
        {:error, Error.new(:invitation_storage_error, "failed to persist invitation state")}
    end
  end

  defp encode_store(clusters, invitations) do
    clusters =
      Enum.map(clusters, fn {_id, cluster} ->
        %{
          "id" => cluster.id,
          "organization_id" => cluster.organization_id,
          "name" => cluster.name,
          "labels" => cluster.labels,
          "inserted_at" => cluster.inserted_at
        }
      end)

    invitations =
      Enum.map(invitations, fn {_digest, invitation} ->
        base = %{
          "id" => invitation.id,
          "organization_id" => invitation.organization_id,
          "cluster_id" => invitation.cluster_id,
          "cluster_name" => invitation.cluster_name,
          "labels" => invitation.labels,
          "token_digest" => Base.encode64(invitation.token_digest, padding: false),
          "expires_at" => invitation.expires_at,
          "inserted_at" => invitation.inserted_at
        }

        if invitation.consumed_at,
          do: Map.put(base, "consumed_at", invitation.consumed_at),
          else: base
      end)

    try do
      {:ok,
       :json.encode(%{"version" => 1, "clusters" => clusters, "invitations" => invitations})
       |> IO.iodata_to_binary()}
    rescue
      _ -> {:error, :encoding_failed}
    end
  end

  defp ensure_store_dir(path) do
    case File.lstat(path) do
      {:ok, %{type: :directory, mode: mode}} when Bitwise.band(mode, 0o777) == 0o700 ->
        :ok

      {:ok, %{type: :directory}} ->
        {:error, :insecure_store_directory}

      {:ok, _} ->
        {:error, :not_a_directory}

      {:error, :enoent} ->
        with :ok <- File.mkdir_p(path), :ok <- File.chmod(path, 0o700), do: :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp store_file(path), do: Path.join(path, "cluster_invitations.json")

  # ---------------------------------------------------------------------------
  # Redaction and audit
  # ---------------------------------------------------------------------------

  defp emit_audit(%{audit_server: nil}, _event, _attributes), do: :ok

  defp emit_audit(%{audit_server: server}, event, attributes) do
    try do
      _ = Audit.emit(event, attributes, server: server)
      :ok
    catch
      :exit, _ -> :ok
    end
  end

  defp redact_state(state) when is_map(state) do
    invitations =
      state
      |> Map.get(:invitations, %{})
      |> Map.new(fn {digest, invitation} ->
        {digest, Map.put(invitation, :token_digest, "[REDACTED]")}
      end)

    state
    |> Map.put(:invitations, invitations)
    |> Map.drop([:rand_fn, :now_fn])
  end

  defp redact_state(state), do: state

  defp default_now, do: System.system_time(:second)

  defp sanitize_reason(reason) when reason in [:eacces, :enoent, :enospc, :erofs, :eisdir],
    do: reason

  defp sanitize_reason(_), do: :io_failure
end
