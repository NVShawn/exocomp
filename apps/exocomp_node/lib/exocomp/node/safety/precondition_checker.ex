defmodule Exocomp.Node.Safety.PreconditionChecker do
  @moduledoc """
  Re-evaluates system state at execution time and verifies it matches the
  preconditions that were present when the coordinator issued the approval token.

  ## Design

  The approval token binds an `evidence_hash` field: the SHA-256 hex digest of
  the canonical evidence map collected when the policy engine produced
  `approval_required`. If system state has changed since approval (e.g. the
  service was already restarted, or disk usage changed), the hashes will differ
  and execution is blocked.

  `verify/3` collects fresh evidence for the action type and target, hashes it
  identically to how the coordinator did, and compares byte-for-byte with the
  token's `evidence_hash`.

  ## Evidence collection

  Evidence collectors implement the `Exocomp.Node.Safety.PreconditionChecker`
  behaviour via `c:collect/2`. The production collector is
  `Exocomp.Node.Safety.PreconditionChecker.SystemCollector`. A custom
  collector is injectable for tests via application config:

      # In config or test setup:
      Application.put_env(:exocomp_node, :precondition_evidence_collector, MyMockCollector)

  The collector must produce exactly the same keys and value types that the
  coordinator used when computing `evidence_hash`. Field names and value
  representations are canonical — see the collector documentation for each
  action type.

  ## Fail-closed guarantee

  If evidence collection fails for any reason, `verify/3` returns
  `{:error, {:collection_failed, reason}}` rather than proceeding. Evidence
  collection failures are never treated as matches.

  ## Canonical evidence maps

  For canonical hashing, **only state fields are included** — not `collected_at`
  or other metadata, since a timestamp collected at execution time would never
  match the coordinator's collection timestamp.

  - `:restart_service` — `%{"active_state" => string, "sub_state" => string, "unit_name" => string}`
  - `:vacuum_logs`     — `%{"available_bytes" => integer, "path" => string, "total_bytes" => integer}`
  """

  alias Exocomp.Core.ApprovalToken

  # ---------------------------------------------------------------------------
  # Behaviour — evidence collectors must implement this callback
  # ---------------------------------------------------------------------------

  @doc """
  Collect a fresh canonical evidence map for the given action type and target.

  The returned map must use the same field names and value types that the
  coordinator used when computing the original `evidence_hash`. Only state
  fields are included (no timestamps).

  Returns `{:ok, evidence_map}` on success, `{:error, reason}` on failure.
  """
  @callback collect(action_id :: atom(), target :: String.t()) ::
              {:ok, %{String.t() => term()}} | {:error, term()}

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Verifies that the current system state matches the preconditions bound in the
  approval token's `evidence_hash`.

  Steps:
  1. Collect fresh evidence for the given `action_id` and `target`.
  2. Compute `Exocomp.Core.ApprovalToken.hash_evidence/1` on the fresh map.
  3. Compare byte-for-byte with `token.evidence_hash`.
  4. Return `:ok` on match, `{:error, :precondition_changed}` on mismatch.
  5. Return `{:error, {:collection_failed, reason}}` if collection fails
     (fail closed — the action MUST NOT proceed).

  The token map may have atom or string keys for `evidence_hash`.
  """
  @spec verify(token :: map(), action_id :: atom(), target :: String.t()) ::
          :ok
          | {:error, :precondition_changed}
          | {:error, {:collection_failed, reason :: term()}}
  def verify(token, action_id, target) do
    collector = collector_impl()

    case collector.collect(action_id, target) do
      {:ok, evidence_map} ->
        fresh_hash = ApprovalToken.hash_evidence(evidence_map)
        token_hash = token_evidence_hash(token)

        if fresh_hash == token_hash do
          :ok
        else
          {:error, :precondition_changed}
        end

      {:error, reason} ->
        {:error, {:collection_failed, reason}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp collector_impl do
    Application.get_env(
      :exocomp_node,
      :precondition_evidence_collector,
      Exocomp.Node.Safety.PreconditionChecker.SystemCollector
    )
  end

  # Accept both atom-keyed (%{evidence_hash: ...}) and string-keyed
  # (%{"evidence_hash" => ...}) tokens — consistent with ApprovalVerifier.
  defp token_evidence_hash(token) do
    Map.get(token, :evidence_hash) || Map.get(token, "evidence_hash")
  end
end

defmodule Exocomp.Node.Safety.PreconditionChecker.SystemCollector do
  @moduledoc """
  Production evidence collector for `Exocomp.Node.Safety.PreconditionChecker`.

  Collects fresh, canonical evidence maps from the operating system using
  unprivileged, read-only APIs.

  ## :restart_service

  Invokes `systemctl show --property=ActiveState,SubState <unit>` via a direct
  argv list (no shell). Returns:

      %{
        "active_state" => String.t(),
        "sub_state"    => String.t(),
        "unit_name"    => String.t()
      }

  ## :vacuum_logs

  Invokes `df -Pk <path>` via a direct argv list (no shell). Returns:

      %{
        "available_bytes" => non_neg_integer(),
        "total_bytes"     => non_neg_integer(),
        "path"            => String.t()
      }

  ## Injectable command runner

  The OS command runner is injectable for unit tests:

      Application.put_env(:exocomp_node, :precondition_cmd_runner,
        {MyMock, :run, []})

  The MFA is invoked as `apply(mod, fun, [cmd, args, opts | extra_args])`.
  The default runner delegates to `System.cmd/3`.
  """

  @behaviour Exocomp.Node.Safety.PreconditionChecker

  @systemctl_timeout_ms 5_000

  @impl true
  def collect(:restart_service, unit_name) when is_binary(unit_name) do
    collect_systemd_state(unit_name)
  end

  def collect(:vacuum_logs, path) when is_binary(path) do
    collect_disk_state(path)
  end

  def collect(action_id, _target) do
    {:error, {:unknown_action, action_id}}
  end

  @doc false
  def default_cmd_runner(cmd, args, cmd_opts) do
    System.cmd(cmd, args, cmd_opts)
  end

  # ---------------------------------------------------------------------------
  # :restart_service — systemctl show
  # ---------------------------------------------------------------------------

  defp collect_systemd_state(unit_name) do
    {mod, fun, extra_args} = cmd_runner()

    cmd = "systemctl"
    args = ["show", "--no-pager", "--property=ActiveState,SubState", unit_name]
    opts = [stderr_to_stdout: true]

    task =
      Task.async(fn ->
        apply(mod, fun, [cmd, args, opts] ++ extra_args)
      end)

    case Task.yield(task, @systemctl_timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        parse_systemctl_output(output, unit_name)

      {:ok, {_output, exit_code}} ->
        {:error, {:systemctl_failed, exit_code}}

      nil ->
        {:error, :timeout}
    end
  end

  defp parse_systemctl_output(output, unit_name) do
    props =
      output
      |> String.split("\n", trim: true)
      |> Enum.reduce(%{}, fn line, acc ->
        case String.split(line, "=", parts: 2) do
          [k, v] -> Map.put(acc, String.trim(k), String.trim(v))
          _ -> acc
        end
      end)

    active_state = Map.get(props, "ActiveState")
    sub_state = Map.get(props, "SubState")

    cond do
      is_nil(active_state) ->
        {:error, :missing_active_state}

      is_nil(sub_state) ->
        {:error, :missing_sub_state}

      true ->
        {:ok,
         %{
           "active_state" => active_state,
           "sub_state" => sub_state,
           "unit_name" => unit_name
         }}
    end
  end

  # ---------------------------------------------------------------------------
  # :vacuum_logs — df
  # ---------------------------------------------------------------------------

  defp collect_disk_state(path) do
    {mod, fun, extra_args} = cmd_runner()

    cmd = "df"
    args = ["-Pk", path]
    opts = [stderr_to_stdout: false]

    task =
      Task.async(fn ->
        apply(mod, fun, [cmd, args, opts] ++ extra_args)
      end)

    case Task.yield(task, @systemctl_timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        parse_df_output(output, path)

      {:ok, {_output, exit_code}} ->
        {:error, {:df_failed, exit_code}}

      nil ->
        {:error, :timeout}
    end
  end

  defp parse_df_output(output, path) do
    lines = output |> String.split("\n", trim: true) |> Enum.drop(1)

    case lines do
      [] ->
        {:error, :malformed_df_output}

      [line | _] ->
        parts = String.split(line)

        case parts do
          [_fs, total_str, _used_str, avail_str | _] ->
            with {total_kb, ""} <- Integer.parse(total_str),
                 {avail_kb, ""} <- Integer.parse(avail_str) do
              {:ok,
               %{
                 "available_bytes" => avail_kb * 1024,
                 "path" => path,
                 "total_bytes" => total_kb * 1024
               }}
            else
              _ -> {:error, :malformed_df_output}
            end

          _ ->
            {:error, {:malformed_df_output, line}}
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Command runner injection
  # ---------------------------------------------------------------------------

  defp cmd_runner do
    Application.get_env(
      :exocomp_node,
      :precondition_cmd_runner,
      {__MODULE__, :default_cmd_runner, []}
    )
  end
end
