# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCClient do
  @moduledoc """
  OIDC client for handling OpenID Connect Authorization Code flow with PKCE.

  This module handles:
  - Creating authorization requests with PKCE
  - Exchanging authorization codes for tokens
  - Validating ID tokens and extracting claims
  - Retrieving provider configuration
  """

  require Logger

  @doc """
  Creates an authorization request with PKCE parameters.

  Returns {:ok, auth_url, state, nonce} or {:error, reason}
  """
  def create_authorization_request do
    with {:ok, config} <- get_provider_config(),
         state <- generate_random_string(32),
         nonce <- generate_random_string(32),
         {code_challenge, code_verifier} <- generate_pkce_parameters(),
         :ok <- store_code_verifier(code_verifier),
         auth_url <- build_authorization_url(config, state, nonce, code_challenge) do
      {:ok, auth_url, state, nonce}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Exchanges an authorization code for tokens.

  Returns {:ok, tokens} or {:error, reason}
  """
  def exchange_code_for_token(code) do
    with {:ok, config} <- get_provider_config(),
         code_verifier <- retrieve_and_clear_code_verifier(),
         {:ok, token_response} <-
           request_tokens(config, code, code_verifier),
         tokens <- extract_tokens(token_response) do
      {:ok, tokens}
    else
      error -> error
    end
  end

  @doc """
  Validates an ID token and extracts claims.

  Returns {:ok, claims} or {:error, reason}
  """
  def validate_and_extract_claims(tokens, expected_nonce) do
    with {:ok, config} <- get_provider_config(),
         {:ok, claims} <- validate_id_token(tokens["id_token"], config),
         :ok <- validate_claims(claims, config, expected_nonce) do
      {:ok, normalize_claims(claims, config)}
    else
      error -> error
    end
  end

  @doc """
  Gets the end session URL from the OIDC provider.
  """
  def get_end_session_url(issuer) when is_binary(issuer) do
    with {:ok, config} <- get_provider_config(),
         ^issuer <- config["issuer"] do
      case config["end_session_endpoint"] do
        url when is_binary(url) -> {:ok, url}
        _ -> {:error, "End session endpoint not available"}
      end
    else
      _ -> {:error, "Issuer mismatch or config unavailable"}
    end
  end

  def get_end_session_url(_), do: {:error, "Invalid issuer"}

  # Private functions

  defp get_provider_config do
    Application.fetch_env(:exocomp_mission_control, :oidc_provider_url)
    |> case do
      {:ok, provider_url} ->
        config_url =
          String.trim_trailing(provider_url, "/") <> "/.well-known/openid-configuration"

        fetch_and_cache_config(config_url)

      :error ->
        {:error, "OIDC provider URL not configured"}
    end
  end

  defp fetch_and_cache_config(config_url) do
    case Application.get_env(:exocomp_mission_control, :oidc_config_cache) do
      config when is_map(config) ->
        expires_at = Map.get(config, "expires_at")

        if expires_at && expires_at > DateTime.utc_now() do
          {:ok, config}
        else
          fetch_and_cache_from_url(config_url)
        end

      _ ->
        fetch_and_cache_from_url(config_url)
    end
  end

  defp fetch_and_cache_from_url(config_url) do
    case fetch_url(config_url) do
      {:ok, body} ->
        config = Jason.decode!(body)
        cached_config = Map.put(config, "expires_at", DateTime.add(DateTime.utc_now(), 3600))
        Application.put_env(:exocomp_mission_control, :oidc_config_cache, cached_config)
        {:ok, config}

      error ->
        error
    end
  end

  defp fetch_url(url) do
    case HTTPoison.get(url, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.error("HTTP error fetching #{url}: status #{status}")
        {:error, "HTTP error: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp generate_random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp generate_pkce_parameters do
    code_verifier =
      43
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    code_challenge =
      code_verifier
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.url_encode64(padding: false)

    {code_challenge, code_verifier}
  end

  defp store_code_verifier(code_verifier) do
    # In production, this should be stored securely (e.g., in a temporary store with TTL)
    # For now, we store it in the process state
    Application.put_env(:exocomp_mission_control, :pkce_verifier, code_verifier)
    :ok
  end

  defp retrieve_and_clear_code_verifier do
    verifier = Application.get_env(:exocomp_mission_control, :pkce_verifier)
    Application.delete_env(:exocomp_mission_control, :pkce_verifier)
    verifier
  end

  defp build_authorization_url(config, state, nonce, code_challenge) do
    base_url = config["authorization_endpoint"]
    client_id = Application.get_env(:exocomp_mission_control, :oidc_client_id)
    redirect_uri = Application.get_env(:exocomp_mission_control, :oidc_redirect_uri)

    query_params = [
      {"client_id", client_id},
      {"redirect_uri", redirect_uri},
      {"response_type", "code"},
      {"scope", "openid profile email"},
      {"state", state},
      {"nonce", nonce},
      {"code_challenge", code_challenge},
      {"code_challenge_method", "S256"}
    ]

    query_string = URI.encode_query(query_params)
    "#{base_url}?#{query_string}"
  end

  defp request_tokens(config, code, code_verifier) do
    token_endpoint = config["token_endpoint"]
    client_id = Application.get_env(:exocomp_mission_control, :oidc_client_id)
    client_secret = Application.get_env(:exocomp_mission_control, :oidc_client_secret)
    redirect_uri = Application.get_env(:exocomp_mission_control, :oidc_redirect_uri)

    body =
      URI.encode_query([
        {"grant_type", "authorization_code"},
        {"code", code},
        {"client_id", client_id},
        {"client_secret", client_secret},
        {"redirect_uri", redirect_uri},
        {"code_verifier", code_verifier}
      ])

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    case HTTPoison.post(token_endpoint, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, response_body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.error("Token endpoint error: status #{status}")
        {:error, "Token endpoint returned status #{status}"}

      {:error, reason} ->
        Logger.error("Token request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp extract_tokens(response_body) do
    case Jason.decode(response_body) do
      {:ok, data} ->
        %{
          "access_token" => Map.get(data, "access_token"),
          "id_token" => Map.get(data, "id_token"),
          "token_type" => Map.get(data, "token_type", "Bearer"),
          "expires_in" => Map.get(data, "expires_in")
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_id_token(id_token, _config) when is_binary(id_token) do
    try do
      # JOSE.JWT.peek returns a %JOSE.JWT{} struct or a list
      # We use as_map/1 to convert the struct to a map to avoid type warnings
      jwt_struct = JOSE.JWT.peek(id_token)
      jwt_map = struct_to_map(jwt_struct)

      case jwt_map do
        %{"payload" => payload} ->
          {:ok, payload}

        _ ->
          Logger.error("Failed to parse JWT")
          {:error, "Invalid ID token"}
      end
    rescue
      error ->
        Logger.error("Error validating ID token: #{inspect(error)}")
        {:error, "ID token validation failed"}
    end
  end

  defp validate_id_token(_, _) do
    {:error, "ID token not provided"}
  end

  defp struct_to_map(struct) when is_struct(struct) do
    Map.from_struct(struct)
  end

  defp struct_to_map(other), do: other

  defp validate_claims(claims, config, expected_nonce) do
    with :ok <- validate_required_claims(claims),
         :ok <- validate_issuer(claims["iss"], config["issuer"]),
         :ok <-
           validate_audience(
             claims["aud"],
             Application.get_env(:exocomp_mission_control, :oidc_client_id)
           ),
         :ok <- validate_nonce(claims["nonce"], expected_nonce),
         :ok <- validate_expiration(claims["exp"]) do
      :ok
    else
      error -> error
    end
  end

  defp validate_required_claims(claims) do
    required = ["iss", "sub", "aud", "exp", "iat"]

    case Enum.all?(required, &Map.has_key?(claims, &1)) do
      true -> :ok
      false -> {:error, "Missing required claims"}
    end
  end

  defp validate_issuer(issuer, expected_issuer)
       when is_binary(issuer) and is_binary(expected_issuer) do
    case issuer == expected_issuer do
      true -> :ok
      false -> {:error, "Invalid issuer"}
    end
  end

  defp validate_issuer(_, _) do
    {:error, "Issuer missing or invalid"}
  end

  defp validate_audience(audience, expected_audience)
       when is_binary(audience) and is_binary(expected_audience) do
    case audience == expected_audience do
      true -> :ok
      false -> {:error, "Invalid audience"}
    end
  end

  defp validate_audience(audience, expected_audience)
       when is_list(audience) and is_binary(expected_audience) do
    case Enum.member?(audience, expected_audience) do
      true -> :ok
      false -> {:error, "Client ID not in audience"}
    end
  end

  defp validate_audience(_, _) do
    {:error, "Audience missing or invalid"}
  end

  defp validate_nonce(nonce, expected_nonce)
       when is_binary(nonce) and is_binary(expected_nonce) do
    case Plug.Crypto.secure_compare(nonce, expected_nonce) do
      true -> :ok
      false -> {:error, "Nonce mismatch"}
    end
  end

  defp validate_nonce(_, _) do
    {:error, "Nonce missing or invalid"}
  end

  defp validate_expiration(exp) when is_integer(exp) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    case exp > now do
      true -> :ok
      false -> {:error, "Token expired"}
    end
  end

  defp validate_expiration(_) do
    {:error, "Expiration claim missing"}
  end

  defp normalize_claims(claims, config) do
    %{
      subject: Map.get(claims, "sub"),
      email: Map.get(claims, "email"),
      name: Map.get(claims, "name", Map.get(claims, "email")),
      issuer: config["issuer"]
    }
  end
end
