# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateMissionControlSchema do
  @moduledoc "Baseline migration reserved for the first Mission Control schema."

  use Ecto.Migration

  # Domain tables are introduced by their owning feature tasks. Keeping this
  # migration reversible gives deployments a stable migration baseline without
  # pulling feature schema into the database-infrastructure task.
  def up, do: :ok
  def down, do: :ok
end
