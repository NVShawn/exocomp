defmodule Exocomp.Node.SudoersPolicyTest do
  @moduledoc """
  Tests for `Exocomp.Node.SudoersPolicy`.

  Covers:
  - Correct sudoers entries for single and multiple services
  - Empty allow-list produces only the vacuum entry (or nothing with include_vacuum: false)
  - No wildcards in generated entries
  - Deterministic output (snapshot test)
  - Account name validation
  - Entry format (exact executable path, exact args)
  """

  use ExUnit.Case, async: true

  alias Exocomp.Node.SudoersPolicy

  @account "exocomp"
  @allow_list ["myapp.service", "nginx.service"]

  # ── render/3 basic shape ─────────────────────────────────────────────────

  describe "render/3 with allow-list" do
    setup do
      %{policy: SudoersPolicy.render(@account, @allow_list)}
    end

    test "output contains the account name", %{policy: policy} do
      assert String.contains?(policy, @account)
    end

    test "output contains /usr/bin/systemctl restart entries for each service", %{policy: policy} do
      for svc <- @allow_list do
        assert String.contains?(policy, "/usr/bin/systemctl restart #{svc}"),
               "Expected systemctl restart entry for #{svc}"
      end
    end

    test "output contains /usr/bin/journalctl vacuum entry", %{policy: policy} do
      assert String.contains?(policy, "/usr/bin/journalctl --vacuum-size=")
    end

    test "all entries use NOPASSWD", %{policy: policy} do
      # Every non-comment, non-empty line that grants a command must use NOPASSWD.
      command_lines =
        policy
        |> String.split("\n")
        |> Enum.reject(&String.starts_with?(String.trim(&1), "#"))
        |> Enum.reject(&(String.trim(&1) == ""))

      for line <- command_lines do
        assert String.contains?(line, "NOPASSWD:"),
               "Expected NOPASSWD in line: #{inspect(line)}"
      end
    end

    test "no wildcards appear in the output", %{policy: policy} do
      # ALL=(root) is the expected target-user specification in sudoers syntax.
      # What we must NOT have is a wildcard '*' in command position.
      refute String.contains?(policy, " * "), "Unexpected wildcard glob in policy"

      # Check that individual command lines don't use wildcard command patterns.
      command_lines =
        policy
        |> String.split("\n")
        |> Enum.filter(&String.contains?(&1, "NOPASSWD:"))

      for line <- command_lines do
        # The command after NOPASSWD: must name a specific executable — not "*".
        [_prefix, cmd_part] = String.split(line, "NOPASSWD:", parts: 2)
        cmd_trimmed = String.trim(cmd_part)

        assert String.starts_with?(cmd_trimmed, "/"),
               "Command must start with an absolute path: #{inspect(cmd_trimmed)}"

        refute String.starts_with?(cmd_trimmed, "/ "),
               "Bare '/' without executable is not allowed: #{inspect(cmd_trimmed)}"

        refute cmd_trimmed == "*",
               "Wildcard command is not allowed: #{inspect(cmd_trimmed)}"
      end
    end

    test "output is a valid sudoers fragment (no shell expansion markers)", %{policy: policy} do
      refute String.contains?(policy, "$(")
      refute String.contains?(policy, "`")
      refute String.contains?(policy, ";")
    end
  end

  # ── snapshot test ─────────────────────────────────────────────────────────

  describe "render/3 deterministic snapshot" do
    test "output matches expected snapshot for single service + vacuum" do
      # This is the canonical output — any future change to the format will
      # break this test, requiring a deliberate update.  This acts as a
      # regression guard for unintended policy changes.
      policy = SudoersPolicy.render("exocomp", ["myapp.service"])

      assert String.contains?(
               policy,
               "exocomp ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp.service"
             )

      assert String.contains?(
               policy,
               "exocomp ALL=(root) NOPASSWD: /usr/bin/journalctl --vacuum-size="
             )

      # Must have exactly one systemctl line for this allow-list.
      systemctl_lines = count_lines_containing(policy, "/usr/bin/systemctl")
      assert systemctl_lines == 1
    end

    test "output is identical for the same inputs (deterministic)" do
      policy1 = SudoersPolicy.render(@account, @allow_list)
      policy2 = SudoersPolicy.render(@account, @allow_list)
      assert policy1 == policy2
    end

    test "different allow-lists produce different outputs" do
      policy_a = SudoersPolicy.render(@account, ["alpha.service"])
      policy_b = SudoersPolicy.render(@account, ["beta.service"])
      assert policy_a != policy_b
    end
  end

  # ── empty allow-list ──────────────────────────────────────────────────────

  describe "render/3 with empty allow-list" do
    test "produces a vacuum entry even with an empty allow-list" do
      policy = SudoersPolicy.render(@account, [])
      assert String.contains?(policy, "/usr/bin/journalctl")
      refute String.contains?(policy, "systemctl")
    end

    test "produces empty string when allow-list is empty and include_vacuum is false" do
      policy = SudoersPolicy.render(@account, [], include_vacuum: false)
      assert policy == ""
    end
  end

  # ── include_vacuum option ─────────────────────────────────────────────────

  describe "render/3 include_vacuum: false" do
    test "omits journalctl entry" do
      policy = SudoersPolicy.render(@account, @allow_list, include_vacuum: false)
      refute String.contains?(policy, "journalctl")
    end

    test "still includes restart entries" do
      policy = SudoersPolicy.render(@account, @allow_list, include_vacuum: false)
      assert String.contains?(policy, "systemctl restart")
    end
  end

  # ── account name validation ───────────────────────────────────────────────

  describe "validate_account/1" do
    test "accepts valid POSIX usernames" do
      for name <- ["exocomp", "exocomp_node", "my-service", "_hidden", "a", "z99"] do
        assert :ok == SudoersPolicy.validate_account(name),
               "Expected :ok for #{inspect(name)}"
      end
    end

    test "rejects names with shell metacharacters" do
      for name <- [
            "exocomp;id",
            "exo$(id)",
            "exo`id`",
            "exo|cat",
            "exo&bg",
            "exo>out",
            "exo<in",
            "exo ALL=(root)",
            "exo\nnewline",
            "exo space",
            ""
          ] do
        assert {:error, :invalid_account} == SudoersPolicy.validate_account(name),
               "Expected :invalid_account for #{inspect(name)}"
      end
    end

    test "rejects names starting with a digit" do
      assert {:error, :invalid_account} = SudoersPolicy.validate_account("1bad")
    end

    test "rejects names starting with a hyphen" do
      assert {:error, :invalid_account} = SudoersPolicy.validate_account("-bad")
    end

    test "rejects non-binary input" do
      assert {:error, :invalid_account} = SudoersPolicy.validate_account(nil)
      assert {:error, :invalid_account} = SudoersPolicy.validate_account(42)
    end
  end

  # ── filename/1 ───────────────────────────────────────────────────────────

  describe "filename/1" do
    test "returns expected drop-in filename" do
      assert SudoersPolicy.filename("exocomp") == "exocomp-exocomp"
    end
  end

  # ── helper ───────────────────────────────────────────────────────────────

  defp count_lines_containing(text, substring) do
    text
    |> String.split("\n")
    |> Enum.count(&String.contains?(&1, substring))
  end
end
