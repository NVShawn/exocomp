# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Authorization.ForbiddenError do
  @moduledoc """
  Raised by `Exocomp.MissionControl.Authorization.authorize!/3` when an
  operator is not authorized to perform an action.

  ## Fields

  - `:reason` — one of `:unauthenticated`, `:cross_organization`, or
    `:insufficient_role`.
  - `:action` — the action that was denied: `:read`, `:operate`, or
    `:administer`.
  - `:message` — a human-readable summary.
  """

  defexception [:reason, :action, :message]

  @type t :: %__MODULE__{
          reason: Exocomp.MissionControl.Authorization.deny_reason(),
          action: Exocomp.MissionControl.Authorization.action(),
          message: String.t()
        }

  @impl Exception
  def exception(opts) do
    reason = Keyword.fetch!(opts, :reason)
    action = Keyword.fetch!(opts, :action)

    %__MODULE__{
      reason: reason,
      action: action,
      message: "Forbidden: cannot #{action} — #{reason}"
    }
  end
end
