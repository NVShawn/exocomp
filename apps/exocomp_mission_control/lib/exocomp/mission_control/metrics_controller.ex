# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.MetricsController do
  @moduledoc "Prometheus text exposition endpoint."

  use Phoenix.Controller

  alias Exocomp.MissionControl.Metrics

  @doc "Returns only aggregate, low-cardinality service metrics."
  def index(conn, _params) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain; version=0.0.4")
    |> Plug.Conn.send_resp(200, Metrics.render())
  end
end
