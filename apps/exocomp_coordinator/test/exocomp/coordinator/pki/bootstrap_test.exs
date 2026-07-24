defmodule Exocomp.Coordinator.PKI.BootstrapTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Exocomp.Coordinator.PKI.Bootstrap

  @passphrase "correct horse battery staple"

  setup do
    base =
      Path.join(
        System.tmp_dir!(),
        "exocomp-pki-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(base)
    File.chmod!(base, 0o700)

    on_exit(fn -> File.rm_rf!(base) end)

    options = [
      online_state: Path.join(base, "online"),
      offline_backup: Path.join(base, "offline"),
      root_key_protection: {:passphrase, @passphrase}
    ]

    %{base: base, options: options}
  end

  test "creates a separated, valid root/intermediate/coordinator chain", %{options: options} do
    assert {:ok, metadata} = Bootstrap.initialize(options)
    assert metadata.online_state == options[:online_state]
    assert metadata.offline_backup == options[:offline_backup]
    assert metadata.root_fingerprint =~ ~r/\A(?:[0-9A-F]{2}:){31}[0-9A-F]{2}\z/

    root = certificate(options[:online_state], "root_ca.pem")
    intermediate = certificate(options[:online_state], "intermediate_ca.pem")
    coordinator = certificate(options[:online_state], "coordinator.pem")

    assert ca?(root)
    assert ca?(intermediate)
    refute ca?(coordinator)

    assert :public_key.pkix_verify(
             X509.Certificate.to_der(root),
             X509.Certificate.public_key(root)
           )

    assert :public_key.pkix_verify(
             X509.Certificate.to_der(intermediate),
             X509.Certificate.public_key(root)
           )

    assert :public_key.pkix_verify(
             X509.Certificate.to_der(coordinator),
             X509.Certificate.public_key(intermediate)
           )
  end

  test "keeps the root private key out of online state and protects its backup", %{
    options: options
  } do
    assert {:ok, _metadata} = Bootstrap.initialize(options)
    refute File.exists?(Path.join(options[:online_state], "root_ca_key.pem"))

    root_key_path = Path.join(options[:offline_backup], "root_ca_key.pem")
    encrypted = File.read!(root_key_path)

    assert encrypted =~ "ENCRYPTED"
    assert {:error, _reason} = X509.PrivateKey.from_pem(encrypted)
    assert {:ok, _root_key} = X509.PrivateKey.from_pem(encrypted, password: @passphrase)
  end

  test "creates a distinct Ed25519 approval-signing key with an explicit role", %{
    options: options
  } do
    assert {:ok, _metadata} = Bootstrap.initialize(options)

    private = approval_key(options[:online_state], "approval_signing.key", "PRIVATE")
    public = approval_key(options[:online_state], "approval_signing.pub", "PUBLIC")
    message = "approval payload"
    signature = :crypto.sign(:eddsa, :none, message, [private, :ed25519])

    assert :crypto.verify(:eddsa, :none, message, signature, [public, :ed25519])

    assert File.read!(Path.join(options[:online_state], "pki.manifest")) =~
             "approval_key_role=action_approval"

    intermediate = certificate(options[:online_state], "intermediate_ca.pem")
    coordinator = certificate(options[:online_state], "coordinator.pem")

    refute public == :erlang.term_to_binary(X509.Certificate.public_key(intermediate))
    refute public == :erlang.term_to_binary(X509.Certificate.public_key(coordinator))
  end

  test "repeat initialization validates and returns stable material", %{options: options} do
    assert {:ok, first} = Bootstrap.initialize(options)
    before = tree_snapshot(options)
    assert {:ok, second} = Bootstrap.initialize(options)

    assert first == second
    assert tree_snapshot(options) == before
  end

  test "uses restrictive directory and private-file modes", %{options: options} do
    assert {:ok, _metadata} = Bootstrap.initialize(options)

    assert mode(options[:online_state]) == 0o700
    assert mode(options[:offline_backup]) == 0o700

    for path <- [
          Path.join(options[:online_state], "intermediate_ca_key.pem"),
          Path.join(options[:online_state], "coordinator_key.pem"),
          Path.join(options[:online_state], "approval_signing.key"),
          Path.join(options[:offline_backup], "root_ca_key.pem")
        ] do
      assert mode(path) == 0o600
    end
  end

  test "fails closed on partial and insecure state without regenerating", %{options: options} do
    assert {:ok, _metadata} = Bootstrap.initialize(options)
    root_before = File.read!(Path.join(options[:online_state], "root_ca.pem"))

    File.rm!(Path.join(options[:online_state], "coordinator.pem"))

    assert {:error, %{code: :invalid_pki_state, message: message}} =
             Bootstrap.initialize(options)

    assert message =~ "missing or unexpected"
    assert File.read!(Path.join(options[:online_state], "root_ca.pem")) == root_before

    File.write!(Path.join(options[:online_state], "coordinator.pem"), "corrupt")
    File.chmod!(Path.join(options[:online_state], "coordinator.pem"), 0o644)
    File.chmod!(Path.join(options[:online_state], "coordinator_key.pem"), 0o644)

    assert {:error, %{code: :invalid_pki_state, message: insecure}} =
             Bootstrap.initialize(options)

    assert insecure =~ "permissions are insecure"
  end

  test "fails closed on corrupt and mismatched cryptographic material", %{options: options} do
    assert {:ok, _metadata} = Bootstrap.initialize(options)
    coordinator_path = Path.join(options[:online_state], "coordinator.pem")
    coordinator_certificate = File.read!(coordinator_path)
    File.write!(coordinator_path, "not a certificate")
    File.chmod!(coordinator_path, 0o644)

    assert {:error, %{code: :invalid_pki_state, message: message}} =
             Bootstrap.initialize(options)

    assert message =~ "certificates are corrupt"

    File.write!(coordinator_path, coordinator_certificate)

    File.write!(
      Path.join(options[:online_state], "coordinator_key.pem"),
      File.read!(Path.join(options[:online_state], "intermediate_ca_key.pem"))
    )

    File.chmod!(Path.join(options[:online_state], "coordinator_key.pem"), 0o600)

    assert {:error, %{code: :invalid_pki_state, message: mismatch}} =
             Bootstrap.initialize(options)

    assert mismatch =~ "does not match"
  end

  test "cleans staging state when initialization cannot complete", %{options: options} do
    unavailable_backup =
      Path.join("/proc", "exocomp-pki-#{System.unique_integer([:positive, :monotonic])}")

    failed_options = Keyword.put(options, :offline_backup, unavailable_backup)

    assert {:error, %{code: :pki_storage_error}} = Bootstrap.initialize(failed_options)
    refute File.exists?(options[:online_state])
    refute File.exists?(unavailable_backup)
    assert [] == Path.wildcard(options[:online_state] <> ".tmp-*")
    assert [] == Path.wildcard(unavailable_backup <> ".tmp-*")
  end

  test "errors and logs redact the root passphrase", %{options: options} do
    assert {:ok, _metadata} = Bootstrap.initialize(options)
    secret = "different secret passphrase"
    wrong_options = Keyword.put(options, :root_key_protection, {:passphrase, secret})

    log =
      capture_log(fn ->
        assert {:error, error} = Bootstrap.initialize(wrong_options)
        refute inspect(error) =~ secret
      end)

    refute log =~ secret
  end

  test "rejects implicit paths, overlapping destinations, weak protection, and invalid calls", %{
    base: base
  } do
    assert {:error, %{code: :invalid_pki_options}} = Bootstrap.initialize(:invalid)

    assert {:error, %{code: :invalid_pki_path}} =
             Bootstrap.initialize(
               online_state: "relative",
               offline_backup: Path.join(base, "offline"),
               root_key_protection: {:passphrase, @passphrase}
             )

    assert {:error, %{code: :invalid_pki_path}} =
             Bootstrap.initialize(
               online_state: base,
               offline_backup: Path.join(base, "nested"),
               root_key_protection: {:passphrase, @passphrase}
             )

    assert {:error, %{code: :invalid_root_key_protection}} =
             Bootstrap.initialize(
               online_state: Path.join(base, "online"),
               offline_backup: Path.join(base, "offline"),
               root_key_protection: {:passphrase, "short"}
             )
  end

  defp certificate(directory, name) do
    directory
    |> Path.join(name)
    |> File.read!()
    |> X509.Certificate.from_pem!()
  end

  defp ca?(certificate) do
    case X509.Certificate.extension(certificate, :basic_constraints) do
      {:Extension, _oid, _critical, {:BasicConstraints, value, _path_length}} -> value
      _other -> false
    end
  end

  defp approval_key(directory, name, kind) do
    contents = File.read!(Path.join(directory, name))
    prefix = "-----BEGIN EXOCOMP ED25519 #{kind} KEY-----\n"
    suffix = "\n-----END EXOCOMP ED25519 #{kind} KEY-----\n"

    contents
    |> String.trim_leading(prefix)
    |> String.trim_trailing(suffix)
    |> Base.decode64!()
  end

  defp mode(path) do
    {:ok, stat} = File.stat(path)
    Bitwise.band(stat.mode, 0o777)
  end

  defp tree_snapshot(options) do
    [options[:online_state], options[:offline_backup]]
    |> Enum.flat_map(fn root ->
      root
      |> File.ls!()
      |> Enum.sort()
      |> Enum.map(fn name ->
        path = Path.join(root, name)
        {path, mode(path), File.read!(path)}
      end)
    end)
  end
end
