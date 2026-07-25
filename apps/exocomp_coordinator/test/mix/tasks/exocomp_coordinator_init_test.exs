defmodule Mix.Tasks.Exocomp.Coordinator.InitTest do
  @moduledoc """
  Integration tests for the `mix exocomp.coordinator.init` Mix task.

  Verifies:
  - Stable exit behavior (success on new and already-initialized states)
  - Output includes offline backup path and root fingerprint
  - Output never includes private key material or protection inputs
  - Distinct outcomes for new / already-initialized / invalid-state
  - Missing arguments and missing passphrase produce clear errors
  """

  use ExUnit.Case, async: false

  @passphrase "mix task integration passphrase"

  setup do
    original_passphrase = System.get_env("EXOCOMP_ROOT_KEY_PASSPHRASE")
    original_shell = Mix.shell()

    on_exit(fn ->
      case original_passphrase do
        nil -> System.delete_env("EXOCOMP_ROOT_KEY_PASSPHRASE")
        value -> System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", value)
      end

      Mix.shell(original_shell)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Run the Mix task directly in the test process and collect all shell output.
  # Mix.Shell.Process sends {:mix_shell, :info, [line]} to self() — since we
  # call run/1 directly, self() is the test process and all lines land here.
  defp run_and_collect(args) do
    Mix.shell(Mix.Shell.Process)

    try do
      Mix.Tasks.Exocomp.Coordinator.Init.run(args)
    rescue
      e in Mix.Error -> {:raised, e}
    end

    collect_shell_lines()
  end

  defp collect_shell_lines(acc \\ []) do
    receive do
      {:mix_shell, :info, [line]} -> collect_shell_lines([line | acc])
      {:mix_shell, :error, [line]} -> collect_shell_lines([line | acc])
    after
      200 -> Enum.reverse(acc)
    end
  end

  # ---------------------------------------------------------------------------
  # New initialization
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "newly initialized PKI outputs PKI_INITIALIZED with backup path and fingerprint", %{
    tmp_dir: tmp_dir
  } do
    online = Path.join(tmp_dir, "online")
    offline = Path.join(tmp_dir, "offline")
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    lines = run_and_collect(["--online-state", online, "--offline-root-backup", offline])

    assert Enum.member?(lines, "PKI_INITIALIZED"),
           "Expected PKI_INITIALIZED in output; got: #{inspect(lines)}"

    backup_line = Enum.find(lines, &String.starts_with?(&1, "offline_root_backup="))
    assert backup_line != nil, "Expected offline_root_backup= line; got: #{inspect(lines)}"
    assert backup_line =~ offline

    fp_line = Enum.find(lines, &String.starts_with?(&1, "root_fingerprint="))
    assert fp_line != nil, "Expected root_fingerprint= line; got: #{inspect(lines)}"

    fp = String.replace_prefix(fp_line, "root_fingerprint=", "")

    assert fp =~ ~r/\A(?:[0-9A-F]{2}:){31}[0-9A-F]{2}\z/,
           "Fingerprint format invalid: #{inspect(fp)}"
  end

  # ---------------------------------------------------------------------------
  # Already-initialized
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "already-initialized PKI outputs PKI_ALREADY_INITIALIZED", %{tmp_dir: tmp_dir} do
    online = Path.join(tmp_dir, "online")
    offline = Path.join(tmp_dir, "offline")
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    # First run: initialize
    run_and_collect(["--online-state", online, "--offline-root-backup", offline])

    # Second run: should report already initialized
    lines = run_and_collect(["--online-state", online, "--offline-root-backup", offline])

    assert Enum.member?(lines, "PKI_ALREADY_INITIALIZED"),
           "Expected PKI_ALREADY_INITIALIZED in output; got: #{inspect(lines)}"
  end

  # ---------------------------------------------------------------------------
  # Output redaction
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "output never contains private key material or the passphrase", %{tmp_dir: tmp_dir} do
    online = Path.join(tmp_dir, "online")
    offline = Path.join(tmp_dir, "offline")
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    lines = run_and_collect(["--online-state", online, "--offline-root-backup", offline])
    output = Enum.join(lines, "\n")

    refute output =~ @passphrase, "Passphrase must not appear in output"
    refute output =~ "PRIVATE KEY", "PEM private key header must not appear in output"
    refute output =~ "ENCRYPTED", "Encrypted PEM header must not appear in output"
    refute output =~ "BEGIN EC", "EC key header must not appear in output"
  end

  # ---------------------------------------------------------------------------
  # Fingerprint stability
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "fingerprint output is stable across idempotent runs", %{tmp_dir: tmp_dir} do
    online = Path.join(tmp_dir, "online")
    offline = Path.join(tmp_dir, "offline")
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    lines1 = run_and_collect(["--online-state", online, "--offline-root-backup", offline])

    fp1 =
      lines1
      |> Enum.find(&String.starts_with?(&1, "root_fingerprint="))
      |> String.replace_prefix("root_fingerprint=", "")

    lines2 = run_and_collect(["--online-state", online, "--offline-root-backup", offline])

    fp2 =
      lines2
      |> Enum.find(&String.starts_with?(&1, "root_fingerprint="))
      |> String.replace_prefix("root_fingerprint=", "")

    assert fp1 == fp2, "Root fingerprint must be stable across idempotent runs"
  end

  # ---------------------------------------------------------------------------
  # Error cases — missing passphrase / missing args
  # ---------------------------------------------------------------------------

  test "missing passphrase environment variable raises a descriptive error" do
    System.delete_env("EXOCOMP_ROOT_KEY_PASSPHRASE")

    assert_raise Mix.Error, ~r/EXOCOMP_ROOT_KEY_PASSPHRASE/, fn ->
      Mix.Tasks.Exocomp.Coordinator.Init.run([
        "--online-state",
        "/tmp/online",
        "--offline-root-backup",
        "/tmp/offline"
      ])
    end
  end

  test "missing --online-state argument raises a descriptive error" do
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    assert_raise Mix.Error, ~r/online-state|offline-root-backup/, fn ->
      Mix.Tasks.Exocomp.Coordinator.Init.run(["--offline-root-backup", "/tmp/offline"])
    end
  end

  test "missing --offline-root-backup argument raises a descriptive error" do
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    assert_raise Mix.Error, ~r/online-state|offline-root-backup/, fn ->
      Mix.Tasks.Exocomp.Coordinator.Init.run(["--online-state", "/tmp/online"])
    end
  end

  test "no arguments raises a descriptive error" do
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    assert_raise Mix.Error, ~r/online-state|offline-root-backup/, fn ->
      Mix.Tasks.Exocomp.Coordinator.Init.run([])
    end
  end

  @tag :tmp_dir
  test "invalid PKI state (partial online only) raises an error without private key material", %{
    tmp_dir: tmp_dir
  } do
    online = Path.join(tmp_dir, "online")
    offline = Path.join(tmp_dir, "offline")
    System.put_env("EXOCOMP_ROOT_KEY_PASSPHRASE", @passphrase)

    # Create incomplete state: only the online dir exists (missing offline)
    File.mkdir_p!(online)
    File.chmod!(online, 0o700)

    error =
      assert_raise Mix.Error, fn ->
        Mix.Tasks.Exocomp.Coordinator.Init.run([
          "--online-state",
          online,
          "--offline-root-backup",
          offline
        ])
      end

    refute error.message =~ @passphrase
    refute error.message =~ "PRIVATE KEY"
    refute error.message =~ "ENCRYPTED"
  end
end
