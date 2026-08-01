# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminAction do
  @moduledoc """
  Auditable record for a Mission Control administrative mutation.
  """

  @enforce_keys [:id, :organization_id, :operator_sub, :action, :resource_id, :inserted_at]
  defstruct [
    :id,
    :organization_id,
    :operator_sub,
    :action,
    :resource_id,
    :correlation_id,
    :inserted_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          operator_sub: String.t(),
          action: String.t(),
          resource_id: String.t(),
          correlation_id: String.t(),
          inserted_at: DateTime.t()
        }
end
