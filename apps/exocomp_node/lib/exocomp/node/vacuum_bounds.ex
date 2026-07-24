defmodule Exocomp.Node.VacuumBounds do
  @moduledoc """
  Installed immutable vacuum bounds and the eligibility gate.

  This module enforces the fixed, operator-installed limits for the
  `system.logs.vacuum` action.  **No caller, model output, or runtime argument
  can widen these limits.**  All configuration is read from `Application` env
  at evaluation time; callers supply no paths or limits.

  ## Installed config keys (set by the operator at deployment time)

  | Key                             | Type    | Example                  |
  |---------------------------------|---------|--------------------------|
  | `:vacuum_log_source`            | string  | `"/var/log/journal"`     |
  | `:vacuum_min_retention_secs`    | integer | `86400`                  |
  | `:vacuum_max_reclaim_bytes`     | integer | `104857600` (100 MiB)    |
  | `:vacuum_min_free_space_bytes`  | integer | `536870912` (512 MiB)    |
  | `:vacuum_cooldown_secs`         | integer | `3600`                   |
  | `:vacuum_max_retries`           | integer | `3`                      |

  ## Source classification

  The configured `:vacuum_log_source` is validated against a strict allowlist
  of known system journal paths before any action is permitted.  User home
  directories, `/tmp`, `/home`, and all other paths are permanently ineligible.

  ## Eligibility gate

  `check_eligible/1` is the single entry-point for the executor.  It:

  1. Checks `:vacuum_log_source` is configured.
  2. Validates the source path via `validate_source/1`.
  3. Requires disk-pressure classification of `:critical`.
  4. Enforces the cooldown period.
  5. Enforces the retry limit.
  6. Returns a `bounds_map` containing only the installed config values.

  The `bounds_map` is the sole authoritative parameter set for the executor.
  It cannot be widened by any argument passed to this module.

  ## VacuumState dependency

  Cooldown and retry state are read from `Exocomp.Node.VacuumState` (or a
  server pid stored in `:vacuum_state_server` application config for testing).
  """

  alias Exocomp.Node.Safety.Evidence
  alias Exocomp.Node.VacuumState

  @type threshold :: :below_threshold | :warning | :critical

  @type bounds_map :: %{
          log_source: String.t(),
          min_retention_secs: pos_integer(),
          max_reclaim_bytes: pos_integer(),
          min_free_space_bytes: pos_integer()
        }

  # Known system journal paths (allowlist).  Only these prefixes are permitted.
  # User paths, /tmp, /home, and all other paths are rejected.
  @system_journal_prefixes ["/var/log/journal", "/run/log/journal"]

  # Path prefixes that are unambiguously user-owned or temporary.
  # Each entry is matched as an exact path OR as a directory prefix (with a
  # trailing slash separator), so "/home/" covers "/home/alice" but not
  # "/homeless".  "/tmp" is handled separately with an exact match for the
  # bare directory itself.
  @user_data_dir_prefixes ["/home/", "/tmp/", "/root/"]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Check whether a vacuum action is currently eligible.

  ## Parameter

  Takes the result of `Exocomp.Node.Safety.DiskPressureCollector.collect/0`:
  `{:ok, %Evidence{}, threshold}`.

  ## Config dependency

  Reads `:vacuum_log_source`, `:vacuum_min_retention_secs`,
  `:vacuum_max_reclaim_bytes`, `:vacuum_min_free_space_bytes`,
  `:vacuum_cooldown_secs`, and `:vacuum_max_retries` from `Application` env.

  Reads cooldown and retry state from `VacuumState` (or the configured test
  server).  No caller-supplied path or limit is accepted.

  ## Return values

  - `{:ok, :eligible, bounds_map}` — all conditions met.
  - `{:error, :below_threshold}` — pressure is `:below_threshold` or `:warning`.
  - `{:error, :on_cooldown, last_executed_at}` — cooldown has not elapsed.
  - `{:error, :retry_exhausted, count}` — consecutive failures exceed the limit.
  - `{:error, :source_not_configured}` — `:vacuum_log_source` is not set.
  - `{:error, :invalid_source, reason}` — source failed `validate_source/1`.
  """
  @spec check_eligible({:ok, Evidence.t(), threshold()}) ::
          {:ok, :eligible, bounds_map()}
          | {:error, :below_threshold}
          | {:error, :on_cooldown, DateTime.t()}
          | {:error, :retry_exhausted, non_neg_integer()}
          | {:error, :source_not_configured}
          | {:error, :invalid_source, :user_data_path | :unknown_path}
  def check_eligible({:ok, %Evidence{}, threshold}) do
    with {:ok, source} <- fetch_log_source(),
         :ok <- check_source(source),
         :ok <- check_threshold(threshold),
         {:ok, state} <- fetch_vacuum_state(source),
         :ok <- check_retry_limit(state),
         :ok <- check_cooldown(state) do
      {:ok, :eligible, build_bounds_map(source)}
    end
  end

  @doc """
  Validate that the configured log source path is a known system journal path.

  ## Allowed paths

  Only these paths (and exact matches) are eligible:

  - `/var/log/journal`
  - `/run/log/journal`

  Subdirectory paths under these prefixes (e.g. `/var/log/journal/abc123`) are
  also accepted.

  ## Rejected paths

  - User home directories (`/home/...`, `/root/...`)
  - Temporary directories (`/tmp`, `/tmp/...`)
  - All other paths

  ## Return values

  - `:ok` — path is a known system journal path.
  - `{:error, :user_data_path}` — path is a user or temporary directory.
  - `{:error, :unknown_path}` — path is not a recognized system journal path.
  """
  @spec validate_source(String.t()) ::
          :ok | {:error, :user_data_path} | {:error, :unknown_path}
  def validate_source(path) when is_binary(path) do
    cond do
      user_data_path?(path) -> {:error, :user_data_path}
      system_journal_path?(path) -> :ok
      true -> {:error, :unknown_path}
    end
  end

  def validate_source(_), do: {:error, :unknown_path}

  # ── Private helpers ───────────────────────────────────────────────────────

  # Wrap validate_source/1 so errors include the :invalid_source tag.
  defp check_source(path) do
    case validate_source(path) do
      :ok -> :ok
      {:error, reason} -> {:error, :invalid_source, reason}
    end
  end

  # Read the configured log source; return :source_not_configured if absent.
  defp fetch_log_source do
    case Application.fetch_env(:exocomp_node, :vacuum_log_source) do
      {:ok, path} when is_binary(path) and byte_size(path) > 0 -> {:ok, path}
      _ -> {:error, :source_not_configured}
    end
  end

  # Require :critical pressure; treat :warning and :below_threshold as
  # ineligible so the action is reserved for genuine disk emergencies.
  defp check_threshold(:critical), do: :ok
  defp check_threshold(_), do: {:error, :below_threshold}

  # Read per-mount-point cooldown/retry state from VacuumState.
  defp fetch_vacuum_state(mount_point) do
    server = vacuum_state_server()
    state = VacuumState.get_state(server, mount_point)
    {:ok, state}
  end

  # Enforce max_retries: if consecutive failures >= limit, refuse.
  defp check_retry_limit(state) do
    max_retries = Application.get_env(:exocomp_node, :vacuum_max_retries, 3)
    count = state.consecutive_failure_count

    if count >= max_retries do
      {:error, :retry_exhausted, count}
    else
      :ok
    end
  end

  # Enforce cooldown_secs: if last_executed_at is set and not enough time has
  # passed since the last success, return :on_cooldown.
  defp check_cooldown(%{last_executed_at: nil}), do: :ok

  defp check_cooldown(%{last_executed_at: last}) do
    cooldown_secs = Application.get_env(:exocomp_node, :vacuum_cooldown_secs, 3600)
    elapsed = DateTime.diff(DateTime.utc_now(), last, :second)

    if elapsed >= cooldown_secs do
      :ok
    else
      {:error, :on_cooldown, last}
    end
  end

  # Build the bounds map from Application config only.
  # Callers cannot supply or override any of these values.
  defp build_bounds_map(source) do
    %{
      log_source: source,
      min_retention_secs: Application.get_env(:exocomp_node, :vacuum_min_retention_secs, 86_400),
      max_reclaim_bytes:
        Application.get_env(:exocomp_node, :vacuum_max_reclaim_bytes, 104_857_600),
      min_free_space_bytes:
        Application.get_env(:exocomp_node, :vacuum_min_free_space_bytes, 536_870_912)
    }
  end

  # Return the VacuumState server to use.  In tests the application config key
  # :vacuum_state_server may be set to a PID to isolate test instances.
  defp vacuum_state_server do
    Application.get_env(:exocomp_node, :vacuum_state_server, VacuumState)
  end

  # True if the path matches a known system journal prefix or exact path.
  defp system_journal_path?(path) do
    Enum.any?(@system_journal_prefixes, fn prefix ->
      path == prefix or String.starts_with?(path, prefix <> "/")
    end)
  end

  # True if the path is a user-owned or temporary directory.
  #
  # Matches:
  #   - /tmp (exact)
  #   - /home/<anything>
  #   - /tmp/<anything>
  #   - /root/<anything>
  defp user_data_path?(path) do
    path == "/tmp" or
      Enum.any?(@user_data_dir_prefixes, &String.starts_with?(path, &1))
  end
end
