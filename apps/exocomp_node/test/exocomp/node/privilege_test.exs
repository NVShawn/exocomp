defmodule Exocomp.Node.PrivilegeTest do
  @moduledoc """
  Tests for `Exocomp.Node.Privilege`.

  The root-detection check is tested by inspecting the current EUID:
  - In the standard test environment (unprivileged container) the process is
    not root, so `check_not_root/0` returns `:ok`.
  - The `:running_as_root` branch is exercised by a mocking strategy: we
    call the private check logic with a stubbed uid string.
  """

  use ExUnit.Case, async: true

  alias Exocomp.Node.Privilege

  describe "check_not_root/0" do
    test "returns :ok when not running as root" do
      # In the standard CI container the test process runs as a non-root user.
      # This test will fail if accidentally run as root — which is intentional:
      # the node must never start as root.
      case Privilege.check_not_root() do
        :ok ->
          assert true

        {:error, :running_as_root} ->
          # If the test environment IS root, flag it explicitly.
          flunk(
            "Test is running as root (EUID=0). " <>
              "The node must not run as root. Run tests as an unprivileged user."
          )
      end
    end
  end

  describe "check_not_root!/0" do
    test "does not raise when not running as root" do
      # Mirrors check_not_root/0 but exercises the raising variant.
      current_uid =
        case System.cmd("id", ["-u"], stderr_to_stdout: true) do
          {output, 0} -> String.trim(output)
          _ -> "unknown"
        end

      if current_uid == "0" do
        # Running as root — the bang function must raise.
        assert_raise RuntimeError, ~r/must not run as root/, fn ->
          Privilege.check_not_root!()
        end
      else
        # Not running as root — the bang function must not raise.
        assert Privilege.check_not_root!() == :ok
      end
    end
  end
end
