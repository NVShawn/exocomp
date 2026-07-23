defmodule Exocomp.Node.Test.FakeLlamaServer do
  @moduledoc """
  In-process fake llama-server for ExUnit tests.

  Listens on a randomly-assigned loopback TCP port and handles:
    - `GET /health`  — for LlamaServer readiness polling
    - `POST /v1/chat/completions` — for ProposalClient inference requests

  Both endpoints return configurable responses so that tests can drive every
  failure mode without a real llama-server binary.

  ## Usage

      {:ok, pid} = FakeLlamaServer.start_link()
      port = FakeLlamaServer.port(pid)

      # Point LlamaServer at the fake port, e.g.:
      #   llama_port: port

      # Change response modes at any time:
      FakeLlamaServer.set_health_mode(pid, :error_503)
      FakeLlamaServer.set_completions_mode(pid, :invalid_json)

  ## Health modes
    - `:ok` (default) — `HTTP 200 OK`
    - `:error_503` — `HTTP 503 Service Unavailable`
    - `:timeout` — never responds (connection hangs until client timeout)

  ## Completions modes
    - `:valid_json` (default) — valid `choices[0].message.content` JSON
    - `:schema_violation` — valid JSON with an unknown `proposal_id`
    - `:invalid_json` — malformed JSON body
    - `:error_500` — `HTTP 500 Internal Server Error`
    - `:timeout` — never responds
  """

  use GenServer

  require Logger

  # A valid ProposalClient completion response: the content field contains a
  # JSON string that passes ProposalSchema.validate/1.
  @content_valid JSON.encode!(%{
                   "schema_version" => "1",
                   "proposal_id" => "restart_service",
                   "rationale" => "High CPU usage detected",
                   "affected_resource" => "nginx.service",
                   "confidence" => 0.92
                 })

  # Valid JSON wrapper with a proposal_id not in the allowed set.
  @content_schema_violation JSON.encode!(%{
                              "schema_version" => "1",
                              "proposal_id" => "make_coffee",
                              "rationale" => "Needs coffee",
                              "affected_resource" => "kitchen",
                              "confidence" => 0.1
                            })

  @valid_response_body JSON.encode!(%{
                         "choices" => [
                           %{
                             "message" => %{
                               "content" => @content_valid
                             }
                           }
                         ]
                       })

  @schema_violation_body JSON.encode!(%{
                           "choices" => [
                             %{
                               "message" => %{
                                 "content" => @content_schema_violation
                               }
                             }
                           ]
                         })

  defstruct [
    :listen_socket,
    :port,
    health_mode: :ok,
    completions_mode: :valid_json
  ]

  @type health_mode :: :ok | :error_503 | :timeout
  @type completions_mode ::
          :valid_json | :schema_violation | :invalid_json | :error_500 | :timeout

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc "Return the TCP port number this server is listening on."
  @spec port(GenServer.server()) :: non_neg_integer()
  def port(pid), do: GenServer.call(pid, :port)

  @doc "Change how the server responds to `GET /health`."
  @spec set_health_mode(GenServer.server(), health_mode()) :: :ok
  def set_health_mode(pid, mode) when mode in [:ok, :error_503, :timeout] do
    GenServer.cast(pid, {:set_health_mode, mode})
  end

  @doc "Change how the server responds to `POST /v1/chat/completions`."
  @spec set_completions_mode(GenServer.server(), completions_mode()) :: :ok
  def set_completions_mode(pid, mode)
      when mode in [:valid_json, :schema_violation, :invalid_json, :error_500, :timeout] do
    GenServer.cast(pid, {:set_completions_mode, mode})
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(opts) do
    {:ok, listen_socket} =
      :gen_tcp.listen(0, [
        :binary,
        active: false,
        reuseaddr: true,
        ip: {127, 0, 0, 1}
      ])

    {:ok, port} = :inet.port(listen_socket)

    state = %__MODULE__{
      listen_socket: listen_socket,
      port: port,
      health_mode: Keyword.get(opts, :health_mode, :ok),
      completions_mode: Keyword.get(opts, :completions_mode, :valid_json)
    }

    # Kick off the non-blocking accept loop.
    send(self(), :accept)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:port, _from, state), do: {:reply, state.port, state}

  def handle_call(:get_modes, _from, state) do
    {:reply, {state.health_mode, state.completions_mode}, state}
  end

  @impl GenServer
  def handle_cast({:set_health_mode, mode}, state) do
    {:noreply, %{state | health_mode: mode}}
  end

  def handle_cast({:set_completions_mode, mode}, state) do
    {:noreply, %{state | completions_mode: mode}}
  end

  @impl GenServer
  def handle_info(:accept, state) do
    server = self()

    case :gen_tcp.accept(state.listen_socket, 50) do
      {:ok, client} ->
        # Handle each connection in its own short-lived process so we don't
        # block the accept loop.
        spawn(fn ->
          {health_mode, completions_mode} = GenServer.call(server, :get_modes)
          handle_connection(client, health_mode, completions_mode)
        end)

        send(self(), :accept)

      {:error, :timeout} ->
        send(self(), :accept)

      {:error, :closed} ->
        # Listen socket closed — GenServer is shutting down, stop the loop.
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
  # Private — connection handler (runs in a spawned process)
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

  defp respond(socket, "GET", "/health", health_mode, _completions_mode) do
    case health_mode do
      :ok ->
        send_http(socket, 200, "OK", "application/json", ~s({"status":"ok"}))

      :error_503 ->
        send_http(
          socket,
          503,
          "Service Unavailable",
          "application/json",
          ~s({"status":"unavailable"})
        )

      :timeout ->
        # Hang until the client gives up (simulates a stalled server).
        Process.sleep(:infinity)
    end
  end

  defp respond(socket, "POST", "/v1/chat/completions", _health_mode, completions_mode) do
    case completions_mode do
      :valid_json ->
        send_http(socket, 200, "OK", "application/json", @valid_response_body)

      :schema_violation ->
        send_http(socket, 200, "OK", "application/json", @schema_violation_body)

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
