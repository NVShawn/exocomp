# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Router do
  @moduledoc false

  use Phoenix.Router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Exocomp.MissionControl do
    pipe_through(:api)

    get("/health", HealthController, :health)
  end
end
