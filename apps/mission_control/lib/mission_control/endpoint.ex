# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule MissionControl.Endpoint do
  use Phoenix.Endpoint, otp_app: :mission_control

  @session_options [
    key: "_mission_control_key",
    signing_salt: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    max_age: 86400,
    store: :cookie
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  plug(Plug.Static, at: "/", from: :mission_control, gzip: false, only: ~w())

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
  plug(MissionControl.Router)

  def init(_key, config) do
    {:ok, config}
  end
end
