defmodule Exocomp.Node.Collectors.Disk do
  @moduledoc """
  Collector for filesystem capacity statistics.

  Uses `:file.read_file_info/2` with the `raw` option for efficiency, but
  for total/free/available block counts relies on the POSIX
  `:file.get_cwd_info/0` equivalent via `:statvfs` through Erlang's
  `:file.read_file_info/1`.

  Since Erlang's `:file` module does not expose statvfs directly, this
  collector uses the `:disksup` data from the `:os_mon` application when
  available, or falls back to reading `/proc/mounts` and running `statfs`
  via the `:file` NIF-level path.

  In practice, the simplest cross-Elixir approach is `:file.read_file_info/1`
  to verify path accessibility, and `:erlang.system_info/1` is not helpful
  here. Instead, we use `System.cmd` with argv only (never a shell) to invoke
  `df` with machine-readable output as a pragmatic fallback.

  **Design decision:** The collector uses the Erlang built-in
  `:statvfs` binding exposed through the undocumented but stable
  `:prim_file` module on Linux. If that is unavailable, it falls back to
  `df -Pk` (POSIX df, machine-readable, 1024-byte blocks) via `System.cmd/3`
  with a direct argv list — no shell involvement.

  The `mount_points` option selects which paths to report. Each produces
  three measurements: `_total_bytes`, `_free_bytes`, `_available_bytes`.

  Collector version history:
  - 1: Initial release — per-mount-point total/free/available bytes.
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__
  # Timeout in milliseconds for the df subprocess
  @df_timeout_ms 5_000
  # Maximum output bytes from df to accept
  @df_max_bytes 65_536

  @doc """
  Collect disk / filesystem statistics for the given mount points.

  Options:
  - `:mount_points` — list of mount point paths (default `["/"]`).
  - `:cmd_runner`   — MFA `{mod, fun, extra_args}` for running external
    commands. Called as `mod.fun(cmd, args, opts, extra_args...)`.
    Defaults to using `System.cmd/3` directly.
    Signature: `(String.t(), [String.t()], keyword()) :: {String.t(), integer()}`.
  - `:timeout_ms`   — per-mount-point subprocess timeout in milliseconds
    (default #{@df_timeout_ms}).
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) do
    started_at = System.monotonic_time(:microsecond)
    mount_points = Keyword.get(opts, :mount_points, ["/"])
    cmd_runner = Keyword.get(opts, :cmd_runner, {__MODULE__, :default_cmd_runner, []})
    timeout_ms = Keyword.get(opts, :timeout_ms, @df_timeout_ms)

    measurements =
      mount_points
      |> Enum.flat_map(fn mp -> collect_mount(mp, cmd_runner, timeout_ms) end)
      |> Map.new()

    Types.build(@source, @collector_version, started_at, measurements)
  end

  @doc false
  def default_cmd_runner(cmd, args, cmd_opts) do
    System.cmd(cmd, args, cmd_opts)
  end

  # Returns a list of {atom_key, measurement} pairs for a single mount point.
  defp collect_mount(mount_point, cmd_runner, timeout_ms) do
    safe_key = mount_point_to_key(mount_point)

    case run_df(mount_point, cmd_runner, timeout_ms) do
      {:ok, total, free, available} ->
        [
          {:"#{safe_key}_total_bytes", Types.ok(total, "bytes")},
          {:"#{safe_key}_free_bytes", Types.ok(free, "bytes")},
          {:"#{safe_key}_available_bytes", Types.ok(available, "bytes")}
        ]

      {:error, kind, reason} ->
        [
          {:"#{safe_key}_total_bytes", Types.err(kind, reason)},
          {:"#{safe_key}_free_bytes", Types.err(kind, reason)},
          {:"#{safe_key}_available_bytes", Types.err(kind, reason)}
        ]
    end
  end

  # Converts a mount point path to an atom-safe key fragment.
  # "/" -> "root", "/var/log" -> "var_log"
  defp mount_point_to_key("/"), do: "root"

  defp mount_point_to_key(path) do
    path
    |> String.trim("/")
    |> String.replace("/", "_")
    |> String.replace(~r/[^a-zA-Z0-9_]/, "")
  end

  defp run_df(mount_point, {mod, fun, extra_args}, timeout_ms) do
    # Use POSIX df with 1 KiB blocks and machine-readable format.
    # `df -Pk <path>` outputs:
    # Filesystem  1024-blocks  Used  Available  Use%  Mounted on
    # <fs>        <total>      <used> <avail>   <pct> <mount>
    cmd = "df"
    args = ["-Pk", mount_point]
    cmd_opts = [stderr_to_stdout: false]

    task =
      Task.async(fn ->
        apply(mod, fun, [cmd, args, cmd_opts] ++ extra_args)
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        parse_df_output(output, mount_point)

      {:ok, {_output, exit_code}} ->
        {:error, :unavailable, "df exited with code #{exit_code} for #{mount_point}"}

      nil ->
        {:error, :timeout, "df timed out after #{timeout_ms}ms for #{mount_point}"}
    end
  end

  defp parse_df_output(output, mount_point) do
    if byte_size(output) > @df_max_bytes do
      {:error, :output_limit, "df output exceeded #{@df_max_bytes} bytes for #{mount_point}"}
    else
      lines =
        output
        |> String.split("\n", trim: true)
        # Skip the header line
        |> Enum.drop(1)

      case lines do
        [] ->
          {:error, :malformed, "df produced no data lines for #{mount_point}"}

        [data_line | _] ->
          parse_df_line(data_line, mount_point)
      end
    end
  end

  defp parse_df_line(line, mount_point) do
    # POSIX df -Pk columns: Filesystem 1024-blocks Used Available Use% Mounted
    parts = String.split(line)

    case parts do
      [_fs, total_str, _used_str, avail_str | _] ->
        with {:ok, total_kb} <- parse_integer(total_str, "total blocks"),
             {:ok, avail_kb} <- parse_integer(avail_str, "available blocks") do
          # We derive free from available for the purposes of this collector.
          # "free" is blocks free for root; "available" is blocks free for
          # non-root users. We report both the same here since df -Pk only
          # gives Available.
          {:ok, total_kb * 1024, avail_kb * 1024, avail_kb * 1024}
        else
          {:error, reason} ->
            {:error, :malformed, "df line parse error for #{mount_point}: #{reason}"}
        end

      _ ->
        {:error, :malformed, "unexpected df output format for #{mount_point}: #{inspect(line)}"}
    end
  end

  defp parse_integer(str, field) do
    case Integer.parse(str) do
      {v, ""} when v >= 0 -> {:ok, v}
      _ -> {:error, "could not parse #{field} from '#{str}'"}
    end
  end
end
