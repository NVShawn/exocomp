# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminCluster do
  @moduledoc """
  Safe certificate and connectivity metadata shown to administrators.
  """

  @enforce_keys [:id, :organization_id, :name, :status, :certificate_status]
  defstruct [
    :id,
    :organization_id,
    :name,
    :status,
    :certificate_status,
    :certificate_serial,
    :certificate_fingerprint,
    :certificate_expires_at,
    :labels,
    :revoked_at,
    :last_seen_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          name: String.t(),
          status: :connected | :disconnected | :reconnecting,
          certificate_status: :active | :expired | :revoked | :unknown,
          certificate_serial: String.t() | nil,
          certificate_fingerprint: String.t() | nil,
          certificate_expires_at: DateTime.t() | nil,
          labels: map(),
          revoked_at: DateTime.t() | nil,
          last_seen_at: DateTime.t() | nil
        }

  @doc "Returns certificate/status metadata without certificate material."
  @spec public(t()) :: map()
  def public(%__MODULE__{} = cluster) do
    Map.from_struct(cluster)
    |> Map.drop([:organization_id])
  end
end
