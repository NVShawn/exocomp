# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OrganizationScope do
  @moduledoc "Reusable, fail-closed organization scoping for tenant-owned data."

  import Ecto.Changeset
  import Ecto.Query

  @organization_required "organization_id is required"

  @doc "Returns a validated organization ID or an error."
  @spec require_id(term()) :: {:ok, String.t()} | {:error, :organization_required}
  def require_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :organization_required}, else: {:ok, id}
  end

  def require_id(_), do: {:error, :organization_required}

  @doc "Raises unless an organization ID is present, for query-building helpers."
  @spec require_id!(term()) :: String.t()
  def require_id!(id) do
    case require_id(id) do
      {:ok, id} -> id
      {:error, :organization_required} -> raise ArgumentError, @organization_required
    end
  end

  @doc "Adds the mandatory organization predicate to a tenant-owned query."
  @spec query(Ecto.Queryable.t(), term()) :: Ecto.Query.t()
  def query(queryable, organization_id) do
    organization_id = require_id!(organization_id)

    from(record in queryable,
      where: field(record, :organization_id) == ^organization_id
    )
  end

  @doc "Alias for `query/2` that makes the predicate visible at call sites."
  @spec scoped(Ecto.Queryable.t(), term()) :: Ecto.Query.t()
  def scoped(queryable, organization_id), do: query(queryable, organization_id)

  @doc "Adds the required organization ID to an insert or mutation changeset."
  @spec put(Ecto.Changeset.t(), term()) :: Ecto.Changeset.t()
  def put(%Ecto.Changeset{} = changeset, organization_id) do
    case require_id(organization_id) do
      {:ok, organization_id} ->
        put_matching_id(changeset, organization_id)

      {:error, :organization_required} ->
        add_error(changeset, :organization_id, @organization_required)
    end
  end

  @doc "Runs an organization-scoped list query; there is intentionally no unscoped variant."
  @spec all(module(), Ecto.Queryable.t(), term()) :: list()
  def all(repo, queryable, organization_id) do
    repo.all(query(queryable, organization_id))
  end

  @doc "Runs an organization-scoped update query."
  @spec update_all(module(), Ecto.Queryable.t(), term(), list()) ::
          {non_neg_integer(), nil | list()}
  def update_all(repo, queryable, organization_id, updates) when is_list(updates) do
    repo.update_all(query(queryable, organization_id), updates)
  end

  @doc "Runs an organization-scoped delete query."
  @spec delete_all(module(), Ecto.Queryable.t(), term()) :: {non_neg_integer(), nil | list()}
  def delete_all(repo, queryable, organization_id) do
    repo.delete_all(query(queryable, organization_id))
  end

  defp put_matching_id(changeset, organization_id) do
    existing = get_field(changeset, :organization_id)

    cond do
      is_nil(existing) ->
        changeset
        |> put_change(:organization_id, organization_id)
        |> clear_required_error(:organization_id)

      existing == organization_id ->
        changeset

      true ->
        add_error(changeset, :organization_id, "does not match organization scope")
    end
  end

  defp clear_required_error(%Ecto.Changeset{errors: errors} = changeset, field) do
    errors =
      Enum.reject(errors, fn
        {^field, {"can't be blank", _opts}} -> true
        _ -> false
      end)

    %{changeset | errors: errors, valid?: errors == []}
  end
end
