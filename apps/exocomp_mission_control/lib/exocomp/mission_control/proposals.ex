# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Proposals do
  @moduledoc "Proposal-facing aliases for the operator decision context."

  alias Exocomp.MissionControl.Approvals

  defdelegate approve(organization_id, proposal_id, operator, opts \\ []),
    to: Approvals

  defdelegate deny(organization_id, proposal_id, operator, reason, opts \\ []),
    to: Approvals

  defdelegate approve_proposal(organization_id, proposal_id, operator, opts \\ []),
    to: Approvals

  defdelegate deny_proposal(organization_id, proposal_id, operator, reason, opts \\ []),
    to: Approvals
end
