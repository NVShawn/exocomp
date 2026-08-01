# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminWebhook do
  @moduledoc """
  Non-secret webhook endpoint metadata used by the admin index.
  """

  @enforce_keys [:id, :organization_id, :url, :enabled, :event_types, :created_at]
  defstruct [:id, :organization_id, :url, :enabled, :event_types, :created_at]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          url: String.t(),
          enabled: boolean(),
          event_types: [String.t()],
          created_at: DateTime.t()
        }
end
