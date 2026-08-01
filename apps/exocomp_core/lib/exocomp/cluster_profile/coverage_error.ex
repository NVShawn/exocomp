# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.CoverageError do
  @moduledoc "Structured errors returned when profile coverage is unavailable."

  defexception code: :profile_coverage_error,
               message: "cluster profile coverage is unavailable",
               profile_id: nil,
               requested_version: nil,
               supported_versions: [],
               details: %{}

  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          profile_id: String.t() | nil,
          requested_version: term(),
          supported_versions: [pos_integer()],
          details: map()
        }

  @spec new(atom(), keyword()) :: t()
  def new(code, opts \\ []) do
    details = Keyword.get(opts, :details, %{})
    profile_id = Keyword.get(opts, :profile_id)
    requested_version = Keyword.get(opts, :requested_version)
    supported_versions = Keyword.get(opts, :supported_versions, [])

    %__MODULE__{
      code: code,
      message: Keyword.get(opts, :message, default_message(code, profile_id, requested_version)),
      profile_id: profile_id,
      requested_version: requested_version,
      supported_versions: supported_versions,
      details: details
    }
  end

  defp default_message(:unknown_profile, profile_id, _version),
    do: "cluster profile is not shipped: #{inspect(profile_id)}"

  defp default_message(:unsupported_profile_version, profile_id, version),
    do: "cluster profile #{inspect(profile_id)} does not support version #{inspect(version)}"

  defp default_message(:non_shipped_profile, _profile_id, _version),
    do: "profiles must be compiled into a signed Exocomp release"

  defp default_message(:duplicate_profile_id, profile_id, _version),
    do: "duplicate shipped cluster profile ID: #{inspect(profile_id)}"

  defp default_message(code, _profile_id, _version),
    do: "cluster profile coverage error: #{code}"
end
