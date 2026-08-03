# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Collectors.ServiceInventory do
  @moduledoc """
  Collector for enabled systemd service inventory.

  Discovers all enabled and enabled-runtime service units, then queries their
  current state and configuration. Filters the result to exclude unit types that
  should not be expected to run.

  ## Security model

  No caller input influences the argv. `systemctl` is invoked with a fixed
  argv list. **No shell is involved.**

  ## Output limits and timeout

  Output per unit is capped at `@max_output_bytes`. Each subprocess is given
  `@timeout_ms` to complete; if it hangs, the task is killed and a `:timeout`
  partial error is returned for that service.

  ## Filtering

  Excluded from the inventory:
  - Completed oneshot services (ActiveState=inactive, Type=oneshot)
  - Static units (UnitFileState=static)
  - Indirect units (UnitFileState=indirect)
  - Disabled units (UnitFileState=disabled)
  - Masked units (UnitFileState=masked)
  - Generated units (UnitFileState=generated)
  - exocomp-node.service (exclude self-reference)

  Failed systemd conditions mark the service as not_applicable.

  ## Collector version history

  - 1: Initial release — list enabled services with Type, RemainAfterExit,
       Condition, LoadState, ActiveState, SubState.
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__

  # Fixed properties to query from each service unit.
  @properties ~w[
    Type
    RemainAfterExit
    Condition
    ConditionResult
    UnitFileState
    LoadState
    ActiveState
    SubState
  ]

  @property_flag "--property=#{Enum.join(@properties, ",")}"

  @timeout_ms 5_000
  @max_output_bytes 65_536

  @doc """
  Collect enabled and enabled-runtime service inventory.

  Returns one measurement group per included service unit.

  Options:
  - `:timeout_ms` — override the per-service subprocess timeout in
    milliseconds. Defaults to #{@timeout_ms}.
  - `:cmd_runner` — MFA `{mod, fun, extra_args}` for running external
    commands, injected for testing. The function receives
    `(cmd, args, cmd_opts)` and returns `{output, exit_code}`.
    Defaults to `System.cmd/3`.
  - `:list_runner` — MFA `{mod, fun, extra_args}` for listing enabled
    services, injected for testing. The function receives
    `(list_cmd, list_args, cmd_opts)` and returns `{output, exit_code}`.
    Defaults to `System.cmd/3`.
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) do
    started_at = System.monotonic_time(:microsecond)
    timeout_ms = Keyword.get(opts, :timeout_ms, @timeout_ms)
    cmd_runner = Keyword.get(opts, :cmd_runner, {__MODULE__, :default_cmd_runner, []})
    list_runner = Keyword.get(opts, :list_runner, {__MODULE__, :default_cmd_runner, []})

    enabled_units = list_enabled_units(list_runner)

    measurements =
      enabled_units
      |> Enum.filter(&include_unit?(&1, timeout_ms, cmd_runner))
      |> Enum.flat_map(fn unit ->
        collect_unit(unit, timeout_ms, cmd_runner)
      end)
      |> Map.new()

    Types.build(@source, @collector_version, started_at, measurements)
  end

  @doc false
  def default_cmd_runner(cmd, args, cmd_opts) do
    System.cmd(cmd, args, cmd_opts)
  end

  # Helper to call runner whether it's a function or MFA tuple
  defp call_runner(runner, cmd, args, cmd_opts) when is_function(runner, 3) do
    runner.(cmd, args, cmd_opts)
  end

  defp call_runner({mod, fun, extra_args}, cmd, args, cmd_opts) do
    apply(mod, fun, [cmd, args, cmd_opts] ++ extra_args)
  end

  # ---------------------------------------------------------------------------
  # List enabled services
  # ---------------------------------------------------------------------------

  # Query systemctl for all enabled and enabled-runtime services.
  # Returns a list of unit names, or an empty list on error.
  defp list_enabled_units(runner) do
    cmd = "systemctl"

    args = [
      "list-unit-files",
      "--type=service",
      "--state=enabled,enabled-runtime",
      "--no-legend",
      "--no-pager",
      "--plain"
    ]

    cmd_opts = [stderr_to_stdout: true]

    task =
      Task.async(fn ->
        call_runner(runner, cmd, args, cmd_opts)
      end)

    case Task.yield(task, @timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.map(fn line ->
          # Each line is "unit-name<spaces>state<spaces>preset"
          # We only need the unit name, which is the first whitespace-delimited field
          line
          |> String.split()
          |> List.first()
        end)
        |> Enum.filter(&(&1 != ""))

      _error ->
        []
    end
  end

  # ---------------------------------------------------------------------------
  # Filtering
  # ---------------------------------------------------------------------------

  # Quick filter: exclude exocomp-node.service and check if we should query it.
  # This is a pre-check to avoid querying every service.
  defp include_unit?(unit, _timeout_ms, _cmd_runner) when unit == "exocomp-node.service" do
    false
  end

  defp include_unit?(_unit, _timeout_ms, _cmd_runner) do
    true
  end

  # Final filter after collecting properties: apply exclusion rules.
  defp should_include_after_query?(props) do
    # Exclude static, indirect, disabled, masked, generated units
    unit_file_state = Map.get(props, "UnitFileState", "")

    excluded_file_states = ["static", "indirect", "disabled", "masked", "generated"]

    if Enum.member?(excluded_file_states, unit_file_state) do
      false
    else
      # Exclude completed oneshots (Type=oneshot and ActiveState=inactive)
      type = Map.get(props, "Type", "")
      active_state = Map.get(props, "ActiveState", "")

      if type == "oneshot" and active_state == "inactive" do
        false
      else
        true
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Per-unit collection
  # ---------------------------------------------------------------------------

  # Returns a list of {atom_key, measurement} pairs for one service.
  defp collect_unit(unit, timeout_ms, cmd_runner) do
    key_prefix = unit_to_key(unit)

    result =
      run_systemctl(unit, timeout_ms, cmd_runner)

    case result do
      {:ok, props} ->
        unless should_include_after_query?(props) do
          # Unit failed final filter, return empty list (no measurements for it)
          []
        else
          Enum.map(@properties, fn prop ->
            atom_key = :"#{key_prefix}_#{String.downcase(prop)}"

            measurement =
              case Map.fetch(props, prop) do
                {:ok, value} ->
                  # Special handling for Condition: mark failed conditions as not_applicable
                  if prop == "ConditionResult" and value == "failed" do
                    Types.ok("not_applicable", "string")
                  else
                    Types.ok(value, "string")
                  end

                :error ->
                  Types.err(:unavailable, "#{prop} not in systemctl output for #{unit}")
              end

            {atom_key, measurement}
          end)
        end

      {:error, kind, reason} ->
        Enum.map(@properties, fn prop ->
          atom_key = :"#{key_prefix}_#{String.downcase(prop)}"
          {atom_key, Types.err(kind, reason)}
        end)
    end
  end

  # ---------------------------------------------------------------------------
  # systemctl invocation
  # ---------------------------------------------------------------------------

  defp run_systemctl(unit, timeout_ms, runner) do
    # argv list — no shell, no interpolation of external input into a shell string
    cmd = "systemctl"
    args = ["show", "--no-pager", @property_flag, unit]
    cmd_opts = [stderr_to_stdout: true]

    task =
      Task.async(fn ->
        call_runner(runner, cmd, args, cmd_opts)
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        cond do
          byte_size(output) > @max_output_bytes ->
            {:error, :output_limit,
             "systemctl output for #{unit} exceeded #{@max_output_bytes} bytes"}

          true ->
            parse_systemctl_output(output, unit)
        end

      {:ok, {_output, exit_code}} ->
        {:error, :unavailable, "systemctl exited #{exit_code} for #{unit}"}

      nil ->
        {:error, :timeout, "systemctl timed out after #{timeout_ms}ms for #{unit}"}
    end
  end

  # ---------------------------------------------------------------------------
  # Output parsing
  # ---------------------------------------------------------------------------

  defp parse_systemctl_output(output, unit) do
    if String.trim(output) == "" do
      {:error, :unavailable, "systemctl returned empty output for #{unit}"}
    else
      props =
        output
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn line, acc ->
          case String.split(line, "=", parts: 2) do
            [key, value] -> Map.put(acc, String.trim(key), String.trim(value))
            _ -> acc
          end
        end)

      {:ok, props}
    end
  end

  # ---------------------------------------------------------------------------
  # Key helpers
  # ---------------------------------------------------------------------------

  # Converts a service unit name to a safe atom key prefix.
  # "sshd.service" -> "sshd_service"
  # "my-cool.service" -> "my_cool_service"
  defp unit_to_key(unit) do
    unit
    |> String.replace(".", "_")
    |> String.replace("-", "_")
    |> String.replace(~r/[^a-zA-Z0-9_]/, "")
  end
end
