# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Router do
  @moduledoc false

  use Phoenix.Router

  pipeline :public_health do
    plug(:accepts, ["json"])
  end

  pipeline :metrics do
    plug(:accepts, ["text"])
  end

  scope "/", Exocomp.MissionControl do
    pipe_through(:public_health)

    get("/health", HealthController, :health)
    get("/health/live", HealthController, :liveness)
    get("/health/ready", HealthController, :readiness)
  end

  scope "/", Exocomp.MissionControl do
    pipe_through(:metrics)

    get("/metrics", MetricsController, :index)
  end
end
