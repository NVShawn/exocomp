# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Seeds do
  @moduledoc "Development and test seed data for the initial deployment."

  alias Exocomp.MissionControl.{Organization, Organizations, Repo}

  @initial_slug "exocomp"
  @initial_name "Exocomp"

  @doc "Ensures the one initial organization exists and is safe to rerun."
  @spec run(keyword()) :: {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}
  def run(opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    case Organizations.get_by_slug(@initial_slug, repo: repo) do
      %Organization{} = organization -> {:ok, organization}
      nil -> Organizations.create(%{name: @initial_name, slug: @initial_slug}, repo: repo)
    end
  end

  @doc "The stable slug used by the test/development seed."
  @spec initial_slug() :: String.t()
  def initial_slug, do: @initial_slug
end
