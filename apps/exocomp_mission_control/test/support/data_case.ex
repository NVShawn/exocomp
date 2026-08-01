# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DataCase do
  @moduledoc "Shared setup for tests that exercise the Mission Control database."

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Exocomp.MissionControl.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Exocomp.MissionControl.DataCase
    end
  end

  setup tags do
    owner =
      Ecto.Adapters.SQL.Sandbox.start_owner!(Exocomp.MissionControl.Repo,
        shared: not tags[:async]
      )

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
    {:ok, repo_owner: owner}
  end
end
