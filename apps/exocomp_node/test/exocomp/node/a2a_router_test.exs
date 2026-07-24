defmodule Exocomp.Node.A2ARouterTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Exocomp.A2A.{Artifact, DataPart, Message, TextPart}
  alias Exocomp.Node.A2ARouter
  alias Exocomp.Node.TaskRegistry

  @base_opts [node_id: "node-7.example"]

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp start_registry(extra_opts \\ []) do
    name = :"registry_#{System.unique_integer([:positive])}"
    start_supervised!({TaskRegistry, Keyword.put(extra_opts, :name, name)})
    name
  end

  defp build_opts(registry, dispatcher \\ nil) do
    opts = Keyword.put(@base_opts, :registry, registry)
    opts = if dispatcher, do: Keyword.put(opts, :dispatcher, dispatcher), else: opts
    A2ARouter.init(opts)
  end

  defp authenticated_conn(method, path, body \\ nil) do
    method
    |> conn(path, body)
    |> put_peer_data(%{ssl_cert: <<1>>})
    |> put_req_header("a2a-version", "1.0")
  end

  defp json_conn(method, path, body) do
    method
    |> authenticated_conn(path, Jason.encode!(body))
    |> put_req_header("content-type", "application/json")
  end

  defp valid_message_body(skill_id \\ "exocomp.system.diagnose", extra \\ %{}) do
    %{
      "role" => "user",
      "parts" => [
        %{"type" => "data", "data" => Map.merge(%{"skill" => skill_id}, extra)}
      ]
    }
  end

  # Returns a direct TaskRegistry message (bypasses HTTP endpoint so no async worker is spawned).
  defp registry_submit(registry, skill_id \\ "exocomp.system.diagnose") do
    msg = %Message{
      role: :user,
      parts: [%DataPart{data: %{"skill" => skill_id}}]
    }

    {:ok, task_id} = TaskRegistry.submit(msg, skill_id, registry)
    task_id
  end

  # A dispatcher that immediately returns a success artifact without running real collectors.
  defmodule OkDispatcher do
    def dispatch(_skill_id, _params, _context \\ %{}) do
      {:ok,
       %Artifact{
         artifactId: "test-artifact-1",
         name: "test",
         parts: [%DataPart{data: %{"result" => "ok"}}]
       }}
    end
  end

  # A dispatcher that immediately returns an error.
  defmodule ErrDispatcher do
    def dispatch(_skill_id, _params, _context \\ %{}) do
      {:error, :simulated_failure}
    end
  end

  # ---------------------------------------------------------------------------
  # Existing scaffold / auth / version / body-limit tests (preserved)
  # ---------------------------------------------------------------------------

  test "agent card contains exactly the diagnostic skills and disables streaming" do
    registry = start_registry()
    opts = build_opts(registry)

    response =
      :get
      |> authenticated_conn("/.well-known/agent-card.json")
      |> A2ARouter.call(opts)

    assert response.status == 200
    card = Jason.decode!(response.resp_body)

    assert card["url"] == "https://node-7.example/"
    assert card["capabilities"]["streaming"] == false

    assert Enum.map(card["skills"], & &1["id"]) == [
             "exocomp.system.diagnose",
             "exocomp.service.diagnose",
             "exocomp.remediation.propose"
           ]
  end

  test "request without a client certificate returns 401 before reading the body" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :post
      |> conn("/message:send", String.duplicate("x", 1_048_577))
      |> put_req_header("a2a-version", "1.0")
      |> A2ARouter.call(opts)

    assert conn.status == 401
    assert %Plug.Conn.Unfetched{aspect: :body_params} = conn.body_params
  end

  test "missing A2A-Version header returns InvalidRequestError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :get
      |> conn("/tasks")
      |> put_peer_data(%{ssl_cert: <<1>>})
      |> A2ARouter.call(opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32600
  end

  test "body over one MiB returns 413" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :post
      |> authenticated_conn("/message:send", String.duplicate("x", 1_048_577))
      |> put_req_header("content-type", "application/json")
      |> A2ARouter.call(opts)

    assert conn.status == 413
  end

  test "message streaming returns UnsupportedOperationError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :post
      |> authenticated_conn("/message/stream", Jason.encode!(%{}))
      |> put_req_header("content-type", "application/json")
      |> A2ARouter.call(opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32004
  end

  test "unknown route returns MethodNotFoundError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :get
      |> authenticated_conn("/not-a-route")
      |> A2ARouter.call(opts)

    assert conn.status == 404
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32601
  end

  # ---------------------------------------------------------------------------
  # POST /message:send
  # ---------------------------------------------------------------------------

  test "POST /message:send: valid message returns 202 with task in submitted state" do
    registry = start_registry()
    opts = build_opts(registry, OkDispatcher)

    conn =
      :post
      |> json_conn("/message:send", valid_message_body())
      |> A2ARouter.call(opts)

    assert conn.status == 202
    body = Jason.decode!(conn.resp_body)
    assert is_binary(body["id"])
    assert body["status"]["state"] == "submitted"

    # Wait for async worker to finish so the registry isn't torn down while
    # the worker is still making calls into it.
    assert_task_state(body["id"], registry, :completed, 500)
  end

  test "POST /message:send: invalid JSON body returns 400 InvalidRequestError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :post
      |> authenticated_conn("/message:send", "not-valid-json{{{")
      |> put_req_header("content-type", "application/json")
      |> A2ARouter.call(opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32600
  end

  test "POST /message:send: missing parts returns 400 InvalidParamsError" do
    registry = start_registry()
    opts = build_opts(registry)

    # Valid JSON but missing required parts field
    conn =
      :post
      |> json_conn("/message:send", %{"role" => "user"})
      |> A2ARouter.call(opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32602
  end

  test "POST /message:send: unknown skill returns 400 InvalidParamsError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :post
      |> json_conn("/message:send", valid_message_body("exocomp.unknown.skill"))
      |> A2ARouter.call(opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32602
  end

  test "POST /message:send: at_capacity returns 429" do
    # max_concurrent_tasks: 1 is accepted (must be > 0)
    registry = start_registry(max_concurrent_tasks: 1)
    opts = build_opts(registry)

    # Pre-fill the single working slot via the registry directly
    task_id = registry_submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)

    # Now the working slot is full — next HTTP submit should return 429
    conn =
      :post
      |> json_conn("/message:send", valid_message_body())
      |> A2ARouter.call(opts)

    assert conn.status == 429
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32603
  end

  # ---------------------------------------------------------------------------
  # GET /tasks/:id
  # ---------------------------------------------------------------------------

  test "GET /tasks/:id: known task returns 200 with task JSON" do
    registry = start_registry()
    opts = build_opts(registry)

    # Submit directly via registry (no async worker spawned)
    task_id = registry_submit(registry)

    conn =
      :get
      |> authenticated_conn("/tasks/#{task_id}")
      |> A2ARouter.call(opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["id"] == task_id
    assert body["status"]["state"] == "submitted"
  end

  test "GET /tasks/:id: unknown id returns 404 TaskNotFoundError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :get
      |> authenticated_conn("/tasks/nonexistent-task-id")
      |> A2ARouter.call(opts)

    assert conn.status == 404
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32001
  end

  # ---------------------------------------------------------------------------
  # GET /tasks
  # ---------------------------------------------------------------------------

  test "GET /tasks: returns list including the submitted task" do
    registry = start_registry()
    opts = build_opts(registry)

    # Submit directly via registry (no async worker spawned)
    task_id = registry_submit(registry)

    conn =
      :get
      |> authenticated_conn("/tasks")
      |> A2ARouter.call(opts)

    assert conn.status == 200
    tasks = Jason.decode!(conn.resp_body)
    assert is_list(tasks)
    assert task_id in Enum.map(tasks, & &1["id"])
  end

  test "GET /tasks: returns empty list when no tasks exist" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :get
      |> authenticated_conn("/tasks")
      |> A2ARouter.call(opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == []
  end

  # ---------------------------------------------------------------------------
  # POST /tasks/:id:cancel
  # ---------------------------------------------------------------------------

  test "POST /tasks/:id:cancel: submitted task returns 200 with canceled task" do
    registry = start_registry()
    opts = build_opts(registry)

    # Submit directly via registry so we can cancel before any async worker
    # races the task into a terminal state.
    task_id = registry_submit(registry)

    conn =
      :post
      |> authenticated_conn("/tasks/#{task_id}:cancel")
      |> A2ARouter.call(opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["id"] == task_id
    assert body["status"]["state"] == "canceled"
  end

  test "POST /tasks/:id:cancel: completed task returns 400 TaskNotCancelableError" do
    registry = start_registry()
    opts = build_opts(registry)

    # Build the task state directly via the registry to avoid the async worker
    # race that would otherwise conflict with our manual state transitions.
    task_id = registry_submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    :ok = TaskRegistry.transition(task_id, :completed, nil, registry)

    conn =
      :post
      |> authenticated_conn("/tasks/#{task_id}:cancel")
      |> A2ARouter.call(opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32002
  end

  test "POST /tasks/:id:cancel: unknown id returns 404 TaskNotFoundError" do
    registry = start_registry()
    opts = build_opts(registry)

    conn =
      :post
      |> authenticated_conn("/tasks/nonexistent-task:cancel")
      |> A2ARouter.call(opts)

    assert conn.status == 404
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32001
  end

  # ---------------------------------------------------------------------------
  # Async skill execution lifecycle
  # ---------------------------------------------------------------------------

  test "async skill execution: success transitions task to :completed with artifact" do
    registry = start_registry()
    opts = build_opts(registry, OkDispatcher)

    send_conn =
      :post
      |> json_conn("/message:send", valid_message_body())
      |> A2ARouter.call(opts)

    assert send_conn.status == 202
    task_id = Jason.decode!(send_conn.resp_body)["id"]

    assert_task_state(task_id, registry, :completed, 500)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :completed
    # TaskRegistry stores the artifact in status.message on transition to :completed
    assert %Artifact{} = task.status.message
  end

  test "async skill execution: skill error transitions task to :failed" do
    registry = start_registry()
    opts = build_opts(registry, ErrDispatcher)

    send_conn =
      :post
      |> json_conn("/message:send", valid_message_body())
      |> A2ARouter.call(opts)

    assert send_conn.status == 202
    task_id = Jason.decode!(send_conn.resp_body)["id"]

    assert_task_state(task_id, registry, :failed, 500)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :failed
    assert task.status.message == :simulated_failure
  end

  # ---------------------------------------------------------------------------
  # Helpers for async tests
  # ---------------------------------------------------------------------------

  # Poll the registry until the task reaches the expected state or the deadline.
  defp assert_task_state(task_id, registry, expected_state, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    Enum.reduce_while(Stream.repeatedly(fn -> :poll end), :waiting, fn _tick, _acc ->
      case TaskRegistry.get(task_id, registry) do
        {:ok, %{status: %{state: ^expected_state}}} ->
          {:halt, :done}

        {:ok, _other} ->
          if System.monotonic_time(:millisecond) >= deadline do
            {:halt, :timeout}
          else
            Process.sleep(5)
            {:cont, :waiting}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      :done ->
        :ok

      :timeout ->
        {:ok, task} = TaskRegistry.get(task_id, registry)

        flunk(
          "Task #{task_id} did not reach state #{expected_state} " <>
            "within #{timeout_ms}ms; current: #{task.status.state}"
        )

      {:error, reason} ->
        flunk("TaskRegistry.get failed: #{inspect(reason)}")
    end
  end
end
