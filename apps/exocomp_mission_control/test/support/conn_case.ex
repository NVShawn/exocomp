# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConnCase do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up
  a connection, including Phoenix LiveView testing utilities.

  Provides helpers for creating authenticated connections with operator sessions.
  """

  use ExUnit.CaseTemplate
  import Plug.Conn

  using do
    quote do
      # The default endpoint for testing
      @endpoint Exocomp.MissionControl.Endpoint

      import Plug.Conn
      import Phoenix.ConnTest, except: [build_conn: 0, init_test_session: 2]
      # Import LiveView testing utilities
      import Phoenix.LiveViewTest
      # Import our ConnCase helpers, including our custom build_conn/0
      import Exocomp.MissionControl.ConnCase

      alias Exocomp.MissionControl.Identity.Operator

      # Helper functions for authenticated testing

      @doc """
      Creates an authenticated connection with operator session data.
      """
      def create_authenticated_conn(operator_attrs \\ %{}) do
        operator = build_operator(operator_attrs)

        build_conn()
        |> init_test_session(%{
          "operator_id" => operator.sub,
          "operator_role" => operator.role,
          "organization_id" => operator.organization_id,
          "operator_name" => operator.display_name
        })
      end

      @doc """
      Builds an Operator struct for testing.
      """
      def build_operator(attrs \\ %{}) do
        defaults = %{
          sub: "user-#{System.unique_integer([:positive])}",
          organization_id: "org-test",
          role: :viewer,
          display_name: "Test User"
        }

        merged = Map.merge(defaults, Enum.into(attrs, %{}))

        %Operator{
          sub: merged.sub,
          organization_id: merged.organization_id,
          role: merged.role,
          display_name: merged.display_name
        }
      end

      def init_live_flash(conn) do
        conn
        |> fetch_live_flash()
        |> put_session(
          :live_socket_id,
          "users_sessions:#{Base.url_encode64(:crypto.strong_rand_bytes(32))}"
        )
      end
    end
  end

  @doc """
  Helper to create a test connection with session cookie support.
  """
  def build_conn do
    Phoenix.ConnTest.build_conn()
    |> Plug.Session.call(Plug.Session.init(Exocomp.MissionControl.Endpoint.session_options()))
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

  setup _context do
    {:ok, conn: build_conn()}
  end
end
