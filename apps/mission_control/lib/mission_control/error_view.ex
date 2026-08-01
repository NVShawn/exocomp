# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule MissionControl.ErrorView do
  # Simple error handler for Phoenix
  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end

  def render(_template, _assigns) do
    %{errors: %{detail: "An error occurred"}}
  end
end
