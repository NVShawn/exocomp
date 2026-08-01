# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :exocomp_mission_control

  @session_options [
    store: :cookie,
    key: "_exocomp_mission_control_key",
    signing_salt: "mission-control-session",
    same_site: "Lax",
    http_only: true,
    secure: Mix.env() == :prod
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options], timeout: 45_000],
    longpoll: [timeout: 45_000]
  )

  plug(Plug.Static,
    at: "/",
    from: :exocomp_mission_control,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(Exocomp.MissionControl.Router)
end
