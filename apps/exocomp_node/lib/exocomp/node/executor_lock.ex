defmodule Exocomp.Node.ExecutorLock do
  @moduledoc """
  Per-target execution serializer.

  Tracks which targets are currently executing an action and rejects concurrent
  attempts on the same target.  This ensures that at most one action runs
  against a given service at any time, preventing double-restart races and
  conflicting log-vacuum executions.

  ## Usage

      # Acquire a lock before executing:
      case ExecutorLock.acquire(server, target) do
        :ok ->
          try do
            # ... run the action ...
          after
            ExecutorLock.release(server, target)
          end

        {:error, :concurrent_execution} ->
          {:error, :concurrent_execution}
      end

  The server is started under the `Exocomp.Node.Supervisor` with the
  registered name `Exocomp.Node.ExecutorLock`.  Tests may start their own
  instance by calling `start_link([])` directly.
  """

  use GenServer

  @doc """
  Start the lock server.

  If `:name` is provided in `opts`, the process is registered under that name.
  When no `:name` is given (e.g., in tests that start an isolated instance),
  the process is started anonymously and the returned `pid` must be passed
  explicitly to `acquire/2` and `release/2`.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    gen_opts =
      case Keyword.get(opts, :name) do
        nil -> []
        name -> [name: name]
      end

    GenServer.start_link(__MODULE__, MapSet.new(), gen_opts)
  end

  @doc """
  Attempt to acquire the execution lock for `target`.

  Returns `:ok` if no execution is currently in progress for `target`, and
  registers the target as in-progress.

  Returns `{:error, :concurrent_execution}` if `target` already has an
  in-progress execution.  The caller should surface this as a transient error.
  """
  @spec acquire(GenServer.server(), target :: String.t()) ::
          :ok | {:error, :concurrent_execution}
  def acquire(server \\ __MODULE__, target) when is_binary(target) do
    GenServer.call(server, {:acquire, target})
  end

  @doc """
  Release the execution lock for `target`.

  Must be called after every `acquire/2` — including when execution fails.
  Safe to call even if the target is not currently locked (no-op).
  """
  @spec release(GenServer.server(), target :: String.t()) :: :ok
  def release(server \\ __MODULE__, target) when is_binary(target) do
    GenServer.call(server, {:release, target})
  end

  @doc """
  Return the set of targets currently locked (for inspection / debugging).
  """
  @spec locked_targets(GenServer.server()) :: MapSet.t(String.t())
  def locked_targets(server \\ __MODULE__) do
    GenServer.call(server, :locked_targets)
  end

  # ── GenServer callbacks ──────────────────────────────────────────────────

  @impl true
  def init(initial_set), do: {:ok, initial_set}

  @impl true
  def handle_call({:acquire, target}, _from, in_progress) do
    if MapSet.member?(in_progress, target) do
      {:reply, {:error, :concurrent_execution}, in_progress}
    else
      {:reply, :ok, MapSet.put(in_progress, target)}
    end
  end

  def handle_call({:release, target}, _from, in_progress) do
    {:reply, :ok, MapSet.delete(in_progress, target)}
  end

  def handle_call(:locked_targets, _from, in_progress) do
    {:reply, in_progress, in_progress}
  end
end
