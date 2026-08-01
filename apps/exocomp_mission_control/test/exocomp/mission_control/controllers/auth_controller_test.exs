# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuthControllerTest do
  use Exocomp.MissionControl.ConnCase

  alias Exocomp.MissionControl.FakeOIDCProvider
  alias Exocomp.MissionControl.OIDCClient

  @port 9997
  @provider_url "http://localhost:9997"

  setup do
    {:ok, _port} = FakeOIDCProvider.start_server(@port)
    Application.put_env(:exocomp_mission_control, :oidc_provider_url, @provider_url)
    Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")
    Application.put_env(:exocomp_mission_control, :oidc_client_secret, "test-secret")

    Application.put_env(
      :exocomp_mission_control,
      :oidc_redirect_uri,
      "http://localhost:4002/auth/callback"
    )

    OIDCClient.clear_cache()

    on_exit(fn ->
      FakeOIDCProvider.stop_server()
      OIDCClient.clear_cache()
    end)

    :ok
  end

  test "login stores state, nonce, and its own PKCE verifier in the session" do
    conn = get(build_conn(), "/auth/login")

    assert redirected_to(conn, 302) =~ "#{@provider_url}/auth"
    assert is_binary(get_session(conn, :oidc_state))
    assert is_binary(get_session(conn, :oidc_nonce))
    assert is_binary(get_session(conn, :oidc_code_verifier))
    refute Application.get_env(:exocomp_mission_control, :pkce_verifier)
  end

  test "callback rejects missing and mismatched state before token exchange" do
    conn = get(build_conn(), "/auth/login")

    missing_state = get(recycle(conn), "/auth/callback?code=unused")
    assert missing_state.status == 401

    conn = get(build_conn(), "/auth/login")
    mismatched_state = get(recycle(conn), "/auth/callback?code=unused&state=wrong")
    assert mismatched_state.status == 401
  end

  test "callback reports provider denial and clears transient login state" do
    conn =
      build_conn()
      |> init_test_session(%{
        oidc_state: "state",
        oidc_nonce: "nonce",
        oidc_code_verifier: "verifier"
      })

    response = get(conn, "/auth/callback?state=state&error=access_denied")

    assert response.status == 401
    assert response.resp_body =~ "Login denied"
    assert get_session(response, :oidc_state) == nil
    assert get_session(response, :oidc_nonce) == nil
    assert get_session(response, :oidc_code_verifier) == nil
  end

  test "logout clears local identity and redirects to the configured provider" do
    conn =
      build_conn()
      |> init_test_session(%{
        operator_id: "user123",
        operator_email: "user@example.com",
        oidc_issuer: @provider_url
      })

    response = get(conn, "/auth/logout")

    assert redirected_to(response, 302) == "#{@provider_url}/logout"
    assert get_session(response, :operator_id) == nil
    assert get_session(response, :operator_email) == nil
  end
end
