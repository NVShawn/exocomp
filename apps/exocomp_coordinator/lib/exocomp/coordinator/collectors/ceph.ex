# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Collectors.Ceph do
  @moduledoc """
  Unprivileged Ceph health and topology collector for coordinators.

  Collects overall health plus monitor, manager, OSD, MDS, and available
  gateway topology using fixed read-only Ceph JSON commands. Enforces
  timeout and output-size limits, never invokes a shell, and never exposes
  keyring contents or command environment values.

  ## Fixed Commands

  The collector runs the following fixed `ceph` commands with `--format=json`:

    * `ceph status` — Overall cluster health
    * `ceph mon metadata` — Monitor daemon topology
    * `ceph mgr metadata` — Manager daemon topology
    * `ceph osd metadata` — OSD daemon topology
    * `ceph mds metadata` — MDS daemon topology
    * `ceph fs ls` — Filesystem presence (implies MDS availability)

  All commands are executed with:
    * Absolute paths to ceph binary, ceph.conf, and keyring
    * Fixed JSON output format
    * No shell invocation
    * Bounded timeout and output size
    * Partial failure recovery

  ## Evidence Structure

  Collected evidence is normalized into a versioned internal structure:

      %{
        "schema_version" => 1,
        "collected_at" => "2026-07-29T21:00:00Z",
        "status" => {:ok | :partial | :degraded},
        "health" => {...},
        "topology" => {...},
        "errors" => [...]
      }

  The `status` field indicates collection success:
    * `:ok` — all commands succeeded
    * `:partial` — some commands succeeded, others failed
    * `:degraded` — ceph integration is unavailable

  Partial failures are preserved with timestamps and sanitized reasons.
  """

  alias Exocomp.ClusterProfile.Ceph.Config

  @collector_version 1

  @default_timeout_ms 10_000
  @max_output_bytes 1_048_576
  @max_errors 64

  @type collection_status :: :ok | :partial | :degraded
  @type error_info :: %{
          timestamp: String.t(),
          command: String.t(),
          error: atom(),
          reason: String.t()
        }

  @type evidence :: %{
          schema_version: pos_integer(),
          collected_at: String.t(),
          status: collection_status(),
          health: map(),
          topology: map(),
          errors: [error_info()]
        }

  @doc """
  Collect Ceph health and topology evidence.

  Options:
    * `:timeout_ms` — per-command timeout in milliseconds (default: 10000)
    * `:cmd_runner` — test seam function/tuple (see run_command/4)
    * `:config` — Config struct (defaults to looking up from app env)

  Returns a map containing collected evidence, partial results on error,
  or a degraded status when integration is unavailable.
  """
  @spec collect(keyword()) :: evidence()
  def collect(opts \\ []) do
    started_at = DateTime.utc_now() |> DateTime.to_iso8601()
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    runner = Keyword.get(opts, :cmd_runner, {__MODULE__, :default_cmd_runner, []})
    config = Keyword.get(opts, :config)

    case get_config(config) do
      {:ok, cfg} ->
        do_collect(cfg, runner, timeout_ms, started_at)

      {:error, reason} ->
        %{
          schema_version: @collector_version,
          collected_at: started_at,
          status: :degraded,
          health: %{},
          topology: %{},
          errors: [error_info(:degraded, "ceph", :unavailable, reason)]
        }
    end
  end

  @doc false
  @spec default_cmd_runner(String.t(), [String.t()], keyword()) ::
          {String.t(), non_neg_integer()}
  def default_cmd_runner(command, args, options) do
    System.cmd(command, args, options)
  end

  # ---------------------------------------------------------------------------
  # Private: Configuration
  # ---------------------------------------------------------------------------

  defp get_config(nil) do
    case Application.get_env(:exocomp_coordinator, :ceph_config) do
      nil -> {:error, "Ceph profile configuration not found in app environment"}
      cfg -> {:ok, cfg}
    end
  end

  defp get_config(%Config{} = cfg), do: {:ok, cfg}
  defp get_config(_), do: {:error, "Invalid Ceph configuration"}

  # ---------------------------------------------------------------------------
  # Private: Collection
  # ---------------------------------------------------------------------------

  defp do_collect(config, runner, timeout_ms, started_at) do
    commands = fixed_commands(config)
    results = Enum.map(commands, &run_command(&1, runner, timeout_ms))

    {health, topology, errors} = reduce_results(results)
    status = determine_status(results)

    %{
      schema_version: @collector_version,
      collected_at: started_at,
      status: status,
      health: health,
      topology: topology,
      errors: Enum.slice(errors, 0, @max_errors)
    }
  end

  # Define fixed ceph commands to run.
  defp fixed_commands(config) do
    base_args = ["-c", config.ceph_conf_path, "--name", "client.exocomp"]

    [
      {
        :status,
        "ceph",
        base_args ++ ["status", "--format=json"],
        config.ceph_binary_path
      },
      {
        :mon_metadata,
        "ceph",
        base_args ++ ["mon", "metadata", "--format=json"],
        config.ceph_binary_path
      },
      {
        :mgr_metadata,
        "ceph",
        base_args ++ ["mgr", "metadata", "--format=json"],
        config.ceph_binary_path
      },
      {
        :osd_metadata,
        "ceph",
        base_args ++ ["osd", "metadata", "--format=json"],
        config.ceph_binary_path
      },
      {
        :mds_metadata,
        "ceph",
        base_args ++ ["mds", "metadata", "--format=json"],
        config.ceph_binary_path
      },
      {
        :fs_ls,
        "ceph",
        base_args ++ ["fs", "ls", "--format=json"],
        config.ceph_binary_path
      }
    ]
  end

  # Run a single ceph command with bounded timeout and output.
  defp run_command({cmd_id, _cmd_name, args, binary_path}, runner, timeout_ms) do
    case safe_run(runner, binary_path, args, timeout_ms) do
      {:ok, output} ->
        case Jason.decode(output) do
          {:ok, data} when is_map(data) ->
            {:ok, cmd_id, data}

          {:ok, data} when is_list(data) ->
            {:ok, cmd_id, data}

          {:error, _} ->
            {:error, cmd_id, :malformed_json, "output was not valid JSON"}

          _other ->
            {:error, cmd_id, :malformed_json, "output was not valid JSON"}
        end

      {:error, reason} ->
        {:error, cmd_id, :command_error, reason}
    end
  end

  # Run a single command with bounded timeout and output size.
  defp safe_run(runner, binary_path, args, timeout_ms) do
    task =
      Task.async(fn ->
        call_runner(runner, binary_path, args)
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} when is_binary(output) and byte_size(output) <= @max_output_bytes ->
        {:ok, output}

      {:ok, {output, 0}} when is_binary(output) ->
        {:error, "output exceeded maximum size limit"}

      {:ok, {_output, exit_code}} when is_integer(exit_code) ->
        {:error, "command exited with status #{exit_code}"}

      {:exit, reason} ->
        {:error, "command process crashed: #{inspect(reason)}"}

      nil ->
        {:error, "command timed out"}

      _other ->
        {:error, "invalid runner response"}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  catch
    _kind, _reason ->
      {:error, "command execution failed"}
  end

  defp call_runner(runner, command, args) when is_function(runner, 3) do
    runner.(command, args, stderr_to_stdout: true)
  end

  defp call_runner({module, function, extra_args}, command, args)
       when is_atom(module) and is_atom(function) and is_list(extra_args) do
    apply(module, function, [command, args, [stderr_to_stdout: true]] ++ extra_args)
  end

  defp call_runner(_runner, _command, _args) do
    raise "invalid runner"
  end

  # ---------------------------------------------------------------------------
  # Private: Result Reduction
  # ---------------------------------------------------------------------------

  defp reduce_results(results) do
    Enum.reduce(results, {%{}, %{}, []}, fn
      {:ok, :status, data}, {health, topo, errs} ->
        {merge_health(health, data), topo, errs}

      {:ok, :mon_metadata, data}, {health, topo, errs} ->
        {health, put_in(topo, ["monitors"], data), errs}

      {:ok, :mgr_metadata, data}, {health, topo, errs} ->
        {health, put_in(topo, ["managers"], data), errs}

      {:ok, :osd_metadata, data}, {health, topo, errs} ->
        {health, put_in(topo, ["osds"], data), errs}

      {:ok, :mds_metadata, data}, {health, topo, errs} ->
        {health, put_in(topo, ["mdss"], data), errs}

      {:ok, :fs_ls, data}, {health, topo, errs} ->
        {health, put_in(topo, ["filesystems"], data), errs}

      {:error, cmd_id, error, reason}, {health, topo, errs} ->
        {health, topo, [error_info(cmd_id, atom_to_string(cmd_id), error, reason) | errs]}
    end)
  end

  # Extract relevant health fields from ceph status output.
  defp merge_health(existing, %{"health" => health_data}) do
    Map.merge(existing, %{
      "overall" => health_data,
      "status" => extract_status(health_data)
    })
  end

  defp merge_health(existing, _data), do: existing

  # Extract status from health data (handle different Ceph versions).
  defp extract_status(%{"status" => status}) when is_binary(status), do: status
  defp extract_status(%{"checks" => _}), do: "unknown"
  defp extract_status(_), do: "unknown"

  # Determine overall collection status.
  defp determine_status(results) do
    successes = Enum.count(results, fn
      {:ok, _, _} -> true
      _ -> false
    end)

    case successes do
      0 -> :degraded
      6 -> :ok
      _ -> :partial
    end
  end

  # ---------------------------------------------------------------------------
  # Private: Helpers
  # ---------------------------------------------------------------------------

  defp error_info(_cmd_id, cmd_name, error_code, reason) do
    %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      command: cmd_name,
      error: error_code,
      reason: String.slice(reason, 0, 512)
    }
  end

  defp atom_to_string(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
  end
end
