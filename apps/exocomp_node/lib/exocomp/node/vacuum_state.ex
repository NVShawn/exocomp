defmodule Exocomp.Node.VacuumState do
  @moduledoc """
  GenServer that tracks per-mount-point vacuum execution state.

  Maintains `last_executed_at` and `consecutive_failure_count` for each mount
  point.  This state is consulted by `VacuumBounds.check_eligible/1` to enforce
  cooldown and retry limits before a vacuum action is permitted.

  ## State per mount point

  | Key                        | Type            | Description                               |
  |----------------------------|-----------------|-------------------------------------------|
  | `last_executed_at`         | `DateTime.t()`  | UTC timestamp of the last *successful* run |
  | `consecutive_failure_count`| `non_neg_integer`| Consecutive failures since last success   |

  Both fields start at `nil` / `0` when a mount point is first seen.

  ## Registration

  The server registers under its own module name so callers do not need to
  track the PID.  A test can start a private instance by passing
  `name: nil` in options.
  """

  use GenServer

  @type mount_point :: String.t()

  @type mount_state :: %{
          last_executed_at: DateTime.t() | nil,
          consecutive_failure_count: non_neg_integer()
        }

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Start the GenServer.

  By default registers under `#{__MODULE__}`.  Pass `name: nil` to start an
  anonymous process (useful in tests where each test manages its own instance).
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, :ok, gen_opts ++ opts)
  end

  @doc """
  Return the current state for `mount_point`.

  Returns `%{last_executed_at: nil, consecutive_failure_count: 0}` for mount
  points that have never been seen.
  """
  @spec get_state(GenServer.server(), mount_point()) :: mount_state()
  def get_state(server \\ __MODULE__, mount_point) do
    GenServer.call(server, {:get_state, mount_point})
  end

  @doc """
  Record a successful vacuum execution for `mount_point`.

  Updates `last_executed_at` to the current UTC time and resets
  `consecutive_failure_count` to 0.
  """
  @spec record_success(GenServer.server(), mount_point()) :: :ok
  def record_success(server \\ __MODULE__, mount_point) do
    GenServer.call(server, {:record_success, mount_point})
  end

  @doc """
  Record a failed vacuum execution for `mount_point`.

  Increments `consecutive_failure_count` without touching `last_executed_at`.
  """
  @spec record_failure(GenServer.server(), mount_point()) :: :ok
  def record_failure(server \\ __MODULE__, mount_point) do
    GenServer.call(server, {:record_failure, mount_point})
  end

  @doc """
  Reset state for `mount_point` (or all state when `mount_point` is `:all`).

  Intended for testing only — not part of the production workflow.
  """
  @spec reset(GenServer.server(), mount_point() | :all) :: :ok
  def reset(server \\ __MODULE__, mount_point_or_all) do
    GenServer.call(server, {:reset, mount_point_or_all})
  end

  # ── GenServer callbacks ───────────────────────────────────────────────────

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_state, mount_point}, _from, state) do
    entry = Map.get(state, mount_point, default_entry())
    {:reply, entry, state}
  end

  def handle_call({:record_success, mount_point}, _from, state) do
    entry = %{last_executed_at: DateTime.utc_now(), consecutive_failure_count: 0}
    {:reply, :ok, Map.put(state, mount_point, entry)}
  end

  def handle_call({:record_failure, mount_point}, _from, state) do
    entry = Map.get(state, mount_point, default_entry())
    new_count = entry.consecutive_failure_count + 1
    updated = %{entry | consecutive_failure_count: new_count}
    {:reply, :ok, Map.put(state, mount_point, updated)}
  end

  def handle_call({:reset, :all}, _from, _state) do
    {:reply, :ok, %{}}
  end

  def handle_call({:reset, mount_point}, _from, state) do
    {:reply, :ok, Map.delete(state, mount_point)}
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  defp default_entry do
    %{last_executed_at: nil, consecutive_failure_count: 0}
  end
end
