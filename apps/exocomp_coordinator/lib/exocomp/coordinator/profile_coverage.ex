# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ProfileCoverage do
  @moduledoc """
  Tracks runtime availability of compiled cluster profiles.

  The core profile registry remains immutable: a failed startup check does not
  remove code from the release. This coordinator-side view records whether a
  configured profile is usable in the current process and prevents degraded
  profiles from being advertised or resolved.
  """

  use GenServer

  alias Exocomp.ClusterProfile.CoverageError
  alias Exocomp.ClusterProfile.Registry, as: StaticRegistry

  @type status :: :available | :degraded | :unknown

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec mark_available(String.t(), GenServer.server()) :: :ok
  def mark_available(profile_id, server \\ __MODULE__) do
    call(server, {:mark, profile_id, :available, %{}})
  end

  @spec mark_degraded(String.t(), map(), GenServer.server()) :: :ok
  def mark_degraded(profile_id, details \\ %{}, server \\ __MODULE__) do
    call(server, {:mark, profile_id, :degraded, details})
  end

  @spec status(String.t(), GenServer.server()) :: status()
  def status(profile_id, server \\ __MODULE__) do
    case call_if_running(server, {:status, profile_id}) do
      {:ok, status} -> status
      :unavailable -> fallback_status(profile_id)
    end
  end

  @spec available?(String.t(), GenServer.server()) :: boolean()
  def available?(profile_id, server \\ __MODULE__), do: status(profile_id, server) == :available

  @spec advertised_profiles(GenServer.server()) :: [map()]
  def advertised_profiles(server \\ __MODULE__) do
    case call_if_running(server, :advertised_profiles) do
      {:ok, profiles} -> profiles
      :unavailable -> StaticRegistry.advertised_profiles()
    end
  end

  @spec lookup(String.t(), term(), GenServer.server()) ::
          {:ok, module()} | {:error, CoverageError.t()}
  def lookup(profile_id, version, server \\ __MODULE__) do
    case status(profile_id, server) do
      :available ->
        StaticRegistry.lookup(profile_id, version)

      :degraded ->
        {:error,
         CoverageError.new(:profile_unavailable,
           profile_id: profile_id,
           requested_version: version,
           supported_versions: supported_versions(profile_id),
           details: %{status: :degraded}
         )}

      :unknown ->
        StaticRegistry.lookup(profile_id, version)
    end
  end

  @impl true
  def init(_opts) do
    statuses =
      StaticRegistry.profile_ids()
      |> Map.new(&{&1, %{status: :available, details: %{}}})

    {:ok, statuses}
  end

  @impl true
  def handle_call({:mark, profile_id, status, details}, _from, state) do
    {:reply, :ok, Map.put(state, profile_id, %{status: status, details: details})}
  end

  def handle_call({:status, profile_id}, _from, state) do
    {:reply, state |> Map.get(profile_id, %{status: :unknown}) |> Map.fetch!(:status), state}
  end

  def handle_call(:advertised_profiles, _from, state) do
    profiles =
      StaticRegistry.advertised_profiles()
      |> Enum.filter(fn profile ->
        match?(%{status: :available}, Map.get(state, profile.id, %{status: :unknown}))
      end)

    {:reply, profiles, state}
  end

  defp call(server, message) do
    GenServer.call(server, message)
  end

  defp call_if_running(server, message) do
    if running?(server) do
      try do
        {:ok, GenServer.call(server, message)}
      catch
        :exit, _reason -> :unavailable
      end
    else
      :unavailable
    end
  end

  defp running?(server) when is_atom(server), do: is_pid(Process.whereis(server))
  defp running?(server) when is_pid(server), do: Process.alive?(server)
  defp running?(_server), do: false

  defp fallback_status(profile_id) do
    if profile_id in StaticRegistry.profile_ids(), do: :available, else: :unknown
  end

  defp supported_versions(profile_id) do
    case StaticRegistry.advertised_profiles() |> Enum.find(&(&1.id == profile_id)) do
      %{versions: versions} -> versions
      nil -> []
    end
  end
end
