defmodule Exocomp.Node.Safety.ReplayLedger do
  @moduledoc """
  Durable write-ahead ledger for approved executions.

  A nonce is persisted and synced before `claim/2` permits execution. Records
  left pending by a node crash are reconciled as `:crashed_incomplete` and
  remain consumed, so approved actions are never automatically retried.
  """

  use GenServer

  require Logger

  @default_table :exocomp_replay_ledger

  defstruct [:table, :dets, :sync_fun, waiters: %{}]

  @type ledger_status :: :not_found | :pending | :complete | :crashed_incomplete
  @type storage_error :: {:storage_failed, term()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec claim(binary(), map()) ::
          {:ok, :proceed}
          | {:error, :already_executed, term()}
          | {:error, :incomplete_pending}
          | {:error, storage_error()}
  def claim(nonce, attrs), do: claim(nonce, attrs, __MODULE__)

  @doc false
  @spec claim(binary(), map(), GenServer.server()) ::
          {:ok, :proceed}
          | {:error, :already_executed, term()}
          | {:error, :incomplete_pending}
          | {:error, storage_error()}
  def claim(nonce, attrs, server) when is_binary(nonce) and is_map(attrs) do
    GenServer.call(server, {:claim, nonce, attrs})
  end

  @spec complete(binary(), term()) :: :ok | {:error, storage_error()}
  def complete(nonce, result), do: complete(nonce, result, __MODULE__)

  @doc false
  @spec complete(binary(), term(), GenServer.server()) :: :ok | {:error, storage_error()}
  def complete(nonce, result, server) when is_binary(nonce) do
    GenServer.call(server, {:complete, nonce, result})
  end

  @spec wait_for_result(binary(), pos_integer()) ::
          {:ok, term()} | {:error, :timeout}
  def wait_for_result(nonce, timeout_ms),
    do: wait_for_result(nonce, timeout_ms, __MODULE__)

  @doc false
  @spec wait_for_result(binary(), pos_integer(), GenServer.server()) ::
          {:ok, term()} | {:error, :timeout}
  def wait_for_result(nonce, timeout_ms, server)
      when is_binary(nonce) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(server, {:wait_for_result, nonce, timeout_ms}, timeout_ms + 1_000)
  end

  @spec status(binary()) :: {:ok, ledger_status()}
  def status(nonce), do: status(nonce, __MODULE__)

  @doc false
  @spec status(binary(), GenServer.server()) :: {:ok, ledger_status()}
  def status(nonce, server) when is_binary(nonce) do
    GenServer.call(server, {:status, nonce})
  end

  @impl true
  def init(opts) do
    table = Keyword.get(opts, :table, @default_table)
    path = Keyword.get(opts, :path, Application.fetch_env!(:exocomp_node, :replay_ledger_path))
    dets = Keyword.get(opts, :dets_module, :dets)
    sync_fun = Keyword.get(opts, :sync_fun, &dets.sync/1)

    case dets.open_file(table, file: String.to_charlist(path), type: :set) do
      {:ok, ^table} ->
        state = %__MODULE__{table: table, dets: dets, sync_fun: sync_fun}

        case reconcile_pending(state) do
          :ok ->
            {:ok, state}

          {:error, reason} ->
            dets.close(table)
            {:stop, {:dets_unavailable, reason}}
        end

      {:error, reason} ->
        {:stop, {:dets_unavailable, reason}}
    end
  rescue
    error -> {:stop, {:dets_unavailable, error}}
  catch
    kind, reason -> {:stop, {:dets_unavailable, {kind, reason}}}
  end

  @impl true
  def handle_call({:claim, nonce, attrs}, _from, state) do
    case lookup(state, nonce) do
      {:ok, nil} ->
        claim_new(state, nonce, attrs)

      {:ok, %{status: :complete, result: result}} ->
        {:reply, {:error, :already_executed, result}, state}

      {:ok, _consumed_record} ->
        {:reply, {:error, :incomplete_pending}, state}

      {:error, reason} ->
        {:reply, storage_failed(reason), state}
    end
  end

  def handle_call({:complete, nonce, result}, _from, state) do
    case lookup(state, nonce) do
      {:ok, %{status: :pending} = record} ->
        complete_record(state, nonce, record, result)

      {:ok, _record} ->
        {:reply, storage_failed(:not_pending), state}

      {:error, reason} ->
        {:reply, storage_failed(reason), state}
    end
  end

  def handle_call({:wait_for_result, nonce, timeout_ms}, from, state) do
    case lookup(state, nonce) do
      {:ok, %{status: :complete, result: result}} ->
        {:reply, {:ok, result}, state}

      {:ok, nil} ->
        {:noreply, add_waiter(state, nonce, from, timeout_ms)}

      {:ok, _record} ->
        {:noreply, add_waiter(state, nonce, from, timeout_ms)}

      {:error, _reason} ->
        {:reply, {:error, :timeout}, state}
    end
  end

  def handle_call({:status, nonce}, _from, state) do
    status =
      case lookup(state, nonce) do
        {:ok, nil} -> :not_found
        {:ok, %{status: value}} -> value
        {:error, _reason} -> :crashed_incomplete
      end

    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_info({:waiter_timeout, nonce, waiter_id}, state) do
    {waiter, state} = pop_waiter(state, nonce, waiter_id)

    if waiter do
      {_waiter_id, _timer_ref, from} = waiter
      GenServer.reply(from, {:error, :timeout})
    end

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{dets: dets, table: table}) do
    dets.close(table)
    :ok
  end

  defp claim_new(state, nonce, attrs) do
    with {:ok, record} <- new_record(nonce, attrs),
         :ok <- insert(state, {nonce, record}),
         :ok <- sync(state) do
      {:reply, {:ok, :proceed}, state}
    else
      {:error, reason} -> {:reply, storage_failed(reason), state}
    end
  end

  defp complete_record(state, nonce, record, result) do
    completed = %{
      record
      | status: :complete,
        completed_at: DateTime.utc_now(),
        result: result
    }

    with :ok <- insert(state, {nonce, completed}),
         :ok <- sync(state) do
      state = notify_waiters(state, nonce, result)
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, storage_failed(reason), state}
    end
  end

  defp new_record(nonce, attrs) do
    with {:ok, task_id} <- fetch_attr(attrs, :task_id),
         {:ok, action_id} <- fetch_attr(attrs, :action_id),
         {:ok, target} <- fetch_attr(attrs, :target) do
      {:ok,
       %{
         nonce: nonce,
         task_id: task_id,
         action_id: action_id,
         target: target,
         status: :pending,
         recorded_at: DateTime.utc_now(),
         completed_at: nil,
         result: nil
       }}
    else
      :error -> {:error, :invalid_attributes}
    end
  end

  defp fetch_attr(attrs, key) do
    case Map.fetch(attrs, key) do
      :error -> Map.fetch(attrs, Atom.to_string(key))
      found -> found
    end
  end

  defp reconcile_pending(state) do
    pending =
      state.dets.foldl(
        fn
          {nonce, %{status: :pending} = record}, records -> [{nonce, record} | records]
          _record, records -> records
        end,
        [],
        state.table
      )

    result =
      Enum.reduce_while(pending, :ok, fn {nonce, record}, :ok ->
        Logger.warning(
          "reconciled crashed replay ledger claim " <>
            "nonce=#{inspect(nonce)} action=#{inspect(record.action_id)} " <>
            "target=#{inspect(record.target)}"
        )

        reconciled = %{record | status: :crashed_incomplete}

        case insert(state, {nonce, reconciled}) do
          :ok -> {:cont, :ok}
          {:error, _reason} = error -> {:halt, error}
        end
      end)

    case {pending, result} do
      {[], :ok} -> :ok
      {_, :ok} -> sync(state)
      {_, {:error, _reason} = error} -> error
    end
  rescue
    error -> {:error, {:fold_failed, error}}
  catch
    kind, reason -> {:error, {:fold_failed, {kind, reason}}}
  end

  defp lookup(state, nonce) do
    case state.dets.lookup(state.table, nonce) do
      [] -> {:ok, nil}
      [{^nonce, record}] when is_map(record) -> {:ok, record}
      other -> {:error, {:invalid_record, other}}
    end
  rescue
    error -> {:error, {:lookup_failed, error}}
  catch
    kind, reason -> {:error, {:lookup_failed, {kind, reason}}}
  end

  defp insert(state, object) do
    case state.dets.insert(state.table, object) do
      :ok -> :ok
      {:error, reason} -> {:error, {:write_failed, reason}}
      other -> {:error, {:write_failed, other}}
    end
  rescue
    error -> {:error, {:write_failed, error}}
  catch
    kind, reason -> {:error, {:write_failed, {kind, reason}}}
  end

  defp sync(state) do
    case state.sync_fun.(state.table) do
      :ok -> :ok
      {:error, reason} -> {:error, {:sync_failed, reason}}
      other -> {:error, {:sync_failed, other}}
    end
  rescue
    error -> {:error, {:sync_failed, error}}
  catch
    kind, reason -> {:error, {:sync_failed, {kind, reason}}}
  end

  defp add_waiter(state, nonce, from, timeout_ms) do
    waiter_id = make_ref()
    timer_ref = Process.send_after(self(), {:waiter_timeout, nonce, waiter_id}, timeout_ms)
    waiter = {waiter_id, timer_ref, from}
    waiters = Map.update(state.waiters, nonce, [waiter], &[waiter | &1])
    %{state | waiters: waiters}
  end

  defp pop_waiter(state, nonce, waiter_id) do
    {matching, remaining} =
      state.waiters
      |> Map.get(nonce, [])
      |> Enum.split_with(fn {id, _timer_ref, _from} -> id == waiter_id end)

    waiters =
      if remaining == [],
        do: Map.delete(state.waiters, nonce),
        else: Map.put(state.waiters, nonce, remaining)

    {List.first(matching), %{state | waiters: waiters}}
  end

  defp notify_waiters(state, nonce, result) do
    {waiters, remaining} = Map.pop(state.waiters, nonce, [])

    Enum.each(waiters, fn {_waiter_id, timer_ref, from} ->
      Process.cancel_timer(timer_ref)
      GenServer.reply(from, {:ok, result})
    end)

    %{state | waiters: remaining}
  end

  defp storage_failed(reason), do: {:error, {:storage_failed, reason}}
end
