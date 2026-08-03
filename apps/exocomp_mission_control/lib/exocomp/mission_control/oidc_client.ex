# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCClient do
  @moduledoc "OIDC Authorization Code client with PKCE and signed ID-token validation."

  require Logger

  alias Exocomp.MissionControl.OIDCConfigCache

  @http_timeout 5_000
  @allowed_algorithms ["RS256"]

  @doc """
  Build an authorization request.

  The code verifier is returned to the controller and must be kept in the
  short-lived login session. It is never stored in application configuration or
  shared process state.
  """
  def create_authorization_request do
    with {:ok, config} <- get_provider_config(),
         {:ok, client_id} <- configured(:oidc_client_id),
         {:ok, redirect_uri} <- configured(:oidc_redirect_uri) do
      state = random_string(32)
      nonce = random_string(32)
      code_verifier = random_string(64)
      code_challenge = pkce_challenge(code_verifier)

      auth_url =
        config["authorization_endpoint"]
        |> URI.parse()
        |> URI.append_query(
          URI.encode_query(
            client_id: client_id,
            redirect_uri: redirect_uri,
            response_type: "code",
            scope: "openid profile email",
            state: state,
            nonce: nonce,
            code_challenge: code_challenge,
            code_challenge_method: "S256"
          )
        )
        |> URI.to_string()

      {:ok, auth_url, state, nonce, code_verifier}
    end
  end

  @doc "Exchange an authorization code using the verifier from its login session."
  def exchange_code_for_token(code, code_verifier)
      when is_binary(code) and is_binary(code_verifier) do
    with {:ok, config} <- get_provider_config(),
         {:ok, client_id} <- configured(:oidc_client_id),
         {:ok, redirect_uri} <- configured(:oidc_redirect_uri),
         {:ok, client_secret} <- optional_config(:oidc_client_secret),
         {:ok, response_body} <-
           request_tokens(config, code, code_verifier, client_id, client_secret, redirect_uri),
         {:ok, tokens} <- extract_tokens(response_body) do
      {:ok, tokens}
    end
  end

  def exchange_code_for_token(_, _), do: {:error, "Invalid authorization code or PKCE verifier"}

  @doc "Verify the ID token and return the minimal identity needed by Mission Control."
  def validate_and_extract_claims(tokens, expected_nonce) when is_map(tokens) do
    with {:ok, config} <- get_provider_config(),
         {:ok, id_token} <- fetch_id_token(tokens),
         {:ok, claims} <- validate_id_token(id_token, config),
         :ok <- validate_claims(claims, config, expected_nonce) do
      {:ok, normalize_claims(claims, config)}
    end
  end

  def validate_and_extract_claims(_, _), do: {:error, "Invalid token response"}

  @doc "Return the provider's logout endpoint only for the configured issuer."
  def get_end_session_url(issuer) when is_binary(issuer) do
    with {:ok, config} <- get_provider_config(),
         :ok <- validate_issuer(issuer, config["issuer"]),
         endpoint when is_binary(endpoint) <- config["end_session_endpoint"] do
      {:ok, endpoint}
    else
      {:error, _} -> {:error, "Issuer mismatch or config unavailable"}
      _ -> {:error, "End session endpoint not available"}
    end
  end

  def get_end_session_url(_), do: {:error, "Invalid issuer"}

  @doc false
  def clear_cache, do: OIDCConfigCache.clear()

  defp get_provider_config do
    with {:ok, provider_url} <- configured(:oidc_provider_url),
         {:ok, config_url} <- discovery_url(provider_url) do
      expected_issuer = String.trim_trailing(provider_url, "/")

      OIDCConfigCache.fetch({:discovery, config_url}, fn ->
        fetch_discovery(config_url, expected_issuer)
      end)
    end
  end

  defp fetch_discovery(config_url, expected_issuer) do
    with {:ok, body} <- fetch_url(config_url),
         {:ok, config} <- decode_json(body),
         :ok <- validate_provider_config(config, expected_issuer) do
      {:ok, config}
    end
  end

  defp discovery_url(provider_url) do
    uri = URI.parse(String.trim_trailing(provider_url, "/"))

    if uri.scheme in ["http", "https"] and is_binary(uri.host) do
      {:ok, String.trim_trailing(provider_url, "/") <> "/.well-known/openid-configuration"}
    else
      {:error, "OIDC provider URL is invalid"}
    end
  end

  defp validate_provider_config(config, expected_issuer) when is_map(config) do
    required_endpoints = ["authorization_endpoint", "token_endpoint", "jwks_uri"]

    with :ok <- validate_issuer(config["issuer"], expected_issuer),
         true <- Enum.all?(required_endpoints, &(is_binary(config[&1]) and config[&1] != "")) do
      :ok
    else
      false -> {:error, "OIDC discovery document is missing required endpoints"}
      {:error, _} -> {:error, "OIDC discovery issuer is invalid"}
    end
  end

  defp validate_provider_config(_, _), do: {:error, "Invalid OIDC discovery document"}

  defp fetch_jwks(config) do
    jwks_uri = config["jwks_uri"]

    if is_binary(jwks_uri) do
      OIDCConfigCache.fetch({:jwks, jwks_uri}, fn ->
        with {:ok, body} <- fetch_url(jwks_uri),
             {:ok, jwks} <- decode_json(body),
             true <- is_list(jwks["keys"]) do
          {:ok, jwks["keys"]}
        else
          false -> {:error, "Invalid OIDC JWKS document"}
          error -> error
        end
      end)
    else
      {:error, "OIDC JWKS endpoint is missing"}
    end
  end

  defp fetch_url(url) do
    case HTTPoison.get(url, [], timeout: @http_timeout, recv_timeout: @http_timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.warning("OIDC endpoint returned HTTP status #{status}")
        {:error, "OIDC endpoint returned HTTP status #{status}"}

      {:error, _reason} ->
        Logger.warning("OIDC endpoint request failed")
        {:error, "OIDC endpoint request failed"}
    end
  end

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, value} -> {:ok, value}
      {:error, _reason} -> {:error, "Invalid JSON from OIDC endpoint"}
    end
  end

  defp request_tokens(config, code, code_verifier, client_id, client_secret, redirect_uri) do
    params = [
      grant_type: "authorization_code",
      code: code,
      client_id: client_id,
      redirect_uri: redirect_uri,
      code_verifier: code_verifier
    ]

    params =
      if is_binary(client_secret) and client_secret != "" do
        Keyword.put(params, :client_secret, client_secret)
      else
        params
      end

    body = URI.encode_query(params)

    case HTTPoison.post(
           config["token_endpoint"],
           body,
           [
             {"Content-Type", "application/x-www-form-urlencoded"},
             {"Accept", "application/json"}
           ],
           timeout: @http_timeout,
           recv_timeout: @http_timeout
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, response_body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.warning("OIDC token endpoint returned HTTP status #{status}")
        {:error, "OIDC token endpoint returned HTTP status #{status}"}

      {:error, _reason} ->
        Logger.warning("OIDC token request failed")
        {:error, "OIDC token request failed"}
    end
  end

  defp extract_tokens(response_body) do
    with {:ok, tokens} <- decode_json(response_body),
         true <- is_binary(tokens["id_token"]) do
      {:ok,
       %{
         "id_token" => tokens["id_token"],
         "access_token" => tokens["access_token"],
         "token_type" => tokens["token_type"],
         "expires_in" => tokens["expires_in"]
       }}
    else
      false -> {:error, "OIDC token response did not include an ID token"}
      {:error, _} -> {:error, "Invalid OIDC token response"}
    end
  end

  defp fetch_id_token(tokens) do
    case tokens["id_token"] do
      id_token when is_binary(id_token) and id_token != "" -> {:ok, id_token}
      _ -> {:error, "ID token not provided"}
    end
  end

  defp validate_id_token(id_token, config) when is_binary(id_token) do
    with {:ok, header} <- peek_header(id_token),
         :ok <- validate_algorithm(header["alg"]),
         {:ok, jwks} <- fetch_jwks(config),
         {:ok, claims} <- verify_signature(id_token, header, jwks) do
      {:ok, claims}
    else
      {:error, _} -> {:error, "ID token signature validation failed"}
      _ -> {:error, "ID token signature validation failed"}
    end
  rescue
    _ -> {:error, "ID token signature validation failed"}
  end

  defp peek_header(id_token) do
    case JOSE.JWT.peek_protected(id_token) do
      %JOSE.JWS{} = protected ->
        case JOSE.JWS.to_map(protected) do
          {_key_type, fields} when is_map(fields) -> {:ok, fields}
          fields when is_map(fields) -> {:ok, fields}
          _ -> {:error, "Invalid ID token header"}
        end

      _ ->
        {:error, "Invalid ID token header"}
    end
  end

  defp validate_algorithm(algorithm) when algorithm in @allowed_algorithms, do: :ok
  defp validate_algorithm(_), do: {:error, "Unsupported ID token signing algorithm"}

  defp verify_signature(id_token, header, jwks) when is_list(jwks) do
    matching_keys =
      Enum.filter(jwks, fn key ->
        is_map(key) and key["kty"] == "RSA" and key_matches?(key["kid"], header["kid"])
      end)

    matching_keys
    |> Enum.find_value({:error, "No matching OIDC signing key"}, fn key ->
      verify_with_key(id_token, key)
    end)
  end

  defp verify_signature(_, _, _), do: {:error, "Invalid OIDC JWKS document"}

  defp key_matches?(nil, _), do: false
  defp key_matches?(kid, kid), do: is_binary(kid)
  defp key_matches?(_, _), do: false

  defp verify_with_key(id_token, key) do
    with {:ok, jwk} <- safe_jwk(key),
         {true, %JOSE.JWT{fields: claims}, _jws} <-
           JOSE.JWT.verify_strict(jwk, @allowed_algorithms, id_token) do
      {:ok, claims}
    else
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp safe_jwk(key) do
    {:ok, JOSE.JWK.from_map(key)}
  rescue
    _ -> {:error, "Invalid OIDC signing key"}
  end

  defp validate_claims(claims, config, expected_nonce) when is_map(claims) do
    with :ok <- validate_required_claims(claims),
         :ok <- validate_subject(claims["sub"]),
         :ok <- validate_issuer(claims["iss"], config["issuer"]),
         {:ok, client_id} <- configured(:oidc_client_id),
         :ok <- validate_audience(claims["aud"], claims["azp"], client_id),
         :ok <- validate_nonce(claims["nonce"], expected_nonce),
         :ok <- validate_expiration(claims["exp"]),
         :ok <- validate_issued_at(claims["iat"]) do
      :ok
    end
  end

  defp validate_claims(_, _, _), do: {:error, "Invalid ID token claims"}

  defp validate_required_claims(claims) do
    required = ["iss", "sub", "aud", "exp", "iat", "nonce"]

    if Enum.all?(required, &Map.has_key?(claims, &1)),
      do: :ok,
      else: {:error, "Missing required claims"}
  end

  defp validate_subject(subject) when is_binary(subject) and subject != "", do: :ok
  defp validate_subject(_), do: {:error, "Subject claim missing or invalid"}

  defp validate_issuer(issuer, expected_issuer)
       when is_binary(issuer) and is_binary(expected_issuer) do
    if issuer == expected_issuer, do: :ok, else: {:error, "Invalid issuer"}
  end

  defp validate_issuer(_, _), do: {:error, "Issuer missing or invalid"}

  defp validate_audience(audience, _azp, expected_audience)
       when is_binary(expected_audience) and is_binary(audience) do
    if audience == expected_audience, do: :ok, else: {:error, "Invalid audience"}
  end

  defp validate_audience(audience, azp, expected_audience)
       when is_list(audience) and is_binary(expected_audience) do
    cond do
      expected_audience not in audience -> {:error, "Invalid audience"}
      length(audience) > 1 and azp != expected_audience -> {:error, "Invalid authorized party"}
      true -> :ok
    end
  end

  defp validate_audience(_, _, _), do: {:error, "Audience missing or invalid"}

  defp validate_nonce(nonce, expected_nonce)
       when is_binary(nonce) and is_binary(expected_nonce) do
    if Plug.Crypto.secure_compare(nonce, expected_nonce),
      do: :ok,
      else: {:error, "Nonce mismatch"}
  end

  defp validate_nonce(_, _), do: {:error, "Nonce missing or invalid"}

  defp validate_expiration(exp) when is_integer(exp) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    if exp > now, do: :ok, else: {:error, "Token expired"}
  end

  defp validate_expiration(_), do: {:error, "Expiration claim missing"}

  defp validate_issued_at(iat) when is_integer(iat) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    if iat <= now + 60,
      do: :ok,
      else: {:error, "Token issued in the future"}
  end

  defp validate_issued_at(_), do: {:error, "Issued-at claim missing"}

  defp normalize_claims(claims, config) do
    subject = claims["sub"]
    email = binary_claim(claims["email"])
    name = binary_claim(claims["name"]) || email || subject

    %{
      subject: subject,
      email: email,
      name: name,
      issuer: config["issuer"]
    }
  end

  defp binary_claim(value) when is_binary(value) and value != "", do: value
  defp binary_claim(_), do: nil

  defp configured(key) do
    case Application.get_env(:exocomp_mission_control, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, "OIDC configuration is incomplete"}
    end
  end

  defp optional_config(key) do
    case Application.get_env(:exocomp_mission_control, key) do
      nil -> {:ok, nil}
      value when is_binary(value) -> {:ok, value}
      _ -> {:error, "OIDC configuration is invalid"}
    end
  end

  defp random_string(bytes),
    do: :crypto.strong_rand_bytes(bytes) |> Base.url_encode64(padding: false)

  defp pkce_challenge(verifier),
    do: :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
end
