# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

pool_size =
  case Integer.parse(System.get_env("EXOCOMP_DB_POOL_SIZE", "10")) do
    {pool_size, ""} when pool_size > 0 -> pool_size
    _ -> 10
  end

# DATABASE_URL is intentionally read in config/runtime.exs so production
# credentials are supplied by the runtime secret store, never compiled into a
# release. Keep only non-secret pool settings in this environment file.
config :exocomp_mission_control, Exocomp.MissionControl.Repo, pool_size: pool_size
