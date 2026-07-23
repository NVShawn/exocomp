defmodule Exocomp.Node.ConfigTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Config

  # Resolve the fixtures directory relative to this source file at compile time.
  # File location: apps/exocomp_node/test/exocomp/node/config_test.exs
  # fixtures/  is two directories up from exocomp/node/
  @fixtures_dir Path.expand("../../fixtures", __DIR__)

  # ── load/1 error cases ──────────────────────────────────────────────────────

  describe "load/1 error cases" do
    test "returns {:error, :enoent} when the config file does not exist" do
      assert {:error, :enoent} = Config.load("/nonexistent/path/no_such_config.json")
    end

    test "returns {:error, {:json_parse, _}} for malformed JSON" do
      path = Path.join(@fixtures_dir, "config_malformed.json")
      assert {:error, {:json_parse, _}} = Config.load(path)
    end

    test "returns {:error, {:unsupported_version, 99}} for an unknown version" do
      path = Path.join(@fixtures_dir, "config_unknown_version.json")
      assert {:error, {:unsupported_version, 99}} = Config.load(path)
    end

    test "returns {:error, {:missing_fields, [...]}} when required fields are absent" do
      path = Path.join(@fixtures_dir, "config_missing_fields.json")
      assert {:error, {:missing_fields, missing}} = Config.load(path)
      # The fixture only has {"version": 1}, so all required top-level fields
      # must be reported as missing.
      assert "node_id" in missing
      assert "tls" in missing
      assert "listen" in missing
    end
  end

  # ── load/1 success ───────────────────────────────────────────────────────────

  describe "load/1 success" do
    test "returns {:ok, %Config{}} with all fields populated for a valid config" do
      path = Path.join(@fixtures_dir, "config_valid.json")
      assert {:ok, %Config{} = cfg} = Config.load(path)

      assert cfg.version == 1
      assert cfg.node_id == "exocomp-test-node"

      assert cfg.tls.ca_cert == "test/fixtures/certs/ca.crt"
      assert cfg.tls.node_cert == "test/fixtures/certs/node.crt"
      assert cfg.tls.node_key == "test/fixtures/certs/node.key"

      assert cfg.listen.host == "127.0.0.1"
      assert cfg.listen.port == 4433
    end
  end

  # ── Environment variable overrides ──────────────────────────────────────────

  describe "environment variable overrides" do
    test "EXOCOMP_NODE_ID overrides node_id from the file" do
      path = Path.join(@fixtures_dir, "config_valid.json")

      System.put_env("EXOCOMP_NODE_ID", "override-node-id")
      on_exit(fn -> System.delete_env("EXOCOMP_NODE_ID") end)

      assert {:ok, %Config{node_id: "override-node-id"}} = Config.load(path)
    end

    test "EXOCOMP_LISTEN_ADDRESS overrides listen.host" do
      path = Path.join(@fixtures_dir, "config_valid.json")

      System.put_env("EXOCOMP_LISTEN_ADDRESS", "0.0.0.0")
      on_exit(fn -> System.delete_env("EXOCOMP_LISTEN_ADDRESS") end)

      assert {:ok, %Config{listen: %Config.Listen{host: "0.0.0.0"}}} = Config.load(path)
    end

    test "EXOCOMP_LISTEN_PORT overrides listen.port as an integer" do
      path = Path.join(@fixtures_dir, "config_valid.json")

      System.put_env("EXOCOMP_LISTEN_PORT", "9999")
      on_exit(fn -> System.delete_env("EXOCOMP_LISTEN_PORT") end)

      assert {:ok, %Config{listen: %Config.Listen{port: 9999}}} = Config.load(path)
    end

    test "EXOCOMP_TLS_KEY_PATH overrides tls.node_key" do
      path = Path.join(@fixtures_dir, "config_valid.json")

      System.put_env("EXOCOMP_TLS_KEY_PATH", "/tmp/override.key")
      on_exit(fn -> System.delete_env("EXOCOMP_TLS_KEY_PATH") end)

      assert {:ok, %Config{tls: %Config.TLS{node_key: "/tmp/override.key"}}} = Config.load(path)
    end
  end

  # ── Secret redaction ─────────────────────────────────────────────────────────

  describe "secret redaction" do
    test "error results do not contain the tls.node_key value" do
      # Construct a config that has a sentinel tls.node_key value but is
      # invalid (missing the required 'listen' section) so that load/1 returns
      # an error.  The error tuple must NOT contain the sentinel value.
      sensitive_key_path = "SENTINEL_PRIVATE_KEY_VALUE_MUST_NOT_APPEAR"

      config_json =
        Jason.encode!(%{
          "version" => 1,
          "node_id" => "redact-test-node",
          "tls" => %{
            "ca_cert" => "ca.crt",
            "node_cert" => "node.crt",
            "node_key" => sensitive_key_path
          }
          # intentionally omitting "listen" to trigger a validation error
        })

      tmp_path = Path.join(System.tmp_dir!(), "redact_test_#{:rand.uniform(999_999)}.json")
      File.write!(tmp_path, config_json)
      on_exit(fn -> File.rm(tmp_path) end)

      result = Config.load(tmp_path)
      result_str = inspect(result)

      refute String.contains?(result_str, sensitive_key_path),
             "Error result must not contain the tls.node_key value, but got: #{result_str}"
    end

    test "Exocomp.Node.Redact.sensitive?/1 identifies tls.node_key as sensitive" do
      assert Exocomp.Node.Redact.sensitive?("tls.node_key")
    end

    test "Exocomp.Node.Redact.redact_value/2 redacts the value for tls.node_key" do
      assert Exocomp.Node.Redact.redact_value("tls.node_key", "/secret/key.pem") ==
               "[REDACTED]"
    end

    test "Exocomp.Node.Redact.redact_value/2 passes through non-sensitive fields" do
      assert Exocomp.Node.Redact.redact_value("node_id", "my-node") == "my-node"
    end
  end
end
