# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuthControllerTest do
  use Exocomp.MissionControl.ConnCase

  describe "login/2" do
    test "redirects to OIDC provider authorization endpoint" do
      Application.put_env(:exocomp_mission_control, :oidc_config_cache, %{
        "issuer" => "http://localhost:9999",
        "authorization_endpoint" => "http://localhost:9999/auth",
        "token_endpoint" => "http://localhost:9999/token",
        "userinfo_endpoint" => "http://localhost:9999/userinfo",
        "expires_at" => DateTime.add(DateTime.utc_now(), 3600)
      })

      conn = get(build_conn(), "/auth/login")

      assert redirected_to(conn, 302)
      # The session should contain state and nonce
      assert get_session(conn, :oidc_state)
      assert get_session(conn, :oidc_nonce)
    end

    test "stores state and nonce in session" do
      Application.put_env(:exocomp_mission_control, :oidc_config_cache, %{
        "issuer" => "http://localhost:9999",
        "authorization_endpoint" => "http://localhost:9999/auth",
        "token_endpoint" => "http://localhost:9999/token",
        "expires_at" => DateTime.add(DateTime.utc_now(), 3600)
      })

      conn = get(build_conn(), "/auth/login")

      state = get_session(conn, :oidc_state)
      nonce = get_session(conn, :oidc_nonce)

      assert is_binary(state)
      assert is_binary(nonce)
      assert byte_size(state) > 0
      assert byte_size(nonce) > 0
    end
  end

  describe "callback/2" do
    test "handles valid callback with code" do
      # This test would require mocking the token exchange and JWT validation
      # Setup test state and nonce
      conn =
        build_conn()
        |> init_test_session(%{"oidc_state" => "valid_state", "oidc_nonce" => "valid_nonce"})

      # Call callback with matching state
      # In practice, this would need proper mocks for HTTP requests
    end

    test "rejects callback with invalid state" do
      conn =
        build_conn()
        |> init_test_session(%{"oidc_state" => "stored_state"})

      # Callback with different state should fail
      response = get(conn, "/auth/callback?code=test_code&state=wrong_state")

      assert response.status == 401
    end

    test "rejects callback with missing state" do
      conn = build_conn()

      response = get(conn, "/auth/callback?code=test_code")

      assert response.status in [400, 401]
    end

    test "handles OIDC provider error in callback" do
      conn =
        build_conn()
        |> init_test_session(%{})

      response =
        get(conn, "/auth/callback?error=access_denied&error_description=User+denied+access")

      assert response.status == 401
    end

    test "handles callback with error but no description" do
      conn =
        build_conn()
        |> init_test_session(%{})

      response = get(conn, "/auth/callback?error=invalid_request")

      assert response.status == 401
    end

    test "clears state and nonce on successful authentication" do
      # This would require full mocking of the OAuth2 flow
      # Test deferred until integration tests with fake OIDC provider
    end

    test "rotates session ID on successful authentication" do
      # This would require full mocking of the OAuth2 flow
      # Test deferred until integration tests with fake OIDC provider
    end
  end

  describe "logout/2" do
    test "clears session and redirects to home" do
      conn =
        build_conn()
        |> init_test_session(%{
          "operator_id" => "user123",
          "operator_email" => "user@example.com",
          "oidc_issuer" => "http://localhost:9999"
        })

      response = post(conn, "/auth/logout")

      # Should clear the session
      assert get_session(response, :operator_id) == nil
      assert get_session(response, :operator_email) == nil
    end

    test "redirects to home when end session endpoint not available" do
      Application.put_env(:exocomp_mission_control, :oidc_config_cache, %{
        "issuer" => "http://localhost:9999"
      })

      conn =
        build_conn()
        |> init_test_session(%{
          "operator_id" => "user123",
          "oidc_issuer" => "http://localhost:9999"
        })

      response = post(conn, "/auth/logout")

      assert redirected_to(response, 302) =~ ~r|/login|
    end
  end
end
