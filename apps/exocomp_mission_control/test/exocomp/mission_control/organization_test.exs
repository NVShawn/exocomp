# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OrganizationTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{Organization, Organizations, Seeds}

  defmodule InsertRepo do
    def get_by(_schema, slug: slug) do
      case Process.get(:seed_organization) do
        %Organization{slug: ^slug} = organization -> organization
        _ -> nil
      end
    end

    def insert(changeset) do
      organization = Ecto.Changeset.apply_changes(changeset)
      Process.put(:seed_organization, organization)
      {:ok, organization}
    end
  end

  test "new generates a stable UUID and does not accept a caller-supplied ID" do
    changeset = Organizations.new(%{id: "caller-selected", name: "Acme", slug: "acme"})

    assert changeset.valid?
    assert {:ok, uuid} = Ecto.UUID.cast(changeset.data.id)
    assert uuid == changeset.data.id
    refute changeset.data.id == "caller-selected"
  end

  test "create inserts the generated organization through the repository boundary" do
    assert {:ok, %Organization{id: id, name: "Acme", slug: "acme"}} =
             Organizations.create(%{name: "Acme", slug: "acme"}, repo: InsertRepo)

    assert {:ok, ^id} = Ecto.UUID.cast(id)
  end

  test "organization changesets validate the unique slug shape" do
    assert %{valid?: false} =
             Organization.changeset(%Organization{}, %{name: "Acme", slug: "bad slug"})

    assert %{valid?: false} = Organization.changeset(%Organization{}, %{name: "Acme", slug: ""})
  end

  test "the initial seed has one stable development slug" do
    assert Seeds.initial_slug() == "exocomp"
  end

  test "the initial seed is idempotent" do
    assert {:ok, first} = Seeds.run(repo: InsertRepo)
    assert {:ok, ^first} = Seeds.run(repo: InsertRepo)
  end
end
