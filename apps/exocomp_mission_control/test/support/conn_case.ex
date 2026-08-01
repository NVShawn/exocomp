# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConnCase do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up a connection.
  Such tests rely on Phoenix connection infrastructure and similar.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint Exocomp.MissionControl.Endpoint

      use Phoenix.ConnTest
      import Plug.Conn
      import Exocomp.MissionControl.ConnCase

      # Import LiveView testing utilities
      import Phoenix.LiveViewTest

      # The following is optional and useful for deep introspection
      # into Ecto's query generation
      # import Ecto.Query, only: [from: 1, from: 2]
    end
  end

  @doc """
  Helper to create a test connection with session cookie support.
  """
  def build_conn do
    Phoenix.ConnTest.build_conn()
    |> Plug.Session.call(Plug.Session.init(key: "_test_key", store: :cookie))
    |> fetch_session()
  end

  @doc """
  Initialize a test session with values.
  """
  def init_test_session(conn, values) do
    conn
    |> fetch_session()
    |> put_session_values(values)
  end

  defp put_session_values(conn, values) do
    Enum.reduce(values, conn, fn {key, value}, acc ->
      put_session(acc, key, value)
    end)
  end
end
