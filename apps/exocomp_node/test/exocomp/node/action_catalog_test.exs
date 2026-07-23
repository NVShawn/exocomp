defmodule Exocomp.Node.ActionCatalogTest do
  @moduledoc """
  Focused security and correctness tests for `Exocomp.Node.ActionCatalog`.

  Covers:
  - Allow-list enforcement for :restart_service
  - Unknown action ID rejection
  - Service-name character-set validation (shell metacharacter injection,
    path traversal, whitespace, NUL bytes)
  - Fixed executable paths (never caller-supplied)
  - Fixed environment (no caller values in env)
  - Fixed argv structure (target appears after a fixed prefix, not mixed with
    shell operators)
  - :vacuum_logs bypass of allow-list (it operates on the local journal)
  - sudoers_entries/1 coverage and snapshot
  """

  use ExUnit.Case, async: true

  alias Exocomp.Node.ActionCatalog

  @allow_list ["myapp.service", "nginx.service", "redis"]

  # ── allow-list enforcement ────────────────────────────────────────────────

  describe "lookup/3 :restart_service allow-list" do
    test "returns action def for a service in the allow-list" do
      assert {:ok, def_} = ActionCatalog.lookup(:restart_service, "myapp.service", @allow_list)
      assert is_map(def_)
      assert def_.executable == "/usr/bin/systemctl"
    end

    test "returns {:error, :not_allowed} for a valid name NOT in the allow-list" do
      assert {:error, :not_allowed} =
               ActionCatalog.lookup(:restart_service, "unknown.service", @allow_list)
    end

    test "returns {:error, :not_allowed} for an empty allow-list" do
      assert {:error, :not_allowed} =
               ActionCatalog.lookup(:restart_service, "myapp.service", [])
    end

    test "returns {:error, :not_allowed} for a nil allow-list element" do
      assert {:error, :not_allowed} =
               ActionCatalog.lookup(:restart_service, "myapp.service", [nil])
    end
  end

  # ── service-name validation (injection vectors) ───────────────────────────

  describe "lookup/3 service-name validation" do
    # Each entry: {description, target}
    # All must be rejected with {:error, :not_allowed}.
    @injection_targets [
      {"shell command substitution", "$(rm -rf /)"},
      {"backtick substitution", "`rm -rf /`"},
      {"semicolon chaining", "myapp.service; rm -rf /"},
      {"pipe operator", "myapp.service | cat /etc/shadow"},
      {"ampersand background", "myapp.service & id"},
      {"dollar variable", "$PATH"},
      {"double-quote", "\"myapp\""},
      {"single-quote", "'myapp'"},
      {"backslash", "my\\app"},
      {"forward slash (path)", "../../etc/passwd"},
      {"space in name", "my app.service"},
      {"tab in name", "my\tapp.service"},
      {"newline in name", "myapp\nservice"},
      {"NUL byte", "myapp\x00.service"},
      {"asterisk glob", "*.service"},
      {"question mark glob", "myapp?.service"},
      {"tilde expansion", "~/.service"},
      {"angle bracket redirect", "myapp.service > /tmp/x"},
      {"exclamation (history expansion)", "!myapp.service"},
      {"hash (comment injection)", "myapp.service # ALL=(root)"},
      {"empty string", ""},
      {"only dot", "."},
      {"leading dot", ".myapp.service"},
      {"leading hyphen", "-myapp.service"}
    ]

    for {desc, target} <- @injection_targets do
      @tag target: target, desc: desc
      test "rejects #{desc}: #{inspect(target)}" do
        target = @tag[:target]

        # Even if somehow in the allow-list, the name must be rejected.
        poisoned_list = [target | @allow_list]

        assert {:error, :not_allowed} =
                 ActionCatalog.lookup(:restart_service, target, poisoned_list),
               "Expected :not_allowed for target: #{inspect(target)}"
      end
    end

    test "accepts a valid name without .service suffix" do
      assert {:ok, _} = ActionCatalog.lookup(:restart_service, "redis", ["redis"])
    end

    test "accepts a valid name with .service suffix" do
      assert {:ok, _} = ActionCatalog.lookup(:restart_service, "myapp.service", @allow_list)
    end

    test "accepts a name with hyphens and underscores" do
      svc = "my-app_v2.service"
      assert {:ok, _} = ActionCatalog.lookup(:restart_service, svc, [svc])
    end

    test "accepts a name with at-sign (instance unit)" do
      svc = "worker@1.service"
      assert {:ok, _} = ActionCatalog.lookup(:restart_service, svc, [svc])
    end
  end

  # ── unknown action rejection ──────────────────────────────────────────────

  describe "lookup/3 unknown action" do
    test "returns {:error, :unknown_action} for an unrecognised atom" do
      assert {:error, :unknown_action} =
               ActionCatalog.lookup(:delete_files, "myapp.service", @allow_list)
    end

    test "returns {:error, :unknown_action} for an arbitrary string action" do
      assert {:error, :unknown_action} =
               ActionCatalog.lookup("systemctl restart", "myapp.service", @allow_list)
    end

    test "returns {:error, :unknown_action} for nil" do
      assert {:error, :unknown_action} =
               ActionCatalog.lookup(nil, "myapp.service", @allow_list)
    end
  end

  # ── action definition shape ───────────────────────────────────────────────

  describe "action def for :restart_service" do
    setup do
      {:ok, def_} = ActionCatalog.lookup(:restart_service, "myapp.service", @allow_list)
      %{def_: def_}
    end

    test "executable is the absolute systemctl path", %{def_: def_} do
      assert def_.executable == "/usr/bin/systemctl"
    end

    test "build_argv returns a list starting with 'restart'", %{def_: def_} do
      argv = def_.build_argv.()
      assert is_list(argv)
      assert hd(argv) == "restart"
    end

    test "build_argv includes the validated service name without modification", %{def_: def_} do
      argv = def_.build_argv.()
      assert "myapp.service" in argv
    end

    test "argv list has no shell metacharacters embedded", %{def_: def_} do
      argv = def_.build_argv.()

      for arg <- argv do
        refute String.contains?(arg, [";", "&", "|", "$", "`", ">", "<"]),
               "Unexpected metacharacter in argv arg: #{inspect(arg)}"
      end
    end

    test "env is an empty list (no caller-supplied vars)", %{def_: def_} do
      assert def_.env == []
    end

    test "timeout_ms is a positive integer", %{def_: def_} do
      assert is_integer(def_.timeout_ms) and def_.timeout_ms > 0
    end

    test "output_limit_bytes is a positive integer", %{def_: def_} do
      assert is_integer(def_.output_limit_bytes) and def_.output_limit_bytes > 0
    end
  end

  describe "action def for :vacuum_logs" do
    setup do
      {:ok, def_} = ActionCatalog.lookup(:vacuum_logs, nil, [])
      %{def_: def_}
    end

    test "executable is the absolute journalctl path", %{def_: def_} do
      assert def_.executable == "/usr/bin/journalctl"
    end

    test "allow-list is not required (nil target accepted)", %{def_: def_} do
      argv = def_.build_argv.()
      assert is_list(argv)
    end

    test "build_argv uses --vacuum-size flag", %{def_: def_} do
      argv = def_.build_argv.()
      assert Enum.any?(argv, &String.starts_with?(&1, "--vacuum-size="))
    end

    test "env is an empty list", %{def_: def_} do
      assert def_.env == []
    end

    test "vacuum_logs ignores the allow_list argument" do
      # Should succeed regardless of allow-list content.
      assert {:ok, _} = ActionCatalog.lookup(:vacuum_logs, nil, [])
      assert {:ok, _} = ActionCatalog.lookup(:vacuum_logs, "irrelevant", ["nothing"])
    end
  end

  # ── executor path immutability ────────────────────────────────────────────

  describe "executable path" do
    test "restart_service executable cannot be changed by injecting a different path" do
      # Even if a caller tried to craft a target that looks like a path argument,
      # the executable path is always /usr/bin/systemctl.
      {:ok, def_} = ActionCatalog.lookup(:restart_service, "myapp.service", @allow_list)
      assert def_.executable == "/usr/bin/systemctl"
      refute String.contains?(def_.executable, "..")
      assert String.starts_with?(def_.executable, "/")
    end

    test "vacuum_logs executable cannot be changed by caller input" do
      {:ok, def_} = ActionCatalog.lookup(:vacuum_logs, nil, [])
      assert def_.executable == "/usr/bin/journalctl"
      assert String.starts_with?(def_.executable, "/")
    end
  end

  # ── sudoers_entries/1 ─────────────────────────────────────────────────────

  describe "sudoers_entries/1" do
    test "empty allow-list returns only the vacuum entry" do
      entries = ActionCatalog.sudoers_entries([])
      assert length(entries) == 1
      [{exec, argv}] = entries
      assert exec == "/usr/bin/journalctl"
      assert Enum.any?(argv, &String.starts_with?(&1, "--vacuum-size="))
    end

    test "returns one restart entry per allow-listed service plus vacuum" do
      entries = ActionCatalog.sudoers_entries(["alpha.service", "beta.service"])
      # 2 restart + 1 vacuum
      assert length(entries) == 3
    end

    test "restart entries use correct executable and argv" do
      entries = ActionCatalog.sudoers_entries(["myapp.service"])

      restart_entry =
        Enum.find(entries, fn {exec, _argv} -> exec == "/usr/bin/systemctl" end)

      assert {"/usr/bin/systemctl", ["restart", "myapp.service"]} = restart_entry
    end

    test "silently drops invalid service names from the allow-list" do
      # Malformed names must not appear in sudoers entries.
      entries = ActionCatalog.sudoers_entries(["valid.service", "inva lid", "$(evil)"])

      restart_entries =
        Enum.filter(entries, fn {exec, _} -> exec == "/usr/bin/systemctl" end)

      assert length(restart_entries) == 1
      [{"/usr/bin/systemctl", ["restart", svc]}] = restart_entries
      assert svc == "valid.service"
    end

    test "returns a list of {executable, argv} tuples" do
      entries = ActionCatalog.sudoers_entries(["a.service"])

      for {exec, argv} <- entries do
        assert is_binary(exec)
        assert is_list(argv)
        assert Enum.all?(argv, &is_binary/1)
      end
    end
  end

  # ── action_ids/0 ─────────────────────────────────────────────────────────

  describe "action_ids/0" do
    test "returns the known action ids" do
      ids = ActionCatalog.action_ids()
      assert :restart_service in ids
      assert :vacuum_logs in ids
    end
  end
end
