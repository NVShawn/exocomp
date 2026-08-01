# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterInvitations do
  @moduledoc """
  Application context for organization-scoped cluster invitations.
  """

  alias Exocomp.Coordinator.{ClusterInvitation, ClusterInvitationStore}

  @spec create(map(), keyword()) ::
          {:ok, ClusterInvitation.t(), String.t()} | {:error, Exocomp.Coordinator.Error.t()}
  def create(attrs, opts \\ []), do: ClusterInvitationStore.create(attrs, opts)

  @spec create_invitation(map(), keyword()) ::
          {:ok, ClusterInvitation.t(), String.t()} | {:error, Exocomp.Coordinator.Error.t()}
  def create_invitation(attrs, opts \\ []), do: create(attrs, opts)

  @spec issue(String.t(), String.t(), map(), keyword()) ::
          {:ok, ClusterInvitation.t(), String.t()} | {:error, Exocomp.Coordinator.Error.t()}
  def issue(organization_id, cluster_name), do: issue(organization_id, cluster_name, %{}, [])

  def issue(organization_id, cluster_name, opts) when is_list(opts) do
    ClusterInvitationStore.issue(organization_id, cluster_name, opts)
  end

  def issue(organization_id, cluster_name, labels) when is_map(labels) do
    issue(organization_id, cluster_name, labels, [])
  end

  def issue(organization_id, cluster_name, labels, opts) when is_map(labels) do
    ClusterInvitationStore.issue(organization_id, cluster_name, labels, opts)
  end

  @spec consume(String.t(), String.t(), keyword()) ::
          {:ok, ClusterInvitation.t()} | {:error, Exocomp.Coordinator.Error.t()}
  def consume(token, organization_id, opts \\ []),
    do: ClusterInvitationStore.consume(token, organization_id, opts)
end
