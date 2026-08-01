# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule ExocompMissionControlWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :exocomp_mission_control

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_exocomp_mission_control_key",
    signing_salt: "4Py+sLJhh9R8VVsP",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :exocomp_mission_control,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the :code_reloader
  # configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug Phoenix.LiveReloader
  end

  plug(Phoenix.CodeReloader, paths: [Path.expand("../../../lib", __DIR__)])

  plug Plug.RequestId

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug Plug.MethodOverride
  plug Plug.Head
  plug {:check_origin, false}

  plug(Plug.Session, @session_options)
  plug ExocompMissionControlWeb.Router
end
