# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Endpoint do
  use Phoenix.Endpoint, otp_app: :exocomp_mission_control

  # The session is stored in an encrypted and signed cookie. The endpoint's
  # key_base must remain secret so the cookie cannot be forged or decrypted.
  @session_options [
    store: :cookie,
    key: "_mission_control_key",
    signing_salt: "Mission Control Session Signing Salt",
    encryption_salt: "Mission Control Session Encryption Salt",
    same_site: "Lax",
    secure: true,
    http_only: true,
    # 7 days
    max_age: 86400 * 7
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  @doc false
  def session_options, do: @session_options

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :exocomp_mission_control,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the :code_reloader configuration
  # of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus)
  end

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
