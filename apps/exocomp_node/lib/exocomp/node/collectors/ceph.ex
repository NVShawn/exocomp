# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Collectors.Ceph do
  @moduledoc """
  Read-only discovery of local Ceph daemon units.

  The collector recognizes only the systemd unit forms shipped by the
  traditional Ceph packages and cephadm:

    * `ceph-mon@NAME.service`
    * `ceph-mgr@NAME.service`
    * `ceph-osd@ID.service`
    * `ceph-mds@NAME.service`
    * `ceph-radosgw@NAME.service`
    * `ceph-FSID@{mon,mgr,osd,mds,rgw}.ID.service`

  Unit names originate in systemd output, not in the caller. They are parsed
  against the strict grammar in `parse_unit_name/1` before being placed in an
  argv list. All subprocesses use `System.cmd/3` directly; no shell, caller
  supplied executable, or caller supplied argument list is accepted.

  Discovery is deliberately independent of Ceph credentials and Ceph CLI
  access. An empty successful systemd listing means the supported node is
  `:not_member`; inability to query systemd is represented as a bounded
  collection error instead.
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__

  @default_timeout_ms 5_000
  @max_output_bytes 65_536
  @max_unit_bytes 255
  @max_units 256

  @list_args [
    "list-units",
    "--all",
    "--type=service",
    "--no-legend",
    "--no-pager",
    "--plain",
    "ceph*.service"
  ]

  @show_properties ~w[UnitFileState LoadState ActiveState SubState]
  @show_property_flag "--property=UnitFileState,LoadState,ActiveState,SubState"

  # Ceph FSIDs are UUIDs. The value is bounded and contains no path, shell, or
  # systemd control characters, even though it is later used in a unit name.
  @id_pattern ~r/\A[A-Za-z0-9][A-Za-z0-9_.-]{0,127}\z/
  @osd_id_pattern ~r/\A[0-9]{1,10}\z/

  @type daemon_kind :: :mon | :mgr | :osd | :mds | :gateway
  @type daemon :: %{
          kind: daemon_kind(),
          id: String.t(),
          unit: String.t(),
          fsid: String.t() | nil,
          enablement: String.t() | nil,
          load_state: String.t() | nil,
          active_state: String.t() | nil,
          substate: String.t() | nil
        }

  @type discovery_error :: %{
          unit: String.t() | nil,
          error: atom(),
          reason: String.t()
        }

  @doc """
  Discover local Ceph daemon units.

  Options are intended for deterministic tests and bounded deployment
  configuration only:

    * `:timeout_ms` — timeout for each fixed systemctl query.
    * `:cmd_runner` — test seam, either a `fn/3` or `{module, function, args}`
      receiving `(command, argv, command_options)` and returning
      `{output, exit_code}`.
    * `:max_output_bytes` — maximum output accepted from one query.
    * `:max_units` — maximum accepted unit names from one listing.

  Production callers do not receive command or unit parameters. The command
  and the listing glob above are compile-time constants.
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) when is_list(opts) do
    started_at = System.monotonic_time(:microsecond)
    timeout_ms = positive_limit(Keyword.get(opts, :timeout_ms), @default_timeout_ms)
    max_output_bytes = positive_limit(Keyword.get(opts, :max_output_bytes), @max_output_bytes)
    max_units = positive_limit(Keyword.get(opts, :max_units), @max_units)
    runner = Keyword.get(opts, :cmd_runner, {__MODULE__, :default_cmd_runner, []})

    measurements =
      case discover(runner, timeout_ms, max_output_bytes, max_units) do
        {:ok, daemons, errors} ->
          membership = if daemons == [] and errors == [], do: :not_member, else: :member

          %{
            membership: Types.ok(membership, "status"),
            daemons: Types.ok(daemons, "daemon"),
            errors: Types.ok(errors, "error")
          }

        {:error, kind, reason} ->
          %{
            membership: Types.err(kind, reason),
            daemons: Types.err(kind, reason),
            errors: Types.ok([], "error")
          }
      end

    Types.build(@source, @collector_version, started_at, measurements)
  end

  @doc false
  @spec default_cmd_runner(String.t(), [String.t()], keyword()) ::
          {String.t(), non_neg_integer()}
  def default_cmd_runner(command, args, command_options) do
    System.cmd(command, args, command_options)
  end

  @doc "Parse one systemd unit name against the shipped Ceph grammar."
  @spec parse_unit_name(term()) :: {:ok, daemon()} | :ignore
  def parse_unit_name(unit) when is_binary(unit) do
    cond do
      byte_size(unit) == 0 or byte_size(unit) > @max_unit_bytes or not String.valid?(unit) ->
        :ignore

      true ->
        parse_traditional_unit(unit) || parse_cephadm_unit(unit) || :ignore
    end
  end

  def parse_unit_name(_unit), do: :ignore

  # ---------------------------------------------------------------------------
  # Discovery
  # ---------------------------------------------------------------------------

  defp discover(runner, timeout_ms, max_output_bytes, max_units) do
    with {:ok, listing} <- run_systemctl(@list_args, runner, timeout_ms, max_output_bytes),
         {:ok, units} <- parse_listing(listing, max_output_bytes, max_units) do
      units
      |> Enum.map(fn %{unit: unit} = daemon ->
        case inspect_unit(daemon, runner, timeout_ms, max_output_bytes) do
          {:ok, inspected} -> {:ok, inspected}
          {:error, kind, reason} -> {:error, unit, kind, reason}
        end
      end)
      |> reduce_unit_results()
    end
  end

  defp parse_listing(output, max_output_bytes, max_units)
       when is_binary(output) and is_integer(max_output_bytes) and is_integer(max_units) do
    cond do
      byte_size(output) > max_output_bytes ->
        {:error, :output_limit, "systemctl unit listing exceeded the output limit"}

      not String.valid?(output) ->
        {:error, :malformed, "systemctl unit listing was not valid text"}

      true ->
        units =
          output
          |> String.split(~r/\r?\n/, trim: true)
          |> Enum.flat_map(&unit_from_listing_line/1)
          |> Enum.uniq_by(& &1.unit)
          |> Enum.sort_by(& &1.unit)

        if length(units) > max_units do
          {:error, :output_limit, "systemctl unit listing exceeded the unit limit"}
        else
          {:ok, units}
        end
    end
  end

  defp parse_listing(_output, _max_output_bytes, _max_units) do
    {:error, :malformed, "systemctl unit listing was not text"}
  end

  # `--plain --no-legend` makes the first token the unit, but accepting a
  # leading status marker keeps parsing harmlessly tolerant of distributions
  # that ignore `--plain`. Every candidate still passes the strict grammar.
  defp unit_from_listing_line(line) when is_binary(line) do
    line
    |> String.split()
    |> Enum.find_value([], fn token ->
      case parse_unit_name(token) do
        {:ok, daemon} -> [daemon]
        :ignore -> false
      end
    end)
  end

  defp reduce_unit_results(results) do
    Enum.reduce(results, {[], []}, fn
      {:ok, daemon}, {daemons, errors} ->
        {[daemon | daemons], errors}

      {:error, unit, kind, reason}, {daemons, errors} ->
        {daemons, [%{unit: unit, error: kind, reason: reason} | errors]}
    end)
    |> then(fn {daemons, errors} ->
      {:ok, Enum.sort_by(daemons, & &1.unit), Enum.reverse(errors)}
    end)
  end

  defp inspect_unit(%{unit: unit} = daemon, runner, timeout_ms, max_output_bytes) do
    args = ["show", "--no-pager", @show_property_flag, unit]

    with {:ok, output} <- run_systemctl(args, runner, timeout_ms, max_output_bytes),
         {:ok, properties} <- parse_show_output(output),
         :ok <- validate_property_values(properties) do
      {:ok,
       %{
         kind: daemon.kind,
         id: daemon.id,
         unit: daemon.unit,
         fsid: daemon.fsid,
         enablement: Map.get(properties, "UnitFileState"),
         load_state: Map.get(properties, "LoadState"),
         active_state: Map.get(properties, "ActiveState"),
         substate: Map.get(properties, "SubState")
       }}
    end
  end

  defp parse_show_output(output) when is_binary(output) do
    cond do
      not String.valid?(output) ->
        {:error, :malformed, "systemctl returned invalid unit state text"}

      String.trim(output) == "" ->
        {:error, :malformed, "systemctl returned empty unit state"}

      true ->
        output
        |> String.split(~r/\r?\n/, trim: true)
        |> Enum.reduce_while({:ok, %{}}, fn line, {:ok, properties} ->
          case String.split(line, "=", parts: 2) do
            [key, value]
            when key in @show_properties and map_size(properties) < length(@show_properties) ->
              if Map.has_key?(properties, key) do
                {:halt, {:error, :malformed, "systemctl returned duplicate unit state"}}
              else
                {:cont, {:ok, Map.put(properties, key, String.trim(value))}}
              end

            [key, _value] when key in @show_properties ->
              {:halt, {:error, :malformed, "systemctl returned duplicate unit state"}}

            _other ->
              {:halt, {:error, :malformed, "systemctl returned malformed unit state"}}
          end
        end)
        |> case do
          {:ok, properties} when map_size(properties) == length(@show_properties) ->
            {:ok, properties}

          {:ok, _partial} ->
            {:error, :malformed, "systemctl returned incomplete unit state"}

          error ->
            error
        end
    end
  end

  defp parse_show_output(_output), do: {:error, :malformed, "systemctl returned non-text state"}

  defp validate_property_values(properties) do
    if Enum.all?(properties, fn {_key, value} -> valid_property_value?(value) end) do
      :ok
    else
      {:error, :malformed, "systemctl returned invalid unit state"}
    end
  end

  defp valid_property_value?(value) when is_binary(value) do
    # Restrict to printable ASCII: 0x20 (space) through 0x7E (~).
    # The original check `!= 0x7F` would admit bytes 0x80-0xFF (UTF-8
    # continuation/start bytes) because those values are all > 0x20.
    # The `<= 0x7E` upper bound correctly excludes both 0x7F (DEL) and every
    # non-ASCII byte, matching the documented intent.
    byte_size(value) <= 256 and
      value |> :binary.bin_to_list() |> Enum.all?(&(&1 >= 0x20 and &1 <= 0x7E))
  end

  defp valid_property_value?(_value), do: false

  # ---------------------------------------------------------------------------
  # Fixed command execution
  # ---------------------------------------------------------------------------

  defp run_systemctl(args, runner, timeout_ms, max_output_bytes) do
    task =
      Task.async(fn ->
        safe_runner_call(runner, "systemctl", args, stderr_to_stdout: true)
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, output, 0}} when byte_size(output) <= max_output_bytes ->
        {:ok, output}

      {:ok, {:ok, output, 0}} when is_binary(output) ->
        _ = output
        {:error, :output_limit, "systemctl output exceeded the output limit"}

      {:ok, {:ok, _output, exit_code}} when is_integer(exit_code) ->
        {:error, :unavailable, "systemctl exited with a non-zero status"}

      {:ok, {:error, :timeout}} ->
        {:error, :timeout, "systemctl query timed out"}

      {:ok, {:error, _reason}} ->
        {:error, :unavailable, "systemctl query failed"}

      {:ok, _other} ->
        {:error, :malformed, "systemctl runner returned an invalid result"}

      {:exit, _reason} ->
        {:error, :unavailable, "systemctl query failed"}

      nil ->
        {:error, :timeout, "systemctl query timed out"}
    end
  end

  defp safe_runner_call(runner, command, args, command_options) do
    result = call_runner(runner, command, args, command_options)

    case result do
      {output, exit_code} when is_binary(output) and is_integer(exit_code) ->
        {:ok, output, exit_code}

      _other ->
        {:error, :malformed}
    end
  rescue
    _exception -> {:error, :runner_failed}
  catch
    _kind, _reason -> {:error, :runner_failed}
  end

  defp call_runner(runner, command, args, command_options) when is_function(runner, 3) do
    runner.(command, args, command_options)
  end

  defp call_runner({module, function, extra_args}, command, args, command_options)
       when is_atom(module) and is_atom(function) and is_list(extra_args) do
    apply(module, function, [command, args, command_options] ++ extra_args)
  end

  defp call_runner(_runner, _command, _args, _command_options), do: :invalid_runner

  # ---------------------------------------------------------------------------
  # Unit grammar
  # ---------------------------------------------------------------------------

  defp parse_traditional_unit(unit) do
    case Regex.run(
           ~r/\Aceph-(mon|mgr|osd|mds)@([A-Za-z0-9][A-Za-z0-9_.-]{0,127})\.service\z/,
           unit,
           capture: :all_but_first
         ) do
      [kind, id] ->
        if valid_id_for_kind?(kind, id) do
          {:ok, daemon_descriptor(kind, id, unit, nil)}
        else
          false
        end

      _other ->
        case Regex.run(
               ~r/\Aceph-radosgw@([A-Za-z0-9][A-Za-z0-9_.-]{0,127})\.service\z/,
               unit,
               capture: :all_but_first
             ) do
          [id] -> {:ok, daemon_descriptor("rgw", id, unit, nil)}
          _other -> false
        end
    end
  end

  defp parse_cephadm_unit(unit) do
    case Regex.run(
           ~r/\Aceph-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})@(mon|mgr|osd|mds|rgw)\.([A-Za-z0-9][A-Za-z0-9_.-]{0,127})\.service\z/,
           unit,
           capture: :all_but_first
         ) do
      [fsid, kind, id] ->
        if valid_id_for_kind?(kind, id) do
          {:ok, daemon_descriptor(kind, id, unit, fsid)}
        else
          false
        end

      _other ->
        false
    end
  end

  defp valid_id_for_kind?("osd", id), do: Regex.match?(@osd_id_pattern, id)

  defp valid_id_for_kind?(kind, id) when kind in ["mon", "mgr", "mds", "rgw"],
    do: Regex.match?(@id_pattern, id)

  defp valid_id_for_kind?(_kind, _id), do: false

  defp daemon_descriptor("mon", id, unit, fsid), do: %{kind: :mon, id: id, unit: unit, fsid: fsid}
  defp daemon_descriptor("mgr", id, unit, fsid), do: %{kind: :mgr, id: id, unit: unit, fsid: fsid}
  defp daemon_descriptor("osd", id, unit, fsid), do: %{kind: :osd, id: id, unit: unit, fsid: fsid}
  defp daemon_descriptor("mds", id, unit, fsid), do: %{kind: :mds, id: id, unit: unit, fsid: fsid}

  defp daemon_descriptor("rgw", id, unit, fsid),
    do: %{kind: :gateway, id: id, unit: unit, fsid: fsid}

  defp positive_limit(value, _default) when is_integer(value) and value > 0, do: value
  defp positive_limit(_value, default), do: default
end
