# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.RedactionTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Redaction

  doctest Redaction

  describe "redact/1 - exact matches" do
    test "redacts api_key field" do
      result = Redaction.redact(%{"api_key" => "secret123"})
      assert result["api_key"] == "[REDACTED]"
    end

    test "redacts authorization field" do
      result = Redaction.redact(%{"authorization" => "Bearer token123"})
      assert result["authorization"] == "[REDACTED]"
    end

    test "redacts cookie field" do
      result = Redaction.redact(%{"cookie" => "session=xyz"})
      assert result["cookie"] == "[REDACTED]"
    end

    test "redacts credential field" do
      result = Redaction.redact(%{"credential" => "user:pass"})
      assert result["credential"] == "[REDACTED]"
    end

    test "redacts credentials field" do
      result = Redaction.redact(%{"credentials" => "user:pass"})
      assert result["credentials"] == "[REDACTED]"
    end

    test "redacts password field" do
      result = Redaction.redact(%{"password" => "secret123"})
      assert result["password"] == "[REDACTED]"
    end

    test "redacts passwd field" do
      result = Redaction.redact(%{"passwd" => "secret123"})
      assert result["passwd"] == "[REDACTED]"
    end

    test "redacts private_key field" do
      result = Redaction.redact(%{"private_key" => "-----BEGIN RSA PRIVATE KEY-----"})
      assert result["private_key"] == "[REDACTED]"
    end

    test "redacts secret field" do
      result = Redaction.redact(%{"secret" => "mysecret"})
      assert result["secret"] == "[REDACTED]"
    end

    test "redacts token field" do
      result = Redaction.redact(%{"token" => "abc123xyz"})
      assert result["token"] == "[REDACTED]"
    end
  end

  describe "redact/1 - suffix matches" do
    test "redacts fields ending in _api_key" do
      result = Redaction.redact(%{"aws_api_key" => "secret"})
      assert result["aws_api_key"] == "[REDACTED]"
    end

    test "redacts fields ending in _authorization" do
      result = Redaction.redact(%{"oidc_authorization" => "Bearer token"})
      assert result["oidc_authorization"] == "[REDACTED]"
    end

    test "redacts fields ending in _cookie" do
      result = Redaction.redact(%{"session_cookie" => "xyz"})
      assert result["session_cookie"] == "[REDACTED]"
    end

    test "redacts fields ending in _password" do
      result = Redaction.redact(%{"db_password" => "secret123"})
      assert result["db_password"] == "[REDACTED]"
    end

    test "redacts fields ending in _token" do
      result = Redaction.redact(%{"webhook_token" => "abc123"})
      assert result["webhook_token"] == "[REDACTED]"
    end

    test "redacts fields ending in _secret" do
      result = Redaction.redact(%{"webhook_secret" => "signing_key"})
      assert result["webhook_secret"] == "[REDACTED]"
    end

    test "redacts fields ending in _private_key" do
      result = Redaction.redact(%{"tls_private_key" => "-----BEGIN"})
      assert result["tls_private_key"] == "[REDACTED]"
    end

    test "redacts fields ending in _credential" do
      result = Redaction.redact(%{"aws_credential" => "user:pass"})
      assert result["aws_credential"] == "[REDACTED]"
    end

    test "redacts fields ending in _credentials" do
      result = Redaction.redact(%{"github_credentials" => "user:pass"})
      assert result["github_credentials"] == "[REDACTED]"
    end

    test "redacts fields ending in _passwd" do
      result = Redaction.redact(%{"root_passwd" => "secret"})
      assert result["root_passwd"] == "[REDACTED]"
    end
  end

  describe "redact/1 - case insensitivity" do
    test "redacts with uppercase field name" do
      result = Redaction.redact(%{"API_KEY" => "secret"})
      assert result["API_KEY"] == "[REDACTED]"
    end

    test "redacts with uppercase field name and hyphen" do
      result = Redaction.redact(%{"API-KEY" => "secret"})
      assert result["API-KEY"] == "[REDACTED]"
    end

    test "redacts with uppercase PASSWORD" do
      result = Redaction.redact(%{"PASSWORD" => "secret"})
      assert result["PASSWORD"] == "[REDACTED]"
    end
  end

  describe "redact/1 - hyphen underscore normalization" do
    test "treats hyphens as underscores" do
      result = Redaction.redact(%{"api-key" => "secret"})
      assert result["api-key"] == "[REDACTED]"
    end

    test "treats Private-Key like private_key" do
      result = Redaction.redact(%{"Private-Key" => "-----BEGIN"})
      assert result["Private-Key"] == "[REDACTED]"
    end

    test "treats webhook-secret like webhook_secret" do
      result = Redaction.redact(%{"webhook-secret" => "key"})
      assert result["webhook-secret"] == "[REDACTED]"
    end
  end

  describe "redact/1 - non-sensitive fields" do
    test "does not redact regular fields" do
      result = Redaction.redact(%{"username" => "alice", "email" => "alice@example.com"})
      assert result["username"] == "alice"
      assert result["email"] == "alice@example.com"
    end

    test "does not redact id fields" do
      result = Redaction.redact(%{"user_id" => "123", "cluster_id" => "456"})
      assert result["user_id"] == "123"
      assert result["cluster_id"] == "456"
    end

    test "does not redact event_type" do
      result = Redaction.redact(%{"event_type" => "approval.granted"})
      assert result["event_type"] == "approval.granted"
    end
  end

  describe "redact/1 - nested maps" do
    test "redacts sensitive fields in nested maps" do
      input = %{
        "user" => %{
          "name" => "Alice",
          "password" => "secret123"
        }
      }

      result = Redaction.redact(input)
      assert result["user"]["name"] == "Alice"
      assert result["user"]["password"] == "[REDACTED]"
    end

    test "redacts deeply nested sensitive fields" do
      input = %{
        "level1" => %{
          "level2" => %{
            "level3" => %{
              "api_key" => "secret"
            }
          }
        }
      }

      result = Redaction.redact(input)
      assert result["level1"]["level2"]["level3"]["api_key"] == "[REDACTED]"
    end

    test "handles mixed sensitive and non-sensitive in nested maps" do
      input = %{
        "config" => %{
          "username" => "admin",
          "password" => "secret",
          "host" => "localhost"
        }
      }

      result = Redaction.redact(input)
      assert result["config"]["username"] == "admin"
      assert result["config"]["password"] == "[REDACTED]"
      assert result["config"]["host"] == "localhost"
    end
  end

  describe "redact/1 - lists" do
    test "redacts sensitive fields in list items" do
      input = [
        %{"api_key" => "secret1", "name" => "service1"},
        %{"api_key" => "secret2", "name" => "service2"}
      ]

      result = Redaction.redact(input)
      [first, second] = result
      assert first["api_key"] == "[REDACTED]"
      assert first["name"] == "service1"
      assert second["api_key"] == "[REDACTED]"
      assert second["name"] == "service2"
    end

    test "redacts lists of sensitive values" do
      input = %{
        "tokens" => ["token1", "token2"],
        "names" => ["alice", "bob"]
      }

      result = Redaction.redact(input)
      # The list itself isn't a sensitive key, so it's not redacted
      # But verify that lists are handled
      assert is_list(result["tokens"])
      assert is_list(result["names"])
    end
  end

  describe "redact/1 - atoms" do
    test "handles atom values" do
      input = %{
        "status" => :active,
        "password" => :hidden
      }

      result = Redaction.redact(input)
      assert result["status"] == :active
      assert result["password"] == "[REDACTED]"
    end
  end

  describe "redact/1 - struct conversion" do
    test "converts map-like structures to map and redacts" do
      # Test with a map that acts like a struct
      input = %{
        "__struct__" => "TestStruct",
        "username" => "alice",
        "password" => "secret"
      }

      result = Redaction.redact(input)

      assert result["username"] == "alice"
      assert result["password"] == "[REDACTED]"
    end
  end

  describe "redact/1 - primitives" do
    test "returns string as-is" do
      assert Redaction.redact("hello") == "hello"
    end

    test "returns number as-is" do
      assert Redaction.redact(42) == 42
      assert Redaction.redact(3.14) == 3.14
    end

    test "returns boolean as-is" do
      assert Redaction.redact(true) == true
      assert Redaction.redact(false) == false
    end

    test "returns nil as-is" do
      assert Redaction.redact(nil) == nil
    end
  end

  describe "redact/1 - empty structures" do
    test "handles empty map" do
      assert Redaction.redact(%{}) == %{}
    end

    test "handles empty list" do
      assert Redaction.redact([]) == []
    end
  end

  describe "sensitive_key?/1" do
    test "identifies exact sensitive keys" do
      assert Redaction.sensitive_key?("api_key")
      assert Redaction.sensitive_key?("password")
      assert Redaction.sensitive_key?("token")
      assert Redaction.sensitive_key?("secret")
    end

    test "identifies suffix sensitive keys" do
      assert Redaction.sensitive_key?("aws_api_key")
      assert Redaction.sensitive_key?("db_password")
      assert Redaction.sensitive_key?("webhook_token")
    end

    test "handles case insensitivity" do
      assert Redaction.sensitive_key?("API_KEY")
      assert Redaction.sensitive_key?("Password")
      assert Redaction.sensitive_key?("SECRET")
    end

    test "handles hyphen normalization" do
      assert Redaction.sensitive_key?("api-key")
      assert Redaction.sensitive_key?("private-key")
    end

    test "rejects non-sensitive keys" do
      refute Redaction.sensitive_key?("username")
      refute Redaction.sensitive_key?("email")
      refute Redaction.sensitive_key?("user_id")
      refute Redaction.sensitive_key?("cluster_id")
    end

    test "handles atom keys" do
      assert Redaction.sensitive_key?(:api_key)
      assert Redaction.sensitive_key?(:password)
      refute Redaction.sensitive_key?(:username)
    end
  end

  describe "redact/1 - real audit event scenario" do
    test "redacts sensitive data in audit event target and outcome_details" do
      input = %{
        "event_id" => "evt_123",
        "event_type" => "approval.granted",
        "actor_type" => "operator",
        "actor_sub" => "user_id",
        "target" => %{
          "type" => "proposal",
          "id" => "prop_456",
          "sensitive_parameter" => %{
            "private_key" => "-----BEGIN RSA PRIVATE KEY-----",
            "api_key" => "sk_live_secret",
            "username" => "admin"
          }
        },
        "outcome_details" => %{
          "authorization" => "Bearer token123",
          "response_time_ms" => 42,
          "webhook_secret" => "signing_key"
        }
      }

      result = Redaction.redact(input)

      # Public fields preserved
      assert result["event_id"] == "evt_123"
      assert result["event_type"] == "approval.granted"
      assert result["actor_sub"] == "user_id"
      assert result["target"]["type"] == "proposal"
      assert result["target"]["id"] == "prop_456"
      assert result["target"]["sensitive_parameter"]["username"] == "admin"

      # Sensitive fields redacted
      assert result["target"]["sensitive_parameter"]["private_key"] == "[REDACTED]"
      assert result["target"]["sensitive_parameter"]["api_key"] == "[REDACTED]"
      assert result["outcome_details"]["authorization"] == "[REDACTED]"
      assert result["outcome_details"]["webhook_secret"] == "[REDACTED]"

      # Non-sensitive outcome fields preserved
      assert result["outcome_details"]["response_time_ms"] == 42
    end
  end

  describe "redact/1 - immutability" do
    test "does not modify input map" do
      input = %{"password" => "secret", "username" => "alice"}
      original_password = input["password"]

      Redaction.redact(input)

      # Input should be unchanged
      assert input["password"] == original_password
    end
  end
end
