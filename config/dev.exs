# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

# For development, we disable any cache and enable debugging/tracing.
config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  code_reloader: true,
  check_origin: false,
  watchers: []

# Watch static and templates for browser reloading.
config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/exocomp/mission_control/(live|views)/.*(ex)$"
    ]
  ]

config :logger, :console, level: :debug
