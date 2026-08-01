# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.Ceph.Validator do
  @moduledoc """
  Validates Ceph profile configuration against the local file system.

  Checks performed, in order:
  1. All configured paths are absolute (no relative paths, no nil values).
  2. Each file exists and is stat-able by the process.
  3. The Ceph binary is a regular file with the owner-execute bit set.
  4. No file is owned by root (uid 0) — root ownership is rejected as unsafe.
  5. The keyring has mode 0600 or 0640 — world-readable or group-writable
     keyrings are rejected.

  Key material is **never read, opened, or included in failure messages.**
  Every failure describes metadata only: path, mode, uid.

  The `validate/2` function accepts an optional `stat_fn` argument so that
  tests can inject a stub without touching the real file system.
  """

  import Bitwise

  alias Exocomp.ClusterProfile.Ceph.Config

  @type failure_code ::
          :relative_path
          | :nil_path
          | :file_missing
          | :file_unreadable
          | :not_regular_file
          | :not_executable
          | :root_owned
          | :keyring_unsafe_permissions

  @type severity :: :error | :warning

  @type failure :: %{
          code: failure_code(),
          reason: String.t(),
          path: String.t() | nil,
          field: String.t(),
          severity: severity(),
          action_required: String.t()
        }

  @type stat_fn :: (String.t() -> {:ok, File.Stat.t()} | {:error, File.posix()})

  @doc """
  Validates the Ceph profile configuration.

  Returns `:ok` when all checks pass or `{:error, [failure()]}` when one
  or more checks fail.  Failures are ordered: path checks first, then
  per-file stat checks in the order binary → conf → keyring.

  The optional `stat_fn` defaults to `&File.stat/1` and can be replaced
  with a stub in tests.
  """
  @spec validate(Config.t(), stat_fn()) :: :ok | {:error, [failure()]}
  def validate(%Config{} = config, stat_fn \\ &File.stat/1) do
    failures =
      []
      |> check_absolute_path(config.ceph_binary_path, "ceph_binary_path")
      |> check_absolute_path(config.ceph_conf_path, "ceph_conf_path")
      |> check_absolute_path(config.keyring_path, "keyring_path")
      |> check_file(config.ceph_binary_path, "ceph_binary_path", stat_fn, &validate_binary/2)
      |> check_file(config.ceph_conf_path, "ceph_conf_path", stat_fn, &validate_conf/2)
      |> check_file(config.keyring_path, "keyring_path", stat_fn, &validate_keyring/2)

    case failures do
      [] -> :ok
      _ -> {:error, Enum.reverse(failures)}
    end
  end

  # ── Path format checks ───────────────────────────────────────────────────────

  defp check_absolute_path(failures, nil, field) do
    [
      %{
        code: :nil_path,
        reason: "#{field} is not configured",
        path: nil,
        field: field,
        severity: :error,
        action_required: "Set #{field} to an absolute path in cluster_profiles.ceph"
      }
      | failures
    ]
  end

  defp check_absolute_path(failures, path, field) when is_binary(path) do
    if Path.type(path) == :absolute do
      failures
    else
      [
        %{
          code: :relative_path,
          reason: "#{field} must be an absolute path; got #{inspect(path)}",
          path: path,
          field: field,
          severity: :error,
          action_required: "Change #{field} to an absolute path starting with /"
        }
        | failures
      ]
    end
  end

  defp check_absolute_path(failures, path, field) do
    [
      %{
        code: :relative_path,
        reason: "#{field} must be a string absolute path; got #{inspect(path)}",
        path: nil,
        field: field,
        severity: :error,
        action_required: "Change #{field} to an absolute path starting with /"
      }
      | failures
    ]
  end

  # ── Per-file existence + stat checks ────────────────────────────────────────

  # Skip file checks when the path already failed a format check.
  defp check_file(failures, path, field, stat_fn, validator) do
    if absolute_path?(path) and not already_failed?(failures, field) do
      do_check_file(failures, path, field, stat_fn, validator)
    else
      failures
    end
  end

  defp do_check_file(failures, path, field, stat_fn, validator) do
    case stat_fn.(path) do
      {:ok, stat} ->
        validator.(failures, {path, field, stat})

      {:error, :enoent} ->
        [
          %{
            code: :file_missing,
            reason: "file does not exist: #{path}",
            path: path,
            field: field,
            severity: :error,
            action_required: "Ensure the file exists at #{path}"
          }
          | failures
        ]

      {:error, reason} ->
        [
          %{
            code: :file_unreadable,
            reason: "could not stat #{path}: #{inspect(reason)}",
            path: path,
            field: field,
            severity: :error,
            action_required:
              "Ensure the exocomp-coordinator service account can read #{path}"
          }
          | failures
        ]
    end
  end

  # ── Per-file stat validators ─────────────────────────────────────────────────

  defp validate_binary(failures, {path, field, stat}) do
    failures
    |> check_root_owned(path, field, stat)
    |> check_regular_file(path, field, stat)
    |> check_owner_execute(path, field, stat)
  end

  defp validate_conf(failures, {path, field, stat}) do
    check_root_owned(failures, path, field, stat)
  end

  defp validate_keyring(failures, {path, field, stat}) do
    failures
    |> check_root_owned(path, field, stat)
    |> check_keyring_permissions(path, field, stat)
  end

  # ── Individual stat checks ───────────────────────────────────────────────────

  defp check_root_owned(failures, path, field, %File.Stat{uid: 0}) do
    [
      %{
        code: :root_owned,
        reason: "file is owned by root (uid 0): #{path}",
        path: path,
        field: field,
        severity: :warning,
        action_required:
          "Change ownership of #{path} to a non-root service account (e.g., ceph or exocomp-coordinator)"
      }
      | failures
    ]
  end

  defp check_root_owned(failures, _path, _field, _stat), do: failures

  defp check_regular_file(failures, path, field, %File.Stat{type: type})
       when type != :regular do
    [
      %{
        code: :not_regular_file,
        reason: "ceph binary is not a regular file (type: #{type}): #{path}",
        path: path,
        field: field,
        severity: :error,
        action_required: "Verify #{field} points to an executable regular file"
      }
      | failures
    ]
  end

  defp check_regular_file(failures, _path, _field, _stat), do: failures

  defp check_owner_execute(failures, path, field, %File.Stat{type: :regular} = stat) do
    perm_bits = band(stat.mode, 0o7777)

    if band(perm_bits, 0o100) == 0 do
      [
        %{
          code: :not_executable,
          reason: "ceph binary does not have owner execute bit set: #{path}",
          path: path,
          field: field,
          severity: :error,
          action_required: "Ensure #{path} has execute permission: chmod u+x #{path}"
        }
        | failures
      ]
    else
      failures
    end
  end

  # Non-regular files are already reported by check_regular_file; skip here.
  defp check_owner_execute(failures, _path, _field, _stat), do: failures

  defp check_keyring_permissions(failures, path, field, stat) do
    perm_bits = band(stat.mode, 0o7777)
    others_readable = band(perm_bits, 0o004) != 0
    others_writable = band(perm_bits, 0o002) != 0
    group_writable = band(perm_bits, 0o020) != 0

    cond do
      others_readable or others_writable ->
        mode_str = perm_bits |> Integer.to_string(8) |> String.pad_leading(4, "0")

        [
          %{
            code: :keyring_unsafe_permissions,
            reason:
              "keyring has world-accessible mode 0#{mode_str}: #{path}; expected 0600 or 0640",
            path: path,
            field: field,
            severity: :error,
            action_required: "Restrict keyring permissions: chmod 0600 #{path}"
          }
          | failures
        ]

      group_writable ->
        mode_str = perm_bits |> Integer.to_string(8) |> String.pad_leading(4, "0")

        [
          %{
            code: :keyring_unsafe_permissions,
            reason:
              "keyring has group-writable mode 0#{mode_str}: #{path}; expected 0600 or 0640",
            path: path,
            field: field,
            severity: :error,
            action_required:
              "Remove group write permission: chmod 0640 #{path}"
          }
          | failures
        ]

      true ->
        failures
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp absolute_path?(path) when is_binary(path), do: Path.type(path) == :absolute
  defp absolute_path?(_), do: false

  # True when the failures list already contains a path-format failure for
  # this field.  This prevents redundant stat checks after a nil/relative
  # failure was already recorded.
  defp already_failed?(failures, field) do
    Enum.any?(failures, fn f ->
      Map.get(f, :field) == field and
        Map.get(f, :code) in [:nil_path, :relative_path]
    end)
  end
end
