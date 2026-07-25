# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Safety.PreconditionCheckerTest do
  @moduledoc """
  Tests for `Exocomp.Node.Safety.PreconditionChecker`.

  All evidence collection is performed via injectable mock collectors so these
  tests are fully self-contained and never invoke systemctl, df, or any other
  OS command.

  Test structure:
  - Happy path: unchanged evidence → :ok
  - Precondition changed: evidence diff → {:error, :precondition_changed}
  - Field-level sensitivity: any single field change triggers mismatch
  - Collection failure: fail closed → {:error, {:collection_failed, reason}}
  - Injectable mock collector via Application config
  - Hash byte-for-byte comparison (not semantic)
  - Field order independence in the canonical map
  - Token key format: atom keys and string keys both work
  """

  use ExUnit.Case, async: false

  alias Exocomp.Core.ApprovalToken
  alias Exocomp.Node.Safety.PreconditionChecker

  # ---------------------------------------------------------------------------
  # Mock collector infrastructure
  #
  # MockCollector stores a canned response in process dictionary so each test
  # is isolated. Tests set the response with MockCollector.set_response/1
  # before calling verify/3.
  # ---------------------------------------------------------------------------

  defmodule MockCollector do
    @moduledoc "Deterministic evidence collector for PreconditionChecker tests."

    @behaviour Exocomp.Node.Safety.PreconditionChecker

    @impl true
    def collect(action_id, target) do
      key = {__MODULE__, action_id, target}

      case Process.get(key) do
        nil ->
          default_response(action_id, target)

        response ->
          response
      end
    end

    defp default_response(:restart_service, target), do: {:ok, restart_evidence(target)}
    defp default_response(:vacuum_logs, target), do: {:ok, vacuum_evidence(target)}
    defp default_response(action_id, _target), do: {:error, {:unknown_action, action_id}}

    @doc "Store a canned collect/2 response for (action_id, target)."
    def set_response(action_id, target, response) do
      Process.put({__MODULE__, action_id, target}, response)
    end

    @doc "Returns the canonical restart_service evidence map for a unit."
    def restart_evidence(unit_name) do
      %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit_name
      }
    end

    @doc "Returns the canonical vacuum_logs evidence map for a path."
    def vacuum_evidence(path) do
      %{
        "available_bytes" => 5_000_000_000,
        "path" => path,
        "total_bytes" => 100_000_000_000
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Test setup: inject MockCollector and restore previous config on exit
  # ---------------------------------------------------------------------------

  setup do
    previous = Application.get_env(:exocomp_node, :precondition_evidence_collector)
    Application.put_env(:exocomp_node, :precondition_evidence_collector, MockCollector)

    on_exit(fn ->
      if previous do
        Application.put_env(:exocomp_node, :precondition_evidence_collector, previous)
      else
        Application.delete_env(:exocomp_node, :precondition_evidence_collector)
      end
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Helper: build a token with evidence_hash computed from a given evidence map
  # ---------------------------------------------------------------------------

  defp token_for(evidence_map) do
    %{evidence_hash: ApprovalToken.hash_evidence(evidence_map)}
  end

  defp string_key_token_for(evidence_map) do
    %{"evidence_hash" => ApprovalToken.hash_evidence(evidence_map)}
  end

  # ---------------------------------------------------------------------------
  # Happy path: evidence unchanged between approval and re-check
  # ---------------------------------------------------------------------------

  describe "verify/3 — evidence unchanged → :ok" do
    test "restart_service: active service matches token evidence" do
      unit = "sshd.service"
      evidence = MockCollector.restart_evidence(unit)
      token = token_for(evidence)

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "vacuum_logs: disk state matches token evidence" do
      path = "/var/log"
      evidence = MockCollector.vacuum_evidence(path)
      token = token_for(evidence)

      assert :ok = PreconditionChecker.verify(token, :vacuum_logs, path)
    end

    test "result is :ok when re-collecting same evidence repeatedly" do
      unit = "nginx.service"
      evidence = MockCollector.restart_evidence(unit)
      token = token_for(evidence)

      for _ <- 1..5 do
        assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Token key format: atom keys and string keys are both accepted
  # ---------------------------------------------------------------------------

  describe "verify/3 — token key format" do
    test "accepts atom-keyed token (%{evidence_hash: ...})" do
      unit = "myapp.service"
      evidence = MockCollector.restart_evidence(unit)
      token = %{evidence_hash: ApprovalToken.hash_evidence(evidence)}

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "accepts string-keyed token (%{'evidence_hash' => ...})" do
      unit = "myapp.service"
      evidence = MockCollector.restart_evidence(unit)
      token = string_key_token_for(evidence)

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end
  end

  # ---------------------------------------------------------------------------
  # Evidence changed: any state change triggers :precondition_changed
  # ---------------------------------------------------------------------------

  describe "verify/3 — service state changed → {:error, :precondition_changed}" do
    test "active_state changed from active to inactive" do
      unit = "myapp.service"

      # Token was issued when service was active
      original_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(original_evidence)

      # Service has since gone inactive
      stale_evidence = %{
        "active_state" => "inactive",
        "sub_state" => "dead",
        "unit_name" => unit
      }

      MockCollector.set_response(:restart_service, unit, {:ok, stale_evidence})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "active_state changed from active to failed" do
      unit = "worker.service"

      original_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(original_evidence)

      failed_evidence = %{
        "active_state" => "failed",
        "sub_state" => "failed",
        "unit_name" => unit
      }

      MockCollector.set_response(:restart_service, unit, {:ok, failed_evidence})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "sub_state changed while active_state stayed the same" do
      unit = "cache.service"

      original_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(original_evidence)

      # Service is still active but sub_state changed (e.g. start-pre → running)
      changed_evidence = %{
        "active_state" => "active",
        "sub_state" => "stop-sigterm",
        "unit_name" => unit
      }

      MockCollector.set_response(:restart_service, unit, {:ok, changed_evidence})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "vacuum_logs: available_bytes changed" do
      path = "/var/log"

      original_evidence = %{
        "available_bytes" => 5_000_000_000,
        "path" => path,
        "total_bytes" => 100_000_000_000
      }

      token = token_for(original_evidence)

      # Disk usage changed since approval
      changed_evidence = %{
        "available_bytes" => 3_000_000_000,
        "path" => path,
        "total_bytes" => 100_000_000_000
      }

      MockCollector.set_response(:vacuum_logs, path, {:ok, changed_evidence})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :vacuum_logs, path)
    end

    test "vacuum_logs: total_bytes changed" do
      path = "/data"

      original_evidence = %{
        "available_bytes" => 10_000_000_000,
        "path" => path,
        "total_bytes" => 100_000_000_000
      }

      token = token_for(original_evidence)

      changed_evidence = %{
        "available_bytes" => 10_000_000_000,
        "path" => path,
        "total_bytes" => 200_000_000_000
      }

      MockCollector.set_response(:vacuum_logs, path, {:ok, changed_evidence})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :vacuum_logs, path)
    end
  end

  # ---------------------------------------------------------------------------
  # Field-level sensitivity: any single field change causes mismatch
  # ---------------------------------------------------------------------------

  describe "verify/3 — single field change causes mismatch" do
    test "changing active_state alone triggers mismatch" do
      unit = "db.service"

      base = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      token = token_for(base)

      altered = Map.put(base, "active_state", "inactive")
      MockCollector.set_response(:restart_service, unit, {:ok, altered})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "changing sub_state alone triggers mismatch" do
      unit = "db.service"

      base = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      token = token_for(base)

      altered = Map.put(base, "sub_state", "dead")
      MockCollector.set_response(:restart_service, unit, {:ok, altered})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "changing unit_name alone triggers mismatch" do
      unit = "db.service"

      base = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      token = token_for(base)

      altered = Map.put(base, "unit_name", "other.service")
      MockCollector.set_response(:restart_service, unit, {:ok, altered})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "adding an extra field triggers mismatch" do
      unit = "db.service"

      base = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      token = token_for(base)

      # Adding any extra field changes the hash
      altered = Map.put(base, "extra_field", "surprise")
      MockCollector.set_response(:restart_service, unit, {:ok, altered})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "removing a field triggers mismatch" do
      unit = "db.service"

      base = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      token = token_for(base)

      altered = Map.delete(base, "sub_state")
      MockCollector.set_response(:restart_service, unit, {:ok, altered})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end
  end

  # ---------------------------------------------------------------------------
  # Collection failure: fail closed
  # ---------------------------------------------------------------------------

  describe "verify/3 — collection failure → {:error, {:collection_failed, reason}}" do
    test "collector returns {:error, :timeout} — fail closed" do
      unit = "slow.service"
      token = token_for(MockCollector.restart_evidence(unit))

      MockCollector.set_response(:restart_service, unit, {:error, :timeout})

      assert {:error, {:collection_failed, :timeout}} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "collector returns {:error, :missing_active_state} — fail closed" do
      unit = "broken.service"
      token = token_for(MockCollector.restart_evidence(unit))

      MockCollector.set_response(:restart_service, unit, {:error, :missing_active_state})

      assert {:error, {:collection_failed, :missing_active_state}} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "collector returns {:error, {:systemctl_failed, 1}} — fail closed" do
      unit = "denied.service"
      token = token_for(MockCollector.restart_evidence(unit))

      MockCollector.set_response(:restart_service, unit, {:error, {:systemctl_failed, 1}})

      assert {:error, {:collection_failed, {:systemctl_failed, 1}}} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "collector returns {:error, :malformed_df_output} — fail closed" do
      path = "/var/log"
      token = token_for(MockCollector.vacuum_evidence(path))

      MockCollector.set_response(:vacuum_logs, path, {:error, :malformed_df_output})

      assert {:error, {:collection_failed, :malformed_df_output}} =
               PreconditionChecker.verify(token, :vacuum_logs, path)
    end

    test "collection failure does NOT return :ok even if evidence might match" do
      unit = "critical.service"
      evidence = MockCollector.restart_evidence(unit)
      token = token_for(evidence)

      # The evidence would match if we could collect it — but collection fails
      MockCollector.set_response(:restart_service, unit, {:error, :permission_denied})

      result = PreconditionChecker.verify(token, :restart_service, unit)

      # Must NOT be :ok — fail closed
      refute result == :ok
      assert {:error, {:collection_failed, :permission_denied}} = result
    end
  end

  # ---------------------------------------------------------------------------
  # Hash comparison is byte-for-byte
  # ---------------------------------------------------------------------------

  describe "verify/3 — byte-for-byte hash comparison" do
    test "identical evidence maps produce identical hashes" do
      unit = "sshd.service"
      evidence = MockCollector.restart_evidence(unit)

      hash1 = ApprovalToken.hash_evidence(evidence)
      hash2 = ApprovalToken.hash_evidence(evidence)

      assert hash1 == hash2
    end

    test "token with correct hash always passes" do
      unit = "sshd.service"
      evidence = MockCollector.restart_evidence(unit)
      correct_hash = ApprovalToken.hash_evidence(evidence)
      token = %{evidence_hash: correct_hash}

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "token with hash of empty map never matches state evidence" do
      unit = "sshd.service"
      wrong_token = %{evidence_hash: ApprovalToken.hash_evidence(%{})}

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(wrong_token, :restart_service, unit)
    end

    test "token with all-zero hash never matches real evidence" do
      unit = "sshd.service"
      # 64 hex zeros is a valid but meaningless hash
      wrong_token = %{evidence_hash: String.duplicate("0", 64)}

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(wrong_token, :restart_service, unit)
    end

    test "a single character difference in a field value changes the hash" do
      unit = "sshd.service"

      evidence_a = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      # "activ" vs "active" — one character removed
      evidence_b = %{"active_state" => "activ", "sub_state" => "running", "unit_name" => unit}

      hash_a = ApprovalToken.hash_evidence(evidence_a)
      hash_b = ApprovalToken.hash_evidence(evidence_b)

      # Hashes are different
      refute hash_a == hash_b

      # Token built from evidence_a fails when evidence_b is collected
      token = %{evidence_hash: hash_a}
      MockCollector.set_response(:restart_service, unit, {:ok, evidence_b})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end
  end

  # ---------------------------------------------------------------------------
  # Field order independence: canonical encoding handles key ordering
  # ---------------------------------------------------------------------------

  describe "verify/3 — field order independence" do
    test "evidence map with different key insertion order hashes identically" do
      unit = "order-test.service"

      # Both maps contain the same keys and values but in different order
      evidence_abc = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      evidence_cba = %{
        "unit_name" => unit,
        "sub_state" => "running",
        "active_state" => "active"
      }

      hash_abc = ApprovalToken.hash_evidence(evidence_abc)
      hash_cba = ApprovalToken.hash_evidence(evidence_cba)

      # Hashes are identical regardless of insertion order
      assert hash_abc == hash_cba
    end

    test "token built from one map order matches collector returning different key order" do
      unit = "order-test.service"

      # Token was built from evidence with keys in one order
      token_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(token_evidence)

      # Collector returns same values but keys in different Elixir map order
      # (map ordering is non-deterministic in Elixir, but these are equivalent)
      collector_evidence = %{
        "unit_name" => unit,
        "sub_state" => "running",
        "active_state" => "active"
      }

      MockCollector.set_response(:restart_service, unit, {:ok, collector_evidence})

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "vacuum_logs evidence with reordered keys hashes identically" do
      path = "/var/log"

      evidence_v1 = %{
        "available_bytes" => 5_000_000_000,
        "path" => path,
        "total_bytes" => 100_000_000_000
      }

      evidence_v2 = %{
        "total_bytes" => 100_000_000_000,
        "available_bytes" => 5_000_000_000,
        "path" => path
      }

      assert ApprovalToken.hash_evidence(evidence_v1) ==
               ApprovalToken.hash_evidence(evidence_v2)
    end
  end

  # ---------------------------------------------------------------------------
  # Mock collector injectable via Application config
  # ---------------------------------------------------------------------------

  describe "verify/3 — injectable evidence collector" do
    test "custom collector module is used when configured" do
      # A collector that always returns a canned response
      defmodule AlwaysActiveCollector do
        @behaviour Exocomp.Node.Safety.PreconditionChecker

        @impl true
        def collect(:restart_service, unit) do
          {:ok,
           %{
             "active_state" => "active",
             "sub_state" => "running",
             "unit_name" => unit
           }}
        end

        def collect(_, _), do: {:error, :not_implemented}
      end

      Application.put_env(:exocomp_node, :precondition_evidence_collector, AlwaysActiveCollector)

      unit = "any.service"
      evidence = %{"active_state" => "active", "sub_state" => "running", "unit_name" => unit}
      token = token_for(evidence)

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "switching collector module changes behavior" do
      defmodule AlwaysInactiveCollector do
        @behaviour Exocomp.Node.Safety.PreconditionChecker

        @impl true
        def collect(:restart_service, unit) do
          {:ok,
           %{
             "active_state" => "inactive",
             "sub_state" => "dead",
             "unit_name" => unit
           }}
        end

        def collect(_, _), do: {:error, :not_implemented}
      end

      unit = "target.service"

      # Token was approved when service was active
      active_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(active_evidence)

      # Switch to a collector that reports the service as inactive
      Application.put_env(
        :exocomp_node,
        :precondition_evidence_collector,
        AlwaysInactiveCollector
      )

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "a failing collector produces fail-closed result" do
      defmodule AlwaysFailingCollector do
        @behaviour Exocomp.Node.Safety.PreconditionChecker

        @impl true
        def collect(_action_id, _target) do
          {:error, :collector_unavailable}
        end
      end

      Application.put_env(
        :exocomp_node,
        :precondition_evidence_collector,
        AlwaysFailingCollector
      )

      unit = "anything.service"
      evidence = MockCollector.restart_evidence(unit)
      token = token_for(evidence)

      assert {:error, {:collection_failed, :collector_unavailable}} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end
  end

  # ---------------------------------------------------------------------------
  # Integer value types in vacuum_logs evidence
  # ---------------------------------------------------------------------------

  describe "verify/3 — vacuum_logs value types" do
    test "available_bytes and total_bytes are integers, not strings" do
      path = "/mnt/data"

      # Integers in the evidence map
      evidence_int = %{
        "available_bytes" => 1_073_741_824,
        "path" => path,
        "total_bytes" => 10_737_418_240
      }

      # String representation would produce a different hash
      evidence_str = %{
        "available_bytes" => "1073741824",
        "path" => path,
        "total_bytes" => "10737418240"
      }

      hash_int = ApprovalToken.hash_evidence(evidence_int)
      hash_str = ApprovalToken.hash_evidence(evidence_str)

      refute hash_int == hash_str,
             "Integer and string representations of the same number must hash differently"

      # Token built with integer evidence
      token = token_for(evidence_int)
      MockCollector.set_response(:vacuum_logs, path, {:ok, evidence_int})

      assert :ok = PreconditionChecker.verify(token, :vacuum_logs, path)

      # String evidence does NOT match the integer-based token
      MockCollector.set_response(:vacuum_logs, path, {:ok, evidence_str})

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :vacuum_logs, path)
    end
  end

  # ---------------------------------------------------------------------------
  # SystemCollector unit tests
  # ---------------------------------------------------------------------------

  describe "SystemCollector.collect/2 — command runner injection" do
    # The SystemCollector uses :precondition_cmd_runner for OS command injection.
    # We set a stub runner and verify it is invoked with the correct argv.

    # Stub runner MFA pattern (same as Collectors.Systemd tests)
    def stub_cmd_runner(_cmd, _args, _opts, output, exit_code), do: {output, exit_code}

    defp make_cmd_runner(output, exit_code \\ 0) do
      {__MODULE__, :stub_cmd_runner, [output, exit_code]}
    end

    setup do
      previous = Application.get_env(:exocomp_node, :precondition_cmd_runner)

      on_exit(fn ->
        if previous do
          Application.put_env(:exocomp_node, :precondition_cmd_runner, previous)
        else
          Application.delete_env(:exocomp_node, :precondition_cmd_runner)
        end
      end)

      # Use the real SystemCollector for these tests
      Application.put_env(
        :exocomp_node,
        :precondition_evidence_collector,
        Exocomp.Node.Safety.PreconditionChecker.SystemCollector
      )

      :ok
    end

    test "restart_service: parses ActiveState and SubState from systemctl output" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("ActiveState=active\nSubState=running\n")
      )

      assert {:ok, evidence} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :restart_service,
                 "sshd.service"
               )

      assert evidence["active_state"] == "active"
      assert evidence["sub_state"] == "running"
      assert evidence["unit_name"] == "sshd.service"
    end

    test "restart_service: captures inactive state" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("ActiveState=inactive\nSubState=dead\n")
      )

      assert {:ok, evidence} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :restart_service,
                 "nginx.service"
               )

      assert evidence["active_state"] == "inactive"
      assert evidence["sub_state"] == "dead"
    end

    test "restart_service: non-zero systemctl exit returns error" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("No such unit", 1)
      )

      assert {:error, {:systemctl_failed, 1}} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :restart_service,
                 "unknown.service"
               )
    end

    test "restart_service: missing ActiveState in output returns error" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("SubState=dead\n")
      )

      assert {:error, :missing_active_state} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :restart_service,
                 "partial.service"
               )
    end

    test "restart_service: missing SubState in output returns error" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("ActiveState=active\n")
      )

      assert {:error, :missing_sub_state} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :restart_service,
                 "partial.service"
               )
    end

    test "vacuum_logs: parses total and available bytes from df output" do
      df_output = """
      Filesystem     1024-blocks    Used Available Use% Mounted on
      /dev/sda1        104857600 4194304  97517568   5% /
      """

      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner(df_output)
      )

      assert {:ok, evidence} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :vacuum_logs,
                 "/"
               )

      # Values are in bytes (df -Pk gives 1K blocks × 1024)
      assert evidence["total_bytes"] == 104_857_600 * 1024
      assert evidence["available_bytes"] == 97_517_568 * 1024
      assert evidence["path"] == "/"
    end

    test "vacuum_logs: non-zero df exit returns error" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("df: /missing: No such file or directory", 1)
      )

      assert {:error, {:df_failed, 1}} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :vacuum_logs,
                 "/missing"
               )
    end

    test "vacuum_logs: empty df output returns error" do
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_cmd_runner("")
      )

      assert {:error, :malformed_df_output} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :vacuum_logs,
                 "/var/log"
               )
    end

    test "unknown action returns {:error, {:unknown_action, action_id}}" do
      assert {:error, {:unknown_action, :run_shell}} =
               Exocomp.Node.Safety.PreconditionChecker.SystemCollector.collect(
                 :run_shell,
                 "anything"
               )
    end
  end

  # ---------------------------------------------------------------------------
  # Full integration: SystemCollector → verify/3 (with injected cmd runner)
  # ---------------------------------------------------------------------------

  describe "verify/3 with SystemCollector and injected cmd runner" do
    def stub_cmd_runner_full(_cmd, _args, _opts, output, exit_code), do: {output, exit_code}

    defp make_full_runner(output, exit_code \\ 0) do
      {__MODULE__, :stub_cmd_runner_full, [output, exit_code]}
    end

    setup do
      prev_collector = Application.get_env(:exocomp_node, :precondition_evidence_collector)
      prev_runner = Application.get_env(:exocomp_node, :precondition_cmd_runner)

      Application.put_env(
        :exocomp_node,
        :precondition_evidence_collector,
        Exocomp.Node.Safety.PreconditionChecker.SystemCollector
      )

      on_exit(fn ->
        if prev_collector,
          do:
            Application.put_env(:exocomp_node, :precondition_evidence_collector, prev_collector),
          else: Application.delete_env(:exocomp_node, :precondition_evidence_collector)

        if prev_runner,
          do: Application.put_env(:exocomp_node, :precondition_cmd_runner, prev_runner),
          else: Application.delete_env(:exocomp_node, :precondition_cmd_runner)
      end)

      :ok
    end

    test "restart_service: matching state passes" do
      unit = "myapp.service"

      # What the coordinator hashed at approval time
      approval_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(approval_evidence)

      # Node collects the same state via systemctl
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_full_runner("ActiveState=active\nSubState=running\n")
      )

      assert :ok = PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "restart_service: changed state after approval fails" do
      unit = "myapp.service"

      # Approved when service was active
      approval_evidence = %{
        "active_state" => "active",
        "sub_state" => "running",
        "unit_name" => unit
      }

      token = token_for(approval_evidence)

      # Service has since failed
      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_full_runner("ActiveState=failed\nSubState=failed\n")
      )

      assert {:error, :precondition_changed} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end

    test "restart_service: systemctl failure fails closed" do
      unit = "crashed.service"

      token =
        token_for(%{"active_state" => "active", "sub_state" => "running", "unit_name" => unit})

      Application.put_env(
        :exocomp_node,
        :precondition_cmd_runner,
        make_full_runner("Failed to connect", 1)
      )

      assert {:error, {:collection_failed, {:systemctl_failed, 1}}} =
               PreconditionChecker.verify(token, :restart_service, unit)
    end
  end
end
