defmodule Bench.Test.FakeLlamaServer do
  @moduledoc """
  Minimal in-process fake llama-server for `Bench.Workload.LlamaInference` tests.

  Listens on a randomly-assigned loopback TCP port and handles:

  - `GET /health` — readiness health check.
  - `POST /v1/chat/completions` — inference completion endpoint.

  Both endpoints return configurable responses so that workload benchmarks can
  drive every failure mode without a real llama-server binary.

  ## Health modes

  - `:ok` (default) — HTTP 200 with `{"status":"ok"}`.
  - `:error_503` — HTTP 503 (not ready).
  - `:timeout` — never responds (hangs until client times out).
  - `:closed` — immediately closes the connection (simulates crash).

  ## Completions modes

  - `:valid_json` (default) — a valid chat completions response with usage stats.
  - `:invalid_json` — malformed JSON body.
  - `:error_500` — HTTP 500 Internal Server Error.
  - `:timeout` — never responds.
  - `:schema_violation` — valid JSON but an unrecognised `proposal_id`.
  """

  use GenServer

  require Logger

  @valid_response Jason.encode!(%{
                    "choices" => [
                      %{
                        "message" => %{
                          "content" =>
                            Jason.encode!(%{
                              "schema_version" => "1",
                              "proposal_id" => "restart_service",
                              "rationale" => "High CPU usage",
                              "affected_resource" => "nginx.service",
                              "confidence" => 0.9
                            })
                        }
                      }
                    ],
                    "usage" => %{
                      "prompt_tokens" => 42,
                      "completion_tokens" => 64
                    }
                  })

  @schema_violation_response Jason.encode!(%{
                               "choices" => [
                                 %{
                                   "message" => %{
                                     "content" =>
                                       Jason.encode!(%{
                                         "schema_version" => "1",
                                         "proposal_id" => "make_coffee",
                                         "rationale" => "Need coffee",
                                         "affected_resource" => "kitchen",
                                         "confidence" => 0.1
                                       })
                                   }
                                 }
                               ],
                               "usage" => %{
                                 "prompt_tokens" => 10,
                                 "completion_tokens" => 20
                               }
                             })

  defstruct [
    :listen_socket,
    :port,
    health_mode: :ok,
    completions_mode: :valid_json
  ]

  @type health_mode :: :ok | :error_503 | :timeout | :closed
  @type completions_mode ::
          :valid_json | :invalid_json | :error_500 | :timeout | :schema_violation

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc "Return the TCP port this fake server is listening on."
  @spec port(GenServer.server()) :: non_neg_integer()
  def port(pid), do: GenServer.call(pid, :port)

  @doc "Return `http://127.0.0.1:<port>` for use as a `base_url`."
  @spec base_url(GenServer.server()) :: String.t()
  def base_url(pid), do: "http://127.0.0.1:#{port(pid)}"

  @doc "Set the health endpoint response mode."
  @spec set_health_mode(GenServer.server(), health_mode()) :: :ok
  def set_health_mode(pid, mode) when mode in [:ok, :error_503, :timeout, :closed] do
    GenServer.cast(pid, {:set_health_mode, mode})
  end

  @doc "Set the completions endpoint response mode."
  @spec set_completions_mode(GenServer.server(), completions_mode()) :: :ok
  def set_completions_mode(pid, mode)
      when mode in [:valid_json, :invalid_json, :error_500, :timeout, :schema_violation] do
    GenServer.cast(pid, {:set_completions_mode, mode})
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(opts) do
    {:ok, listen_socket} =
      :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true, ip: {127, 0, 0, 1}])

    {:ok, port} = :inet.port(listen_socket)

    state = %__MODULE__{
      listen_socket: listen_socket,
      port: port,
      health_mode: Keyword.get(opts, :health_mode, :ok),
      completions_mode: Keyword.get(opts, :completions_mode, :valid_json)
    }

    send(self(), :accept)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:port, _from, state), do: {:reply, state.port, state}

  def handle_call(:get_modes, _from, state) do
    {:reply, {state.health_mode, state.completions_mode}, state}
  end

  @impl GenServer
  def handle_cast({:set_health_mode, mode}, state), do: {:noreply, %{state | health_mode: mode}}

  def handle_cast({:set_completions_mode, mode}, state),
    do: {:noreply, %{state | completions_mode: mode}}

  @impl GenServer
  def handle_info(:accept, state) do
    server = self()

    case :gen_tcp.accept(state.listen_socket, 50) do
      {:ok, client} ->
        spawn(fn ->
          {hm, cm} = GenServer.call(server, :get_modes)
          handle_connection(client, hm, cm)
        end)

        send(self(), :accept)

      {:error, :timeout} ->
        send(self(), :accept)

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        Logger.debug("[FakeLlamaServer] accept error: #{inspect(reason)}")
        send(self(), :accept)
    end

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gen_tcp.close(state.listen_socket)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Connection handler (spawned per request)
  # ---------------------------------------------------------------------------

  defp handle_connection(socket, health_mode, completions_mode) do
    case :gen_tcp.recv(socket, 0, 2_000) do
      {:ok, data} ->
        {method, path} = parse_request_line(data)
        respond(socket, method, path, health_mode, completions_mode)

      {:error, _} ->
        :ok
    end

    :gen_tcp.close(socket)
  end

  defp respond(socket, "GET", "/health", health_mode, _cm) do
    case health_mode do
      :ok ->
        send_http(socket, 200, "OK", "application/json", ~s({"status":"ok"}))

      :error_503 ->
        send_http(socket, 503, "Service Unavailable", "application/json", ~s({"status":"down"}))

      :timeout ->
        Process.sleep(:infinity)

      :closed ->
        :gen_tcp.close(socket)
    end
  end

  defp respond(socket, "POST", "/v1/chat/completions", _hm, completions_mode) do
    case completions_mode do
      :valid_json ->
        send_http(socket, 200, "OK", "application/json", @valid_response)

      :schema_violation ->
        send_http(socket, 200, "OK", "application/json", @schema_violation_response)

      :invalid_json ->
        send_http(socket, 200, "OK", "application/json", "not valid json {")

      :error_500 ->
        send_http(socket, 500, "Internal Server Error", "application/json", ~s({"error":"oops"}))

      :timeout ->
        Process.sleep(:infinity)
    end
  end

  defp respond(socket, _method, _path, _hm, _cm) do
    send_http(socket, 404, "Not Found", "text/plain", "Not Found")
  end

  defp send_http(socket, status, reason, content_type, body) do
    response =
      "HTTP/1.1 #{status} #{reason}\r\n" <>
        "Content-Type: #{content_type}\r\n" <>
        "Content-Length: #{byte_size(body)}\r\n" <>
        "Connection: close\r\n" <>
        "\r\n" <>
        body

    :gen_tcp.send(socket, response)
  end

  defp parse_request_line(data) do
    case :binary.split(data, "\r\n") do
      [first_line | _] ->
        case String.split(first_line, " ", parts: 3) do
          [method, path | _] -> {method, path}
          _ -> {"GET", "/"}
        end

      _ ->
        {"GET", "/"}
    end
  end
end
