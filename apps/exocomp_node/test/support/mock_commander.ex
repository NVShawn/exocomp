defmodule Exocomp.Node.MockCommander do
  @moduledoc """
  Test double for `Exocomp.Node.OsCommander`.

  Stores a queue of canned responses in an unlinked Agent.  Each call to the
  commander function pops the front of the queue; when the queue is empty,
  `{:ok, "", 0}` is returned as a fallback.

  ## Usage in tests

      setup do
        {:ok, mock} = MockCommander.start()
        commander_fn = MockCommander.as_commander(mock)

        previous = Application.get_env(:exocomp_node, :os_commander)
        Application.put_env(:exocomp_node, :os_commander, commander_fn)

        on_exit(fn ->
          if previous,
            do: Application.put_env(:exocomp_node, :os_commander, previous),
            else: Application.delete_env(:exocomp_node, :os_commander)
          MockCommander.stop(mock)
        end)

        %{mock: mock}
      end

      test "some behaviour", %{mock: mock} do
        MockCommander.push(mock, {:ok, "Restarted.", 0})
        # ...
      end

  ## Why Agent.start (not start_link)?

  Using `Agent.start` avoids linking the agent to the test process.  If the
  test body exits (normally or via error), the agent stays alive so the
  `on_exit` callback can call `stop/1` cleanly.  Without this, the test
  process exit kills the linked agent before `on_exit` fires, causing a
  spurious `no process` exit in the cleanup callback.
  """

  @type response :: Exocomp.Node.OsCommander.run_result()

  @doc "Start an anonymous unlinked mock agent."
  @spec start(responses :: [response()]) :: {:ok, pid()}
  def start(responses \\ []) do
    # Agent.start (not start_link) — the agent is NOT linked to the caller.
    Agent.start(fn -> {:queue.from_list(responses), []} end)
  end

  @doc "Stop the mock agent.  Safe to call even if the process is already dead."
  @spec stop(pid()) :: :ok
  def stop(agent) do
    if Process.alive?(agent), do: Agent.stop(agent)
    :ok
  end

  @doc "Push a canned response onto the back of the queue."
  @spec push(pid(), response()) :: :ok
  def push(agent, response) do
    Agent.update(agent, fn {q, calls} -> {:queue.in(response, q), calls} end)
  end

  @doc "Return the recorded calls in FIFO order (oldest first)."
  @spec calls(pid()) :: [{executable :: String.t(), argv :: [String.t()], opts :: keyword()}]
  def calls(agent) do
    Agent.get(agent, fn {_q, calls} -> Enum.reverse(calls) end)
  end

  @doc """
  Return a 3-arity commander function that dispatches to this mock agent.

  Pass the returned function to `Application.put_env(:exocomp_node,
  :os_commander, fun)`.  The `Executor` accepts both module atoms and
  3-arity functions as commanders.
  """
  @spec as_commander(pid()) :: (String.t(), [String.t()], keyword() -> response())
  def as_commander(agent) do
    fn executable, argv, opts ->
      Agent.get_and_update(agent, fn {q, calls} ->
        new_calls = [{executable, argv, opts} | calls]

        case :queue.out(q) do
          {{:value, response}, q2} -> {response, {q2, new_calls}}
          {:empty, q2} -> {{:ok, "", 0}, {q2, new_calls}}
        end
      end)
    end
  end
end
