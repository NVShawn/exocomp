# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.PKI.CertificateRegistry do
  @moduledoc """
  Tracks issued certificate serials and explicit revocations for the
  coordinator's node PKI.

  This registry enables:

  - Renewal eligibility enforcement: renewal is only permitted if neither the
    presenting serial nor the node identity has been explicitly revoked.
  - Admin revocation: an operator can revoke a node identity and all its known
    active certificate serials through `revoke_identity/2`.
  - Deterministic certificate status lookup: the connection gateway calls
    `certificate_status/2` to verify a serial before accepting a connection.

  ## Revocation guarantees

  Revocations are durable: a revoked serial or identity remains revoked across
  process and host restarts. State is written atomically via a staged rename to
  a mode-0700 directory with mode-0600 files.

  ## Registration

  Serials are registered at certificate issuance time. The registry stores the
  serial integer, the bound node identity, and the certificate validity window.
  Expired serials are pruned lazily during status lookups.

  ## Concurrency

  All mutations are serialized through GenServer, so concurrent renewal
  requests receive consistent eligibility decisions. Status lookups are
  `GenServer.call/2` and therefore also serialized.

  ## Injected seams (for deterministic tests)

  - `:now_fn` — nullary function returning current Unix seconds.
  - `:store_path` — directory for durable state; `nil` disables persistence.
  """

  use GenServer

  alias Exocomp.Coordinator.Error

  @unix_epoch_gregorian :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  @type serial :: non_neg_integer()
  @type node_id :: String.t()
  @type cert_status :: :active | :revoked | :unknown
  @type identity_status :: :active | :revoked | :unknown
  @type option ::
          {:name, GenServer.name()}
          | {:now_fn, (-> integer())}
          | {:store_path, Path.t() | nil}

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Registers an issued certificate serial with its bound node identity and
  validity window. Called after a certificate is successfully issued.

  `issued_at` and `expires_at` are Unix seconds.
  """
  @spec register(serial(), node_id(), integer(), integer(), keyword()) ::
          :ok | {:error, Error.t()}
  def register(serial, node_id, issued_at, expires_at, opts \\ [])
      when is_integer(serial) and is_binary(node_id) and
             is_integer(issued_at) and is_integer(expires_at) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:register, serial, node_id, issued_at, expires_at})
  end

  @doc """
  Revokes a specific certificate serial. The serial is permanently marked as
  revoked and cannot be renewed. Idempotent.
  """
  @spec revoke_serial(serial(), keyword()) :: :ok | {:error, Error.t()}
  def revoke_serial(serial, opts \\ []) when is_integer(serial) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:revoke_serial, serial})
  end

  @doc """
  Revokes a node identity and all its known active certificate serials. The
  identity is permanently blocked from renewal. Idempotent.

  This is the primary admin operation for decommissioning a node.
  """
  @spec revoke_identity(node_id(), keyword()) :: :ok | {:error, Error.t()}
  def revoke_identity(node_id, opts \\ []) when is_binary(node_id) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:revoke_identity, node_id})
  end

  @doc """
  Returns the status of a certificate serial from the perspective of the
  connection gateway.

  - `:active` — serial is known and not explicitly revoked.
  - `:revoked` — serial has been explicitly revoked or belongs to a revoked
    identity.
  - `:unknown` — serial is not in the registry (may have been issued before
    tracking began or belong to a foreign issuer).

  Note: Certificate expiry is enforced by the TLS layer, not by this function.
  """
  @spec certificate_status(serial(), keyword()) :: cert_status()
  def certificate_status(serial, opts \\ []) when is_integer(serial) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:certificate_status, serial})
  end

  @doc """
  Returns the renewal eligibility status of a node identity.

  - `:active` — identity is known and not explicitly revoked; renewal may
    proceed subject to the renewal window check.
  - `:revoked` — identity has been explicitly revoked; renewal is denied.
  - `:unknown` — identity has no registered certificates (renewal may still be
    denied by the renewal window check, which uses the client certificate's own
    validity dates).
  """
  @spec identity_status(node_id(), keyword()) :: identity_status()
  def identity_status(node_id, opts \\ []) when is_binary(node_id) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:identity_status, node_id})
  end

  @doc """
  Returns safe observability metadata for the registry.
  """
  @spec status(keyword()) :: map()
  def status(opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, :status)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    state = %{
      issued: %{},
      revoked_serials: MapSet.new(),
      revoked_identities: MapSet.new(),
      store_path: Keyword.get(opts, :store_path),
      now_fn: Keyword.get(opts, :now_fn, &default_now/0)
    }

    case load_persisted(state) do
      {:ok, loaded} -> {:ok, loaded}
      {:error, error} -> {:stop, {:storage_unavailable, error.code}}
    end
  end

  @impl true
  def handle_call({:register, serial, node_id, issued_at, expires_at}, _from, state) do
    entry = %{node_id: node_id, issued_at: issued_at, expires_at: expires_at}
    new_issued = Map.put(state.issued, serial, entry)
    new_state = %{state | issued: new_issued}

    case persist(new_state) do
      :ok -> {:reply, :ok, new_state}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call({:revoke_serial, serial}, _from, state) do
    new_revoked = MapSet.put(state.revoked_serials, serial)
    new_state = %{state | revoked_serials: new_revoked}

    case persist(new_state) do
      :ok -> {:reply, :ok, new_state}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call({:revoke_identity, node_id}, _from, state) do
    # Mark the identity as revoked
    new_identities = MapSet.put(state.revoked_identities, node_id)

    # Also revoke all known serials for this identity
    identity_serials =
      state.issued
      |> Enum.filter(fn {_serial, entry} -> entry.node_id == node_id end)
      |> Enum.map(fn {serial, _entry} -> serial end)

    new_revoked_serials = Enum.reduce(identity_serials, state.revoked_serials, &MapSet.put(&2, &1))

    new_state = %{state | revoked_identities: new_identities, revoked_serials: new_revoked_serials}

    case persist(new_state) do
      :ok -> {:reply, :ok, new_state}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call({:certificate_status, serial}, _from, state) do
    status =
      cond do
        MapSet.member?(state.revoked_serials, serial) ->
          :revoked

        Map.has_key?(state.issued, serial) ->
          # Check if the identity owning this serial is revoked
          entry = Map.fetch!(state.issued, serial)

          if MapSet.member?(state.revoked_identities, entry.node_id) do
            :revoked
          else
            :active
          end

        true ->
          :unknown
      end

    {:reply, status, state}
  end

  def handle_call({:identity_status, node_id}, _from, state) do
    status =
      cond do
        MapSet.member?(state.revoked_identities, node_id) ->
          :revoked

        Enum.any?(state.issued, fn {_serial, entry} -> entry.node_id == node_id end) ->
          :active

        true ->
          :unknown
      end

    {:reply, status, state}
  end

  def handle_call(:status, _from, state) do
    now = state.now_fn.()

    active_serials =
      Enum.count(state.issued, fn {serial, entry} ->
        entry.expires_at > now and not MapSet.member?(state.revoked_serials, serial) and
          not MapSet.member?(state.revoked_identities, entry.node_id)
      end)

    status = %{
      issued_count: map_size(state.issued),
      active_serial_count: active_serials,
      revoked_serial_count: MapSet.size(state.revoked_serials),
      revoked_identity_count: MapSet.size(state.revoked_identities),
      store_path: state.store_path
    }

    {:reply, status, state}
  end

  # ---------------------------------------------------------------------------
  # Persistence
  # ---------------------------------------------------------------------------

  defp load_persisted(%{store_path: nil} = state), do: {:ok, state}

  defp load_persisted(%{store_path: store_path} = state) do
    file = store_file(store_path)

    case File.read(file) do
      {:error, :enoent} ->
        {:ok, state}

      {:ok, contents} ->
        case decode_store(contents) do
          {:ok, loaded} ->
            {:ok, Map.merge(state, loaded)}

          {:error, reason} ->
            {:error,
             Error.new(:cert_registry_corrupt, "certificate registry store is corrupt", %{
               reason: reason
             })}
        end

      {:error, reason} ->
        {:error,
         Error.new(:cert_registry_unavailable, "certificate registry cannot be read", %{
           reason: sanitize_reason(reason)
         })}
    end
  end

  defp persist(%{store_path: nil}), do: :ok

  defp persist(state) do
    file = store_file(state.store_path)
    stage = file <> ".tmp"

    result =
      with :ok <- ensure_store_dir(state.store_path),
           {:ok, encoded} <- encode_store(state),
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

      {:error, _} ->
        File.rm(stage)
        {:error, Error.new(:cert_registry_error, "failed to persist certificate registry state")}
    end
  end

  defp ensure_store_dir(path) do
    case File.lstat(path) do
      {:ok, %{type: :directory, mode: mode}} ->
        if Bitwise.band(mode, 0o777) == 0o700 do
          :ok
        else
          {:error, :insecure_store_directory}
        end

      {:ok, _} ->
        {:error, :not_a_directory}

      {:error, :enoent} ->
        with :ok <- File.mkdir_p(path),
             :ok <- File.chmod(path, 0o700) do
          :ok
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp store_file(store_path), do: Path.join(store_path, "certificate_registry.json")

  defp encode_store(state) do
    issued_entries =
      Enum.map(state.issued, fn {serial, entry} ->
        %{
          "s" => serial,
          "n" => entry.node_id,
          "i" => entry.issued_at,
          "e" => entry.expires_at
        }
      end)

    payload = %{
      "version" => 1,
      "issued" => issued_entries,
      "revoked_serials" => MapSet.to_list(state.revoked_serials),
      "revoked_identities" => MapSet.to_list(state.revoked_identities)
    }

    try do
      encoded = payload |> :json.encode() |> IO.iodata_to_binary()
      {:ok, encoded}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp decode_store(contents) do
    try do
      case :json.decode(contents) do
        %{
          "version" => 1,
          "issued" => issued,
          "revoked_serials" => revoked_serials,
          "revoked_identities" => revoked_identities
        }
        when is_list(issued) and is_list(revoked_serials) and is_list(revoked_identities) ->
          with {:ok, decoded_issued} <- decode_issued(issued),
               :ok <- validate_serials(revoked_serials),
               :ok <- validate_identities(revoked_identities) do
            {:ok,
             %{
               issued: decoded_issued,
               revoked_serials: MapSet.new(revoked_serials),
               revoked_identities: MapSet.new(revoked_identities)
             }}
          end

        _ ->
          {:error, :invalid_format}
      end
    rescue
      _ -> {:error, :invalid_json}
    end
  end

  defp decode_issued(entries) do
    Enum.reduce_while(entries, {:ok, %{}}, fn entry, {:ok, acc} ->
      case entry do
        %{"s" => s, "n" => n, "i" => i, "e" => e}
        when is_integer(s) and is_binary(n) and is_integer(i) and is_integer(e) ->
          record = %{node_id: n, issued_at: i, expires_at: e}
          {:cont, {:ok, Map.put(acc, s, record)}}

        _ ->
          {:halt, {:error, :invalid_issued_entry}}
      end
    end)
  end

  defp validate_serials(serials) do
    if Enum.all?(serials, &is_integer/1) do
      :ok
    else
      {:error, :invalid_serial_list}
    end
  end

  defp validate_identities(identities) do
    if Enum.all?(identities, &is_binary/1) do
      :ok
    else
      {:error, :invalid_identity_list}
    end
  end

  # ---------------------------------------------------------------------------
  # Time helpers
  # ---------------------------------------------------------------------------

  @doc false
  @spec asn1_time_to_unix({:utcTime | :generalTime, charlist() | String.t()}) :: integer()
  def asn1_time_to_unix({:utcTime, value}) do
    value_str = to_string(value)
    <<year_2::binary-size(2), rest::binary>> = value_str
    year_int = String.to_integer(year_2)
    year = if year_int < 50, do: year_int + 2000, else: year_int + 1900
    parse_asn1_time_rest(year, rest)
  end

  def asn1_time_to_unix({:generalTime, value}) do
    value_str = to_string(value)
    <<year::binary-size(4), rest::binary>> = value_str
    parse_asn1_time_rest(String.to_integer(year), rest)
  end

  defp parse_asn1_time_rest(year, rest) do
    <<month::binary-size(2), day::binary-size(2), hour::binary-size(2), minute::binary-size(2),
      second::binary-size(2), "Z">> = rest

    gregorian =
      :calendar.datetime_to_gregorian_seconds({
        {year, String.to_integer(month), String.to_integer(day)},
        {String.to_integer(hour), String.to_integer(minute), String.to_integer(second)}
      })

    gregorian - @unix_epoch_gregorian
  end

  # ---------------------------------------------------------------------------
  # Defaults and helpers
  # ---------------------------------------------------------------------------

  defp default_now, do: System.system_time(:second)

  defp sanitize_reason(reason)
       when reason in [:eacces, :enoent, :enospc, :erofs, :eisdir],
       do: reason

  defp sanitize_reason(_), do: :io_failure
end
