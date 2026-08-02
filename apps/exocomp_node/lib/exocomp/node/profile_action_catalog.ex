# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.ProfileActionCatalog do
  @moduledoc """
  Fixed catalog for actions implemented by a shipped cluster profile.

  The coordinator can request only the typed action exposed here.  The node
  owns the helper path, protocol encoding, subprocess limits, and target lock;
  none of those are request-controlled.
  """

  alias Exocomp.Node.ExecutorLock

  @profile_id "ceph"
  @profile_version 1
  @action_id "restart_failed_daemon"
  @sudo_path "/usr/bin/sudo"
  @helper_path "/opt/exocomp/node/bin/profile-action-helper"
  @timeout_ms 30_000
  @output_limit_bytes 65_536

  @type request :: %{
          profile_id: String.t(),
          profile_version: pos_integer(),
          action_id: String.t(),
          target_unit: String.t()
        }

  @doc "Returns the helper path from the installed, fixed node catalog."
  @spec helper_path() :: String.t()
  def helper_path, do: @helper_path

  @doc "Returns the typed action IDs installed on this node."
  @spec action_ids() :: [String.t()]
  def action_ids, do: [@action_id]

  @doc "Builds the exact helper wire request, including its terminating newline."
  @spec request_line(request()) :: {:ok, binary()} | {:error, term()}
  def request_line(%{
        profile_id: @profile_id,
        profile_version: @profile_version,
        action_id: @action_id,
        target_unit: target_unit
      }) do
    with :ok <- validate_target_unit(target_unit) do
      {:ok, "1\tceph\t1\trestart_failed_daemon\t#{target_unit}\n"}
    end
  end

  def request_line(_request), do: {:error, :unsupported_profile_action}

  @doc "Validates and executes one typed profile action through the node helper."
  @spec execute(request(), keyword()) :: {:ok, map()} | {:error, term()}
  def execute(request, opts \\ []) do
    lock_server = Keyword.get(opts, :lock_server, ExecutorLock)
    runner = Keyword.get(opts, :runner, configured_runner())

    with {:ok, line} <- request_line(request),
         :ok <- ExecutorLock.acquire(lock_server, request.target_unit) do
      try do
        run_once(runner, line)
      after
        ExecutorLock.release(lock_server, request.target_unit)
      end
    end
  end

  @doc false
  def valid_target_unit?(unit), do: validate_target_unit(unit) == :ok

  defp run_once(runner, line) do
    result =
      invoke_runner(runner, @sudo_path, [@helper_path],
        input: line,
        timeout_ms: @timeout_ms,
        output_limit_bytes: @output_limit_bytes
      )

    case result do
      {:ok, output, 0} when is_binary(output) ->
        {:ok, %{status: "accepted", output: output, target_unit: target_from_line(line)}}

      {:ok, output, exit_code} when is_binary(output) and is_integer(exit_code) ->
        {:error, {:helper_rejected, exit_code, output}}

      {:error, _reason} = error ->
        error

      other ->
        {:error, {:invalid_helper_result, other}}
    end
  end

  defp invoke_runner(module, executable, argv, opts) when is_atom(module),
    do: module.run(executable, argv, opts)

  defp invoke_runner(fun, executable, argv, opts) when is_function(fun, 3),
    do: fun.(executable, argv, opts)

  defp configured_runner do
    Application.get_env(:exocomp_node, :profile_action_runner, Exocomp.Node.SystemCommander)
  end

  defp validate_target_unit(unit) when is_binary(unit) do
    unit = String.trim_trailing(unit, ".service")

    cond do
      Regex.match?(~r/\Aceph-osd@[0-9]{1,10}\z/, unit) ->
        :ok

      Regex.match?(~r/\Aceph-(?:mon|mgr|mds|radosgw)@[A-Za-z0-9][A-Za-z0-9_.-]{0,127}\z/, unit) ->
        :ok

      unit == "ceph-crash" ->
        :ok

      true ->
        {:error, :invalid_target_unit}
    end
  end

  defp validate_target_unit(_unit), do: {:error, :invalid_target_unit}

  defp target_from_line(line) do
    line |> String.trim_trailing("\n") |> String.split("\t") |> List.last()
  end
end
