# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminRoleMapping do
  @moduledoc """
  An organization-scoped OIDC claim-to-role mapping.
  """

  @enforce_keys [:id, :organization_id, :claim, :role, :inserted_at]
  defstruct [:id, :organization_id, :claim, :role, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          claim: String.t(),
          role: :viewer | :operator | :admin,
          inserted_at: DateTime.t()
        }
end
