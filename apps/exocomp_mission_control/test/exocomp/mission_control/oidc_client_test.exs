# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCClientTest do
  use ExUnit.Case

  alias Exocomp.MissionControl.FakeOIDCProvider
  alias Exocomp.MissionControl.OIDCClient

  @port 9998
  @provider_url "http://localhost:9998"

  setup do
    {:ok, _port} = FakeOIDCProvider.start_server(@port)
    configure_oidc()
    OIDCClient.clear_cache()

    on_exit(fn ->
      FakeOIDCProvider.stop_server()
      OIDCClient.clear_cache()
    end)

    :ok
  end

  test "creates a PKCE authorization request without shared verifier state" do
    {:ok, auth_url, state, nonce, verifier} = OIDCClient.create_authorization_request()
    query = URI.parse(auth_url).query |> URI.decode_query()

    assert query["response_type"] == "code"
    assert query["client_id"] == "test-client"
    assert query["scope"] == "openid profile email"
    assert query["state"] == state
    assert query["nonce"] == nonce
    assert query["code_challenge_method"] == "S256"
    assert query["code_challenge"] == pkce_challenge(verifier)
    assert Application.get_env(:exocomp_mission_control, :pkce_verifier) == nil
  end

  test "concurrent authorization requests retain independent state and verifiers" do
    requests =
      1..12
      |> Task.async_stream(fn _ -> OIDCClient.create_authorization_request() end,
        max_concurrency: 12,
        ordered: true
      )
      |> Enum.map(fn {:ok, result} -> result end)

    states = Enum.map(requests, &elem(&1, 2))
    verifiers = Enum.map(requests, &elem(&1, 4))

    assert length(Enum.uniq(states)) == length(states)
    assert length(Enum.uniq(verifiers)) == length(verifiers)
    assert Application.get_env(:exocomp_mission_control, :oidc_config_cache) == nil
  end

  test "exchanges the code and verifies the provider signature before returning claims" do
    {:ok, auth_url, _state, nonce, verifier} = OIDCClient.create_authorization_request()
    {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} = HTTPoison.get(auth_url)
    callback_url = header(headers, "location")
    code = URI.parse(callback_url).query |> URI.decode_query() |> Map.fetch!("code")

    assert {:ok, tokens} = OIDCClient.exchange_code_for_token(code, verifier)
    assert {:ok, claims} = OIDCClient.validate_and_extract_claims(tokens, nonce)

    assert claims == %{
             subject: "test-user-123",
             email: "test@example.com",
             name: "Test User",
             issuer: @provider_url
           }
  end

  test "rejects an unsigned or malformed ID token" do
    assert {:error, "ID token signature validation failed"} =
             OIDCClient.validate_and_extract_claims(%{"id_token" => "not-a-jwt"}, "nonce")
  end

  test "rejects a token whose signature was modified" do
    {:ok, auth_url, _state, nonce, verifier} = OIDCClient.create_authorization_request()
    {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} = HTTPoison.get(auth_url)
    callback_url = header(headers, "location")
    code = URI.parse(callback_url).query |> URI.decode_query() |> Map.fetch!("code")
    {:ok, tokens} = OIDCClient.exchange_code_for_token(code, verifier)

    [header_part, payload_part, _signature] = String.split(tokens["id_token"], ".")

    forged_token =
      Enum.join([header_part, payload_part, Base.url_encode64("forged", padding: false)], ".")

    assert {:error, "ID token signature validation failed"} =
             OIDCClient.validate_and_extract_claims(%{"id_token" => forged_token}, nonce)
  end

  test "returns the provider logout endpoint only for the configured issuer" do
    assert {:ok, "#{@provider_url}/logout"} = OIDCClient.get_end_session_url(@provider_url)
    assert {:error, _reason} = OIDCClient.get_end_session_url("https://other.example")
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

  defp header(headers, name) do
    Enum.find_value(headers, fn
      {^name, value} -> value
      {key, value} when is_binary(key) -> if String.downcase(key) == name, do: value
      _ -> nil
    end)
  end

  defp pkce_challenge(verifier),
    do: :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
end
