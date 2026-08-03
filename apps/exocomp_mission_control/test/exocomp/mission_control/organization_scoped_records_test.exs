# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OrganizationScopedRecordsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{OrganizationScopedRecord, OrganizationScopedRecords}

  defmodule CaptureRepo do
    def insert(changeset) do
      send(self(), {:insert, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def all(query) do
      send(self(), {:all, query})
      []
    end

    def one(query) do
      send(self(), {:one, query})

      case Process.get(:scoped_record) do
        %OrganizationScopedRecord{organization_id: organization_id} = record ->
          params =
            Enum.flat_map(query.wheres, fn where -> Enum.map(where.params, &elem(&1, 0)) end)

          if organization_id in params, do: record

        _ ->
          nil
      end
    end

    def update(changeset) do
      send(self(), {:update, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def delete(record) do
      send(self(), {:delete, record})
      {:ok, record}
    end
  end

  test "create requires an organization before it calls the repository" do
    assert {:error, changeset} =
             OrganizationScopedRecords.create(nil, %{key: "setting"}, repo: CaptureRepo)

    refute changeset.valid?
    refute_received {:insert, _}
  end

  test "create applies the organization scope before insert" do
    organization_id = Ecto.UUID.generate()

    assert {:ok, %OrganizationScopedRecord{organization_id: ^organization_id}} =
             OrganizationScopedRecords.create(organization_id, %{key: "setting"},
               repo: CaptureRepo
             )

    assert_received {:insert, changeset}
    assert Ecto.Changeset.get_change(changeset, :organization_id) == organization_id
  end

  test "a different organization cannot read, update, or delete the record ID" do
    record = %OrganizationScopedRecord{
      id: Ecto.UUID.generate(),
      organization_id: Ecto.UUID.generate(),
      key: "setting"
    }

    Process.put(:scoped_record, record)

    other_organization_id = Ecto.UUID.generate()

    assert nil ==
             OrganizationScopedRecords.get(other_organization_id, record.id, repo: CaptureRepo)

    assert_received {:one, get_query}

    assert {:error, :not_found} =
             OrganizationScopedRecords.update(other_organization_id, record.id, %{key: "changed"},
               repo: CaptureRepo
             )

    assert_received {:one, update_query}
    refute_received {:update, _}

    assert {:error, :not_found} =
             OrganizationScopedRecords.delete(other_organization_id, record.id, repo: CaptureRepo)

    assert_received {:one, delete_query}
    refute_received {:delete, _}

    for query <- [get_query, update_query, delete_query] do
      assert query_contains_scope?(query, other_organization_id)
    end
  end

  test "list always requires one organization" do
    refute function_exported?(OrganizationScopedRecords, :list, 0)

    assert {:error, :organization_required} =
             OrganizationScopedRecords.list(nil, repo: CaptureRepo)

    refute_received {:all, _}

    organization_id = Ecto.UUID.generate()

    assert [] = OrganizationScopedRecords.list(organization_id, repo: CaptureRepo)
    assert_received {:all, query}
    assert query_contains_scope?(query, organization_id)
  end

  defp query_contains_scope?(query, organization_id) do
    params = query_params(query)
    assert query_has_organization_predicate?(query)
    assert organization_id in params
  end

  defp query_params(query) do
    Enum.flat_map(query.wheres, fn where -> Enum.map(where.params, &elem(&1, 0)) end)
  end

  defp query_has_organization_predicate?(query) do
    Enum.any?(query.wheres, &match?(%Ecto.Query.BooleanExpr{expr: {:==, _, _}}, &1))
  end
end
