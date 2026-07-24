defmodule Exocomp.Node.Safety.DiskPressureCollector do
  @moduledoc """
  Deterministic disk-pressure evidence collector.

  Collects filesystem usage for the configured journal/log partition via
  `df -B1` (byte-unit blocks) using the injectable `OsCommander` behaviour.

  ## Config keys (read from Application env at collection time)

  | Key                             | Type    | Example          |
  |---------------------------------|---------|------------------|
  | `:disk_pressure_warning_pct`    | integer | 75               |
  | `:disk_pressure_critical_pct`   | integer | 90               |
  | `:disk_pressure_mount_point`    | string  | `"/run/log/journal"` |

  All config values are installed by the operator and read at collection time.
  They are never supplied by the caller or from model output.

  ## Return value

      {:ok, %Evidence{}, :below_threshold | :warning | :critical}
      {:error, reason}

  ## Injectable OS commander

  The OS commander defaults to `Application.get_env(:exocomp_node, :os_commander)`
  (falling back to `Exocomp.Node.SystemCommander`).  In tests a mock function or
  module can be set via `Application.put_env(:exocomp_node, :os_commander, fun)`.
  """

  alias Exocomp.Node.Safety.Evidence

  @collector "system.disk.pressure"
  @collector_version "1.0.0"

  @type threshold :: :below_threshold | :warning | :critical

  @doc """
  Collect disk-pressure evidence for the configured mount point.

  Reads `:disk_pressure_mount_point`, `:disk_pressure_warning_pct`, and
  `:disk_pressure_critical_pct` from `Application` config.  The OS commander
  is also sourced from Application config — callers may not supply any of these
  values directly.

  Returns `{:ok, evidence, threshold}` on success, or `{:error, reason}` when
  the OS command fails or the output cannot be parsed.
  """
  @spec collect() :: {:ok, Evidence.t(), threshold()} | {:error, term()}
  def collect do
    commander = os_commander()
    mount_point = Application.fetch_env!(:exocomp_node, :disk_pressure_mount_point)
    warning_pct = Application.fetch_env!(:exocomp_node, :disk_pressure_warning_pct)
    critical_pct = Application.fetch_env!(:exocomp_node, :disk_pressure_critical_pct)

    case run_df(commander, mount_point) do
      {:ok, output, 0} ->
        case parse_df_output(output) do
          {:ok, {used_bytes, free_bytes, total_bytes}} ->
            used_pct = compute_pct(used_bytes, total_bytes)
            evidence = build_evidence(mount_point, used_bytes, free_bytes, total_bytes, used_pct)
            threshold = evaluate_threshold(used_pct, warning_pct, critical_pct)
            {:ok, evidence, threshold}

          {:error, reason} ->
            {:error, reason}
        end

      {:ok, _output, code} ->
        {:error, {:df_exit_code, code}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Compute the integrity hash for an `Evidence` struct.

  The hash is SHA-256 over the canonical pipe-delimited serialisation of all
  evidence fields *except* `integrity_hash` itself.  The `values` map entries
  are sorted by key before serialisation to ensure determinism.

  Callers and tests can use this function to verify that the hash stored in a
  collected evidence record is correct.
  """
  @spec integrity_hash_for(Evidence.t()) :: String.t()
  def integrity_hash_for(%Evidence{} = ev) do
    sorted_values =
      ev.values
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map_join(";", fn {k, v} -> "#{k}=#{v}" end)

    canonical =
      [
        ev.schema_version,
        ev.evidence_id,
        ev.collector,
        ev.collector_version,
        ev.target_id,
        DateTime.to_iso8601(ev.observed_at),
        sorted_values
      ]
      |> Enum.join("|")

    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  # ── private helpers ──────────────────────────────────────────────────────

  defp run_df(commander, mount_point) do
    invoke_commander(commander, "/bin/df", ["-B1", mount_point],
      timeout_ms: 10_000,
      output_limit_bytes: 4_096
    )
  end

  defp invoke_commander(mod_or_fun, executable, argv, opts) do
    case mod_or_fun do
      mod when is_atom(mod) -> mod.run(executable, argv, opts)
      fun when is_function(fun, 3) -> fun.(executable, argv, opts)
    end
  end

  # Parse `df -B1` output.
  #
  # Expected format (Linux, including BusyBox):
  #
  #   Filesystem     1B-blocks       Used  Available Use% Mounted on
  #   /dev/sda1   107374182400  50000000  57374182400  47% /var/log
  #
  # Columns: filesystem, total, used, available, use%, mountpoint
  defp parse_df_output(output) do
    case String.split(output, "\n", trim: true) do
      [_header | [data_line | _]] ->
        case String.split(data_line) do
          [_fs, total_str, used_str, avail_str | _] ->
            with {:ok, total} <- parse_integer(total_str),
                 {:ok, used} <- parse_integer(used_str),
                 {:ok, free} <- parse_integer(avail_str) do
              {:ok, {used, free, total}}
            end

          _other ->
            {:error, {:unexpected_df_format, data_line}}
        end

      _other ->
        {:error, {:unexpected_df_output, output}}
    end
  end

  defp parse_integer(str) do
    case Integer.parse(str) do
      {n, ""} -> {:ok, n}
      _ -> {:error, {:invalid_integer, str}}
    end
  end

  defp compute_pct(_used, 0), do: 0

  defp compute_pct(used, total),
    do: round(used / total * 100)

  defp evaluate_threshold(used_pct, _warning, critical) when used_pct >= critical, do: :critical
  defp evaluate_threshold(used_pct, warning, _critical) when used_pct >= warning, do: :warning
  defp evaluate_threshold(_used_pct, _warning, _critical), do: :below_threshold

  defp build_evidence(mount_point, used_bytes, free_bytes, total_bytes, used_pct) do
    evidence_id = generate_id()
    observed_at = DateTime.utc_now()

    values = %{
      "used_bytes" => Integer.to_string(used_bytes),
      "free_bytes" => Integer.to_string(free_bytes),
      "total_bytes" => Integer.to_string(total_bytes),
      "used_pct" => Integer.to_string(used_pct)
    }

    # Build a partial struct to compute the hash over all non-hash fields.
    partial = %Evidence{
      schema_version: "1",
      evidence_id: evidence_id,
      collector: @collector,
      collector_version: @collector_version,
      target_id: mount_point,
      observed_at: observed_at,
      values: values,
      integrity_hash: ""
    }

    %{partial | integrity_hash: integrity_hash_for(partial)}
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp os_commander do
    Application.get_env(:exocomp_node, :os_commander, Exocomp.Node.SystemCommander)
  end
end
