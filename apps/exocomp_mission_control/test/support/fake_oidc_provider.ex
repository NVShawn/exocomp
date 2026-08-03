# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.FakeOIDCProvider do
  @moduledoc "A signed, local OIDC provider used by the Mission Control integration tests."

  def start_server(port \\ 9999, options \\ []) do
    issuer = "http://localhost:#{port}"

    generated_jwk =
      {:rsa, 2048}
      |> JOSE.JWK.generate_key()

    {_key_type, signing_parameters} = JOSE.JWK.to_map(generated_jwk)

    signing_jwk =
      signing_parameters
      |> Map.put("kid", "test-signing-key")
      |> JOSE.JWK.from_map()

    router_options = [
      issuer: issuer,
      discovery_issuer: Keyword.get(options, :discovery_issuer, issuer),
      signing_jwk: signing_jwk,
      client_id: Keyword.get(options, :client_id, "test-client"),
      client_secret: Keyword.get(options, :client_secret, "test-secret"),
      token_claims: Keyword.get(options, :token_claims, %{}),
      authorization_error: Keyword.get(options, :authorization_error)
    ]

    {:ok, _pid} = Plug.Cowboy.http(__MODULE__.Router, router_options, port: port)
    :timer.sleep(25)
    {:ok, port}
  end

  def stop_server do
    Plug.Cowboy.shutdown(__MODULE__.Router.HTTP)
  catch
    :exit, _ -> :ok
  end
end

defmodule Exocomp.MissionControl.FakeOIDCProvider.Router do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, opts) do
    case conn.path_info do
      [".well-known", "openid-configuration"] -> handle_config(conn, opts)
      [".well-known", "jwks.json"] -> handle_jwks(conn, opts)
      ["auth"] -> handle_authorization(conn, opts)
      ["token"] -> handle_token(conn, opts)
      ["logout"] -> Plug.Conn.send_resp(conn, 200, "logged out")
      _ -> Plug.Conn.send_resp(conn, 404, "Not Found")
    end
  end

  defp handle_config(conn, opts) do
    discovery_issuer = Keyword.fetch!(opts, :discovery_issuer)

    json_response(conn, %{
      "issuer" => discovery_issuer,
      "authorization_endpoint" => "#{Keyword.fetch!(opts, :issuer)}/auth",
      "token_endpoint" => "#{Keyword.fetch!(opts, :issuer)}/token",
      "jwks_uri" => "#{Keyword.fetch!(opts, :issuer)}/.well-known/jwks.json",
      "end_session_endpoint" => "#{Keyword.fetch!(opts, :issuer)}/logout"
    })
  end

  defp handle_jwks(conn, opts) do
    {_key_type, jwk} = opts |> Keyword.fetch!(:signing_jwk) |> JOSE.JWK.to_public_map()
    json_response(conn, %{"keys" => [jwk]})
  end

  defp handle_authorization(conn, opts) do
    params = Plug.Conn.fetch_query_params(conn).query_params
    redirect_uri = Map.get(params, "redirect_uri")
    state = Map.get(params, "state", "")

    case Keyword.get(opts, :authorization_error) do
      nil ->
        payload = %{
          "nonce" => Map.get(params, "nonce", ""),
          "code_challenge" => Map.get(params, "code_challenge", ""),
          "client_id" => Map.get(params, "client_id", ""),
          "redirect_uri" => redirect_uri
        }

        code = Base.url_encode64(Jason.encode!(payload), padding: false)
        redirect(conn, redirect_uri, %{code: code, state: state})

      error ->
        {error_code, description} = normalize_error(error)

        redirect(conn, redirect_uri, %{
          error: error_code,
          error_description: description,
          state: state
        })
    end
  end

  defp handle_token(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    params = URI.decode_query(body)

    with {:ok, code_payload} <- decode_code(params["code"]),
         :ok <- verify_client(params, opts),
         :ok <- verify_pkce(code_payload["code_challenge"], params["code_verifier"]),
         id_token <- create_id_token(opts, code_payload["nonce"]) do
      json_response(conn, %{
        "access_token" => "fake-access-token",
        "token_type" => "Bearer",
        "expires_in" => 3600,
        "id_token" => id_token
      })
    else
      _ -> json_response(conn, %{"error" => "invalid_grant"}, 400)
    end
  end

  defp decode_code(code) when is_binary(code) do
    with {:ok, decoded} <- Base.url_decode64(code, padding: false),
         {:ok, payload} <- Jason.decode(decoded) do
      {:ok, payload}
    else
      _ -> {:error, :invalid_code}
    end
  end

  defp decode_code(_), do: {:error, :invalid_code}

  defp verify_client(params, opts) do
    expected_id = Keyword.fetch!(opts, :client_id)
    expected_secret = Keyword.fetch!(opts, :client_secret)

    if params["client_id"] == expected_id and params["client_secret"] == expected_secret,
      do: :ok,
      else: {:error, :invalid_client}
  end

  defp verify_pkce(expected_challenge, verifier)
       when is_binary(expected_challenge) and is_binary(verifier) do
    actual_challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

    if Plug.Crypto.secure_compare(expected_challenge, actual_challenge),
      do: :ok,
      else: {:error, :invalid_pkce}
  end

  defp verify_pkce(_, _), do: {:error, :invalid_pkce}

  defp create_id_token(opts, nonce) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    claims =
      %{
        "iss" => Keyword.fetch!(opts, :issuer),
        "sub" => "test-user-123",
        "aud" => Keyword.fetch!(opts, :client_id),
        "nonce" => nonce,
        "email" => "test@example.com",
        "name" => "Test User",
        "iat" => now,
        "exp" => now + 3600
      }
      |> Map.merge(Keyword.fetch!(opts, :token_claims))

    opts
    |> Keyword.fetch!(:signing_jwk)
    |> JOSE.JWT.sign(%{"alg" => "RS256", "typ" => "JWT", "kid" => "test-signing-key"}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp redirect(conn, redirect_uri, params) do
    location =
      redirect_uri
      |> URI.parse()
      |> URI.append_query(URI.encode_query(params))
      |> URI.to_string()

    conn |> Plug.Conn.put_resp_header("location", location) |> Plug.Conn.send_resp(302, "")
  end

  defp normalize_error({code, description}) when is_atom(code),
    do: {Atom.to_string(code), description}

  defp normalize_error(code) when is_atom(code),
    do: {Atom.to_string(code), "The login was denied."}

  defp normalize_error(code), do: {to_string(code), "The login was denied."}

  defp json_response(conn, body, status \\ 200) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end
end
