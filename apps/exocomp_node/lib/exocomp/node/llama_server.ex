defmodule Exocomp.Node.LlamaServer do
  @moduledoc """
  Owns and monitors one loopback-only `llama-server` OS process.

  Process failures are represented as a degraded server state and retried with
  backoff; they do not crash this GenServer or its supervisor siblings.
  """

  use GenServer

  require Logger

  @loopback "127.0.0.1"
  @health_interval_ms 500
  @default_ready_timeout_ms 30_000
  @default_max_restart_backoff_ms 60_000
  @restart_backoff_base_ms 1_000

  defstruct [
    :path,
    :model_path,
    :port_number,
    :port,
    :ready_deadline,
    status: :stopped,
    restart_count: 0,
    backoff_attempt: 0,
    ready_timeout_ms: @default_ready_timeout_ms,
    max_restart_backoff_ms: @default_max_restart_backoff_ms,
    host: @loopback
  ]

  @type status :: :ready | :starting | :degraded | :stopped

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec status(GenServer.server()) :: status()
  def status(server \\ __MODULE__) do
    call_or_default(server, :status, :stopped)
  end

  @spec base_url(GenServer.server()) :: {:ok, String.t()} | {:error, :not_ready}
  def base_url(server \\ __MODULE__) do
    call_or_default(server, :base_url, {:error, :not_ready})
  end

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    configured_host = option(opts, :llama_host, @loopback)

    if configured_host != @loopback do
      Logger.warning(
        "ignoring non-loopback llama_host #{inspect(configured_host)}; llama-server is loopback-only"
      )
    end

    state = %__MODULE__{
      path: option(opts, :llama_server_path, nil),
      model_path: option(opts, :llama_model_path, nil),
      port_number: option(opts, :llama_port, 8_080),
      ready_timeout_ms:
        positive_integer(
          option(opts, :llama_ready_timeout_ms, @default_ready_timeout_ms),
          @default_ready_timeout_ms
        ),
      max_restart_backoff_ms:
        positive_integer(
          option(opts, :llama_max_restart_backoff_ms, @default_max_restart_backoff_ms),
          @default_max_restart_backoff_ms
        ),
      status: :starting
    }

    {:ok, state, {:continue, :spawn}}
  end

  @impl true
  def handle_continue(:spawn, state), do: {:noreply, spawn_server(state)}

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state.status, state}

  def handle_call(:base_url, _from, %{status: :ready} = state) do
    {:reply, {:ok, server_url(state)}, state}
  end

  def handle_call(:base_url, _from, state) do
    {:reply, {:error, :not_ready}, state}
  end

  @impl true
  def handle_info({:health_check, port}, %{port: port, status: :starting} = state) do
    if healthy?(state) do
      {:noreply, %{state | status: :ready, backoff_attempt: 0}}
    else
      continue_health_checks(state)
    end
  end

  def handle_info({port, {:data, output}}, %{port: port} = state) do
    Logger.debug("llama-server output: #{inspect(output)}")
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, exit_status}}, %{port: port} = state) do
    {:noreply, process_exited(state, exit_status)}
  end

  def handle_info({:EXIT, port, reason}, %{port: port} = state) do
    {:noreply, process_exited(state, reason)}
  end

  def handle_info({:restart, attempt}, %{port: nil, backoff_attempt: attempt} = state) do
    {:noreply, spawn_server(%{state | status: :starting})}
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %{port: port}) when is_port(port) do
    Port.close(port)
    :ok
  catch
    :error, :badarg -> :ok
  end

  def terminate(_reason, _state), do: :ok

  defp spawn_server(%{path: path} = state) when not is_binary(path) or path == "" do
    Logger.error("llama_server_path is not configured")
    schedule_restart(state)
  end

  defp spawn_server(state) do
    port =
      Port.open(
        {:spawn_executable, String.to_charlist(state.path)},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          args: Enum.map(server_args(state), &String.to_charlist/1)
        ]
      )

    deadline = System.monotonic_time(:millisecond) + state.ready_timeout_ms
    send(self(), {:health_check, port})
    %{state | port: port, ready_deadline: deadline, status: :starting}
  rescue
    error ->
      Logger.error("failed to start llama-server: #{Exception.message(error)}")
      schedule_restart(state)
  end

  defp server_args(state) do
    model_args =
      case state.model_path do
        path when is_binary(path) and path != "" -> ["--model", path]
        _other -> []
      end

    ["--host", @loopback, "--port", Integer.to_string(state.port_number)] ++ model_args
  end

  defp healthy?(state) do
    timeout = @health_interval_ms - 100

    with {:ok, socket} <-
           :gen_tcp.connect(
             String.to_charlist(state.host),
             state.port_number,
             [:binary, active: false],
             timeout
           ) do
      request =
        "GET /health HTTP/1.1\r\nHost: #{state.host}:#{state.port_number}\r\nConnection: close\r\n\r\n"

      result =
        with :ok <- :gen_tcp.send(socket, request),
             {:ok, response} <- :gen_tcp.recv(socket, 0, timeout) do
          successful_response?(response)
        else
          _error -> false
        end

      :gen_tcp.close(socket)
      result
    else
      _error -> false
    end
  end

  defp successful_response?(
         <<"HTTP/", _version::binary-size(3), " ", status::binary-size(3), _::binary>>
       ) do
    case Integer.parse(status) do
      {status_code, ""} -> status_code in 200..299
      :error -> false
    end
  end

  defp successful_response?(_response), do: false

  defp continue_health_checks(state) do
    if System.monotonic_time(:millisecond) >= state.ready_deadline do
      Logger.warning("llama-server did not become ready within #{state.ready_timeout_ms}ms")
      {:noreply, %{state | status: :degraded}}
    else
      Process.send_after(self(), {:health_check, state.port}, @health_interval_ms)
      {:noreply, state}
    end
  end

  defp process_exited(state, reason) do
    Logger.warning("llama-server exited: #{inspect(reason)}")
    schedule_restart(%{state | port: nil, ready_deadline: nil})
  end

  defp schedule_restart(state) do
    attempt = state.backoff_attempt + 1
    restart_count = state.restart_count + 1
    delay = restart_delay(attempt, state.max_restart_backoff_ms)

    Logger.info("restarting llama-server in #{delay}ms (attempt #{attempt})")
    Process.send_after(self(), {:restart, attempt}, delay)

    %{
      state
      | port: nil,
        status: :degraded,
        restart_count: restart_count,
        backoff_attempt: attempt
    }
  end

  defp restart_delay(attempt, maximum) do
    exponent = min(attempt - 1, 30)
    capped = min(@restart_backoff_base_ms * Integer.pow(2, exponent), maximum)
    floor = div(capped, 2)
    floor + :rand.uniform(capped - floor + 1) - 1
  end

  defp server_url(state), do: "http://#{state.host}:#{state.port_number}"

  defp option(opts, key, default) do
    Keyword.get(opts, key, Application.get_env(:exocomp_node, key, default))
  end

  defp positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp positive_integer(_value, default), do: default

  defp call_or_default(server, request, default) do
    GenServer.call(server, request)
  catch
    :exit, _reason -> default
  end
end
