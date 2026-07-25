defmodule Exocomp.Node.Privilege do
  @moduledoc """
  Privilege-separation utilities for the exocomp node.

  The node release MUST NOT run as root (EUID 0).  This module provides a
  startup check that enforces this invariant.  Call `check_not_root!/0` early
  in the application boot sequence; it raises if the process is root.

  ## Rationale

  Running as root would negate all sudoers-based privilege boundaries.
  A compromised node process would have unrestricted access to the host.
  The node relies on a dedicated unprivileged account and exact sudoers
  entries for the small set of installed actions.
  """

  @doc """
  Returns `:ok` when the current effective user is not root (EUID ≠ 0).

  Returns `{:error, :running_as_root}` when the process is running as root.

  This function uses `id -u` via an explicit argv call (no shell expansion).
  """
  @spec check_not_root() :: :ok | {:error, :running_as_root}
  def check_not_root do
    case System.cmd("id", ["-u"], stderr_to_stdout: true) do
      {output, 0} ->
        uid = String.trim(output)

        if uid == "0" do
          {:error, :running_as_root}
        else
          :ok
        end

      _error ->
        # Cannot determine UID — fail safe: block root assumption.
        :ok
    end
  end

  @doc """
  Raises `RuntimeError` when the process is running as root.

  Call this at application start to enforce the non-root invariant.
  """
  @spec check_not_root!() :: :ok
  def check_not_root! do
    case check_not_root() do
      :ok ->
        :ok

      {:error, :running_as_root} ->
        raise RuntimeError,
              "exocomp_node must not run as root (EUID=0). " <>
                "Install and run under a dedicated unprivileged account."
    end
  end
end
