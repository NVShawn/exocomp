# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Safety.ApprovalGateTest do
  @moduledoc """
  Comprehensive focused test suite for `Exocomp.Node.Safety.ApprovalGate`.

  Covers all 15 scenarios from the Milestone 3 test strategy:

  Unit / isolation tests (stub one layer at a time):
    5.  Wrong node_id → token_invalid binding_mismatch
    6.  Wrong task_id → token_invalid binding_mismatch
    7.  Wrong action_id → token_invalid binding_mismatch
    8.  Wrong parameters (parameter_hash mismatch) → token_invalid
    9.  Wrong evidence in token (evidence_hash mismatch) → precondition_changed
   10.  Expired token → token_invalid :expired
   11.  Changed precondition (collection fails or hash differs) → precondition_changed
   12.  Storage corruption (DETS sync fails) → replay_state_unavailable, no execution
   13.  Interrupted persistence (sync fails after :pending write) → no execution

  Integration tests (real verifier + real checker + real ledger + mock commander):
    1.  First use: valid token, fresh nonce → executes, ledger records :complete
    2.  Concurrent duplicate: one executes, other receives authoritative result
    3.  Sequential replay: same token again after completion → already_executed
    4.  Replay after restart: pending nonce not re-executed after ledger restart
   14.  Signature tampered → token_invalid :invalid_signature
   15.  Coordinator public key missing → token_invalid :public_key_unavailable
  """

  use ExUnit.Case, async: false

  @moduletag :tmp_dir

  import ExUnit.CaptureLog

  alias Exocomp.Core.ApprovalToken
  alias Exocomp.Node.Executor
  alias Exocomp.Node.ExecutorLock
  alias Exocomp.Node.MockCommander
  alias Exocomp.Node.Safety.ApprovalGate
  alias Exocomp.Node.Safety.ApprovalVerifier
  alias Exocomp.Node.Safety.PreconditionChecker
  alias Exocomp.Node.Safety.ReplayLedger

  # ---------------------------------------------------------------------------
  # Stub modules used in isolation tests
  #
  # The gate runs synchronously in the test process, so stubs configure their
  # behaviour via the process dictionary — no inter-process coordination needed.
  # ---------------------------------------------------------------------------

  defmodule StubVerifier do
    @moduledoc "Configurable verifier stub. Set :stub_verifier in the process dict."

    # Well-known nonce so tests can assert on ledger state.
    @nonce "unit-test-nonce-00"
    @evidence_hash "a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0"

    def verify(_token_wire, _ctx) do
      case Process.get(:stub_verifier, :pass) do
        :pass ->
          {:ok, %{payload: %{nonce: @nonce, evidence_hash: @evidence_hash}, signature: "stub"}}

        {:pass_with, token} ->
          {:ok, token}

        {:fail, reason} ->
          {:error, reason}
      end
    end

    def default_nonce, do: @nonce
    def default_evidence_hash, do: @evidence_hash
  end

  defmodule StubChecker do
    @moduledoc "Configurable precondition checker stub. Set :stub_checker in process dict."

    def verify(_payload, _action_id, _target) do
      Process.get(:stub_checker, :ok)
    end
  end

  defmodule StubExecutor do
    @moduledoc "Configurable executor stub. Set :stub_executor in process dict."

    @default_result %{
      action_id: :restart_service,
      target: "example.service",
      output: "",
      exit_code: 0,
      verified: true
    }

    def execute(_action_id, _target, _allow_list) do
      key = {__MODULE__, :calls, self()}
      Process.put(key, Process.get(key, 0) + 1)
      Process.get(:stub_executor, {:ok, @default_result})
    end

    def call_count, do: Process.get({__MODULE__, :calls, self()}, 0)
    def default_result, do: @default_result
  end

  # Injected as :precondition_evidence_collector in integration tests.
  defmodule MockEvidenceCollector do
    @behaviour PreconditionChecker

    @impl true
    def collect(_action_id, _target) do
      {:ok, default_evidence()}
    end

    def default_evidence do
      %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => "example.service"
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------------

  @allow_list ["example.service"]

  defp base_context(overrides \\ %{}) do
    Map.merge(
      %{
        node_id: "node-test-1",
        task_id: "task-test-1",
        correlation_id: "corr-test-1",
        action_id: :restart_service,
        target: "example.service",
        parameters: %{"unit" => "example.service"},
        allow_list: @allow_list
      },
      overrides
    )
  end

  # Gate opts for isolation tests: stubs for all four dependencies.
  defp stub_opts(ledger_pid, extra \\ []) do
    [
      verifier: StubVerifier,
      checker: StubChecker,
      executor: StubExecutor,
      ledger: ledger_pid,
      wait_timeout_ms: 500
    ] ++ extra
  end

  # Start an isolated ReplayLedger for a single test; registers cleanup.
  defp start_ledger(tmp_dir, extra_opts \\ []) do
    id = System.unique_integer([:positive])
    name = :"gate_test_ledger_#{id}"
    table = :"gate_test_table_#{id}"
    path = Path.join(tmp_dir, "gate_ledger_#{id}.dets")
    opts = [name: name, table: table, path: path] ++ extra_opts
    {:ok, server} = ReplayLedger.start_link(opts)

    on_exit(fn ->
      if Process.alive?(server), do: GenServer.stop(server)
    end)

    %{server: server, name: name, table: table, path: path}
  end

  # Build a valid token payload with dynamic timestamps so tokens are always live.
  defp good_payload(evidence_hash, overrides \\ %{}) do
    now = DateTime.utc_now()

    base = %{
      schema_version: "1",
      nonce: Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
      node_id: "node-test-1",
      task_id: "task-test-1",
      correlation_id: "corr-test-1",
      action_id: "restart_service",
      parameter_hash: ApprovalToken.hash_params(%{"unit" => "example.service"}),
      evidence_hash: evidence_hash,
      issued_at: now |> DateTime.add(-30, :second) |> DateTime.to_iso8601(),
      expires_at: now |> DateTime.add(3_600, :second) |> DateTime.to_iso8601(),
      operator: "operator@example.com"
    }

    Map.merge(base, overrides)
  end

  # Sign a token payload with the given Ed25519 private key.
  defp signed_token(payload, private_key) do
    signature =
      :crypto.sign(:eddsa, :none, ApprovalToken.canonical_encode(payload), [
        private_key,
        :ed25519
      ])

    %{payload: payload, signature: signature}
  end

  # Push two canned MockCommander responses for a successful service restart.
  defp push_successful_restart(mock) do
    # restart_service command succeeds.
    MockCommander.push(mock, {:ok, "", 0})
    # Post-action verifier (is-active --quiet) succeeds.
    MockCommander.push(mock, {:ok, "", 0})
  end

  # ---------------------------------------------------------------------------
  # Integration test setup
  # ---------------------------------------------------------------------------

  defp setup_integration(%{tmp_dir: tmp_dir}) do
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    key_path = Path.join(tmp_dir, "coordinator-approval.key")
    File.write!(key_path, public_key)

    prev_key = Application.get_env(:exocomp_node, :approval_public_key_path)
    Application.put_env(:exocomp_node, :approval_public_key_path, key_path)

    prev_collector = Application.get_env(:exocomp_node, :precondition_evidence_collector)
    Application.put_env(:exocomp_node, :precondition_evidence_collector, MockEvidenceCollector)

    {:ok, mock} = MockCommander.start()
    commander_fn = MockCommander.as_commander(mock)
    prev_commander = Application.get_env(:exocomp_node, :os_commander)
    Application.put_env(:exocomp_node, :os_commander, commander_fn)

    {:ok, lock} = ExecutorLock.start_link([])
    ledger = start_ledger(tmp_dir)

    evidence_hash = ApprovalToken.hash_evidence(MockEvidenceCollector.default_evidence())

    # 3-arity executor closure that routes to the real Executor + isolated lock.
    executor_fn = fn action_id, target, allow_list ->
      Executor.execute(action_id, target, allow_list, lock_server: lock)
    end

    on_exit(fn ->
      if prev_key,
        do: Application.put_env(:exocomp_node, :approval_public_key_path, prev_key),
        else: Application.delete_env(:exocomp_node, :approval_public_key_path)

      if prev_collector,
        do: Application.put_env(:exocomp_node, :precondition_evidence_collector, prev_collector),
        else: Application.delete_env(:exocomp_node, :precondition_evidence_collector)

      if prev_commander,
        do: Application.put_env(:exocomp_node, :os_commander, prev_commander),
        else: Application.delete_env(:exocomp_node, :os_commander)

      MockCommander.stop(mock)
      if Process.alive?(lock), do: GenServer.stop(lock)
    end)

    %{
      private_key: private_key,
      key_path: key_path,
      evidence_hash: evidence_hash,
      mock: mock,
      lock: lock,
      ledger: ledger,
      executor_fn: executor_fn
    }
  end

  # Gate opts for integration tests.
  # extra keys come FIRST so Keyword.get/3 returns them over the defaults below.
  defp integration_opts(extra, ctx) do
    extra ++
      [
        verifier: ApprovalVerifier,
        checker: PreconditionChecker,
        executor: ctx.executor_fn,
        ledger: ctx.ledger.server,
        wait_timeout_ms: 3_000
      ]
  end

  # ===========================================================================
  # Scenario 1 — First use
  # ===========================================================================

  describe "scenario 1: first use (integration)" do
    setup :setup_integration

    test "valid token, fresh nonce → executes and ledger records :complete", ctx do
      %{private_key: pk, evidence_hash: eh, mock: mock, ledger: ledger} = ctx

      payload = good_payload(eh)
      nonce = payload.nonce
      token = signed_token(payload, pk)

      push_successful_restart(mock)

      assert {:ok, exec_result} =
               ApprovalGate.execute(token, base_context(), integration_opts([], ctx))

      assert exec_result.action_id == :restart_service
      assert exec_result.target == "example.service"
      assert exec_result.exit_code == 0
      assert exec_result.verified == true

      # Ledger must durably record the nonce as :complete.
      assert {:ok, :complete} = ReplayLedger.status(nonce, ledger.server)
    end
  end

  # ===========================================================================
  # Scenario 2 — Concurrent duplicate
  # ===========================================================================

  describe "scenario 2: concurrent duplicate (integration)" do
    setup :setup_integration

    test "two concurrent calls with same token → one executes, other gets same result", ctx do
      %{private_key: pk, evidence_hash: eh, mock: mock, ledger: ledger} = ctx

      payload = good_payload(eh)
      nonce = payload.nonce
      token = signed_token(payload, pk)

      test_pid = self()

      # Slow executor: signals when it has started, then waits for a :proceed message.
      slow_executor = fn action_id, target, allow_list ->
        send(test_pid, {:executor_running, self()})

        receive do
          :proceed -> Executor.execute(action_id, target, allow_list, lock_server: ctx.lock)
        after
          5_000 -> {:error, :test_executor_timeout}
        end
      end

      opts = integration_opts([executor: slow_executor], ctx)

      push_successful_restart(mock)

      # Task 1 claims the ledger and enters the slow executor.
      t1 = Task.async(fn -> ApprovalGate.execute(token, base_context(), opts) end)

      # Wait until Task 1 is executing (its nonce is now :pending in the ledger).
      assert_receive {:executor_running, exec_pid}, 3_000

      # Task 2 starts — it will find the nonce :pending → wait_for_result.
      t2 = Task.async(fn -> ApprovalGate.execute(token, base_context(), opts) end)

      # Give Task 2 time to reach wait_for_result before we release Task 1.
      Process.sleep(50)

      # Release Task 1's executor.
      send(exec_pid, :proceed)

      r1 = Task.await(t1, 5_000)
      r2 = Task.await(t2, 5_000)

      # Both callers get the same successful result.
      assert {:ok, %{action_id: :restart_service, verified: true}} = r1
      assert r1 == r2

      # Executor invoked exactly once (one restart command + one is-active).
      restart_calls =
        MockCommander.calls(mock)
        |> Enum.filter(fn {_exe, argv, _opts} -> "restart" in argv end)

      assert length(restart_calls) == 1

      # Ledger records the nonce as :complete.
      assert {:ok, :complete} = ReplayLedger.status(nonce, ledger.server)
    end
  end

  # ===========================================================================
  # Scenario 3 — Sequential replay
  # ===========================================================================

  describe "scenario 3: sequential replay (integration)" do
    setup :setup_integration

    test "same token presented again after completion → already_executed error", ctx do
      %{private_key: pk, evidence_hash: eh, mock: mock} = ctx

      payload = good_payload(eh)
      token = signed_token(payload, pk)
      opts = integration_opts([], ctx)

      push_successful_restart(mock)

      assert {:ok, exec_result} = ApprovalGate.execute(token, base_context(), opts)

      # Second presentation: no new commands should run; ledger returns already_executed.
      assert {:error, {:already_executed, {:ok, ^exec_result}}} =
               ApprovalGate.execute(token, base_context(), opts)
    end
  end

  # ===========================================================================
  # Scenario 4 — Replay after restart
  # ===========================================================================

  describe "scenario 4: replay after restart (integration)" do
    setup :setup_integration

    test "pending nonce after ledger restart is NOT re-executed", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx
      ledger = ctx.ledger

      payload = good_payload(eh)
      nonce = payload.nonce
      token = signed_token(payload, pk)

      # Record the nonce as :pending without completing (simulates mid-execution crash).
      assert {:ok, :proceed} =
               ReplayLedger.claim(
                 nonce,
                 %{
                   task_id: "task-test-1",
                   action_id: :restart_service,
                   target: "example.service"
                 },
                 ledger.server
               )

      assert {:ok, :pending} = ReplayLedger.status(nonce, ledger.server)

      # Simulate node restart: stop then restart the ledger with the same DETS file.
      GenServer.stop(ledger.server)

      id2 = System.unique_integer([:positive])

      {:ok, restarted} =
        ReplayLedger.start_link(
          name: :"gate_test_restarted_#{id2}",
          table: ledger.table,
          path: ledger.path
        )

      on_exit(fn ->
        if Process.alive?(restarted), do: GenServer.stop(restarted)
      end)

      # After restart, :pending → :crashed_incomplete.
      assert {:ok, :crashed_incomplete} = ReplayLedger.status(nonce, restarted)

      # Present the same token to the gate backed by the restarted ledger.
      opts = integration_opts([ledger: restarted, wait_timeout_ms: 200], ctx)

      result = ApprovalGate.execute(token, base_context(), opts)

      # The gate MUST NOT re-execute.
      # :crashed_incomplete → :incomplete_pending from claim → wait_for_result times out
      # → :replay_state_unavailable.
      assert result == {:error, :replay_state_unavailable} or
               match?({:error, {:already_executed, _}}, result)

      # Executor was NOT invoked (no restart commands in mock).
      restart_calls =
        MockCommander.calls(ctx.mock)
        |> Enum.filter(fn {_exe, argv, _opts} -> "restart" in argv end)

      assert restart_calls == []
    end
  end

  # ===========================================================================
  # Scenarios 5–8, 10 — Token verification failures (isolation, stub verifier)
  # ===========================================================================

  describe "token binding mismatch errors (isolation)" do
    setup %{tmp_dir: tmp_dir} do
      {:ok, ledger: start_ledger(tmp_dir)}
    end

    # Scenario 5
    test "wrong node_id → token_invalid binding_mismatch :node_id", %{ledger: ledger} do
      Process.put(:stub_verifier, {:fail, {:binding_mismatch, :node_id, "node-test-1", "wrong"}})

      assert {:error, {:token_invalid, {:binding_mismatch, :node_id, _expected, _actual}}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end

    # Scenario 6
    test "wrong task_id → token_invalid binding_mismatch :task_id", %{ledger: ledger} do
      Process.put(
        :stub_verifier,
        {:fail, {:binding_mismatch, :task_id, "task-test-1", "wrong-task"}}
      )

      assert {:error, {:token_invalid, {:binding_mismatch, :task_id, _expected, _actual}}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end

    # Scenario 7
    test "wrong action_id → token_invalid binding_mismatch :action_id", %{ledger: ledger} do
      Process.put(
        :stub_verifier,
        {:fail, {:binding_mismatch, :action_id, "restart_service", "vacuum_logs"}}
      )

      assert {:error, {:token_invalid, {:binding_mismatch, :action_id, _expected, _actual}}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end

    # Scenario 8
    test "wrong parameters → token_invalid binding_mismatch :parameter_hash", %{ledger: ledger} do
      Process.put(
        :stub_verifier,
        {:fail, {:binding_mismatch, :parameter_hash, "expected-hash", "actual-hash"}}
      )

      assert {:error, {:token_invalid, {:binding_mismatch, :parameter_hash, _expected, _actual}}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end

    # Scenario 10
    test "expired token → token_invalid :expired", %{ledger: ledger} do
      Process.put(:stub_verifier, {:fail, :expired})

      assert {:error, {:token_invalid, :expired}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end
  end

  # ===========================================================================
  # Scenarios 5–8, 10 — real verifier + integration setup
  # ===========================================================================

  describe "token binding mismatches via real verifier (integration)" do
    setup :setup_integration

    test "scenario 5: wrong node_id in context → binding_mismatch :node_id", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx
      token = signed_token(good_payload(eh), pk)

      assert {:error, {:token_invalid, {:binding_mismatch, :node_id, _expected, _actual}}} =
               ApprovalGate.execute(
                 token,
                 base_context(%{node_id: "wrong-node"}),
                 integration_opts([], ctx)
               )
    end

    test "scenario 6: wrong task_id in context → binding_mismatch :task_id", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx
      token = signed_token(good_payload(eh), pk)

      assert {:error, {:token_invalid, {:binding_mismatch, :task_id, _expected, _actual}}} =
               ApprovalGate.execute(
                 token,
                 base_context(%{task_id: "wrong-task"}),
                 integration_opts([], ctx)
               )
    end

    test "scenario 7: wrong action_id in context → binding_mismatch :action_id", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx
      token = signed_token(good_payload(eh), pk)

      assert {:error, {:token_invalid, {:binding_mismatch, :action_id, _expected, _actual}}} =
               ApprovalGate.execute(
                 token,
                 base_context(%{action_id: :vacuum_logs}),
                 integration_opts([], ctx)
               )
    end

    test "scenario 8: wrong parameters in context → binding_mismatch :parameter_hash", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx
      token = signed_token(good_payload(eh), pk)

      assert {:error, {:token_invalid, {:binding_mismatch, :parameter_hash, _expected, _actual}}} =
               ApprovalGate.execute(
                 token,
                 base_context(%{parameters: %{"unit" => "other.service"}}),
                 integration_opts([], ctx)
               )
    end

    test "scenario 10: expired token → token_invalid :expired", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx

      # expires_at is 60 s in the past; the verifier uses DateTime.utc_now().
      expired_payload =
        good_payload(eh, %{
          expires_at: DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.to_iso8601()
        })

      token = signed_token(expired_payload, pk)

      assert {:error, {:token_invalid, :expired}} =
               ApprovalGate.execute(token, base_context(), integration_opts([], ctx))
    end

    # Security: empty-node_id token must not match an unconfigured node.
    # Previously build_verifier_context fell back to "" for an unconfigured node_id,
    # which meant a token signed with node_id: "" would pass the binding check on
    # any such node. The fix uses nil as the fallback so the binding always fails.
    test "scenario 5c: unconfigured node_id falls back to nil, not empty string", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx

      # A coordinator-signed token with node_id: "" — the "attack token".
      attack_payload = good_payload(eh, %{node_id: ""})
      attack_token = signed_token(attack_payload, pk)

      # Present the attack token with a context that has no node_id key.
      context_without_node = Map.delete(base_context(), :node_id)

      # Also remove node_id from the application environment so the fallback is used.
      prev = Application.get_env(:exocomp_node, :node_id)
      Application.delete_env(:exocomp_node, :node_id)

      on_exit(fn ->
        if prev,
          do: Application.put_env(:exocomp_node, :node_id, prev),
          else: Application.delete_env(:exocomp_node, :node_id)
      end)

      # The nil fallback means context node_id = nil; token node_id = "".
      # nil != "" → binding_mismatch → token rejected.
      assert {:error, {:token_invalid, _reason}} =
               ApprovalGate.execute(attack_token, context_without_node, integration_opts([], ctx))
    end
  end

  # ===========================================================================
  # Scenarios 9, 11 — Precondition failures (isolation, stub checker)
  # ===========================================================================

  describe "precondition failures (isolation)" do
    setup %{tmp_dir: tmp_dir} do
      {:ok, ledger: start_ledger(tmp_dir)}
    end

    # Scenario 9 — wrong evidence_hash in token (hash mismatch detected by checker)
    test "scenario 9: evidence_hash in token doesn't match current state → precondition_changed",
         %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, {:error, :precondition_changed})

      assert {:error, {:precondition_changed, :precondition_changed}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end

    # Scenario 11 — state has changed since approval (collection fails or different hash)
    test "scenario 11: state changed since approval → precondition_changed", %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, {:error, {:collection_failed, :state_changed}})

      assert {:error, {:precondition_changed, {:collection_failed, :state_changed}}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
    end
  end

  # Scenario 9 — real verifier + real checker with stale evidence_hash in token
  describe "scenario 9 integration: stale evidence_hash (real verifier + real checker)" do
    setup :setup_integration

    test "token signed with stale evidence_hash → precondition_changed from real checker", ctx do
      %{private_key: pk} = ctx

      # Token signed with evidence from the old (failed) state — does NOT match the
      # evidence that MockEvidenceCollector returns.
      stale_evidence = %{
        "active_state" => "failed",
        "sub_state" => "failed",
        "unit_name" => "example.service"
      }

      stale_hash = ApprovalToken.hash_evidence(stale_evidence)
      payload = good_payload(stale_hash)
      token = signed_token(payload, pk)

      assert {:error, {:precondition_changed, :precondition_changed}} =
               ApprovalGate.execute(token, base_context(), integration_opts([], ctx))
    end
  end

  # ===========================================================================
  # Scenarios 12, 13 — Replay ledger storage failures
  # ===========================================================================

  describe "replay ledger storage failures (real ledger with failing sync)" do
    # Ledger whose sync always fails.
    setup %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir, sync_fun: fn _table -> {:error, :injected_sync_failure} end)
      {:ok, ledger: ledger}
    end

    # Scenario 12 — storage corruption: claim cannot persist
    test "scenario 12: DETS sync failure on claim → replay_state_unavailable, no execution",
         %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, :ok)

      before_count = StubExecutor.call_count()

      assert {:error, :replay_state_unavailable} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))

      # Executor MUST NOT have been called.
      assert StubExecutor.call_count() == before_count
    end

    # Scenario 13 — interrupted persistence: :pending written to memory, sync fails
    test "scenario 13: sync fails after :pending write → error, nonce :pending in memory, no execution",
         %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, :ok)

      before_count = StubExecutor.call_count()

      assert {:error, :replay_state_unavailable} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))

      # The nonce was inserted into the in-memory DETS table even though fsync failed,
      # proving the write happened — it just wasn't durably stored.
      assert {:ok, :pending} =
               ReplayLedger.status(StubVerifier.default_nonce(), ledger.server)

      # Executor was NOT invoked.
      assert StubExecutor.call_count() == before_count
    end
  end

  # ===========================================================================
  # Scenario 14 — Signature tampered
  # ===========================================================================

  describe "scenario 14: tampered signature (real verifier + integration keys)" do
    setup :setup_integration

    test "one byte of the signature flipped → token_invalid :invalid_signature", ctx do
      %{private_key: pk, evidence_hash: eh} = ctx

      token = signed_token(good_payload(eh), pk)

      <<first, rest::binary>> = token.signature
      tampered = %{token | signature: <<Bitwise.bxor(first, 1), rest::binary>>}

      assert {:error, {:token_invalid, :invalid_signature}} =
               ApprovalGate.execute(tampered, base_context(), integration_opts([], ctx))
    end
  end

  # ===========================================================================
  # Scenario 15 — Coordinator public key missing
  # ===========================================================================

  describe "scenario 15: coordinator public key missing (real verifier)" do
    setup :setup_integration

    test "key file removed → token_invalid :public_key_unavailable", ctx do
      %{private_key: pk, evidence_hash: eh, key_path: key_path} = ctx

      token = signed_token(good_payload(eh), pk)

      # Remove the provisioned key file.
      File.rm!(key_path)

      assert {:error, {:token_invalid, :public_key_unavailable}} =
               ApprovalGate.execute(token, base_context(), integration_opts([], ctx))
    end
  end

  # ===========================================================================
  # Execution failure — gate records error result in ledger
  # ===========================================================================

  describe "execution failure handling" do
    setup %{tmp_dir: tmp_dir} do
      {:ok, ledger: start_ledger(tmp_dir)}
    end

    test "executor error → execution_failed returned, nonce marked :complete in ledger",
         %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, :ok)
      Process.put(:stub_executor, {:error, :not_allowed})

      assert {:error, {:execution_failed, :not_allowed}} =
               ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))

      # Nonce must be :complete (with an error result) so replays don't retry.
      assert {:ok, :complete} =
               ReplayLedger.status(StubVerifier.default_nonce(), ledger.server)
    end
  end

  # ===========================================================================
  # Ledger complete failure — gate returns exec result even if recording fails
  # ===========================================================================

  describe "ledger complete failure after successful execution" do
    test "complete fails → gate logs error but still returns {:ok, exec_result}", %{
      tmp_dir: tmp_dir
    } do
      # Sync succeeds on the first call (claim), fails on the second (complete).
      # Using :atomics for a process-independent call counter.
      counter = :atomics.new(1, [])

      sync_fn = fn _table ->
        n = :atomics.add_get(counter, 1, 1)
        if n > 1, do: {:error, :injected_complete_sync_failure}, else: :ok
      end

      ledger = start_ledger(tmp_dir, sync_fun: sync_fn)

      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, :ok)
      Process.put(:stub_executor, {:ok, StubExecutor.default_result()})

      log =
        capture_log(fn ->
          # The gate should return the exec result even though complete failed.
          assert {:ok, %{action_id: :restart_service}} =
                   ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
        end)

      # Gate must log a critical/error entry about the incomplete recording.
      assert log =~ "LEDGER_COMPLETE_FAILED"
    end
  end

  # ===========================================================================
  # Audit log format
  # ===========================================================================

  describe "audit log properties" do
    setup %{tmp_dir: tmp_dir} do
      {:ok, ledger: start_ledger(tmp_dir)}
    end

    test "token_invalid step logged with correlation_id; raw token not logged", %{ledger: ledger} do
      Process.put(:stub_verifier, {:fail, :expired})

      log =
        capture_log(fn ->
          ApprovalGate.execute(
            %{"payload" => %{}, "signature" => "SUPER_SECRET"},
            base_context(),
            stub_opts(ledger.server)
          )
        end)

      assert log =~ "token_invalid"
      assert log =~ "corr-test-1"
      refute log =~ "SUPER_SECRET"
    end

    test "successful execution path emits one log entry per step", %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, :ok)

      log =
        capture_log(fn ->
          ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
        end)

      assert log =~ "token_valid"
      assert log =~ "preconditions_ok"
      assert log =~ "replay_claimed"
      assert log =~ "execution_success"
    end

    test "nonce is truncated to 8-char prefix in all log entries", %{ledger: ledger} do
      Process.put(:stub_verifier, :pass)
      Process.put(:stub_checker, :ok)

      log =
        capture_log(fn ->
          ApprovalGate.execute(%{}, base_context(), stub_opts(ledger.server))
        end)

      # Full nonce "unit-test-nonce-00" must NOT appear; truncated form must appear.
      # safe_nonce takes binary_part(nonce, 0, 8) → "unit-tes" + "..."
      refute log =~ StubVerifier.default_nonce()
      assert log =~ "unit-tes..."
    end
  end
end
