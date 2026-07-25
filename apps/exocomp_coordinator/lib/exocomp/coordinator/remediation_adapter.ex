# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter do
  @moduledoc """
  Trusted boundary used by the remediation lifecycle.

  Implementations communicate with the node's typed action catalog and safety
  gates. The coordinator deliberately has no callback that accepts a command,
  executable, environment, or filesystem path.
  """

  @callback validate_proposal(map()) :: {:ok, term()} | {:error, term()}
  @callback collect_evidence(term()) :: {:ok, term()} | {:error, term()}
  @callback decide(term(), term()) ::
              {:allow, term()}
              | {:approval_required, term(), map()}
              | {:deny, term()}
              | {:error, term()}
  @callback execute(term(), term(), term() | nil) :: {:ok, term()} | {:error, term()}
  @callback verify(term(), term(), term()) :: {:ok, term()} | {:error, term()}
end
