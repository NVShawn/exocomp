defmodule Exocomp.Node.Safety.DiskPressureCollectorTest do
  @moduledoc """
  Unit tests for `DiskPressureCollector`.

  All OS invocations are intercepted by `MockCommander` so no `df` binary is
  required.  Application config is set per-test and restored on exit.
  """

  # async: false because we mutate Application env.
  use ExUnit.Case, async: false

  alias Exocomp.Node.MockCommander
  alias Exocomp.Node.Safety.DiskPressureCollector
  alias Exocomp.Node.Safety.Evidence

  # Default thresholds installed for all tests (overridden per-test when needed).
  @default_warning_pct 75
  @default_critical_pct 90
  @default_mount "/var/log"

  # ---------------------------------------------------------------------------
  # Setup / teardown
  # ---------------------------------------------------------------------------

  setup do
    # Snapshot current Application env so we can restore it after each test.
    prev_commander = Application.get_env(:exocomp_node, :os_commander)
    prev_mount = Application.get_env(:exocomp_node, :disk_pressure_mount_point)
    prev_warning = Application.get_env(:exocomp_node, :disk_pressure_warning_pct)
    prev_critical = Application.get_env(:exocomp_node, :disk_pressure_critical_pct)

    # Install defaults.
    Application.put_env(:exocomp_node, :disk_pressure_mount_point, @default_mount)
    Application.put_env(:exocomp_node, :disk_pressure_warning_pct, @default_warning_pct)
    Application.put_env(:exocomp_node, :disk_pressure_critical_pct, @default_critical_pct)

    # Start a fresh mock agent for each test.
    {:ok, mock} = MockCommander.start()
    Application.put_env(:exocomp_node, :os_commander, MockCommander.as_commander(mock))

    on_exit(fn ->
      restore_env(:os_commander, prev_commander)
      restore_env(:disk_pressure_mount_point, prev_mount)
      restore_env(:disk_pressure_warning_pct, prev_warning)
      restore_env(:disk_pressure_critical_pct, prev_critical)
      MockCommander.stop(mock)
    end)

    %{mock: mock}
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Build a synthetic `df -B1` response at a given usage percentage.
  #
  # Total is fixed at 1 GiB.  `used_pct` must be 0–100.
  defp df_response(used_pct) when used_pct >= 0 and used_pct <= 100 do
    total = 1_073_741_824
    used = div(total * used_pct, 100)
    free = total - used

    output = """
    Filesystem     1B-blocks       Used  Available Use% Mounted on
    /dev/sda1 #{total} #{used} #{free} #{used_pct}% /var/log
    """

    {:ok, output, 0}
  end

  defp restore_env(key, nil), do: Application.delete_env(:exocomp_node, key)
  defp restore_env(key, val), do: Application.put_env(:exocomp_node, key, val)

  # ---------------------------------------------------------------------------
  # Threshold classification
  # ---------------------------------------------------------------------------

  describe "threshold classification" do
    test "returns :below_threshold when usage is below warning threshold", %{mock: mock} do
      MockCommander.push(mock, df_response(50))
      assert {:ok, _evidence, :below_threshold} = DiskPressureCollector.collect()
    end

    test "returns :warning when usage equals the warning threshold exactly", %{mock: mock} do
      MockCommander.push(mock, df_response(@default_warning_pct))
      assert {:ok, _evidence, :warning} = DiskPressureCollector.collect()
    end

    test "returns :warning when usage is above warning but below critical", %{mock: mock} do
      # Between 75 and 89 inclusive.
      MockCommander.push(mock, df_response(80))
      assert {:ok, _evidence, :warning} = DiskPressureCollector.collect()
    end

    test "returns :critical when usage equals the critical threshold exactly", %{mock: mock} do
      MockCommander.push(mock, df_response(@default_critical_pct))
      assert {:ok, _evidence, :critical} = DiskPressureCollector.collect()
    end

    test "returns :critical when usage is above the critical threshold", %{mock: mock} do
      MockCommander.push(mock, df_response(95))
      assert {:ok, _evidence, :critical} = DiskPressureCollector.collect()
    end

    test "returns :below_threshold when usage is 0%", %{mock: mock} do
      MockCommander.push(mock, df_response(0))
      assert {:ok, _evidence, :below_threshold} = DiskPressureCollector.collect()
    end

    test "returns :critical when usage is 100%", %{mock: mock} do
      MockCommander.push(mock, df_response(100))
      assert {:ok, _evidence, :critical} = DiskPressureCollector.collect()
    end
  end

  # ---------------------------------------------------------------------------
  # OS command failure
  # ---------------------------------------------------------------------------

  describe "OS command failure" do
    test "returns {:error, :timeout} when the df command times out", %{mock: mock} do
      MockCommander.push(mock, {:error, :timeout})
      assert {:error, :timeout} = DiskPressureCollector.collect()
    end

    test "returns {:error, reason} on commander error", %{mock: mock} do
      MockCommander.push(mock, {:error, :enoent})
      assert {:error, :enoent} = DiskPressureCollector.collect()
    end

    test "returns {:error, {:df_exit_code, n}} when df exits non-zero", %{mock: mock} do
      MockCommander.push(mock, {:ok, "df: /no/such/path: No such file or directory\n", 1})
      assert {:error, {:df_exit_code, 1}} = DiskPressureCollector.collect()
    end
  end

  # ---------------------------------------------------------------------------
  # Evidence record structure
  # ---------------------------------------------------------------------------

  describe "evidence record structure" do
    test "all required fields are present in the returned Evidence struct", %{mock: mock} do
      MockCommander.push(mock, df_response(50))

      assert {:ok, %Evidence{} = ev, _threshold} = DiskPressureCollector.collect()

      assert ev.schema_version == "1"
      assert is_binary(ev.evidence_id) and byte_size(ev.evidence_id) > 0
      assert ev.collector == "system.disk.pressure"
      assert is_binary(ev.collector_version) and byte_size(ev.collector_version) > 0
      assert ev.target_id == @default_mount
      assert %DateTime{} = ev.observed_at
      assert is_map(ev.values)
      assert is_binary(ev.integrity_hash) and byte_size(ev.integrity_hash) == 64
    end

    test "values map contains used_bytes, free_bytes, total_bytes, and used_pct", %{mock: mock} do
      MockCommander.push(mock, df_response(50))

      assert {:ok, %Evidence{values: values}, _threshold} = DiskPressureCollector.collect()

      assert Map.has_key?(values, "used_bytes")
      assert Map.has_key?(values, "free_bytes")
      assert Map.has_key?(values, "total_bytes")
      assert Map.has_key?(values, "used_pct")

      # All values must be strings (not integers).
      for {_k, v} <- values, do: assert(is_binary(v))
    end

    test "values are numerically correct for a 50% usage on a 1 GiB filesystem", %{mock: mock} do
      total = 1_073_741_824
      used = div(total, 2)
      free = total - used

      MockCommander.push(mock, df_response(50))

      assert {:ok, %Evidence{values: values}, _threshold} = DiskPressureCollector.collect()

      assert values["total_bytes"] == Integer.to_string(total)
      assert values["used_bytes"] == Integer.to_string(used)
      assert values["free_bytes"] == Integer.to_string(free)
      assert values["used_pct"] == "50"
    end

    test "target_id matches the configured mount point", %{mock: mock} do
      Application.put_env(:exocomp_node, :disk_pressure_mount_point, "/run/log/journal")
      MockCommander.push(mock, df_response(40))

      assert {:ok, %Evidence{target_id: target_id}, _threshold} = DiskPressureCollector.collect()
      assert target_id == "/run/log/journal"
    end

    test "observed_at is a recent UTC datetime", %{mock: mock} do
      before = DateTime.utc_now()
      MockCommander.push(mock, df_response(50))

      assert {:ok, %Evidence{observed_at: observed_at}, _threshold} =
               DiskPressureCollector.collect()

      after_collect = DateTime.utc_now()

      assert DateTime.compare(observed_at, before) in [:gt, :eq]
      assert DateTime.compare(observed_at, after_collect) in [:lt, :eq]
    end

    test "integrity_hash is a valid 64-character lowercase hex string", %{mock: mock} do
      MockCommander.push(mock, df_response(50))

      assert {:ok, %Evidence{integrity_hash: hash}, _threshold} = DiskPressureCollector.collect()

      assert byte_size(hash) == 64
      assert String.match?(hash, ~r/\A[0-9a-f]{64}\z/)
    end

    test "integrity_hash matches the recomputed hash for the returned evidence", %{mock: mock} do
      MockCommander.push(mock, df_response(50))

      assert {:ok, %Evidence{} = ev, _threshold} = DiskPressureCollector.collect()

      expected_hash = DiskPressureCollector.integrity_hash_for(ev)
      assert ev.integrity_hash == expected_hash
    end

    test "Evidence.parse/1 accepts the collected evidence converted to a string-key map",
         %{mock: mock} do
      MockCommander.push(mock, df_response(50))
      assert {:ok, %Evidence{} = ev, _threshold} = DiskPressureCollector.collect()

      string_map = %{
        "schema_version" => ev.schema_version,
        "evidence_id" => ev.evidence_id,
        "collector" => ev.collector,
        "collector_version" => ev.collector_version,
        "target_id" => ev.target_id,
        "observed_at" => DateTime.to_iso8601(ev.observed_at),
        "values" => ev.values,
        "integrity_hash" => ev.integrity_hash
      }

      assert {:ok, %Evidence{}} = Evidence.parse(string_map)
    end
  end

  # ---------------------------------------------------------------------------
  # Config-only access (mount point and thresholds are not caller-supplied)
  # ---------------------------------------------------------------------------

  describe "config-only values" do
    test "collect/0 accepts no arguments — mount point and thresholds cannot be supplied by the caller" do
      # collect/0 takes no arguments; this test asserts the public arity.
      assert function_exported?(DiskPressureCollector, :collect, 0)
      refute function_exported?(DiskPressureCollector, :collect, 1)
    end

    test "collector reads mount point from Application config, not from caller", %{mock: mock} do
      Application.put_env(:exocomp_node, :disk_pressure_mount_point, "/mnt/custom")
      MockCommander.push(mock, df_response(30))

      assert {:ok, %Evidence{target_id: target_id}, _threshold} = DiskPressureCollector.collect()
      assert target_id == "/mnt/custom"
    end

    test "collector reads warning threshold from Application config", %{mock: mock} do
      # Set a very low warning threshold so a 30% usage triggers :warning.
      Application.put_env(:exocomp_node, :disk_pressure_warning_pct, 20)
      Application.put_env(:exocomp_node, :disk_pressure_critical_pct, 90)

      MockCommander.push(mock, df_response(30))
      assert {:ok, _evidence, :warning} = DiskPressureCollector.collect()
    end

    test "collector reads critical threshold from Application config", %{mock: mock} do
      # Set a very low critical threshold so a 30% usage triggers :critical.
      Application.put_env(:exocomp_node, :disk_pressure_warning_pct, 10)
      Application.put_env(:exocomp_node, :disk_pressure_critical_pct, 20)

      MockCommander.push(mock, df_response(30))
      assert {:ok, _evidence, :critical} = DiskPressureCollector.collect()
    end
  end
end
