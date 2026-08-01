# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OrganizationScopedRecords do
  @moduledoc "Organization-scoped CRUD example for later tenant-owned contexts."

  import Ecto.Query

  alias Exocomp.MissionControl.{OrganizationScope, OrganizationScopedRecord, Repo}

  @doc "Creates a record only under the supplied organization scope."
  @spec create(term(), map(), keyword()) ::
          {:ok, OrganizationScopedRecord.t()}
          | {:error, Ecto.Changeset.t() | :organization_required}
  def create(organization_id, attrs, opts \\ []) when is_map(attrs) do
    repo = Keyword.get(opts, :repo, Repo)

    changeset =
      %OrganizationScopedRecord{}
      |> OrganizationScopedRecord.changeset(attrs)
      |> OrganizationScope.put(organization_id)

    if changeset.valid? do
      repo.insert(changeset)
    else
      {:error, changeset}
    end
  end

  @doc "Fetches a record only when its ID belongs to the supplied organization."
  @spec get(term(), term(), keyword()) ::
          OrganizationScopedRecord.t() | nil | {:error, :organization_required}
  def get(organization_id, id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    case OrganizationScope.require_id(organization_id) do
      {:ok, organization_id} ->
        OrganizationScope.query(OrganizationScopedRecord, organization_id)
        |> where([record], record.id == ^id)
        |> repo.one()

      error ->
        error
    end
  end

  @doc "Lists records for exactly one organization."
  @spec list(term(), keyword()) ::
          [OrganizationScopedRecord.t()] | {:error, :organization_required}
  def list(organization_id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    case OrganizationScope.require_id(organization_id) do
      {:ok, organization_id} ->
        OrganizationScope.all(repo, OrganizationScopedRecord, organization_id)

      error ->
        error
    end
  end

  @doc "Updates a record only when its ID belongs to the supplied organization."
  @spec update(term(), term(), map(), keyword()) ::
          {:ok, OrganizationScopedRecord.t()}
          | {:error, Ecto.Changeset.t() | :organization_required | :not_found}
  def update(organization_id, id, attrs, opts \\ []) when is_map(attrs) do
    repo = Keyword.get(opts, :repo, Repo)

    case get(organization_id, id, repo: repo) do
      %OrganizationScopedRecord{} = record ->
        changeset =
          record
          |> OrganizationScopedRecord.changeset(attrs)
          |> OrganizationScope.put(organization_id)

        if changeset.valid?, do: repo.update(changeset), else: {:error, changeset}

      nil ->
        {:error, :not_found}

      error ->
        error
    end
  end

  @doc "Deletes a record only when its ID belongs to the supplied organization."
  @spec delete(term(), term(), keyword()) ::
          {:ok, OrganizationScopedRecord.t()} | {:error, :organization_required | :not_found}
  def delete(organization_id, id, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    case get(organization_id, id, repo: repo) do
      %OrganizationScopedRecord{} = record -> repo.delete(record)
      nil -> {:error, :not_found}
      error -> error
    end
  end
end
