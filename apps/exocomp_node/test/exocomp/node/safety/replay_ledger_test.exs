defmodule Exocomp.Node.Safety.ReplayLedgerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Exocomp.Node.Safety.ReplayLedger

  @moduletag :tmp_dir

  test "first claim is durably recorded before proceeding", %{tmp_dir: tmp_dir} do
    %{server: server, table: table} = start_ledger(tmp_dir)

    assert {:ok, :proceed} = ReplayLedger.claim("nonce-1", attrs(), server)
    assert {:ok, :pending} = ReplayLedger.status("nonce-1", server)

    assert [
             {"nonce-1",
              %{
                nonce: "nonce-1",
                task_id: "task-1",
                action_id: :restart_service,
                target: "example.service",
                status: :pending,
                recorded_at: %DateTime{},
                completed_at: nil,
                result: nil
              }}
           ] = :dets.lookup(table, "nonce-1")
  end

  test "completed nonce returns the authoritative result on replay", %{tmp_dir: tmp_dir} do
    %{server: server} = start_ledger(tmp_dir)
    result = {:ok, %{restarted: true}}

    assert {:ok, :proceed} = ReplayLedger.claim("nonce-2", attrs(), server)
    assert :ok = ReplayLedger.complete("nonce-2", result, server)
    assert {:ok, :complete} = ReplayLedger.status("nonce-2", server)

    assert {:error, :already_executed, ^result} =
             ReplayLedger.claim("nonce-2", attrs(), server)
  end

  test "a duplicate claim is rejected while execution is pending", %{tmp_dir: tmp_dir} do
    %{server: server} = start_ledger(tmp_dir)

    assert {:ok, :proceed} = ReplayLedger.claim("nonce-3", attrs(), server)
    assert {:error, :incomplete_pending} = ReplayLedger.claim("nonce-3", attrs(), server)
  end

  test "concurrent duplicate claims are serialized", %{tmp_dir: tmp_dir} do
    %{server: server} = start_ledger(tmp_dir)

    tasks =
      for _index <- 1..2 do
        Task.async(fn -> ReplayLedger.claim("racing-nonce", attrs(), server) end)
      end

    results = Enum.map(tasks, &Task.await/1)

    assert Enum.count(results, &(&1 == {:ok, :proceed})) == 1
    assert Enum.count(results, &(&1 == {:error, :incomplete_pending})) == 1
  end

  test "waiters receive the result from the authoritative execution", %{tmp_dir: tmp_dir} do
    %{server: server} = start_ledger(tmp_dir)
    result = {:ok, "authoritative"}

    assert {:ok, :proceed} = ReplayLedger.claim("nonce-4", attrs(), server)

    waiter =
      Task.async(fn ->
        ReplayLedger.wait_for_result("nonce-4", 1_000, server)
      end)

    assert :ok = ReplayLedger.complete("nonce-4", result, server)
    assert {:ok, ^result} = Task.await(waiter)
    assert {:ok, ^result} = ReplayLedger.wait_for_result("nonce-4", 100, server)
  end

  test "wait_for_result times out and removes its waiter", %{tmp_dir: tmp_dir} do
    %{server: server} = start_ledger(tmp_dir)

    assert {:ok, :proceed} = ReplayLedger.claim("nonce-timeout", attrs(), server)
    assert {:error, :timeout} = ReplayLedger.wait_for_result("nonce-timeout", 10, server)
    assert :ok = ReplayLedger.complete("nonce-timeout", :late_result, server)
  end

  test "pending records fail closed after restart", %{tmp_dir: tmp_dir} do
    ledger = start_ledger(tmp_dir)

    assert {:ok, :proceed} = ReplayLedger.claim("crashed-nonce", attrs(), ledger.server)
    GenServer.stop(ledger.server)

    log =
      capture_log(fn ->
        assert {:ok, restarted} =
                 ReplayLedger.start_link(
                   name: ledger.name,
                   table: ledger.table,
                   path: ledger.path
                 )

        assert {:ok, :crashed_incomplete} =
                 ReplayLedger.status("crashed-nonce", restarted)

        assert {:error, :incomplete_pending} =
                 ReplayLedger.claim("crashed-nonce", attrs(), restarted)

        GenServer.stop(restarted)
      end)

    assert log =~ "reconciled crashed replay ledger claim"
    assert log =~ "crashed-nonce"
  end

  test "a corrupt DETS file prevents startup", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "corrupt.dets")
    File.write!(path, :crypto.strong_rand_bytes(127))
    table = unique_atom("corrupt_table")
    name = unique_atom("corrupt_server")
    previous_trap_exit = Process.flag(:trap_exit, true)

    assert {:error, {:dets_unavailable, _reason}} =
             ReplayLedger.start_link(name: name, table: table, path: path)

    Process.flag(:trap_exit, previous_trap_exit)
  end

  test "sync failure blocks execution", %{tmp_dir: tmp_dir} do
    ledger =
      start_ledger(tmp_dir,
        sync_fun: fn _table -> {:error, :injected_sync_failure} end
      )

    assert {:error, {:storage_failed, {:sync_failed, :injected_sync_failure}}} =
             ReplayLedger.claim("unsynced-nonce", attrs(), ledger.server)

    assert {:ok, :pending} = ReplayLedger.status("unsynced-nonce", ledger.server)
  end

  test "different nonces are independent", %{tmp_dir: tmp_dir} do
    %{server: server} = start_ledger(tmp_dir)

    assert {:ok, :proceed} = ReplayLedger.claim("nonce-a", attrs(), server)
    assert {:ok, :proceed} = ReplayLedger.claim("nonce-b", attrs(), server)
    assert :ok = ReplayLedger.complete("nonce-a", :result_a, server)
    assert :ok = ReplayLedger.complete("nonce-b", :result_b, server)

    assert {:error, :already_executed, :result_a} =
             ReplayLedger.claim("nonce-a", attrs(), server)

    assert {:error, :already_executed, :result_b} =
             ReplayLedger.claim("nonce-b", attrs(), server)
  end

  defp start_ledger(tmp_dir, extra_opts \\ []) do
    id = System.unique_integer([:positive])
    name = :"replay_ledger_server_#{id}"
    table = :"replay_ledger_table_#{id}"
    path = Path.join(tmp_dir, "replay_ledger_#{id}.dets")
    opts = [name: name, table: table, path: path] ++ extra_opts
    {:ok, server} = ReplayLedger.start_link(opts)

    on_exit(fn ->
      if Process.alive?(server), do: GenServer.stop(server)
    end)

    %{server: server, name: name, table: table, path: path}
  end

  defp attrs do
    %{
      task_id: "task-1",
      action_id: :restart_service,
      target: "example.service"
    }
  end

  defp unique_atom(prefix) do
    :"#{prefix}_#{System.unique_integer([:positive])}"
  end
end
