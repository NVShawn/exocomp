defmodule Exocomp.Node.Executor do
  @moduledoc """
  Restricted executor for installed action definitions.

  The executor enforces the following security invariants before and during
  every execution:

  1. **Typed action catalog** — Only actions present in `ActionCatalog` are
     executable.  Unknown action IDs are immediately rejected.

  2. **Allow-list enforcement** — For `:restart_service`, the target service
     name must appear in the installed allow-list, which is loaded from
     application configuration at startup.  Request or model fields never
     become service names.

  3. **Character-set validation** — Service names are validated against a
     strict regex before the allow-list is consulted.  Shell metacharacters,
     path separators, whitespace, and NUL bytes are rejected unconditionally.

  4. **No shell expansion** — Process invocation uses `System.cmd/3` with an
     explicit argv list (via the `OsCommander` behaviour).  No shell is
     involved; glob expansion, variable substitution, and command substitution
     are structurally impossible.

  5. **Fixed argv** — The argv list is built entirely from the action
     definition and the pre-validated, allow-listed target.  No raw string
     from any caller or model output is appended to the argv.

  6. **Fixed environment** — The environment passed to the subprocess is fixed
     in the action definition.  Callers cannot add, remove, or override
     environment variables.

  7. **Bounded output** — Subprocess output is capped at `output_limit_bytes`
     (default 64 KB).  Excess output causes `{:error, {:output_limit_exceeded,
     actual_bytes}}`.

  8. **Hard timeout** — Each action has a fixed timeout.  The subprocess is
     killed and `{:error, :timeout}` is returned when the deadline elapses.

  9. **Per-target serialization** — At most one action may execute against a
     given target at any time.  Concurrent attempts return
     `{:error, :concurrent_execution}`.

  10. **Post-action verification** — After every successful subprocess exit
      (exit code 0), a verifier checks that the desired state has been
      reached.  Verification failure does not retry execution.

  ## Usage

      allow_list = Application.get_env(:exocomp_node, :allowed_services, [])

      case Executor.execute(:restart_service, "myapp.service", allow_list) do
        {:ok, result} -> ...
        {:error, reason} -> ...
      end

  ## Injectable OS commander

  The OS commander can be overridden via application config for unit testing:

      # config/test.exs
      config :exocomp_node, :os_commander, MyApp.MockCommander

  The default is `Exocomp.Node.SystemCommander`.
  """

  require Logger

  alias Exocomp.Node.ActionCatalog
  alias Exocomp.Node.ExecutorLock

  @type action_id :: ActionCatalog.action_id()

  @type exec_result :: %{
          action_id: action_id(),
          target: String.t(),
          output: binary(),
          exit_code: non_neg_integer(),
          verified: boolean()
        }

  @type exec_error ::
          :unknown_action
          | :not_allowed
          | :concurrent_execution
          | :timeout
          | {:output_limit_exceeded, pos_integer()}
          | {:subprocess_failed, exit_code :: non_neg_integer(), output :: binary()}
          | {:verification_failed, reason :: term()}
          | term()

  @doc """
  Execute `action_id` against `target` using the installed `allow_list`.

  Returns `{:ok, exec_result}` on success (exit 0 + verified).

  Returns `{:error, reason}` for any security, resource, or execution failure.

  ### Options

  - `:lock_server` — override the `ExecutorLock` server (default:
    `Exocomp.Node.ExecutorLock`).  Useful in tests that start an isolated
    lock server to avoid interference between concurrent test cases.
  """
  @spec execute(action_id(), target :: term(), allow_list :: [String.t()], opts :: keyword()) ::
          {:ok, exec_result()} | {:error, exec_error()}

  def execute(action_id, target, allow_list, opts \\ []) do
    lock_server = Keyword.get(opts, :lock_server, ExecutorLock)
    # Derive a string key for the per-target lock.  Vacuum logs and similar
    # actions use a fixed sentinel since they have no per-service target.
    lock_target = canonical_lock_target(action_id, target)

    with {:ok, action_def} <- ActionCatalog.lookup(action_id, target, allow_list),
         :ok <- ExecutorLock.acquire(lock_server, lock_target) do
      try do
        run_action(action_id, target, action_def, opts)
      after
        ExecutorLock.release(lock_server, lock_target)
      end
    end
  end

  # Return a canonical string key for the per-target serialization lock.
  # Actions without a per-service target use a fixed sentinel string.
  defp canonical_lock_target(:vacuum_logs, _target), do: "system.logs.vacuum"
  defp canonical_lock_target(_action_id, target) when is_binary(target), do: target
  defp canonical_lock_target(_action_id, target), do: to_string(target)

  # ── Private ───────────────────────────────────────────────────────────────

  defp run_action(action_id, target, action_def, opts) do
    %{
      executable: executable,
      build_argv: build_argv,
      env: env,
      timeout_ms: timeout_ms,
      output_limit_bytes: output_limit_bytes
    } = action_def

    # Build argv entirely from the catalog — never from any caller string.
    argv = build_argv.()

    Logger.debug(
      "[Executor] action=#{action_id} target=#{inspect(target)} " <>
        "exec=#{executable} argv=#{inspect(argv)}"
    )

    commander = os_commander()

    run_opts = [
      env: env,
      timeout_ms: timeout_ms,
      output_limit_bytes: output_limit_bytes
    ]

    case invoke_commander(commander, executable, argv, run_opts) do
      {:ok, output, 0} ->
        verify_then_return(action_id, target, output, opts)

      {:ok, output, exit_code} ->
        Logger.warning(
          "[Executor] action=#{action_id} target=#{inspect(target)} " <>
            "failed exit_code=#{exit_code}"
        )

        {:error, {:subprocess_failed, exit_code, output}}

      {:error, reason} = err ->
        Logger.warning(
          "[Executor] action=#{action_id} target=#{inspect(target)} " <>
            "error=#{inspect(reason)}"
        )

        err
    end
  end

  defp verify_then_return(action_id, target, output, opts) do
    case run_verifier(action_id, target, opts) do
      :ok ->
        {:ok,
         %{
           action_id: action_id,
           target: target,
           output: output,
           exit_code: 0,
           verified: true
         }}

      {:error, reason} ->
        Logger.warning(
          "[Executor] post-action verification failed " <>
            "action=#{action_id} target=#{inspect(target)} reason=#{inspect(reason)}"
        )

        {:error, {:verification_failed, reason}}
    end
  end

  # Post-action verifiers — called after every successful subprocess exit.
  # Verifiers use the injectable OS commander so tests can stub them.

  defp run_verifier(:restart_service, target, _opts) do
    commander = os_commander()

    # Verify that the restarted service is now active.
    case invoke_commander(
           commander,
           "/usr/bin/systemctl",
           ["is-active", "--quiet", target],
           env: [],
           timeout_ms: 10_000,
           output_limit_bytes: 1024
         ) do
      {:ok, _output, 0} -> :ok
      {:ok, _output, code} -> {:error, {:service_not_active, code}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_verifier(:vacuum_logs, _target, _opts) do
    # The vacuum action is self-verifying via its exit code.
    # A non-zero exit is already handled before this point.
    :ok
  end

  defp run_verifier(_action_id, _target, _opts), do: :ok

  # Return the configured OS commander.  Accepts either a module atom (the
  # default, `Exocomp.Node.SystemCommander`) or a 3-arity function closure
  # (typically a `MockCommander.as_commander/1` return value used in tests).
  defp os_commander do
    Application.get_env(:exocomp_node, :os_commander, Exocomp.Node.SystemCommander)
  end

  # Invoke the commander regardless of whether it is a module or a function.
  defp invoke_commander(mod_or_fun, executable, argv, opts) do
    case mod_or_fun do
      mod when is_atom(mod) ->
        mod.run(executable, argv, opts)

      fun when is_function(fun, 3) ->
        fun.(executable, argv, opts)
    end
  end
end
