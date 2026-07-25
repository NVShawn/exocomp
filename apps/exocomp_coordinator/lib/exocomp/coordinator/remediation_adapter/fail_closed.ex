# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.FailClosed do
  @moduledoc false

  @behaviour Exocomp.Coordinator.RemediationAdapter

  @impl true
  def validate_proposal(_proposal), do: {:error, :remediation_adapter_unavailable}

  @impl true
  def collect_evidence(_proposal), do: {:error, :remediation_adapter_unavailable}

  @impl true
  def decide(_proposal, _evidence), do: {:deny, :remediation_adapter_unavailable}

  @impl true
  def execute(_action, _evidence, _approval), do: {:error, :remediation_adapter_unavailable}

  @impl true
  def verify(_action, _evidence, _result), do: {:error, :remediation_adapter_unavailable}
end
