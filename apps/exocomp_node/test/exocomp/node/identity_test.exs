defmodule Exocomp.Node.IdentityTest do
  use ExUnit.Case, async: false

  alias Exocomp.Node.Config
  alias Exocomp.Node.Identity

  # Resolve the fixtures directory at compile time.
  # File: apps/exocomp_node/test/exocomp/node/identity_test.exs
  # fixtures/ is two directories up from exocomp/node/
  @fixtures_dir Path.expand("../../fixtures", __DIR__)
  @certs_dir Path.join(@fixtures_dir, "certs")

  # ── Helpers ──────────────────────────────────────────────────────────────────

  # Build a Config struct pointing to specific certs.
  defp make_config(opts) do
    node_cert = Keyword.get(opts, :cert, Path.join(@certs_dir, "node.crt"))
    node_key = Keyword.get(opts, :key, Path.join(@certs_dir, "node.key"))
    ca_cert = Keyword.get(opts, :ca, Path.join(@certs_dir, "ca.crt"))
    node_id = Keyword.get(opts, :node_id, "exocomp-test-node")

    %Config{
      version: 1,
      node_id: node_id,
      tls: %Config.TLS{
        ca_cert: ca_cert,
        node_cert: node_cert,
        node_key: node_key
      },
      listen: %Config.Listen{host: "127.0.0.1", port: 4433}
    }
  end

  # Copy a key to a temp file with the given mode so we can test permission checks
  # without permanently mutating the committed fixture file.
  defp tmp_key_with_mode(source_path, mode) do
    tmp = Path.join(System.tmp_dir!(), "identity_test_key_#{:rand.uniform(999_999)}.key")
    File.cp!(source_path, tmp)
    File.chmod!(tmp, mode)
    tmp
  end

  # ── Key permission tests ──────────────────────────────────────────────────────

  describe "key file permissions" do
    test "group-readable key (0o640) returns {:error, :key_not_secure}" do
      key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o640)
      on_exit(fn -> File.rm(key) end)

      config = make_config(key: key)
      assert {:error, :key_not_secure} = Identity.validate(config)
    end

    test "world-readable key (0o644) returns {:error, :key_not_secure}" do
      key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o644)
      on_exit(fn -> File.rm(key) end)

      config = make_config(key: key)
      assert {:error, :key_not_secure} = Identity.validate(config)
    end

    test "group-writable key (0o660) returns {:error, :key_not_secure}" do
      key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o660)
      on_exit(fn -> File.rm(key) end)

      config = make_config(key: key)
      assert {:error, :key_not_secure} = Identity.validate(config)
    end

    test "key with mode 0o600 proceeds beyond the permission check" do
      key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o600)
      on_exit(fn -> File.rm(key) end)

      config = make_config(key: key)
      # Result must NOT be {:error, :key_not_secure}; chain/SAN checks run next.
      result = Identity.validate(config)
      refute result == {:error, :key_not_secure}
    end
  end

  # ── Chain validation tests ────────────────────────────────────────────────────

  describe "certificate chain validation" do
    setup do
      # Use a secure key for all chain/SAN tests.
      key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o600)
      on_exit(fn -> File.rm(key) end)
      {:ok, secure_key: key}
    end

    test "cert signed by rogue CA returns {:error, {:invalid_chain, _}}", %{
      secure_key: _key
    } do
      # The rogue CA has its own key. Use rogue key with rogue cert.
      rogue_key = tmp_key_with_mode(Path.join(@certs_dir, "rogue.key"), 0o600)
      on_exit(fn -> File.rm(rogue_key) end)

      config =
        make_config(
          cert: Path.join(@certs_dir, "rogue.crt"),
          key: rogue_key,
          ca: Path.join(@certs_dir, "ca.crt")
        )

      assert {:error, {:invalid_chain, _}} = Identity.validate(config)
    end

    test "expired cert returns {:error, {:invalid_chain, _}}", %{secure_key: _key} do
      expired_key = tmp_key_with_mode(Path.join(@certs_dir, "expired.key"), 0o600)
      on_exit(fn -> File.rm(expired_key) end)

      config =
        make_config(
          cert: Path.join(@certs_dir, "expired.crt"),
          key: expired_key,
          ca: Path.join(@certs_dir, "ca.crt")
        )

      assert {:error, {:invalid_chain, _}} = Identity.validate(config)
    end
  end

  # ── SAN mismatch tests ────────────────────────────────────────────────────────

  describe "SAN match" do
    setup do
      key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o600)
      on_exit(fn -> File.rm(key) end)
      {:ok, secure_key: key}
    end

    test "cert with wrong SAN returns {:error, {:san_mismatch, _}}", %{secure_key: _key} do
      wrong_key = tmp_key_with_mode(Path.join(@certs_dir, "wrong_san.key"), 0o600)
      on_exit(fn -> File.rm(wrong_key) end)

      config =
        make_config(
          cert: Path.join(@certs_dir, "wrong_san.crt"),
          key: wrong_key,
          ca: Path.join(@certs_dir, "ca.crt"),
          node_id: "exocomp-test-node"
        )

      assert {:error, {:san_mismatch, expected: "exocomp-test-node"}} =
               Identity.validate(config)
    end

    test "valid cert chain + SAN match + secure key returns :ok", %{secure_key: key} do
      config =
        make_config(
          cert: Path.join(@certs_dir, "node.crt"),
          key: key,
          ca: Path.join(@certs_dir, "ca.crt"),
          node_id: "exocomp-test-node"
        )

      assert :ok = Identity.validate(config)
    end
  end

  # ── Secret redaction ──────────────────────────────────────────────────────────

  describe "secret redaction" do
    test "error messages do not contain the key file path" do
      # Use a world-readable key to trigger :key_not_secure without looking at
      # the actual path value.
      sentinel_path = "/secret/sentinel-key-#{:rand.uniform(999_999)}.pem"
      tmp = Path.join(System.tmp_dir!(), Path.basename(sentinel_path))
      # Create a file at the sentinel-named path so stat works.
      File.write!(tmp, "fake key")
      File.chmod!(tmp, 0o644)
      on_exit(fn -> File.rm(tmp) end)

      config = make_config(key: tmp)
      result = Identity.validate(config)
      result_str = inspect(result)

      refute String.contains?(result_str, tmp),
             "Error result must not contain the key file path, got: #{result_str}"
    end
  end
end
