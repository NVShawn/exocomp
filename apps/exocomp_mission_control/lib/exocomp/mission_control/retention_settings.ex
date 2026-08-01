# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.RetentionSettings do
  @moduledoc """
  Organization retention policy with bounded day values.
  """

  @enforce_keys [:organization_id, :status_history_days, :incident_days]
  defstruct [:organization_id, :status_history_days, :incident_days, :updated_at]

  @type t :: %__MODULE__{
          organization_id: String.t(),
          status_history_days: pos_integer(),
          incident_days: pos_integer(),
          updated_at: DateTime.t() | nil
        }
end
