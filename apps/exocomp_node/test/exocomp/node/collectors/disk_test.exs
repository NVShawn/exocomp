defmodule Exocomp.Node.Collectors.DiskTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.Disk

  # ---------------------------------------------------------------------------
  # Stub runner helpers
  #
  # The collector dispatches via: apply(mod, fun, [cmd, args, cmd_opts] ++ extra_args)
  # so public helpers must receive (cmd, args, opts, <extra_args...>).
  # ---------------------------------------------------------------------------

  # Fixed-response runner: returns `{output, exit_code}` without invoking df.
  # MFA extra_args = [output, exit_code] → called as fixed_runner(cmd, args, opts, output, exit_code)
  def fixed_runner(_cmd, _args, _opts, output, exit_code), do: {output, exit_code}

  defp make_runner(output, exit_code \\ 0) do
    {__MODULE__, :fixed_runner, [output, exit_code]}
  end

  # Proxy runner: delegates to an anonymous function f that takes no args.
  # MFA extra_args = [f] → called as call_fn(cmd, args, opts, f)
  def call_fn(_cmd, _args, _opts, f), do: f.()

  # ---------------------------------------------------------------------------
  # Fixtures
  # ---------------------------------------------------------------------------

  defp valid_df_output do
    """
    Filesystem      1024-blocks     Used  Available Use% Mounted on
    /dev/sda1         102400000 50000000   50000000  49% /
    """
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "collect/1 with valid df output" do
    test "returns observation envelope" do
      obs = Disk.collect(mount_points: ["/"], cmd_runner: make_runner(valid_df_output()))

      assert is_binary(obs.observed_at)
      assert obs.source == Exocomp.Node.Collectors.Disk
      assert obs.collector_version >= 1
      assert is_integer(obs.duration_us)
    end

    test "root mount point produces three measurements" do
      obs = Disk.collect(mount_points: ["/"], cmd_runner: make_runner(valid_df_output()))
      m = obs.measurements

      assert Map.has_key?(m, :root_total_bytes)
      assert Map.has_key?(m, :root_free_bytes)
      assert Map.has_key?(m, :root_available_bytes)
    end

    test "values are in bytes (1024-blocks * 1024)" do
      obs = Disk.collect(mount_points: ["/"], cmd_runner: make_runner(valid_df_output()))
      m = obs.measurements

      assert m.root_total_bytes.value == 102_400_000 * 1024
      assert m.root_total_bytes.unit == "bytes"
      assert m.root_available_bytes.value == 50_000_000 * 1024
    end
  end

  describe "collect/1 with multiple mount points" do
    test "each mount point produces its own three measurements" do
      var_output = """
      Filesystem      1024-blocks    Used Available Use% Mounted on
      /dev/sdb1          51200000 1000000  50000000   2% /var
      """

      # Use an agent to serve different outputs per call.
      {:ok, agent} = Agent.start_link(fn -> [valid_df_output(), var_output] end)

      rotating_runner = fn ->
        Agent.get_and_update(agent, fn [h | t] -> {h, t} end)
        |> then(fn out -> {out, 0} end)
      end

      obs =
        Disk.collect(
          mount_points: ["/", "/var"],
          cmd_runner: {__MODULE__, :call_fn, [rotating_runner]}
        )

      m = obs.measurements

      assert Map.has_key?(m, :root_total_bytes)
      assert Map.has_key?(m, :var_total_bytes)
      assert m.root_total_bytes.value == 102_400_000 * 1024
      assert m.var_total_bytes.value == 51_200_000 * 1024
    end
  end

  describe "collect/1 when df exits with non-zero" do
    test "all three measurements return unavailable error" do
      obs =
        Disk.collect(
          mount_points: ["/"],
          cmd_runner: make_runner("df: /: No such file or directory\n", 1)
        )

      assert obs.measurements.root_total_bytes.error == :unavailable
      assert obs.measurements.root_free_bytes.error == :unavailable
      assert obs.measurements.root_available_bytes.error == :unavailable
    end
  end

  describe "collect/1 with malformed df output" do
    test "measurements return malformed error when there are no data lines" do
      # Only a header, no data rows
      header_only = "Filesystem 1024-blocks Used Available Use% Mounted\n"

      obs =
        Disk.collect(
          mount_points: ["/"],
          cmd_runner: make_runner(header_only)
        )

      assert obs.measurements.root_total_bytes.error == :malformed
    end

    test "measurements return malformed error when columns are unparseable" do
      bad_output = """
      Filesystem 1024-blocks Used Available Use% Mounted
      /dev/sda1 NOT_AN_INT 50000000 50000000 49% /
      """

      obs =
        Disk.collect(
          mount_points: ["/"],
          cmd_runner: make_runner(bad_output)
        )

      assert obs.measurements.root_total_bytes.error == :malformed
    end
  end

  describe "collect/1 with oversized df output" do
    test "measurements return output_limit error" do
      header = "Filesystem 1024-blocks Used Available Use% Mounted\n"
      row = "/dev/sda1 102400000 50000000 50000000 49% /\n"
      # > 65 536 bytes
      big_output = header <> String.duplicate(row, 2000)

      obs =
        Disk.collect(
          mount_points: ["/"],
          cmd_runner: make_runner(big_output)
        )

      assert obs.measurements.root_total_bytes.error == :output_limit
    end
  end

  describe "collect/1 timeout" do
    test "measurements return timeout error when runner hangs" do
      slow_runner = fn ->
        Process.sleep(30_000)
        {"", 0}
      end

      obs =
        Disk.collect(
          mount_points: ["/"],
          cmd_runner: {__MODULE__, :call_fn, [slow_runner]},
          timeout_ms: 50
        )

      assert obs.measurements.root_total_bytes.error == :timeout
      assert obs.measurements.root_free_bytes.error == :timeout
      assert obs.measurements.root_available_bytes.error == :timeout
    end
  end

  describe "collect/1 partial independence across mount points" do
    test "error on one mount point does not affect another" do
      {:ok, agent} = Agent.start_link(fn -> [{valid_df_output(), 0}, {"", 1}] end)

      rotating_runner = fn ->
        Agent.get_and_update(agent, fn [h | t] -> {h, t} end)
      end

      obs =
        Disk.collect(
          mount_points: ["/", "/missing"],
          cmd_runner: {__MODULE__, :call_fn, [rotating_runner]}
        )

      assert obs.measurements.root_total_bytes.unit == "bytes"
      assert obs.measurements.missing_total_bytes.error == :unavailable
    end
  end
end
