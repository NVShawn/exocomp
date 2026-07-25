# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Safety.ApprovalGate do
  @moduledoc """
  Unified approval gate for node-side execution of coordinator-approved actions.

  Enforces four sequential safety checks before delegating to the executor:

  1. **Token verification** — validates the Ed25519 signature, binding fields
     (node_id, task_id, correlation_id, action_id, parameter_hash), and
     timestamp (issued_at, expires_at).
  2. **Precondition check** — re-evaluates system state and compares it with
     the evidence hash encoded in the approved token.  If state has changed
     since approval, execution is blocked.
  3. **Replay claim** — writes the nonce durably before execution to guarantee
     at-most-once semantics.  A duplicate nonce blocks execution and routes the
     caller to the authoritative result.
  4. **Execution** — invokes the restricted executor and records the outcome in
     the replay ledger.

  ## Fail-closed guarantee

  Any failure in steps 1-3 prevents execution.  A ledger-completion failure
  after step 4 is logged at error severity but does **not** cause
  re-execution — the action is already done.

  ## Audit logging

  Structured log entries are emitted at each step.  The full token, raw
  signature, and private key material are never logged.  Nonces are truncated
  to 8 bytes + "..." for log safety.

  ## Injection points (for testing)

  Pass keyword options to `execute/3`:

  - `:verifier` — module with `verify/2` (default: `ApprovalVerifier`)
  - `:checker` — module with `verify/3` (default: `PreconditionChecker`)
  - `:executor` — module with `execute/3`, or a 3- or 4-arity function
    (default: `Executor`)
  - `:ledger` — replay ledger server name or pid
    (default: `Exocomp.Node.Safety.ReplayLedger`)
  - `:wait_timeout_ms` — timeout for `wait_for_result` when a concurrent
    claim is pending (default: 30 000 ms)
  """

  require Logger

  alias Exocomp.Node.Executor
  alias Exocomp.Node.Safety.ApprovalVerifier
  alias Exocomp.Node.Safety.PreconditionChecker
  alias Exocomp.Node.Safety.ReplayLedger

  @default_wait_timeout_ms 30_000

  @type execution_context :: %{
          required(:task_id) => String.t(),
          required(:correlation_id) => String.t(),
          required(:action_id) => atom(),
          required(:target) => String.t(),
          required(:parameters) => map(),
          required(:allow_list) => [String.t()],
          optional(:node_id) => String.t()
        }

  @type gate_error ::
          {:token_invalid, term()}
          | {:precondition_changed, term()}
          | {:already_executed, term()}
          | :replay_state_unavailable
          | {:execution_failed, term()}

  @doc """
  Execute an approved action through the full safety gate.

  Returns `{:ok, exec_result}` on success or `{:error, gate_error()}` on any
  gate or execution failure.

  ## Options

  - `:verifier` — module with `verify/2` (default: `ApprovalVerifier`)
  - `:checker` — module with `verify/3` (default: `PreconditionChecker`)
  - `:executor` — module with `execute/3` or 3/4-arity fun (default: `Executor`)
  - `:ledger` — replay ledger server (default: `ReplayLedger`)
  - `:wait_timeout_ms` — timeout for pending-slot wait (default: 30 000 ms)
  """
  @spec execute(token_wire :: map(), context :: execution_context(), opts :: keyword()) ::
          {:ok, map()} | {:error, gate_error()}
  def execute(token_wire, context, opts \\ []) do
    verifier = Keyword.get(opts, :verifier, ApprovalVerifier)
    checker = Keyword.get(opts, :checker, PreconditionChecker)
    executor = Keyword.get(opts, :executor, Executor)
    ledger = Keyword.get(opts, :ledger, ReplayLedger)
    wait_ms = Keyword.get(opts, :wait_timeout_ms, @default_wait_timeout_ms)

    action_id = map_get(context, :action_id)
    target = map_get(context, :target)
    task_id = map_get(context, :task_id)
    allow_list = map_get(context, :allow_list) || []
    correlation_id = map_get(context, :correlation_id)

    Logger.info(
      "[ApprovalGate] start correlation_id=#{correlation_id} " <>
        "action=#{action_id} target=#{safe_log(target)}"
    )

    verifier_ctx = build_verifier_context(context)

    # Step 1: Verify token
    case verifier.verify(token_wire, verifier_ctx) do
      {:error, reason} ->
        Logger.warning(
          "[ApprovalGate] token_invalid correlation_id=#{correlation_id} " <>
            "action=#{action_id} reason=#{inspect(reason)}"
        )

        {:error, {:token_invalid, reason}}

      {:ok, verified_token} ->
        payload = token_payload(verified_token)
        nonce = map_get(payload, :nonce)
        nonce_log = safe_nonce(nonce)

        Logger.info(
          "[ApprovalGate] token_valid correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id}"
        )

        # Step 2: Check preconditions
        case checker.verify(payload, action_id, target) do
          {:error, reason} ->
            Logger.warning(
              "[ApprovalGate] precondition_changed correlation_id=#{correlation_id} " <>
                "nonce=#{nonce_log} action=#{action_id} target=#{safe_log(target)} " <>
                "reason=#{inspect(reason)}"
            )

            {:error, {:precondition_changed, reason}}

          :ok ->
            Logger.info(
              "[ApprovalGate] preconditions_ok correlation_id=#{correlation_id} " <>
                "nonce=#{nonce_log} action=#{action_id}"
            )

            claim_and_execute(
              nonce,
              task_id,
              action_id,
              target,
              allow_list,
              executor,
              ledger,
              wait_ms,
              correlation_id,
              nonce_log
            )
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Private — replay claim
  # ---------------------------------------------------------------------------

  defp claim_and_execute(
         nonce,
         task_id,
         action_id,
         target,
         allow_list,
         executor,
         ledger,
         wait_ms,
         correlation_id,
         nonce_log
       ) do
    attrs = %{task_id: task_id, action_id: action_id, target: target}

    # Step 3: Claim replay slot
    case ReplayLedger.claim(nonce, attrs, ledger) do
      {:ok, :proceed} ->
        Logger.info(
          "[ApprovalGate] replay_claimed correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id}"
        )

        do_execute(
          action_id,
          target,
          allow_list,
          executor,
          nonce,
          ledger,
          correlation_id,
          nonce_log
        )

      {:error, :already_executed, result} ->
        Logger.info(
          "[ApprovalGate] replay_already_executed correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id}"
        )

        {:error, {:already_executed, result}}

      {:error, :incomplete_pending} ->
        Logger.info(
          "[ApprovalGate] replay_incomplete_pending correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id} waiting=true"
        )

        case ReplayLedger.wait_for_result(nonce, wait_ms, ledger) do
          {:ok, result} -> result
          {:error, :timeout} -> {:error, :replay_state_unavailable}
        end

      {:error, _storage_error} ->
        Logger.error(
          "[ApprovalGate] replay_storage_failure correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id}"
        )

        {:error, :replay_state_unavailable}
    end
  end

  # ---------------------------------------------------------------------------
  # Private — execution and ledger recording
  # ---------------------------------------------------------------------------

  defp do_execute(
         action_id,
         target,
         allow_list,
         executor,
         nonce,
         ledger,
         correlation_id,
         nonce_log
       ) do
    # Step 4: Execute
    case invoke_executor(executor, action_id, target, allow_list) do
      {:error, exec_error} ->
        Logger.warning(
          "[ApprovalGate] execution_failed correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id} error=#{inspect(exec_error)}"
        )

        ReplayLedger.complete(nonce, {:error, exec_error}, ledger)
        {:error, {:execution_failed, exec_error}}

      {:ok, exec_result} ->
        Logger.info(
          "[ApprovalGate] execution_success correlation_id=#{correlation_id} " <>
            "nonce=#{nonce_log} action=#{action_id}"
        )

        # Step 5: Record completion
        case ReplayLedger.complete(nonce, {:ok, exec_result}, ledger) do
          :ok ->
            :ok

          {:error, complete_error} ->
            # The action already executed — do NOT re-execute.  Log and continue.
            Logger.error(
              "[ApprovalGate] LEDGER_COMPLETE_FAILED action executed but ledger " <>
                "could not be updated correlation_id=#{correlation_id} " <>
                "nonce=#{nonce_log} action=#{action_id} error=#{inspect(complete_error)}"
            )
        end

        # Step 6: Return exec result regardless of ledger-complete outcome
        {:ok, exec_result}
    end
  end

  # ---------------------------------------------------------------------------
  # Private — helpers
  # ---------------------------------------------------------------------------

  defp invoke_executor(executor, action_id, target, allow_list) do
    case executor do
      mod when is_atom(mod) -> mod.execute(action_id, target, allow_list)
      fun when is_function(fun, 3) -> fun.(action_id, target, allow_list)
      fun when is_function(fun, 4) -> fun.(action_id, target, allow_list, [])
    end
  end

  defp build_verifier_context(context) do
    # Use nil (not "") as the default so that a token signed with node_id: ""
    # cannot match an unconfigured node. An nil node_id will always fail the
    # token-binding check (nil != any_non_nil_value), which is the correct
    # fail-closed behaviour.
    node_id =
      map_get(context, :node_id) ||
        Application.get_env(:exocomp_node, :node_id)

    %{
      node_id: node_id,
      task_id: map_get(context, :task_id),
      correlation_id: map_get(context, :correlation_id),
      action: map_get(context, :action_id),
      parameters: map_get(context, :parameters) || %{}
    }
  end

  # Extract payload from a verified token (handles both atom- and string-keyed maps).
  defp token_payload(token) when is_map(token) do
    map_get(token, :payload) || token
  end

  # Access a map key by atom, falling back to its string form.
  defp map_get(map, key) when is_map(map) and is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, val} -> val
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  # Truncate a nonce to 8 bytes for log-safe display.
  defp safe_nonce(nonce) when is_binary(nonce) and byte_size(nonce) >= 8 do
    binary_part(nonce, 0, 8) <> "..."
  end

  defp safe_nonce(nonce), do: inspect(nonce)

  defp safe_log(value) when is_binary(value), do: value
  defp safe_log(value), do: inspect(value)
end
