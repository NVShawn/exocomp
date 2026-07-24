defmodule Exocomp.Coordinator.Audit do
  @moduledoc """
  Correlated, redacted coordinator audit delivery.

  Sink failures are reported to callers and retained as degraded health rather
  than crashing the supervision tree. State-changing callers can therefore
  fail closed while diagnostic processes continue running.
  """

  use GenServer

  alias Exocomp.Coordinator.Audit.JSONLines
  alias Exocomp.Coordinator.Error

  @redacted "[REDACTED]"
  # Keys whose values must never appear in audit output. The check applies to
  # exact matches and suffix matches (e.g. "stored_digest" matches "digest").
  # Include every term that could carry key material, passphrases, or digests
  # that identify a specific secret value.
  @sensitive_keys ~w(api_key authorization cookie credential credentials digest passphrase password passwd pin private_key secret token)

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec emit(atom() | String.t(), map(), keyword()) :: :ok | {:error, Error.t()}
  def emit(type, attributes \\ %{}, opts \\ []) when is_map(attributes) do
    server = Keyword.get(opts, :server, __MODULE__)
    correlation_id = valid_correlation_id(Keyword.get(opts, :correlation_id))
    GenServer.call(server, {:emit, type, correlation_id, attributes})
  end

  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @spec correlation_id() :: String.t()
  def correlation_id do
    entropy = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    "corr_" <> entropy
  end

  @spec redact(term()) :: term()
  def redact(value), do: redact_value(value)

  @impl true
  def init(opts) do
    default_path = Path.join(System.tmp_dir!(), "exocomp-coordinator-audit.jsonl")
    sink = Keyword.get(opts, :sink, {JSONLines, path: default_path})
    {:ok, initialize_sink(sink)}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      healthy: state.sink_state != nil,
      sink: state.sink_module,
      last_error: state.last_error
    }

    {:reply, status, state}
  end

  def handle_call({:emit, type, correlation_id, attributes}, _from, state) do
    event =
      %{
        event_type: to_string(type),
        correlation_id: correlation_id,
        occurred_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        attributes: attributes
      }
      |> redact()
      |> json_safe()

    case deliver(state, event) do
      {:ok, updated} ->
        {:reply, :ok, updated}

      {:error, reason, updated} ->
        error =
          Error.new(:audit_unavailable, "audit event could not be persisted", %{
            reason: inspect(reason),
            correlation_id: correlation_id
          })

        {:reply, {:error, error}, %{updated | last_error: error}}
    end
  end

  @impl true
  def terminate(_reason, %{sink_module: module, sink_state: sink_state})
      when not is_nil(sink_state) do
    module.close(sink_state)
  end

  def terminate(_reason, _state), do: :ok

  defp initialize_sink({module, opts}) do
    case safe_sink_call(fn -> module.init(opts) end) do
      {:ok, sink_state} ->
        %{sink_module: module, sink_opts: opts, sink_state: sink_state, last_error: nil}

      {:error, reason} ->
        %{
          sink_module: module,
          sink_opts: opts,
          sink_state: nil,
          last_error:
            Error.new(:audit_unavailable, "audit sink failed to initialize", %{
              reason: inspect(reason)
            })
        }
    end
  end

  defp deliver(%{sink_state: nil} = state, event) do
    retried = initialize_sink({state.sink_module, state.sink_opts})

    if retried.sink_state do
      deliver(retried, event)
    else
      {:error, retried.last_error, retried}
    end
  end

  defp deliver(state, event) do
    case safe_sink_call(fn -> state.sink_module.write(state.sink_state, event) end) do
      {:ok, sink_state} ->
        {:ok, %{state | sink_state: sink_state, last_error: nil}}

      {:error, reason} ->
        safe_sink_call(fn -> state.sink_module.close(state.sink_state) end)
        {:error, reason, %{state | sink_state: nil}}
    end
  end

  defp safe_sink_call(function) do
    function.()
  rescue
    error -> {:error, {:exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp redact_value(%_{} = struct), do: struct |> Map.from_struct() |> redact_value()

  defp redact_value(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      if sensitive_key?(key) do
        {key, @redacted}
      else
        {key, redact_value(value)}
      end
    end)
  end

  defp redact_value(list) when is_list(list), do: Enum.map(list, &redact_value/1)
  defp redact_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> redact_value()
  defp redact_value(value), do: value

  defp sensitive_key?(key) do
    normalized =
      key
      |> to_string()
      |> String.downcase()
      |> String.replace("-", "_")

    Enum.any?(@sensitive_keys, fn sensitive ->
      normalized == sensitive or String.ends_with?(normalized, "_" <> sensitive)
    end)
  end

  defp json_safe(%_{} = struct), do: struct |> Map.from_struct() |> json_safe()

  defp json_safe(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), json_safe(value)} end)
  end

  defp json_safe(list) when is_list(list), do: Enum.map(list, &json_safe/1)
  defp json_safe(value) when is_atom(value), do: to_string(value)
  defp json_safe(value) when is_binary(value) or is_number(value) or is_nil(value), do: value
  defp json_safe(value), do: inspect(value)

  defp valid_correlation_id(value) when is_binary(value) and byte_size(value) > 0, do: value
  defp valid_correlation_id(_value), do: correlation_id()
end
