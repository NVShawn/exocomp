# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCIntegrationTest do
  use Exocomp.MissionControl.ConnCase

  import ExUnit.CaptureLog

  alias Exocomp.MissionControl.FakeOIDCProvider
  alias Exocomp.MissionControl.OIDCClient
  alias Exocomp.MissionControl.Endpoint

  @moduletag :integration
  @provider_port 9999
  @provider_url "http://localhost:9999"

  setup do
    {:ok, _port} = FakeOIDCProvider.start_server(@provider_port)
    configure_oidc()
    OIDCClient.clear_cache()

    on_exit(fn ->
      FakeOIDCProvider.stop_server()
      OIDCClient.clear_cache()
    end)

    :ok
  end

  test "completes a signed OIDC login with PKCE and stores only identity claims" do
    {conn, callback_path} = begin_login(build_conn())
    callback_conn = get(recycle(conn), callback_path)

    session_cookie = get_resp_header(conn, "set-cookie") |> Enum.join(";")
    assert session_cookie =~ "Secure"
    assert session_cookie =~ "HttpOnly"
    assert session_cookie =~ "SameSite=Lax"
    assert session_cookie =~ "Max-Age=604800"

    assert redirected_to(callback_conn, 302) == "/"
    assert get_session(callback_conn, :operator_id) == "test-user-123"
    assert get_session(callback_conn, :operator_email) == "test@example.com"
    assert get_session(callback_conn, :operator_name) == "Test User"
    assert get_session(callback_conn, :oidc_issuer) == @provider_url
    assert get_session(callback_conn, :oidc_state) == nil
    assert get_session(callback_conn, :oidc_nonce) == nil
    assert get_session(callback_conn, :oidc_code_verifier) == nil
    assert get_session(callback_conn, :id_token) == nil
    assert get_session(callback_conn, :access_token) == nil

    assert callback_conn.private[:plug_session_info] == :renew
  end

  test "rejects a callback with a bad state" do
    {conn, callback_path} = begin_login(build_conn())
    bad_path = replace_query(callback_path, "state", "tampered-state")

    response = get(recycle(conn), bad_path)

    assert response.status == 401
    assert get_session(response, :operator_id) == nil
    assert get_session(response, :oidc_code_verifier) == nil
  end

  test "rejects a callback with a bad nonce" do
    restart_provider(token_claims: %{"nonce" => "wrong-nonce"})
    {conn, callback_path} = begin_login(build_conn())

    response = get(recycle(conn), callback_path)

    assert response.status == 401
    assert get_session(response, :operator_id) == nil
  end

  test "rejects an ID token from an unexpected issuer" do
    restart_provider(token_claims: %{"iss" => "https://attacker.example"})
    {conn, callback_path} = begin_login(build_conn())

    response = get(recycle(conn), callback_path)

    assert response.status == 401
    assert get_session(response, :operator_id) == nil
  end

  test "rejects an ID token with an unexpected audience" do
    restart_provider(token_claims: %{"aud" => "another-client"})
    {conn, callback_path} = begin_login(build_conn())

    response = get(recycle(conn), callback_path)

    assert response.status == 401
    assert get_session(response, :operator_id) == nil
  end

  test "handles a denied login without exchanging a token" do
    restart_provider(authorization_error: {:access_denied, "User denied access"})
    {conn, callback_path} = begin_login(build_conn())

    response = get(recycle(conn), callback_path)

    assert response.status == 401
    assert response.resp_body =~ "Login denied"
    assert get_session(response, :operator_id) == nil
  end

  test "rejects a discovery document whose issuer does not match the provider URL" do
    restart_provider(discovery_issuer: "https://attacker.example")

    response = get(build_conn(), "/auth/login")

    assert response.status == 500
    assert response.resp_body =~ "Internal Server Error"
  end

  test "logout clears the session and redirects to the provider" do
    {conn, callback_path} = begin_login(build_conn())
    authenticated = get(recycle(conn), callback_path)

    logout = get(recycle(authenticated), "/auth/logout")

    assert redirected_to(logout, 302) == "#{@provider_url}/logout"
    assert get_session(logout, :operator_id) == nil
    assert get_session(logout, :operator_email) == nil

    assert {:ok, %HTTPoison.Response{status_code: 200}} =
             HTTPoison.get(redirected_to(logout, 302))
  end

  test "session cookies are encrypted, secure, HTTP-only, same-site, and expiring" do
    options = Endpoint.session_options()

    assert options[:store] == :cookie
    assert options[:http_only]
    assert options[:secure]
    assert options[:same_site] == "Lax"
    assert options[:max_age] == 7 * 24 * 60 * 60
    assert is_binary(options[:encryption_salt])
  end

  test "login and callback logs never contain tokens or client secrets" do
    {conn, callback_path} = begin_login(build_conn())

    log =
      capture_log(fn ->
        response = get(recycle(conn), replace_query(callback_path, "state", "wrong"))
        assert response.status == 401
      end)

    refute log =~ "fake-access-token"
    refute log =~ "test-secret"
  end

  defp configure_oidc do
    Application.put_env(:exocomp_mission_control, :oidc_provider_url, @provider_url)
    Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")
    Application.put_env(:exocomp_mission_control, :oidc_client_secret, "test-secret")

    Application.put_env(
      :exocomp_mission_control,
      :oidc_redirect_uri,
      "http://localhost:4002/auth/callback"
    )
  end

  defp restart_provider(options) do
    FakeOIDCProvider.stop_server()
    OIDCClient.clear_cache()
    {:ok, _port} = FakeOIDCProvider.start_server(@provider_port, options)
  end

  defp begin_login(conn) do
    login = get(conn, "/auth/login")
    auth_url = redirected_to(login, 302)

    {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} =
      HTTPoison.get(auth_url, [], follow_redirect: false)

    callback_url =
      headers
      |> Enum.find_value(fn
        {key, value} when key in ["location", "Location"] -> value
        _ -> nil
      end)

    {login, callback_path(callback_url)}
  end

  defp callback_path(url) do
    uri = URI.parse(url)
    uri.path <> if(uri.query, do: "?" <> uri.query, else: "")
  end

  defp replace_query(path, key, value) do
    uri = URI.parse(path)
    query = uri.query |> URI.decode_query() |> Map.put(key, value) |> URI.encode_query()
    uri.path <> "?" <> query
  end
end
