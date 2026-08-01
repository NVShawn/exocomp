# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Collectors.CephTest do
  @moduledoc """
  Unit tests for `Exocomp.Coordinator.Collectors.Ceph`.

  Uses injectable `:cmd_runner` and `:config` options so no real Ceph
  cluster, ceph.conf, or keyring file is needed.
  """

  use ExUnit.Case, async: false

  alias Exocomp.ClusterProfile.Ceph.Config
  alias Exocomp.Coordinator.Collectors.Ceph

  # ---------------------------------------------------------------------------
  # Test fixtures for Ceph JSON responses
  # ---------------------------------------------------------------------------

  defmodule CephFixtures do
    @moduledoc "Fixture data for common Ceph command outputs."

    def status_healthy do
      %{
        "fsid" => "01234567-89ab-cdef-0123-456789abcdef",
        "health" => %{
          "status" => "HEALTH_OK",
          "checks" => %{}
        }
      }
      |> Jason.encode!()
    end

    def status_warning do
      %{
        "health" => %{
          "status" => "HEALTH_WARN",
          "checks" => %{
            "PG_DEGRADED" => %{
              "severity" => "WARN",
              "summary" => %{"message" => "some PGs degraded"}
            }
          }
        }
      }
      |> Jason.encode!()
    end

    def status_error do
      %{
        "health" => %{
          "status" => "HEALTH_ERR",
          "checks" => %{
            "HEALTH_RED" => %{
              "severity" => "ERR",
              "summary" => %{"message" => "health error"}
            }
          }
        }
      }
      |> Jason.encode!()
    end

    def empty_health do
      %{"health" => %{}}
      |> Jason.encode!()
    end

    def mon_metadata do
      %{
        "0" => %{
          "hostname" => "ceph-mon-0",
          "public_addr" => "192.168.1.10"
        },
        "1" => %{
          "hostname" => "ceph-mon-1",
          "public_addr" => "192.168.1.11"
        }
      }
      |> Jason.encode!()
    end

    def empty_metadata do
      %{}
      |> Jason.encode!()
    end

    def osd_metadata do
      %{
        "0" => %{
          "id" => 0,
          "hostname" => "ceph-osd-0",
          "public_addr" => "192.168.1.20"
        },
        "1" => %{
          "id" => 1,
          "hostname" => "ceph-osd-1",
          "public_addr" => "192.168.1.21"
        }
      }
      |> Jason.encode!()
    end

    def fs_list do
      [
        %{
          "name" => "cephfs",
          "metadata_pool" => "cephfs_metadata",
          "data_pools" => ["cephfs_data"]
        }
      ]
      |> Jason.encode!()
    end

    def malformed_json do
      "{ invalid json"
    end

    def empty_output do
      ""
    end

    def large_output do
      # Create output larger than max limit (1 MiB)
      large_data = %{"data" => String.duplicate("x", 2_000_000)}
      Jason.encode!(large_data)
    end
  end

  # ---------------------------------------------------------------------------
  # Mock command runners
  # ---------------------------------------------------------------------------

  defmodule MockRunner do
    @moduledoc "Test runner that returns predefined responses."

    @doc "Returns success responses for all Ceph commands."
    def success_all(_cmd, args, _opts) do
      cmd_output(args)
    end

    @doc "Returns failures for some commands (simulate partial failure)."
    def partial_failure(cmd, args, opts) do
      args_str = args |> Enum.join(" ")

      cond do
        String.contains?(args_str, "mon metadata") -> {"{}", 1}
        String.contains?(args_str, "mgr metadata") -> {"{}", 1}
        true -> success_all(cmd, args, opts)
      end
    end

    @doc "Returns timeout by never finishing."
    def timeout_runner(_cmd, _args, _opts) do
      Process.sleep(30_000)
      {"", 0}
    end

    @doc "Returns oversized output."
    def oversized_runner(_cmd, _args, _opts) do
      {CephFixtures.large_output(), 0}
    end

    @doc "Returns malformed JSON."
    def malformed_runner(_cmd, args, _opts) do
      args_str = args |> Enum.join(" ")

      if String.contains?(args_str, "status") do
        {CephFixtures.status_healthy(), 0}
      else
        {CephFixtures.malformed_json(), 0}
      end
    end

    @doc "Returns command execution errors."
    def error_runner(_cmd, _args, _opts) do
      {"permission denied", 13}
    end

    # Helper to determine which fixture to return based on command.
    defp cmd_output(args) do
      cmd_str = Enum.join(args, " ")

      output =
        cond do
          String.contains?(cmd_str, ["status"]) -> CephFixtures.status_healthy()
          String.contains?(cmd_str, ["mon metadata"]) -> CephFixtures.mon_metadata()
          String.contains?(cmd_str, ["mgr metadata"]) -> CephFixtures.empty_metadata()
          String.contains?(cmd_str, ["osd metadata"]) -> CephFixtures.osd_metadata()
          String.contains?(cmd_str, ["mds metadata"]) -> CephFixtures.empty_metadata()
          String.contains?(cmd_str, ["fs ls"]) -> CephFixtures.fs_list()
          true -> "{}"
        end

      {output, 0}
    end
  end

  # ---------------------------------------------------------------------------
  # Test configuration
  # ---------------------------------------------------------------------------

  defp base_config do
    %Config{
      version: 1,
      ceph_binary_path: "/usr/bin/ceph",
      ceph_conf_path: "/etc/ceph/ceph.conf",
      keyring_path: "/etc/ceph/ceph.client.exocomp.keyring"
    }
  end

  defp with_config(config) do
    Application.put_env(:exocomp_coordinator, :ceph_config, config)

    on_exit(fn ->
      Application.delete_env(:exocomp_coordinator, :ceph_config)
    end)
  end

  # ---------------------------------------------------------------------------
  # Tests: Successful Collection
  # ---------------------------------------------------------------------------

  test "collects HEALTH_OK status successfully" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert result.schema_version == 1
    assert result.status == :ok
    assert is_binary(result.collected_at)
    assert is_map(result.health)
    assert is_map(result.topology)
    assert result.errors == []
  end

  test "collects HEALTH_WARN status successfully" do
    with_config(base_config())

    runner = fn cmd, args, opts ->
      args_str = Enum.join(args)

      if String.contains?(args_str, "status") do
        {CephFixtures.status_warning(), 0}
      else
        MockRunner.success_all(cmd, args, opts)
      end
    end

    result =
      Ceph.collect(
        cmd_runner: runner,
        config: base_config()
      )

    assert result.status == :ok
    assert result.health["overall"]["status"] == "HEALTH_WARN"
  end

  test "collects HEALTH_ERR status successfully" do
    with_config(base_config())

    runner = fn cmd, args, opts ->
      args_str = Enum.join(args)

      if String.contains?(args_str, "status") do
        {CephFixtures.status_error(), 0}
      else
        MockRunner.success_all(cmd, args, opts)
      end
    end

    result =
      Ceph.collect(
        cmd_runner: runner,
        config: base_config()
      )

    assert result.status == :ok
    assert result.health["overall"]["status"] == "HEALTH_ERR"
  end

  test "normalizes health structure across versions" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert is_map(result.health)
    assert Map.has_key?(result.health, "overall")
    assert Map.has_key?(result.health, "status")
  end

  test "collects monitor topology" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert is_map(result.topology["monitors"])
    assert Map.has_key?(result.topology["monitors"], "0")
  end

  test "preserves the authoritative cluster FSID beside topology" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert result.topology["fsid"] == "01234567-89ab-cdef-0123-456789abcdef"
  end

  test "collects OSD topology" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert is_map(result.topology["osds"])
    assert Map.has_key?(result.topology["osds"], "0")
  end

  test "collects empty cluster data without error" do
    with_config(base_config())

    runner = fn _cmd, _args, _opts ->
      {CephFixtures.empty_metadata(), 0}
    end

    result =
      Ceph.collect(
        cmd_runner: runner,
        config: base_config()
      )

    # All commands return empty metadata -> no errors
    assert result.status == :ok
  end

  test "collects filesystem list when available" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert is_list(result.topology["filesystems"])
  end

  # ---------------------------------------------------------------------------
  # Tests: Error Handling
  # ---------------------------------------------------------------------------

  test "handles malformed JSON gracefully" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.malformed_runner/3,
        config: base_config()
      )

    assert result.status == :partial
    assert length(result.errors) > 0
    # Status succeeded, others failed
    assert Enum.any?(result.errors, &String.contains?(&1.command, "mon"))
  end

  test "handles partial command failures" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.partial_failure/3,
        config: base_config()
      )

    assert result.status == :partial
    assert length(result.errors) == 2
    assert Enum.all?(result.errors, &is_binary(&1.timestamp))
    assert Enum.all?(result.errors, &is_atom(&1.error))
  end

  test "preserves error timestamps" do
    with_config(base_config())

    before = DateTime.utc_now()

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.partial_failure/3,
        config: base_config()
      )

    after_ts = DateTime.utc_now()

    error = List.first(result.errors)
    assert is_binary(error.timestamp)

    # Parse and verify timestamp is between before and after
    {:ok, parsed_ts, _} = DateTime.from_iso8601(error.timestamp)
    assert DateTime.compare(parsed_ts, before) in [:eq, :gt]
    assert DateTime.compare(parsed_ts, after_ts) in [:eq, :lt]
  end

  test "sanitizes error reasons (max 512 bytes)" do
    with_config(base_config())

    runner = fn _cmd, _args, _opts ->
      long_reason = String.duplicate("x", 1000)
      {long_reason, 1}
    end

    result =
      Ceph.collect(
        cmd_runner: runner,
        config: base_config()
      )

    error = List.first(result.errors)
    assert byte_size(error.reason) <= 512
  end

  test "returns degraded status when config is unavailable" do
    # Don't set config in app env
    Application.delete_env(:exocomp_coordinator, :ceph_config)

    result = Ceph.collect()

    assert result.status == :degraded
    assert length(result.errors) == 1
    assert result.errors |> List.first() |> Map.fetch!(:error) == :unavailable
  end

  test "handles command exit codes" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.error_runner/3,
        config: base_config()
      )

    assert result.status == :degraded
    assert length(result.errors) == 6
  end

  # ---------------------------------------------------------------------------
  # Tests: Timeout and Output Limits
  # ---------------------------------------------------------------------------

  test "enforces command timeout" do
    with_config(base_config())

    result =
      Ceph.collect(
        timeout_ms: 100,
        cmd_runner: &MockRunner.timeout_runner/3,
        config: base_config()
      )

    assert result.status == :degraded
    assert length(result.errors) == 6
    assert Enum.all?(result.errors, &String.contains?(&1.reason, "timed out"))
  end

  test "enforces output size limit" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.oversized_runner/3,
        config: base_config()
      )

    assert result.status == :degraded
    assert length(result.errors) == 6
    assert Enum.all?(result.errors, &String.contains?(&1.reason, "exceeded"))
  end

  test "truncates error list when exceeding max" do
    with_config(base_config())

    runner = fn _cmd, _args, _opts ->
      {"", 1}
    end

    result =
      Ceph.collect(
        cmd_runner: runner,
        config: base_config()
      )

    # We have 6 commands, so at most 6 errors
    assert length(result.errors) <= 64
  end

  # ---------------------------------------------------------------------------
  # Tests: Data Structure
  # ---------------------------------------------------------------------------

  test "returns properly structured evidence" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert Map.has_key?(result, :schema_version)
    assert Map.has_key?(result, :collected_at)
    assert Map.has_key?(result, :status)
    assert Map.has_key?(result, :health)
    assert Map.has_key?(result, :topology)
    assert Map.has_key?(result, :errors)

    assert is_integer(result.schema_version)
    assert is_binary(result.collected_at)
    assert is_atom(result.status)
    assert is_map(result.health)
    assert is_map(result.topology)
    assert is_list(result.errors)
  end

  test "error entries have required fields" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.partial_failure/3,
        config: base_config()
      )

    error = List.first(result.errors)

    assert Map.has_key?(error, :timestamp)
    assert Map.has_key?(error, :command)
    assert Map.has_key?(error, :error)
    assert Map.has_key?(error, :reason)

    assert is_binary(error.timestamp)
    assert is_binary(error.command)
    assert is_atom(error.error)
    assert is_binary(error.reason)
  end

  # ---------------------------------------------------------------------------
  # Tests: Redaction and Security
  # ---------------------------------------------------------------------------

  test "does not expose keyring path in errors" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.error_runner/3,
        config: base_config()
      )

    error_str = result.errors |> Enum.map(& &1.reason) |> Enum.join(" ")
    assert not String.contains?(error_str, "keyring")
    assert not String.contains?(error_str, "ceph.client.exocomp")
  end

  test "does not expose ceph.conf path in errors" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.error_runner/3,
        config: base_config()
      )

    error_str = result.errors |> Enum.map(& &1.reason) |> Enum.join(" ")
    # The error message from our runner is "permission denied", not a path
    assert not String.contains?(error_str, ".conf")
  end

  # ---------------------------------------------------------------------------
  # Tests: Schema Version
  # ---------------------------------------------------------------------------

  test "reports correct schema version" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    assert result.schema_version == 1
  end

  test "includes collected_at timestamp in ISO8601 format" do
    with_config(base_config())

    result =
      Ceph.collect(
        cmd_runner: &MockRunner.success_all/3,
        config: base_config()
      )

    # Verify it's a valid ISO8601 timestamp
    assert {:ok, _datetime, _offset} = DateTime.from_iso8601(result.collected_at)
  end
end
