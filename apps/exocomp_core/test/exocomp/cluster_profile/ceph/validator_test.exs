# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.Ceph.ValidatorTest do
  use ExUnit.Case, async: true

  alias Exocomp.ClusterProfile.Ceph.Config
  alias Exocomp.ClusterProfile.Ceph.Validator

  # ── Helpers ──────────────────────────────────────────────────────────────────

  # Build a Config using real temp files (created in tests that need them).
  defp config(binary_path, conf_path, keyring_path, version \\ 1) do
    %Config{
      version: version,
      ceph_binary_path: binary_path,
      ceph_conf_path: conf_path,
      keyring_path: keyring_path
    }
  end

  # Returns a File.Stat stub with the given mode (octal) and uid.
  defp stub_stat(mode, uid \\ 1000, type \\ :regular) do
    {:ok,
     %File.Stat{
       mode: mode,
       uid: uid,
       gid: 1000,
       type: type,
       size: 0,
       access: :read,
       atime: {{2026, 1, 1}, {0, 0, 0}},
       mtime: {{2026, 1, 1}, {0, 0, 0}},
       ctime: {{2026, 1, 1}, {0, 0, 0}},
       links: 1,
       major_device: 0,
       minor_device: 0,
       inode: 1
     }}
  end

  # Stat function that returns the same stat for every path.
  defp uniform_stat_fn(mode, uid \\ 1000, type \\ :regular) do
    fn _path -> stub_stat(mode, uid, type) end
  end

  # Stat function that returns a missing error for every path.
  defp missing_stat_fn do
    fn _path -> {:error, :enoent} end
  end

  # Stat function that returns successful stat for all paths except the named
  # one, which returns {:error, :enoent}.
  defp missing_one_stat_fn(missing_path, mode \\ 0o100755, uid \\ 1000) do
    fn path ->
      if path == missing_path do
        {:error, :enoent}
      else
        stub_stat(mode, uid)
      end
    end
  end

  # ── Valid configuration ───────────────────────────────────────────────────────

  describe "valid configuration" do
    test "returns :ok when all files exist with correct ownership and permissions" do
      # binary: 0755 regular; conf: 0644 regular; keyring: 0600 regular
      stat_fn = fn path ->
        cond do
          String.ends_with?(path, "ceph") -> stub_stat(0o100755)
          String.ends_with?(path, "ceph.conf") -> stub_stat(0o100644)
          String.ends_with?(path, "keyring") -> stub_stat(0o100600)
          true -> stub_stat(0o100644)
        end
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert :ok = Validator.validate(cfg, stat_fn)
    end

    test "returns :ok when keyring has mode 0640 (group-readable, not group-writable)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring") do
          stub_stat(0o100640)
        else
          stub_stat(0o100755)
        end
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert :ok = Validator.validate(cfg, stat_fn)
    end
  end

  # ── Relative path rejection ───────────────────────────────────────────────────

  describe "relative paths" do
    test "rejects relative ceph_binary_path" do
      cfg = config("ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())
      assert Enum.any?(failures, &(&1.code == :relative_path and &1.field == "ceph_binary_path"))
    end

    test "rejects relative ceph_conf_path" do
      cfg = config("/usr/bin/ceph", "etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())
      assert Enum.any?(failures, &(&1.code == :relative_path and &1.field == "ceph_conf_path"))
    end

    test "rejects relative keyring_path" do
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "ceph.client.exocomp.keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())
      assert Enum.any?(failures, &(&1.code == :relative_path and &1.field == "keyring_path"))
    end

    test "rejects dot-relative path (./etc/ceph/ceph.conf)" do
      cfg = config("/usr/bin/ceph", "./etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())
      assert Enum.any?(failures, &(&1.code == :relative_path and &1.field == "ceph_conf_path"))
    end

    test "rejects parent-relative path (../ceph.conf)" do
      cfg = config("/usr/bin/ceph", "../ceph.conf", "/etc/ceph/keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())
      assert Enum.any?(failures, &(&1.code == :relative_path and &1.field == "ceph_conf_path"))
    end

    test "skips file existence check when path is relative (no stat errors)" do
      cfg = config("ceph", "ceph.conf", "keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())
      # Should have only relative_path failures, not file_missing failures
      assert Enum.all?(failures, &(&1.code == :relative_path))
    end
  end

  # ── Missing files ─────────────────────────────────────────────────────────────

  describe "missing files" do
    test "fails when ceph binary is absent" do
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      stat_fn =
        missing_one_stat_fn("/usr/bin/ceph", 0o100644)
        |> then(fn f ->
          fn path ->
            if path == "/usr/bin/ceph", do: {:error, :enoent}, else: stub_stat(0o100644)
          end
        end)

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :file_missing and &1.field == "ceph_binary_path")
             )
    end

    test "fails when ceph.conf is absent" do
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      stat_fn = fn path ->
        if path == "/etc/ceph/ceph.conf", do: {:error, :enoent}, else: stub_stat(0o100755)
      end

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :file_missing and &1.field == "ceph_conf_path")
             )
    end

    test "fails when keyring is absent" do
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      stat_fn = fn path ->
        if path == "/etc/ceph/keyring", do: {:error, :enoent}, else: stub_stat(0o100755)
      end

      assert {:error, failures} = Validator.validate(cfg, stat_fn)
      assert Enum.any?(failures, &(&1.code == :file_missing and &1.field == "keyring_path"))
    end

    test "reports all three files missing independently" do
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert {:error, failures} = Validator.validate(cfg, missing_stat_fn())

      fields_with_missing = failures |> Enum.filter(&(&1.code == :file_missing)) |> Enum.map(& &1.field)
      assert "ceph_binary_path" in fields_with_missing
      assert "ceph_conf_path" in fields_with_missing
      assert "keyring_path" in fields_with_missing
    end
  end

  # ── Absent binary (binary exists as path but executable identity fails) ───────

  describe "absent binary / non-executable binary" do
    test "fails when binary is not a regular file (e.g., a directory)" do
      stat_fn = uniform_stat_fn(0o040755, 1000, :directory)
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :not_regular_file and &1.field == "ceph_binary_path")
             )
    end

    test "fails when binary exists but owner execute bit is not set" do
      stat_fn = uniform_stat_fn(0o100644)
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :not_executable and &1.field == "ceph_binary_path")
             )
    end

    test "passes when binary has owner-only execute bit (0100)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "ceph") do
          stub_stat(0o100700)
        else
          stub_stat(0o100600)
        end
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert :ok = Validator.validate(cfg, stat_fn)
    end
  end

  # ── Wrong ownership (root-owned) ──────────────────────────────────────────────

  describe "wrong ownership" do
    test "warns when ceph binary is owned by root (uid 0)" do
      stat_fn = uniform_stat_fn(0o100755, 0)
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      root_owned = Enum.filter(failures, &(&1.code == :root_owned))
      assert length(root_owned) == 3

      fields = Enum.map(root_owned, & &1.field)
      assert "ceph_binary_path" in fields
      assert "ceph_conf_path" in fields
      assert "keyring_path" in fields
    end

    test "warns when only keyring is root-owned" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"),
          do: stub_stat(0o100600, 0),
          else: stub_stat(0o100755, 1000)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :root_owned and &1.field == "keyring_path")
             )
    end

    test "passes when all files are owned by a non-root user (uid > 0)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "ceph") and not String.ends_with?(path, "ceph.conf"),
          do: stub_stat(0o100755, 500),
          else: stub_stat(0o100600, 500)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert :ok = Validator.validate(cfg, stat_fn)
    end
  end

  # ── Unsafe keyring permissions ────────────────────────────────────────────────

  describe "unsafe permissions" do
    test "fails when keyring is world-readable (0644)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"),
          do: stub_stat(0o100644),
          else: stub_stat(0o100755)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :keyring_unsafe_permissions and &1.field == "keyring_path")
             )
    end

    test "fails when keyring is world-readable (0664)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"),
          do: stub_stat(0o100664),
          else: stub_stat(0o100755)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :keyring_unsafe_permissions and &1.field == "keyring_path")
             )
    end

    test "fails when keyring has world-read and world-write (0666)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"),
          do: stub_stat(0o100666),
          else: stub_stat(0o100755)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :keyring_unsafe_permissions and &1.field == "keyring_path")
             )
    end

    test "fails when keyring has group-writable mode (0660)" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"),
          do: stub_stat(0o100660),
          else: stub_stat(0o100755)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      assert Enum.any?(
               failures,
               &(&1.code == :keyring_unsafe_permissions and &1.field == "keyring_path")
             )
    end

    test "passes when keyring has mode 0600 (owner-only)" do
      stat_fn = fn path ->
        cond do
          String.ends_with?(path, "ceph") and not String.ends_with?(path, "ceph.conf") ->
            stub_stat(0o100755)

          String.ends_with?(path, "keyring") ->
            stub_stat(0o100600)

          true ->
            stub_stat(0o100644)
        end
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert :ok = Validator.validate(cfg, stat_fn)
    end

    test "passes when keyring has mode 0640 (group-readable but not group-writable)" do
      stat_fn = fn path ->
        cond do
          String.ends_with?(path, "ceph") and not String.ends_with?(path, "ceph.conf") ->
            stub_stat(0o100755)

          String.ends_with?(path, "keyring") ->
            stub_stat(0o100640)

          true ->
            stub_stat(0o100644)
        end
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")
      assert :ok = Validator.validate(cfg, stat_fn)
    end
  end

  # ── Secret redaction ──────────────────────────────────────────────────────────

  describe "secret redaction" do
    test "failure messages do not include key material or file content" do
      # Simulate a missing keyring to generate failure messages
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"), do: {:error, :enoent}, else: stub_stat(0o100755)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      # No failure message should ever include file content markers
      for failure <- failures do
        refute String.contains?(failure.reason, "key = "),
               "failure.reason must not contain key material"

        refute String.contains?(failure.reason, "[keyring]"),
               "failure.reason must not contain keyring file content"

        refute String.contains?(failure.reason, "AQ"),
               "failure.reason must not contain base64 Ceph key material"
      end
    end

    test "failure messages for permission errors contain only mode and path, not content" do
      stat_fn = fn path ->
        if String.ends_with?(path, "keyring"),
          do: stub_stat(0o100644),
          else: stub_stat(0o100755)
      end

      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)
      keyring_failure = Enum.find(failures, &(&1.code == :keyring_unsafe_permissions))

      # Message should reference mode and path, not file content
      assert String.contains?(keyring_failure.reason, "/etc/ceph/keyring")
      assert String.contains?(keyring_failure.reason, "0644")
      refute String.contains?(keyring_failure.reason, "key =")
      refute String.contains?(keyring_failure.reason, "[keyring]")
    end

    test "failure messages for root ownership contain only uid and path, not content" do
      stat_fn = uniform_stat_fn(0o100755, 0)
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)
      root_failure = Enum.find(failures, &(&1.code == :root_owned))

      assert String.contains?(root_failure.reason, "uid 0")
      refute String.contains?(root_failure.reason, "key =")
    end

    test "action_required messages do not include key material" do
      stat_fn = uniform_stat_fn(0o100644)
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      for failure <- failures do
        refute String.contains?(failure.action_required, "key = "),
               "action_required must not contain key material"
      end
    end
  end

  # ── Failure structure ─────────────────────────────────────────────────────────

  describe "failure structure" do
    test "each failure has required fields: code, reason, path, field, severity, action_required" do
      stat_fn = missing_stat_fn()
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      for failure <- failures do
        assert Map.has_key?(failure, :code)
        assert Map.has_key?(failure, :reason)
        assert Map.has_key?(failure, :path)
        assert Map.has_key?(failure, :field)
        assert Map.has_key?(failure, :severity)
        assert Map.has_key?(failure, :action_required)
        assert failure.severity in [:error, :warning]
        assert is_binary(failure.reason)
        assert is_binary(failure.action_required)
      end
    end

    test "failures are returned in binary → conf → keyring order" do
      # Use all-missing to get failures for every file
      stat_fn = missing_stat_fn()
      cfg = config("/usr/bin/ceph", "/etc/ceph/ceph.conf", "/etc/ceph/keyring")

      assert {:error, failures} = Validator.validate(cfg, stat_fn)

      fields = Enum.map(failures, & &1.field)
      binary_idx = Enum.find_index(fields, &(&1 == "ceph_binary_path"))
      conf_idx = Enum.find_index(fields, &(&1 == "ceph_conf_path"))
      keyring_idx = Enum.find_index(fields, &(&1 == "keyring_path"))

      assert binary_idx < conf_idx
      assert conf_idx < keyring_idx
    end
  end

  # ── Default stat_fn uses real file system ────────────────────────────────────

  @tag :tmp_dir
  test "validate/1 with real files (no stat_fn) passes for well-configured files",
       %{tmp_dir: tmp_dir} do
    binary_path = Path.join(tmp_dir, "ceph")
    conf_path = Path.join(tmp_dir, "ceph.conf")
    keyring_path = Path.join(tmp_dir, "keyring")

    File.write!(binary_path, "#!/bin/sh\necho ok\n")
    File.chmod!(binary_path, 0o755)

    File.write!(conf_path, "[global]\n")
    File.chmod!(conf_path, 0o644)

    File.write!(keyring_path, "[client.exocomp]\n\tkey = [PLACEHOLDER]\n")
    File.chmod!(keyring_path, 0o600)

    {:ok, binary_stat} = File.stat(binary_path)
    {:ok, _conf_stat} = File.stat(conf_path)
    {:ok, _keyring_stat} = File.stat(keyring_path)

    cfg = config(binary_path, conf_path, keyring_path)

    if binary_stat.uid == 0 do
      # Running as root: ownership check will warn, skip this test
      :skip
    else
      assert :ok = Validator.validate(cfg)
    end
  end
end
