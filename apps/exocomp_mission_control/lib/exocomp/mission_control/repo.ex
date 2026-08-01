# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo do
  @moduledoc "Mission Control's PostgreSQL repository."

  use Ecto.Repo,
    otp_app: :exocomp_mission_control,
    adapter: Ecto.Adapters.Postgres
end
