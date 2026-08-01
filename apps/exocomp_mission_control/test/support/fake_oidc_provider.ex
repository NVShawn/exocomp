# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.FakeOIDCProvider do
  @moduledoc """
  A fake OIDC provider for testing OIDC flows without connecting to real providers.
  """

  require Logger

  def start_server(port \\ 9999) do
    {:ok, _} =
      Plug.Cowboy.http(__MODULE__.Router,
        issuer: "http://localhost:#{port}",
        port: port
      )

    :timer.sleep(100)
    {:ok, port}
  end

  def stop_server do
    Plug.Cowboy.shutdown(__MODULE__.Router.HTTP)
  end
end

defmodule Exocomp.MissionControl.FakeOIDCProvider.Router do
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    issuer = Keyword.get(opts, :issuer, "http://localhost:9999")

    case conn.path_info do
      [".well-known", "openid-configuration"] ->
        handle_config(conn, issuer)

      ["auth"] ->
        handle_authorization(conn, issuer)

      ["token"] ->
        handle_token(conn, issuer)

      ["userinfo"] ->
        handle_userinfo(conn)

      _ ->
        Plug.Conn.send_resp(conn, 404, "Not Found")
    end
  end

  defp handle_config(conn, issuer) do
    config = %{
      "issuer" => issuer,
      "authorization_endpoint" => "#{issuer}/auth",
      "token_endpoint" => "#{issuer}/token",
      "userinfo_endpoint" => "#{issuer}/userinfo",
      "end_session_endpoint" => "#{issuer}/logout",
      "jwks_uri" => "#{issuer}/.well-known/jwks.json"
    }

    Plug.Conn.send_resp(conn, 200, Jason.encode!(config))
  end

  defp handle_authorization(conn, issuer) do
    # Extract parameters
    params = Plug.Conn.fetch_query_params(conn).query_params

    state = Map.get(params, "state", "")
    nonce = Map.get(params, "nonce", "")
    code_challenge = Map.get(params, "code_challenge", "")

    # For testing, we'll store these and return them with the code
    code = Base.url_encode64("#{state}:#{nonce}:#{code_challenge}", padding: false)

    redirect_uri = Map.get(params, "redirect_uri", "http://localhost:4000/auth/callback")
    callback_url = "#{redirect_uri}?code=#{code}&state=#{state}"

    Plug.Conn.put_resp_header(conn, "location", callback_url)
    |> Plug.Conn.send_resp(302, "")
  end

  defp handle_token(conn, issuer) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    params = URI.decode_query(body)

    code = Map.get(params, "code", "")
    code_verifier = Map.get(params, "code_verifier", "")

    # Decode the code to verify PKCE
    case verify_pkce(code, code_verifier) do
      :ok ->
        # Extract state and nonce from code
        [state, nonce, _code_challenge] = String.split(Base.url_decode64!(code), ":")

        # Generate ID token
        id_token = create_id_token(issuer, nonce)

        response = %{
          "access_token" => "test_access_token",
          "token_type" => "Bearer",
          "expires_in" => 3600,
          "id_token" => id_token
        }

        Plug.Conn.send_resp(conn, 200, Jason.encode!(response))

      :error ->
        Plug.Conn.send_resp(conn, 400, Jason.encode!(%{"error" => "invalid_grant"}))
    end
  end

  defp handle_userinfo(conn) do
    userinfo = %{
      "sub" => "test-user-123",
      "email" => "test@example.com",
      "name" => "Test User",
      "email_verified" => true
    }

    Plug.Conn.send_resp(conn, 200, Jason.encode!(userinfo))
  end

  defp verify_pkce(code, _code_verifier) do
    # For testing, we're simplified - in production PKCE verification is more complex
    case code do
      "" -> :error
      # Simplified for testing
      _ -> :ok
    end
  end

  defp create_id_token(issuer, nonce) do
    # Create a simple JWT with test claims
    # This is NOT a properly signed JWT, suitable only for testing
    header = %{"alg" => "RS256", "typ" => "JWT"}

    claims = %{
      "iss" => issuer,
      "sub" => "test-user-123",
      "aud" => "test-client",
      "nonce" => nonce,
      "email" => "test@example.com",
      "name" => "Test User",
      "email_verified" => true,
      "iat" => DateTime.utc_now() |> DateTime.to_unix(),
      "exp" => DateTime.utc_now() |> DateTime.add(3600) |> DateTime.to_unix()
    }

    # Create unsigned JWT (for testing only)
    header_encoded = header |> Jason.encode!() |> Base.url_encode64(padding: false)
    claims_encoded = claims |> Jason.encode!() |> Base.url_encode64(padding: false)
    signature = Base.url_encode64("test-signature", padding: false)

    "#{header_encoded}.#{claims_encoded}.#{signature}"
  end
end
