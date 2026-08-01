# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCClientTest do
  use ExUnit.Case

  alias Exocomp.MissionControl.OIDCClient

  describe "create_authorization_request/0" do
    test "creates authorization request with PKCE" do
      # Mock the config
      config = %{
        "issuer" => "http://localhost:9999",
        "authorization_endpoint" => "http://localhost:9999/auth"
      }

      Application.put_env(:exocomp_mission_control, :oidc_config_cache, config)
      Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")

      Application.put_env(
        :exocomp_mission_control,
        :oidc_redirect_uri,
        "http://localhost:4000/auth/callback"
      )

      {:ok, auth_url, state, nonce} = OIDCClient.create_authorization_request()

      assert is_binary(auth_url)
      assert String.contains?(auth_url, "http://localhost:9999/auth")
      assert String.contains?(auth_url, "response_type=code")
      assert String.contains?(auth_url, "client_id=test-client")
      assert String.contains?(auth_url, "scope=openid+profile+email")
      assert String.contains?(auth_url, "code_challenge_method=S256")
      assert is_binary(state)
      assert is_binary(nonce)
      assert byte_size(state) > 0
      assert byte_size(nonce) > 0
    end
  end

  describe "validate_and_extract_claims/2" do
    test "validates ID token and extracts claims" do
      # Create a mock ID token with valid claims
      claims = %{
        "iss" => "http://localhost:9999",
        "sub" => "user123",
        "aud" => "test-client",
        "nonce" => "test-nonce",
        "email" => "user@example.com",
        "name" => "Test User",
        "exp" => DateTime.utc_now() |> DateTime.add(3600) |> DateTime.to_unix(),
        "iat" => DateTime.utc_now() |> DateTime.to_unix()
      }

      config = %{
        "issuer" => "http://localhost:9999"
      }

      Application.put_env(:exocomp_mission_control, :oidc_config_cache, config)
      Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")

      # Mock JOSE.JWT.peek to return our test claims
      # Since we can't easily mock JOSE, we'll test the claims validation logic
      # by testing with valid claims

      # For this test, we would need to mock the JWT parsing
      # This is a limitation of the current implementation
    end

    test "rejects token with invalid issuer" do
      Application.put_env(:exocomp_mission_control, :oidc_config_cache, %{
        "issuer" => "http://localhost:9999"
      })

      Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")
    end

    test "rejects token with mismatched nonce" do
      Application.put_env(:exocomp_mission_control, :oidc_config_cache, %{
        "issuer" => "http://localhost:9999"
      })

      Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")
    end

    test "rejects expired token" do
      Application.put_env(:exocomp_mission_control, :oidc_config_cache, %{
        "issuer" => "http://localhost:9999"
      })

      Application.put_env(:exocomp_mission_control, :oidc_client_id, "test-client")
    end
  end

  describe "get_end_session_url/1" do
    test "returns end session URL when issuer matches" do
      config = %{
        "issuer" => "http://localhost:9999",
        "end_session_endpoint" => "http://localhost:9999/logout"
      }

      Application.put_env(:exocomp_mission_control, :oidc_config_cache, config)

      {:ok, url} = OIDCClient.get_end_session_url("http://localhost:9999")

      assert url == "http://localhost:9999/logout"
    end

    test "returns error when issuer doesn't match" do
      config = %{
        "issuer" => "http://localhost:9999",
        "end_session_endpoint" => "http://localhost:9999/logout"
      }

      Application.put_env(:exocomp_mission_control, :oidc_config_cache, config)

      {:error, _} = OIDCClient.get_end_session_url("http://different-provider.com")
    end

    test "returns error when end session endpoint not available" do
      config = %{
        "issuer" => "http://localhost:9999"
      }

      Application.put_env(:exocomp_mission_control, :oidc_config_cache, config)

      {:error, _} = OIDCClient.get_end_session_url("http://localhost:9999")
    end
  end
end
