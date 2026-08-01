# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.HealthController do
  @moduledoc false

  use Phoenix.Controller

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
