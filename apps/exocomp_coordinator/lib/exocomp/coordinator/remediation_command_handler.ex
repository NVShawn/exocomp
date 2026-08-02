# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationCommandHandler do
  @moduledoc """
  Typed Mission Control command adapter for the coordinator.

  CommandProcessor authenticates and durably claims the command before this
  module is called.  The handler still validates the typed payload and leaves
  all policy, signing, node safety, and verification decisions to the
  remediation lifecycle.
  """

  alias Exocomp.Coordinator.RemediationLifecycle

  @spec handle(map(), map()) :: {:ok, map()} | {:error, term()}
  def handle(payload, %{kind: "proposal.approve"} = context) when is_map(payload) do
    RemediationLifecycle.approve_command(payload, context)
  end

  def handle(payload, %{kind: "proposal.deny"} = context) when is_map(payload) do
    RemediationLifecycle.deny_command(payload, context)
  end

  def handle(_payload, _context), do: {:error, :unsupported_remediation_command}
end
