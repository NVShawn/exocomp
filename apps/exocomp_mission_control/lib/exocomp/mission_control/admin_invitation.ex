# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminInvitation do
  @moduledoc """
  The safe, persisted portion of a Mission Control cluster invitation.

  The plaintext token is deliberately not a field on this struct.  Callers
  receive it only as the third element of `Administration.create_invitation/2`.
  """

  @enforce_keys [
    :id,
    :organization_id,
    :cluster_name,
    :labels,
    :token_digest,
    :expires_at,
    :inserted_at
  ]
  defstruct [
    :id,
    :organization_id,
    :cluster_name,
    :labels,
    :token_digest,
    :expires_at,
    :inserted_at,
    :consumed_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          cluster_name: String.t(),
          labels: %{optional(String.t()) => String.t()},
          token_digest: binary(),
          expires_at: DateTime.t(),
          inserted_at: DateTime.t(),
          consumed_at: DateTime.t() | nil
        }

  @doc "Returns fields safe for display or JSON serialization."
  @spec public(t()) :: map()
  def public(%__MODULE__{} = invitation) do
    Map.take(Map.from_struct(invitation), [
      :id,
      :organization_id,
      :cluster_name,
      :labels,
      :expires_at,
      :inserted_at,
      :consumed_at
    ])
  end
end
