defmodule Exocomp.Node.A2ARouter do
  @moduledoc """
  HTTP entry point for the node's A2A 1.0 service.

  Client certificate authentication and protocol-version validation run before
  request parsing so unauthenticated requests cannot cause their bodies to be
  read.

  Accepted router options (passed through `init/1` and accessible via
  `conn.assigns.router_opts`):

  - `:node_id`    — node identifier forwarded to the Agent Card handler.
  - `:registry`   — TaskRegistry GenServer name (default `Exocomp.Node.TaskRegistry`).
  - `:dispatcher` — Dispatcher module (default `Exocomp.Node.Skills.Dispatcher`).
  """

  use Plug.Router, copy_opts_to_assign: :router_opts

  require Logger

  alias Exocomp.A2A.InternalError
  alias Exocomp.A2A.InvalidParamsError
  alias Exocomp.A2A.InvalidRequestError
  alias Exocomp.A2A.MethodNotFoundError
  alias Exocomp.A2A.TaskNotCancelableError
  alias Exocomp.A2A.TaskNotFoundError
  alias Exocomp.A2A.UnsupportedOperationError
  alias Exocomp.Node.A2A.Codec
  alias Exocomp.Node.Handlers.AgentCardHandler
  alias Exocomp.Node.Plug.JSONBodyParser
  alias Exocomp.Node.Skills.Dispatcher
  alias Exocomp.Node.TaskRegistry

  @max_body_length 1_048_576

  plug(:authenticate_mtls)
  plug(:require_a2a_version)

  plug(JSONBodyParser,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason,
    length: @max_body_length,
    pass_assigns: true
  )

  plug(:match)
  plug(:dispatch)

  get "/.well-known/agent-card.json" do
    AgentCardHandler.call(conn, conn.assigns.router_opts)
  end

  post "/message:send" do
    registry = registry_opt(conn)
    dispatcher = dispatcher_opt(conn)

    with {:ok, message} <- Codec.decode_message(conn.body_params),
         {:ok, {skill_id, params}} <- Codec.extract_skill(message),
         {:ok, task_id} <- TaskRegistry.submit(message, skill_id, registry) do
      run_skill_async(task_id, skill_id, params, registry, dispatcher)
      {:ok, task} = TaskRegistry.get(task_id, registry)
      json_response(conn, 202, Codec.encode_task(task))
    else
      {:error, %InvalidParamsError{} = err} ->
        error_response(conn, 400, err)

      {:error, %InvalidRequestError{} = err} ->
        error_response(conn, 400, err)

      {:error, :at_capacity} ->
        error_response(conn, 429, %InternalError{message: "Server at capacity"})
    end
  end

  get "/tasks/:id" do
    registry = registry_opt(conn)

    case TaskRegistry.get(id, registry) do
      {:ok, task} ->
        json_response(conn, 200, Codec.encode_task(task))

      {:error, :not_found} ->
        error_response(conn, 404, %TaskNotFoundError{})
    end
  end

  get "/tasks" do
    registry = registry_opt(conn)
    tasks = TaskRegistry.list(registry)
    json_response(conn, 200, Enum.map(tasks, &Codec.encode_task/1))
  end

  post "/tasks/:id" do
    if String.ends_with?(id, ":cancel") do
      task_id = String.trim_trailing(id, ":cancel")
      registry = registry_opt(conn)

      case TaskRegistry.cancel(task_id, registry) do
        {:ok, task} ->
          json_response(conn, 200, Codec.encode_task(task))

        {:error, :not_found} ->
          error_response(conn, 404, %TaskNotFoundError{})

        {:error, :not_cancelable} ->
          error_response(conn, 400, %TaskNotCancelableError{})
      end
    else
      error_response(conn, 404, %MethodNotFoundError{})
    end
  end

  post "/message/stream" do
    error_response(conn, 400, %UnsupportedOperationError{})
  end

  post "/tasks/:id/resubscribe" do
    error_response(conn, 400, %UnsupportedOperationError{})
  end

  match _ do
    error_response(conn, 404, %MethodNotFoundError{})
  end

  # ---------------------------------------------------------------------------
  # Async skill execution
  # ---------------------------------------------------------------------------

  # Spawns a detached process that transitions the task through :working →
  # :completed | :failed.  The dispatcher is run in an inner Task so that
  # a per-skill timeout can be enforced without blocking the outer worker
  # process indefinitely.
  defp run_skill_async(task_id, skill_id, params, registry, dispatcher) do
    Task.start(fn ->
      case TaskRegistry.transition(task_id, :working, nil, registry) do
        :ok ->
          # Register ourselves so the registry can signal us on cancellation.
          :ok = TaskRegistry.register_worker(task_id, self(), registry)

          timeout_ms =
            Application.get_env(:exocomp_node, :skill_timeout_ms, 30_000)

          dispatch_task =
            Task.async(fn ->
              try do
                dispatcher.dispatch(skill_id, params)
              rescue
                e -> {:error, {:exception, Exception.message(e)}}
              catch
                kind, reason -> {:error, {kind, reason}}
              end
            end)

          result =
            case Task.yield(dispatch_task, timeout_ms) do
              {:ok, dispatch_result} ->
                dispatch_result

              nil ->
                Task.shutdown(dispatch_task, :brutal_kill)
                {:error, :timeout}
            end

          # Transition to terminal state.  If the task was already canceled
          # while we were dispatching, the transition will fail with
          # :invalid_transition; that is expected and we ignore the error.
          case result do
            {:ok, artifact} ->
              TaskRegistry.transition(task_id, :completed, artifact, registry)

            {:error, reason} ->
              TaskRegistry.transition(task_id, :failed, reason, registry)
          end

        {:error, _} ->
          # Task was canceled before we could start — nothing to do.
          :ok
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Middleware
  # ---------------------------------------------------------------------------

  defp authenticate_mtls(conn, _opts) do
    case Plug.Conn.get_peer_data(conn) do
      %{ssl_cert: ssl_cert} when is_binary(ssl_cert) and byte_size(ssl_cert) > 0 ->
        Logger.info("[A2ARouter] mTLS client certificate accepted")
        conn

      _peer_data ->
        Logger.warning("[A2ARouter] mTLS client certificate missing")

        conn
        |> error_response(401, %InvalidRequestError{
          message: "Client certificate required"
        })
        |> halt()
    end
  end

  defp require_a2a_version(conn, _opts) do
    case get_req_header(conn, "a2a-version") do
      ["1.0"] ->
        conn

      _other ->
        conn
        |> error_response(400, %InvalidRequestError{
          message: "A2A-Version header must be 1.0"
        })
        |> halt()
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp registry_opt(conn) do
    Keyword.get(conn.assigns.router_opts || [], :registry, TaskRegistry)
  end

  defp dispatcher_opt(conn) do
    Keyword.get(conn.assigns.router_opts || [], :dispatcher, Dispatcher)
  end

  defp error_response(conn, status, error) do
    json_response(conn, status, %{
      jsonrpc: "2.0",
      id: nil,
      error: Map.from_struct(error)
    })
  end

  defp json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
