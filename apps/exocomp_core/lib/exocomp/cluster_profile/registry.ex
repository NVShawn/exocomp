# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.Registry do
  @moduledoc """
  Registry of cluster profiles compiled into the Exocomp release.

  This is deliberately a static registry.  There is no file loader, command
  runner, application configuration hook, or runtime mutation API.  Adding a
  profile therefore requires source code to be compiled and included in the
  signed release artifact.
  """

  alias Exocomp.ClusterProfile
  alias Exocomp.ClusterProfile.CoverageError

  @shipped_profile_modules [Exocomp.ClusterProfile.Default]

  @type advertisement :: %{id: ClusterProfile.id(), versions: [ClusterProfile.version()]}

  @doc "Returns the profile modules compiled into this release."
  @spec shipped_modules() :: [module()]
  def shipped_modules, do: @shipped_profile_modules

  @doc "Returns the IDs and versions suitable for Agent Card advertisement."
  @spec advertised_profiles() :: [advertisement()]
  def advertised_profiles do
    @shipped_profile_modules
    |> Enum.map(fn profile -> %{id: profile.id(), versions: [profile.version()]} end)
    |> Enum.sort_by(& &1.id)
  end

  @doc "Aliases used by callers that need the release capability inventory."
  @spec supported_profiles() :: [advertisement()]
  def supported_profiles, do: advertised_profiles()

  @spec profile_ids() :: [ClusterProfile.id()]
  def profile_ids, do: Enum.map(advertised_profiles(), & &1.id)

  @doc "Resolves a profile only when both its shipped ID and exact version match."
  @spec lookup(term(), term()) :: {:ok, module()} | {:error, CoverageError.t()}
  def lookup(profile_id, version) when is_binary(profile_id) do
    case Enum.find(@shipped_profile_modules, &(safe_id(&1) == profile_id)) do
      nil ->
        {:error,
         CoverageError.new(:unknown_profile,
           profile_id: profile_id,
           requested_version: version,
           supported_versions: []
         )}

      profile ->
        if safe_version(profile) == version do
          {:ok, profile}
        else
          {:error,
           CoverageError.new(:unsupported_profile_version,
             profile_id: profile_id,
             requested_version: version,
             supported_versions: [safe_version(profile)]
           )}
        end
    end
  end

  def lookup(profile_id, version) do
    {:error,
     CoverageError.new(:unknown_profile,
       profile_id: profile_id,
       requested_version: version,
       supported_versions: []
     )}
  end

  @doc "Common fetch spelling for profile resolution."
  def fetch(profile_id, version), do: lookup(profile_id, version)

  @doc "Returns the public descriptor for a supported profile version."
  @spec describe(term(), term()) :: {:ok, map()} | {:error, CoverageError.t()}
  def describe(profile_id, version) do
    with {:ok, profile} <- lookup(profile_id, version) do
      {:ok, ClusterProfile.descriptor(profile)}
    end
  end

  @doc "Validates a prospective static module list without registering it."
  @spec validate_profiles([module()]) :: :ok | {:error, CoverageError.t()}
  def validate_profiles(profiles) when is_list(profiles) do
    Enum.reduce_while(profiles, {:ok, MapSet.new()}, fn profile, {:ok, ids} ->
      with :ok <- validate_module(profile),
           id <- profile.id(),
           false <- MapSet.member?(ids, id) do
        {:cont, {:ok, MapSet.put(ids, id)}}
      else
        true ->
          {:halt,
           {:error,
            CoverageError.new(:duplicate_profile_id,
              profile_id: profile.id(),
              requested_version: profile.version()
            )}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, _ids} -> :ok
      error -> error
    end
  end

  def validate_profiles(_profiles) do
    {:error, CoverageError.new(:invalid_profile, message: "profiles must be a module list")}
  end

  @doc "Rejects all runtime registration attempts, including file and command sources."
  def register(_profile), do: reject_runtime_registration()
  def register(_profile, _opts), do: reject_runtime_registration()
  def register_from_file(_path), do: reject_runtime_registration()
  def register_from_command(_command), do: reject_runtime_registration()

  defp reject_runtime_registration do
    {:error, CoverageError.new(:non_shipped_profile)}
  end

  defp validate_module(profile) when is_atom(profile) do
    callbacks = [
      {:id, 0},
      {:version, 0},
      {:node_discovery_capability, 0},
      {:expected_services, 1},
      {:health_reduction, 1},
      {:supported_typed_actions, 0},
      {:redaction_metadata, 0}
    ]

    if Enum.all?(callbacks, &function_exported?(profile, elem(&1, 0), elem(&1, 1))) do
      :ok
    else
      {:error, CoverageError.new(:invalid_profile, details: %{module: profile})}
    end
  end

  defp validate_module(profile) do
    {:error, CoverageError.new(:invalid_profile, details: %{module: profile})}
  end

  defp safe_id(profile), do: profile.id()
  defp safe_version(profile), do: profile.version()
end
