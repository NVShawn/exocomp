# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OrganizationScopeTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{OrganizationScope, OrganizationScopedRecord}

  defmodule MutationRepo do
    def all(query) do
      send(self(), {:all, query})
      []
    end

    def update_all(query, updates) do
      send(self(), {:update_all, query, updates})
      {1, nil}
    end

    def delete_all(query) do
      send(self(), {:delete_all, query})
      {1, nil}
    end
  end

  test "requires a non-empty organization ID" do
    assert OrganizationScope.require_id(nil) == {:error, :organization_required}
    assert OrganizationScope.require_id("  ") == {:error, :organization_required}
    assert {:ok, "org-a"} = OrganizationScope.require_id("org-a")

    assert_raise ArgumentError, "organization_id is required", fn ->
      OrganizationScope.require_id!(nil)
    end
  end

  test "tenant queries always contain the requested organization predicate" do
    query = OrganizationScope.query(OrganizationScopedRecord, "org-a")
    params = query_params(query)

    assert "org-a" in params
    assert query_has_organization_predicate?(query)
    refute function_exported?(OrganizationScope, :all, 2)
  end

  test "missing scope cannot produce a query" do
    assert_raise ArgumentError, "organization_id is required", fn ->
      OrganizationScope.query(OrganizationScopedRecord, nil)
    end
  end

  test "insert changesets fail closed without a scope" do
    changeset =
      %OrganizationScopedRecord{}
      |> OrganizationScopedRecord.changeset(%{key: "setting"})
      |> OrganizationScope.put(nil)

    refute changeset.valid?
    assert "organization_id is required" in errors_on(changeset).organization_id
  end

  test "insert changesets reject a scope different from the supplied record" do
    supplied_organization_id = Ecto.UUID.generate()

    changeset =
      %OrganizationScopedRecord{}
      |> OrganizationScopedRecord.changeset(%{
        key: "setting",
        organization_id: supplied_organization_id
      })
      |> OrganizationScope.put(Ecto.UUID.generate())

    refute changeset.valid?
    assert "does not match organization scope" in errors_on(changeset).organization_id
  end

  test "all mutations require the same organization-scoped query boundary" do
    organization_id = Ecto.UUID.generate()
    queryable = OrganizationScopedRecord

    assert [] = OrganizationScope.all(MutationRepo, queryable, organization_id)
    assert_received {:all, all_query}

    assert {1, nil} =
             OrganizationScope.update_all(MutationRepo, queryable, organization_id,
               set: [key: "new"]
             )

    assert_received {:update_all, update_query, set: [key: "new"]}

    assert {1, nil} = OrganizationScope.delete_all(MutationRepo, queryable, organization_id)
    assert_received {:delete_all, delete_query}

    for query <- [all_query, update_query, delete_query] do
      assert query_has_organization_predicate?(query)
      assert organization_id in query_params(query)
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end

  defp query_params(query) do
    Enum.flat_map(query.wheres, fn where -> Enum.map(where.params, &elem(&1, 0)) end)
  end

  defp query_has_organization_predicate?(query) do
    Enum.any?(query.wheres, &match?(%Ecto.Query.BooleanExpr{expr: {:==, _, _}}, &1))
  end
end
