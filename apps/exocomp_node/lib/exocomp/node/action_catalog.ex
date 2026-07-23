defmodule Exocomp.Node.ActionCatalog do
  @moduledoc """
  Fixed, typed action catalog for the exocomp node executor.

  Every action definition specifies:

  - `:executable` — absolute path of the executable.  Never derived from any
    caller input, request field, or model output.
  - `:build_argv` — zero-arity function that returns the exact argv list for
    the action.  The argv is determined entirely by the catalog definition and
    the pre-validated, allow-listed target; it is never constructed from raw
    caller strings.
  - `:env` — fixed environment list `[{key, value}]`.  Callers cannot add or
    override environment variables.
  - `:timeout_ms` — maximum wall-clock execution time.  The subprocess is
    killed when this elapses.
  - `:output_limit_bytes` — maximum captured output in bytes.  Excess causes
    `{:error, {:output_limit_exceeded, actual_bytes}}`.

  ## Installed actions

  | Action ID            | Description                              |
  |----------------------|------------------------------------------|
  | `:restart_service`   | Restart one allow-listed systemd service |
  | `:vacuum_logs`       | Vacuum journald logs up to a fixed limit |

  There is **no generic command action**.  The allow-listed services and the
  `vacuum_logs` parameters are determined at installation time by the node
  operator, not by any request or model field.

  ## Allow-list enforcement

  For `:restart_service`, the caller supplies a `target` (service name) and an
  `allow_list` derived from installation-time configuration.  `lookup/3`
  validates the target against both a strict character-set regex and the
  allow-list before returning any definition.  A target that fails either
  check returns `{:error, :not_allowed}`.

  ## Service-name validation

  Valid systemd unit names consist only of:
  `[a-zA-Z0-9]`, `-`, `_`, `.`, `@`.
  They must start with an alphanumeric character and may optionally end with
  `.service`.  Shell metacharacters, path separators, whitespace, NUL bytes,
  newlines, and all other characters are unconditionally rejected.
  """

  @type action_id :: :restart_service | :vacuum_logs

  @type action_def :: %{
          executable: String.t(),
          build_argv: (-> [String.t()]),
          env: [{String.t(), String.t()}],
          timeout_ms: pos_integer(),
          output_limit_bytes: pos_integer()
        }

  # Absolute executable paths — never caller-supplied.
  @systemctl "/usr/bin/systemctl"
  @journalctl "/usr/bin/journalctl"

  # Fixed resource limits.
  @default_output_limit_bytes 65_536
  @restart_timeout_ms 30_000
  @vacuum_timeout_ms 120_000

  # Valid systemd unit-name regex (strict allowlist of characters).
  # Must start with alphanumeric; body may contain alphanumeric, hyphen,
  # underscore, dot, or at-sign; optional ".service" suffix.
  # This rejects any shell metacharacter, path component, whitespace, or
  # control character before the name is ever used in an argv.
  @service_name_re ~r/\A[a-zA-Z0-9][a-zA-Z0-9._@\-]*(?:\.service)?\z/

  @doc """
  Return the ordered list of action IDs in this catalog.
  """
  @spec action_ids() :: [action_id()]
  def action_ids, do: [:restart_service, :vacuum_logs]

  @doc """
  Look up the action definition for `action_id` and `target`.

  For `:restart_service`:
  - `target` must pass service-name validation (see module doc).
  - `target` must be present in `allow_list`.
  - The `allow_list` is expected to come from installation-time configuration,
    never from request or model fields.

  For `:vacuum_logs`:
  - `target` is ignored (the action operates on the local journal).
  - `allow_list` is ignored.

  Returns:
  - `{:ok, action_def}` — action is installed and target is allowed.
  - `{:error, :unknown_action}` — action ID is not in the catalog.
  - `{:error, :not_allowed}` — target failed validation or is not allow-listed.
  """
  @spec lookup(action_id(), target :: String.t(), allow_list :: [String.t()]) ::
          {:ok, action_def()} | {:error, :unknown_action | :not_allowed}

  def lookup(:restart_service, target, allow_list) do
    with :ok <- validate_service_name(target),
         :ok <- check_allow_list(target, allow_list) do
      {:ok, build_restart_def(target)}
    end
  end

  def lookup(:vacuum_logs, _target, _allow_list) do
    {:ok, build_vacuum_def()}
  end

  def lookup(_unknown_action, _target, _allow_list) do
    {:error, :unknown_action}
  end

  @doc """
  Return all `{executable, argv_prefix}` pairs for generating sudoers entries.

  The list covers every allow-listed service for `:restart_service` plus the
  fixed `:vacuum_logs` entry.  An empty `allow_list` produces only the vacuum
  entry.

  Invalid service names (those that would fail `validate_service_name/1`) are
  silently dropped — they would never be reachable via `lookup/3` anyway.
  """
  @spec sudoers_entries(allow_list :: [String.t()]) ::
          [{executable :: String.t(), argv :: [String.t()]}]

  def sudoers_entries(allow_list) when is_list(allow_list) do
    service_entries =
      allow_list
      |> Enum.filter(&valid_service_name?/1)
      |> Enum.map(fn svc -> {@systemctl, ["restart", svc]} end)

    vacuum_entry = {
      @journalctl,
      ["--vacuum-size=#{vacuum_size()}"]
    }

    service_entries ++ [vacuum_entry]
  end

  # ── Private helpers ──────────────────────────────────────────────────────

  defp validate_service_name(name) when is_binary(name) do
    if Regex.match?(@service_name_re, name) do
      :ok
    else
      {:error, :not_allowed}
    end
  end

  defp validate_service_name(_), do: {:error, :not_allowed}

  defp valid_service_name?(name), do: validate_service_name(name) == :ok

  defp check_allow_list(target, allow_list) when is_list(allow_list) do
    if target in allow_list do
      :ok
    else
      {:error, :not_allowed}
    end
  end

  defp check_allow_list(_target, _), do: {:error, :not_allowed}

  defp build_restart_def(target) do
    # The argv is constructed here from a pre-validated, allow-listed target.
    # The target string has already passed the strict regex and allow-list check
    # at this point.  It is captured in a closure and evaluated at execution time
    # — no further transformation is applied.
    %{
      executable: @systemctl,
      build_argv: fn -> ["restart", target] end,
      env: [],
      timeout_ms: @restart_timeout_ms,
      output_limit_bytes: @default_output_limit_bytes
    }
  end

  defp build_vacuum_def do
    # The vacuum size is fixed at installation time via application config.
    # No caller-supplied value can influence the argv.
    %{
      executable: @journalctl,
      build_argv: fn -> ["--vacuum-size=#{vacuum_size()}"] end,
      env: [],
      timeout_ms: @vacuum_timeout_ms,
      output_limit_bytes: @default_output_limit_bytes
    }
  end

  defp vacuum_size do
    Application.get_env(:exocomp_node, :vacuum_size, "100M")
  end
end
