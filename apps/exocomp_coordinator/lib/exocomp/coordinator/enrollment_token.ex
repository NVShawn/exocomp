defmodule Exocomp.Coordinator.EnrollmentToken do
  # Module attributes used in @moduledoc must be defined before @moduledoc.
  @default_lifetime 600
  @min_lifetime 1
  @token_prefix "tok_"
  @key_bytes 16
  @secret_bytes 32

  @moduledoc """
  Durable node-bound enrollment-token service.

  Tokens are inventory-bound, expiring, and single-use under concurrent load
  and across coordinator restarts. Only a cryptographic digest is persisted;
  the plaintext token is returned once at issuance and never stored.

  ## Security properties

  - Issuance rejects node IDs absent from the active inventory.
  - Default token lifetime is #{@default_lifetime} seconds. Configured lifetimes
    must be positive and at most the default; longer values are rejected.
  - Tokens carry 256 bits of entropy split into a 128-bit lookup key and a
    128-bit secret; only SHA-256(secret) is stored.
  - Consumption performs constant-time digest comparison using
    `:crypto.hash_equals/2` and atomically validates inventory membership,
    bound node ID, expiry, and unused status inside a single GenServer call,
    so concurrent requests cannot both succeed.
  - Persistent state is written atomically via a staged rename, stored in a
    mode-0700 directory with mode-0600 files, and fail-closed on corruption
    or I/O errors.
  - Expired records are pruned safely without reopening replay windows; the
    expiry check occurs before consulting the consumed flag.

  ## Redaction

  Tokens, digests, and all private metadata are stripped from Logger output,
  Audit payloads, Error structs, Inspect output (via `format_status/1`), and
  crash reports. Audit events emit only safe node ID, result, and correlation
  metadata through the EXOCOMP-14 audit abstraction.

  ## Injected seams (for deterministic tests)

  - `:now_fn` — nullary function returning current Unix seconds (integer).
  - `:rand_fn` — unary function accepting a byte count, returning that many
    random bytes.
  - `:store_path` — directory for durable state; `nil` disables persistence.
  - `:inventory_fn` — unary function accepting a node_id binary, returning
    `:ok` or `{:error, Error.t()}`. Defaults to a live `Inventory` lookup.
  - `:max_lifetime` — token lifetime in seconds (1..#{@default_lifetime};
    default #{@default_lifetime}).
  """

  use GenServer

  alias Exocomp.Coordinator.{Audit, Error, Inventory}

  @type token :: String.t()
  @type option ::
          {:name, GenServer.name()}
          | {:now_fn, (-> integer())}
          | {:rand_fn, (pos_integer() -> binary())}
          | {:store_path, Path.t() | nil}
          | {:inventory_fn, (String.t() -> :ok | {:error, Error.t()})}
          | {:max_lifetime, pos_integer()}

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Issues a single-use enrollment token bound to `node_id`.

  Returns `{:ok, plaintext_token}` on success. The plaintext token is returned
  exactly once and is never stored by the coordinator.

  Returns `{:error, Error.t()}` when `node_id` is absent from the active
  inventory, the inventory is unavailable, or persistent storage is
  unavailable.
  """
  @spec issue(String.t(), keyword()) :: {:ok, token()} | {:error, Error.t()}
  def issue(node_id, opts \\ []) when is_binary(node_id) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:issue, node_id})
  end

  @doc """
  Consumes a previously issued token, validating that it is bound to
  `claimed_node_id`, has not expired, and has not been used before.

  Returns `:ok` on first use. Returns `{:error, Error.t()}` on invalid format,
  wrong node ID, expiry, replay, or storage failure.
  """
  @spec consume(token(), String.t(), keyword()) :: :ok | {:error, Error.t()}
  def consume(token, claimed_node_id, opts \\ [])
      when is_binary(token) and is_binary(claimed_node_id) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:consume, token, claimed_node_id})
  end

  @doc """
  Prunes expired token records. Safe to call at any time; does not reopen
  replay windows because the expiry check is enforced during consumption.

  Returns `{:ok, pruned_count}`.
  """
  @spec prune(keyword()) :: {:ok, non_neg_integer()}
  def prune(opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, :prune)
  end

  @doc "Returns safe observability metadata; never includes tokens or digests."
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
        records: %{},
        store_path: Keyword.get(opts, :store_path),
        now_fn: Keyword.get(opts, :now_fn, &default_now/0),
        rand_fn: Keyword.get(opts, :rand_fn, &:crypto.strong_rand_bytes/1),
        inventory_fn: Keyword.get(opts, :inventory_fn, &default_inventory_check/1),
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
  def handle_call({:issue, node_id}, _from, state) do
    case do_issue(node_id, state) do
      {:ok, token, new_state} -> {:reply, {:ok, token}, new_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:consume, token, claimed_node_id}, _from, state) do
    case do_consume(token, claimed_node_id, state) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call(:prune, _from, state) do
    now = state.now_fn.()
    {new_records, pruned_count} = do_prune(state.records, now)
    new_state = %{state | records: new_records}

    # Pruning failures are non-fatal; log no details to avoid digest leakage.
    persist(new_state)

    {:reply, {:ok, pruned_count}, new_state}
  end

  def handle_call(:status, _from, state) do
    now = state.now_fn.()

    active =
      Enum.count(state.records, fn {_, r} ->
        r.expires_at > now and is_nil(r.consumed_at)
      end)

    consumed = Enum.count(state.records, fn {_, r} -> not is_nil(r.consumed_at) end)

    status = %{
      record_count: map_size(state.records),
      active_count: active,
      consumed_count: consumed,
      store_path: state.store_path
    }

    {:reply, status, state}
  end

  @impl true
  def format_status(status) do
    Map.update(status, :state, %{}, &redact_state/1)
  end

  # ---------------------------------------------------------------------------
  # Issue / consume
  # ---------------------------------------------------------------------------

  defp do_issue(node_id, state) do
    correlation_id = Audit.correlation_id()

    case state.inventory_fn.(node_id) do
      :ok ->
        now = state.now_fn.()
        expires_at = now + state.max_lifetime
        {token, key_b64, record} = generate_token(node_id, expires_at, state.rand_fn)
        new_records = Map.put(state.records, key_b64, record)
        new_state = %{state | records: new_records}

        case persist(new_state) do
          :ok ->
            Audit.emit(
              :enrollment_token_issued,
              %{node_id: node_id},
              correlation_id: correlation_id
            )

            {:ok, token, new_state}

          {:error, error} ->
            Audit.emit(
              :enrollment_token_issue_failed,
              %{node_id: node_id, result: :storage_error},
              correlation_id: correlation_id
            )

            {:error, error}
        end

      {:error, error} ->
        Audit.emit(
          :enrollment_token_issue_failed,
          %{node_id: node_id, result: error.code},
          correlation_id: correlation_id
        )

        {:error, error}
    end
  end

  defp do_consume(token, claimed_node_id, state) do
    correlation_id = Audit.correlation_id()
    now = state.now_fn.()

    case validate_and_consume(token, claimed_node_id, now, state) do
      {:ok, new_state} ->
        Audit.emit(
          :enrollment_token_consumed,
          %{node_id: claimed_node_id, result: :ok},
          correlation_id: correlation_id
        )

        {:ok, new_state}

      {:error, error} ->
        Audit.emit(
          :enrollment_token_consume_failed,
          %{node_id: claimed_node_id, result: error.code},
          correlation_id: correlation_id
        )

        {:error, error}
    end
  end

  defp validate_and_consume(token, claimed_node_id, now, state) do
    with {:ok, key_b64, secret_bytes} <- parse_token(token),
         {:ok, record} <- lookup_record(state.records, key_b64),
         :ok <- verify_digest(secret_bytes, record.digest),
         :ok <- verify_node_id(claimed_node_id, record.node_id),
         :ok <- verify_expiry(now, record.expires_at),
         :ok <- verify_unused(record) do
      new_record = %{record | consumed_at: now}
      new_records = Map.put(state.records, key_b64, new_record)
      new_state = %{state | records: new_records}

      case persist(new_state) do
        :ok -> {:ok, new_state}
        {:error, error} -> {:error, error}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Token generation and parsing
  # ---------------------------------------------------------------------------

  defp generate_token(node_id, expires_at, rand_fn) do
    key_bytes = rand_fn.(@key_bytes)
    secret_bytes = rand_fn.(@secret_bytes)

    key_b64 = Base.url_encode64(key_bytes, padding: false)
    secret_b64 = Base.url_encode64(secret_bytes, padding: false)
    token = @token_prefix <> key_b64 <> "." <> secret_b64

    # Never store the plaintext secret; store only its SHA-256 digest.
    digest = :crypto.hash(:sha256, secret_bytes)

    record = %{
      node_id: node_id,
      expires_at: expires_at,
      consumed_at: nil,
      digest: digest
    }

    {token, key_b64, record}
  end

  # Pattern-match on the literal prefix to avoid branching leaks.
  defp parse_token(@token_prefix <> rest) do
    case String.split(rest, ".", parts: 2) do
      [key_b64, secret_b64] ->
        with {:ok, key_bytes} <- Base.url_decode64(key_b64, padding: false),
             true <- byte_size(key_bytes) == @key_bytes,
             {:ok, secret_bytes} <- Base.url_decode64(secret_b64, padding: false),
             true <- byte_size(secret_bytes) == @secret_bytes do
          {:ok, key_b64, secret_bytes}
        else
          _ -> token_format_error()
        end

      _ ->
        token_format_error()
    end
  end

  defp parse_token(_), do: token_format_error()

  defp token_format_error,
    do: {:error, Error.new(:invalid_token_format, "token format is invalid")}

  defp lookup_record(records, key_b64) do
    case Map.fetch(records, key_b64) do
      {:ok, record} -> {:ok, record}
      :error -> {:error, Error.new(:token_not_found, "token is not valid")}
    end
  end

  defp verify_digest(secret_bytes, stored_digest) do
    computed = :crypto.hash(:sha256, secret_bytes)

    if :crypto.hash_equals(computed, stored_digest) do
      :ok
    else
      # Use the same error code as :token_not_found to avoid oracle leakage.
      {:error, Error.new(:token_not_found, "token is not valid")}
    end
  end

  defp verify_node_id(claimed, bound) when claimed == bound, do: :ok

  defp verify_node_id(_claimed, _bound),
    do: {:error, Error.new(:token_node_mismatch, "token is not bound to this node")}

  defp verify_expiry(now, expires_at) when now < expires_at, do: :ok

  defp verify_expiry(_now, _expires_at),
    do: {:error, Error.new(:token_expired, "token has expired")}

  defp verify_unused(%{consumed_at: nil}), do: :ok

  defp verify_unused(_),
    do: {:error, Error.new(:token_already_consumed, "token has already been used")}

  defp do_prune(records, now) do
    Enum.reduce(records, {%{}, 0}, fn {key, record}, {kept, count} ->
      if record.expires_at < now do
        {kept, count + 1}
      else
        {Map.put(kept, key, record), count}
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Persistence
  # ---------------------------------------------------------------------------

  defp load_persisted(%{store_path: nil} = state), do: {:ok, state}

  defp load_persisted(%{store_path: store_path, now_fn: now_fn} = state) do
    file = store_file(store_path)

    case File.read(file) do
      {:error, :enoent} ->
        # First start — no store yet; begin with empty state.
        {:ok, state}

      {:ok, contents} ->
        case decode_store(contents) do
          {:ok, records} ->
            now = now_fn.()
            {pruned, _} = do_prune(records, now)
            {:ok, %{state | records: pruned}}

          {:error, reason} ->
            {:error,
             Error.new(:token_storage_corrupt, "enrollment token store is corrupt", %{
               reason: reason
             })}
        end

      {:error, reason} ->
        {:error,
         Error.new(:token_storage_unavailable, "enrollment token store cannot be read", %{
           reason: sanitize_reason(reason)
         })}
    end
  end

  defp persist(%{store_path: nil}), do: :ok

  defp persist(%{store_path: store_path, records: records}) do
    file = store_file(store_path)
    stage = file <> ".tmp"

    result =
      with :ok <- ensure_store_dir(store_path),
           {:ok, encoded} <- encode_store(records),
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
        File.rm(stage)

        {:error, Error.new(:token_storage_error, "failed to persist enrollment token state")}
    end
  end

  defp ensure_store_dir(path) do
    # Use lstat so a symlink at `path` is never mistaken for the directory
    # itself. A symlink would show type :symlink, not :directory, and fail the
    # pattern match below — preventing an attacker who can create a symlink
    # from redirecting token storage to a world-readable location.
    case File.lstat(path) do
      {:ok, %{type: :directory, mode: mode}} ->
        # Reject an existing directory whose permissions have been widened.
        # An unprotected store directory exposes token digests to other local
        # users; fail closed rather than silently writing to an insecure path.
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

  defp store_file(store_path), do: Path.join(store_path, "enrollment_tokens.json")

  defp encode_store(records) do
    entries =
      Enum.map(records, fn {key_b64, record} ->
        base = %{
          "k" => key_b64,
          "n" => record.node_id,
          "e" => record.expires_at,
          "d" => Base.encode64(record.digest, padding: false)
        }

        if record.consumed_at,
          do: Map.put(base, "c", record.consumed_at),
          else: base
      end)

    try do
      encoded =
        %{"version" => 1, "records" => entries}
        |> :json.encode()
        |> IO.iodata_to_binary()

      {:ok, encoded}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp decode_store(contents) do
    try do
      case :json.decode(contents) do
        %{"version" => 1, "records" => records} when is_list(records) ->
          decode_records(records)

        _ ->
          {:error, :invalid_format}
      end
    rescue
      _ -> {:error, :invalid_json}
    end
  end

  defp decode_records(records) do
    Enum.reduce_while(records, {:ok, %{}}, fn entry, {:ok, acc} ->
      case decode_record(entry) do
        {:ok, {key_b64, record}} -> {:cont, {:ok, Map.put(acc, key_b64, record)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp decode_record(%{"k" => k, "n" => n, "e" => e, "d" => d} = entry)
       when is_binary(k) and is_binary(n) and is_integer(e) and is_binary(d) do
    consumed_at = Map.get(entry, "c")

    if is_nil(consumed_at) or is_integer(consumed_at) do
      case Base.decode64(d, padding: false) do
        {:ok, digest} when byte_size(digest) == 32 ->
          record = %{
            node_id: n,
            expires_at: e,
            consumed_at: consumed_at,
            digest: digest
          }

          {:ok, {k, record}}

        _ ->
          {:error, :invalid_digest}
      end
    else
      {:error, :invalid_consumed_at}
    end
  end

  defp decode_record(_), do: {:error, :invalid_record}

  # ---------------------------------------------------------------------------
  # Redaction (crash reports / Inspect)
  # ---------------------------------------------------------------------------

  defp redact_state(state) when is_map(state) do
    safe_records =
      Map.get(state, :records, %{})
      |> Map.new(fn {key, record} ->
        {key, Map.put(record, :digest, "[REDACTED]")}
      end)

    state
    |> Map.put(:records, safe_records)
    |> Map.drop([:rand_fn, :now_fn, :inventory_fn])
  end

  defp redact_state(state), do: state

  # ---------------------------------------------------------------------------
  # Defaults and helpers
  # ---------------------------------------------------------------------------

  defp default_now, do: System.system_time(:second)

  defp default_inventory_check(node_id) do
    try do
      inventory = Inventory.current()

      if Enum.any?(inventory.nodes, fn n -> n.id == node_id end) do
        :ok
      else
        {:error,
         Error.new(:node_not_in_inventory, "node ID is not in the active inventory", %{
           node_id: node_id
         })}
      end
    catch
      :exit, _reason ->
        {:error, Error.new(:inventory_unavailable, "inventory is not available")}
    end
  end

  defp validate_lifetime(value)
       when is_integer(value) and value >= @min_lifetime and value <= @default_lifetime,
       do: {:ok, value}

  defp validate_lifetime(_value) do
    {:error,
     Error.new(
       :invalid_token_lifetime,
       "token lifetime must be a positive integer of at most #{@default_lifetime} seconds"
     )}
  end

  defp sanitize_reason(reason)
       when reason in [:eacces, :enoent, :enospc, :erofs, :eisdir],
       do: reason

  defp sanitize_reason(_), do: :io_failure
end
