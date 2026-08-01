# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Layouts do
  @moduledoc false

  use Phoenix.Component

  import Exocomp.MissionControl.Components

  embed_templates("layouts/*")
end
