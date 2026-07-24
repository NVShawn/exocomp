defmodule Exocomp.Coordinator.PKI.Bootstrap do
  @moduledoc """
  Creates and validates the coordinator's separated online and offline PKI state.

  The root-key protection value is accepted only as `{:passphrase, value}` so it
  is not accidentally mixed into application configuration or logged metadata.
  """

  alias Exocomp.Coordinator.Error

  @manifest "pki.manifest"
  @online_files %{
    "root_ca.pem" => 0o644,
    "intermediate_ca.pem" => 0o644,
    "intermediate_ca_key.pem" => 0o600,
    "coordinator.pem" => 0o644,
    "coordinator_key.pem" => 0o600,
    "approval_signing.key" => 0o600,
    "approval_signing.pub" => 0o644,
    @manifest => 0o600
  }
  @backup_files %{"root_ca.pem" => 0o644, "root_ca_key.pem" => 0o600, @manifest => 0o600}

  @type metadata :: %{
          online_state: String.t(),
          offline_backup: String.t(),
          root_fingerprint: String.t()
        }

  @spec initialize(keyword()) :: {:ok, metadata()} | {:error, Error.t()}
  def initialize(options) when is_list(options) do
    with {:ok, online, backup, passphrase} <- validate_options(options),
         {:ok, disposition} <- disposition(online, backup) do
      case disposition do
        :new -> create(online, backup, passphrase)
        :existing -> validate_existing(online, backup, passphrase)
      end
    end
  rescue
    _exception ->
      {:error,
       Error.new(
         :pki_operation_failed,
         "PKI initialization failed; no secret details were retained"
       )}
  catch
    _kind, _reason ->
      {:error,
       Error.new(
         :pki_operation_failed,
         "PKI initialization failed; no secret details were retained"
       )}
  end

  def initialize(_options) do
    {:error, Error.new(:invalid_pki_options, "PKI initialization options must be a keyword list")}
  end

  defp validate_options(options) do
    online = Keyword.get(options, :online_state)
    backup = Keyword.get(options, :offline_backup)
    protection = Keyword.get(options, :root_key_protection)

    with :ok <- absolute_path(online, "online_state"),
         :ok <- absolute_path(backup, "offline_backup"),
         :ok <- distinct_paths(online, backup),
         {:ok, passphrase} <- protection_input(protection) do
      {:ok, Path.expand(online), Path.expand(backup), passphrase}
    end
  end

  defp absolute_path(path, _name) when is_binary(path) and byte_size(path) > 0 do
    if Path.type(path) == :absolute do
      :ok
    else
      {:error, Error.new(:invalid_pki_path, "PKI destinations must be explicit absolute paths")}
    end
  end

  defp absolute_path(_path, _name) do
    {:error, Error.new(:invalid_pki_path, "PKI destinations must be non-empty absolute paths")}
  end

  defp distinct_paths(first, second) do
    first = Path.expand(first)
    second = Path.expand(second)
    separator = "/"

    if first == second or String.starts_with?(first <> separator, second <> separator) or
         String.starts_with?(second <> separator, first <> separator) do
      {:error,
       Error.new(
         :invalid_pki_path,
         "Online state and offline backup destinations must be separate paths"
       )}
    else
      :ok
    end
  end

  defp protection_input({:passphrase, passphrase})
       when is_binary(passphrase) and byte_size(passphrase) >= 16 do
    {:ok, passphrase}
  end

  defp protection_input(_input) do
    {:error,
     Error.new(
       :invalid_root_key_protection,
       "Root-key protection must be a passphrase of at least 16 bytes"
     )}
  end

  defp disposition(online, backup) do
    case {File.exists?(online), File.exists?(backup)} do
      {false, false} -> {:ok, :new}
      {true, true} -> {:ok, :existing}
      _ -> invalid_state("Online and offline PKI state must either both exist or both be absent")
    end
  end

  defp create(online, backup, passphrase) do
    online_stage = stage_path(online)
    backup_stage = stage_path(backup)

    try do
      with :ok <- ensure_parent(online),
           :ok <- ensure_parent(backup),
           :ok <- mkdir_private(online_stage),
           :ok <- mkdir_private(backup_stage),
           {:ok, material} <- generate_material(passphrase),
           :ok <- write_new_state(online_stage, backup_stage, online, backup, material),
           :ok <- install_staged(online_stage, backup_stage, online, backup) do
        metadata(online, backup, material.fingerprint)
      end
    after
      File.rm_rf(online_stage)
      File.rm_rf(backup_stage)
    end
  end

  defp stage_path(destination) do
    destination <> ".tmp-" <> Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
  end

  defp ensure_parent(destination) do
    parent = Path.dirname(destination)

    case File.stat(parent) do
      {:ok, %{type: :directory}} -> :ok
      {:ok, _stat} -> invalid_state("A PKI destination parent is not a directory")
      {:error, reason} -> io_error("access PKI destination parent", reason)
    end
  end

  defp mkdir_private(path) do
    with :ok <- File.mkdir(path),
         :ok <- File.chmod(path, 0o700) do
      :ok
    else
      {:error, reason} -> io_error("create protected PKI staging directory", reason)
    end
  end

  defp generate_material(passphrase) do
    root_key = X509.PrivateKey.new_ec(:secp384r1)

    root_cert =
      X509.Certificate.self_signed(root_key, "/O=Exocomp/CN=Exocomp Root CA",
        template: :root_ca,
        validity: 7_305
      )

    intermediate_key = X509.PrivateKey.new_ec(:secp384r1)

    intermediate_cert =
      intermediate_key
      |> X509.PublicKey.derive()
      |> X509.Certificate.new(
        "/O=Exocomp/CN=Exocomp Coordinator Intermediate CA",
        root_cert,
        root_key,
        template: :ca,
        validity: 1_825
      )

    coordinator_key = X509.PrivateKey.new_ec(:secp256r1)

    coordinator_cert =
      coordinator_key
      |> X509.PublicKey.derive()
      |> X509.Certificate.new(
        "/O=Exocomp/CN=exocomp-coordinator",
        intermediate_cert,
        intermediate_key,
        template: :server,
        validity: 30,
        extensions: [
          subject_alt_name: X509.Certificate.Extension.subject_alt_name(["exocomp-coordinator"])
        ]
      )

    {approval_public, approval_private} = :crypto.generate_key(:eddsa, :ed25519)
    fingerprint = fingerprint(root_cert)

    {:ok,
     %{
       root_cert: X509.Certificate.to_pem(root_cert),
       protected_root_key: X509.PrivateKey.to_pem(root_key, password: passphrase),
       intermediate_cert: X509.Certificate.to_pem(intermediate_cert),
       intermediate_key: X509.PrivateKey.to_pem(intermediate_key),
       coordinator_cert: X509.Certificate.to_pem(coordinator_cert),
       coordinator_key: X509.PrivateKey.to_pem(coordinator_key),
       approval_private: encode_approval("PRIVATE", approval_private),
       approval_public: encode_approval("PUBLIC", approval_public),
       fingerprint: fingerprint
     }}
  end

  defp write_new_state(online_stage, backup_stage, online, backup, material) do
    manifest = manifest(online, backup, material.fingerprint)

    online_files = %{
      "root_ca.pem" => material.root_cert,
      "intermediate_ca.pem" => material.intermediate_cert,
      "intermediate_ca_key.pem" => material.intermediate_key,
      "coordinator.pem" => material.coordinator_cert,
      "coordinator_key.pem" => material.coordinator_key,
      "approval_signing.key" => material.approval_private,
      "approval_signing.pub" => material.approval_public,
      @manifest => manifest
    }

    backup_files = %{
      "root_ca.pem" => material.root_cert,
      "root_ca_key.pem" => material.protected_root_key,
      @manifest => manifest
    }

    with :ok <- write_files(online_stage, online_files, @online_files),
         :ok <- write_files(backup_stage, backup_files, @backup_files) do
      :ok
    end
  end

  defp write_files(directory, files, modes) do
    Enum.reduce_while(files, :ok, fn {name, contents}, :ok ->
      path = Path.join(directory, name)

      result =
        with :ok <- File.write(path, contents, [:binary, :exclusive]),
             :ok <- File.chmod(path, Map.fetch!(modes, name)) do
          :ok
        else
          {:error, reason} -> io_error("write protected PKI state", reason)
        end

      if result == :ok, do: {:cont, :ok}, else: {:halt, result}
    end)
  end

  defp install_staged(online_stage, backup_stage, online, backup) do
    case File.rename(online_stage, online) do
      :ok ->
        case File.rename(backup_stage, backup) do
          :ok ->
            :ok

          {:error, reason} ->
            File.rm_rf(online)
            io_error("install offline PKI backup", reason)
        end

      {:error, reason} ->
        io_error("install online PKI state", reason)
    end
  end

  defp validate_existing(online, backup, passphrase) do
    with :ok <- validate_tree(online, @online_files),
         :ok <- validate_tree(backup, @backup_files),
         {:ok, online_manifest} <- read_manifest(online),
         {:ok, backup_manifest} <- read_manifest(backup),
         :ok <- validate_manifests(online_manifest, backup_manifest, online, backup),
         {:ok, certificates} <- read_certificates(online, backup),
         {:ok, keys} <- read_keys(online, backup, passphrase),
         :ok <- validate_certificates(certificates, keys),
         :ok <- validate_approval_key(online),
         fingerprint = fingerprint(certificates.root),
         :ok <- validate_fingerprint(online_manifest, fingerprint) do
      metadata(online, backup, fingerprint)
    end
  end

  defp validate_tree(directory, expected_files) do
    with {:ok, %{type: :directory, mode: mode}} <- File.lstat(directory),
         :ok <- require_mode(mode, 0o700, "PKI directory"),
         {:ok, entries} <- File.ls(directory),
         :ok <- require_entries(entries, Map.keys(expected_files)) do
      Enum.reduce_while(expected_files, :ok, fn {name, expected_mode}, :ok ->
        case File.lstat(Path.join(directory, name)) do
          {:ok, %{type: :regular, mode: mode}} ->
            case require_mode(mode, expected_mode, "PKI file") do
              :ok -> {:cont, :ok}
              error -> {:halt, error}
            end

          {:ok, _stat} ->
            {:halt, invalid_state("PKI state contains a non-regular file")}

          {:error, _reason} ->
            {:halt, invalid_state("PKI state is incomplete")}
        end
      end)
    else
      {:error, %Error{} = error} -> {:error, error}
      {:ok, _stat} -> invalid_state("PKI destination is not a directory")
      {:error, _reason} -> invalid_state("PKI state cannot be inspected")
    end
  end

  defp require_mode(mode, expected, kind) do
    if Bitwise.band(mode, 0o777) == expected do
      :ok
    else
      invalid_state(
        "#{kind} permissions are insecure; expected #{Integer.to_string(expected, 8)}"
      )
    end
  end

  defp require_entries(actual, expected) do
    if Enum.sort(actual) == Enum.sort(expected) do
      :ok
    else
      invalid_state("PKI state has missing or unexpected material")
    end
  end

  defp read_manifest(directory) do
    with {:ok, contents} <- File.read(Path.join(directory, @manifest)),
         {:ok, fields} <- parse_manifest(contents) do
      {:ok, fields}
    else
      _error -> invalid_state("PKI manifest is missing or corrupt")
    end
  end

  defp parse_manifest(contents) do
    fields =
      contents
      |> String.split("\n", trim: true)
      |> Enum.map(&String.split(&1, "=", parts: 2))

    case fields do
      [
        ["version", "1"],
        ["online", online],
        ["backup", backup],
        ["fingerprint", fingerprint],
        ["approval_key_role", "action_approval"]
      ] ->
        with {:ok, online} <- Base.url_decode64(online, padding: false),
             {:ok, backup} <- Base.url_decode64(backup, padding: false),
             true <- valid_fingerprint?(fingerprint) do
          {:ok, %{online: online, backup: backup, fingerprint: fingerprint}}
        else
          _failure -> {:error, :malformed}
        end

      _other ->
        {:error, :malformed}
    end
  end

  defp validate_manifests(first, second, online, backup) do
    if first == second and first.online == online and first.backup == backup do
      :ok
    else
      invalid_state("PKI manifests do not match the requested destinations")
    end
  end

  defp read_certificates(online, backup) do
    with {:ok, root} <- read_certificate(Path.join(online, "root_ca.pem")),
         {:ok, backup_root} <- read_certificate(Path.join(backup, "root_ca.pem")),
         true <- X509.Certificate.to_der(root) == X509.Certificate.to_der(backup_root),
         {:ok, intermediate} <- read_certificate(Path.join(online, "intermediate_ca.pem")),
         {:ok, coordinator} <- read_certificate(Path.join(online, "coordinator.pem")) do
      {:ok, %{root: root, intermediate: intermediate, coordinator: coordinator}}
    else
      _failure -> invalid_state("PKI certificates are corrupt or inconsistent")
    end
  end

  defp read_certificate(path) do
    with {:ok, pem} <- File.read(path),
         {:ok, certificate} <- X509.Certificate.from_pem(pem) do
      {:ok, certificate}
    end
  end

  defp read_keys(online, backup, passphrase) do
    with {:ok, intermediate} <-
           read_private_key(Path.join(online, "intermediate_ca_key.pem"), []),
         {:ok, coordinator} <- read_private_key(Path.join(online, "coordinator_key.pem"), []),
         {:ok, root} <-
           read_private_key(Path.join(backup, "root_ca_key.pem"), password: passphrase) do
      {:ok, %{root: root, intermediate: intermediate, coordinator: coordinator}}
    else
      _failure ->
        invalid_state("PKI private material is corrupt, mismatched, or cannot be unlocked")
    end
  end

  defp read_private_key(path, options) do
    with {:ok, pem} <- File.read(path),
         {:ok, key} <- X509.PrivateKey.from_pem(pem, options) do
      {:ok, key}
    end
  end

  defp validate_certificates(certificates, keys) do
    with :ok <- key_matches(certificates.root, keys.root, "root"),
         :ok <- key_matches(certificates.intermediate, keys.intermediate, "intermediate"),
         :ok <- key_matches(certificates.coordinator, keys.coordinator, "coordinator"),
         :ok <- require_ca(certificates.root, true, "root"),
         :ok <- require_ca(certificates.intermediate, true, "intermediate"),
         :ok <- require_ca(certificates.coordinator, false, "coordinator"),
         :ok <- require_key_usage(certificates.root, :keyCertSign, "root"),
         :ok <- require_key_usage(certificates.intermediate, :keyCertSign, "intermediate"),
         :ok <- require_key_usage(certificates.coordinator, :digitalSignature, "coordinator"),
         :ok <- verify_signature(certificates.root, certificates.root, "root"),
         :ok <- validate_path(certificates) do
      :ok
    end
  end

  defp key_matches(certificate, key, role) do
    if X509.Certificate.public_key(certificate) == X509.PublicKey.derive(key) do
      :ok
    else
      invalid_state("The #{role} private key does not match its certificate")
    end
  end

  defp require_ca(certificate, expected, role) do
    ca? =
      case X509.Certificate.extension(certificate, :basic_constraints) do
        {:Extension, _oid, _critical, {:BasicConstraints, value, _path_length}} -> value
        _other -> false
      end

    if ca? == expected do
      :ok
    else
      invalid_state("The #{role} certificate has an invalid CA role")
    end
  end

  defp require_key_usage(certificate, expected, role) do
    usages =
      case X509.Certificate.extension(certificate, :key_usage) do
        {:Extension, _oid, true, values} when is_list(values) -> values
        _other -> []
      end

    if expected in usages do
      :ok
    else
      invalid_state("The #{role} certificate has an invalid key usage")
    end
  end

  defp verify_signature(certificate, issuer, role) do
    valid? =
      certificate
      |> X509.Certificate.to_der()
      |> :public_key.pkix_verify(X509.Certificate.public_key(issuer))

    if valid?, do: :ok, else: invalid_state("The #{role} certificate signature is invalid")
  end

  defp validate_path(certificates) do
    root = X509.Certificate.to_der(certificates.root)

    chain = [
      X509.Certificate.to_der(certificates.intermediate),
      X509.Certificate.to_der(certificates.coordinator)
    ]

    case :public_key.pkix_path_validation(root, chain, max_path_length: 1) do
      {:ok, _validation} -> :ok
      {:error, _reason} -> invalid_state("The coordinator certificate chain is invalid")
    end
  end

  defp validate_approval_key(online) do
    with {:ok, private} <- read_approval(Path.join(online, "approval_signing.key"), "PRIVATE", 32),
         {:ok, public} <- read_approval(Path.join(online, "approval_signing.pub"), "PUBLIC", 32),
         derived <- derive_approval_public(private),
         true <- derived == public,
         signature <-
           :crypto.sign(:eddsa, :none, "exocomp-approval-key-check", [private, :ed25519]),
         true <-
           :crypto.verify(
             :eddsa,
             :none,
             "exocomp-approval-key-check",
             signature,
             [public, :ed25519]
           ) do
      :ok
    else
      _failure -> invalid_state("The approval-signing key is corrupt or mismatched")
    end
  end

  defp derive_approval_public(private) do
    case :crypto.generate_key(:eddsa, :ed25519, private) do
      {public, _private} -> public
      public when is_binary(public) -> public
    end
  end

  defp encode_approval(kind, key) do
    "-----BEGIN EXOCOMP ED25519 #{kind} KEY-----\n" <>
      Base.encode64(key) <>
      "\n-----END EXOCOMP ED25519 #{kind} KEY-----\n"
  end

  defp read_approval(path, kind, length) do
    with {:ok, contents} <- File.read(path),
         prefix = "-----BEGIN EXOCOMP ED25519 #{kind} KEY-----\n",
         suffix = "\n-----END EXOCOMP ED25519 #{kind} KEY-----\n",
         true <- String.starts_with?(contents, prefix),
         true <- String.ends_with?(contents, suffix),
         encoded <- contents |> String.trim_leading(prefix) |> String.trim_trailing(suffix),
         {:ok, key} <- Base.decode64(encoded),
         true <- byte_size(key) == length do
      {:ok, key}
    else
      _failure -> {:error, :malformed}
    end
  end

  defp fingerprint(certificate) do
    digest = :crypto.hash(:sha256, X509.Certificate.to_der(certificate))

    digest
    |> Base.encode16()
    |> String.graphemes()
    |> Enum.chunk_every(2)
    |> Enum.map_join(":", &Enum.join/1)
  end

  defp valid_fingerprint?(fingerprint) do
    String.match?(fingerprint, ~r/\A(?:[0-9A-F]{2}:){31}[0-9A-F]{2}\z/)
  end

  defp manifest(online, backup, fingerprint) do
    [
      "version=1",
      "online=" <> Base.url_encode64(online, padding: false),
      "backup=" <> Base.url_encode64(backup, padding: false),
      "fingerprint=" <> fingerprint,
      "approval_key_role=action_approval"
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp validate_fingerprint(manifest, fingerprint) do
    if manifest.fingerprint == fingerprint do
      :ok
    else
      invalid_state("The root certificate fingerprint does not match the PKI manifest")
    end
  end

  defp metadata(online, backup, fingerprint) do
    {:ok, %{online_state: online, offline_backup: backup, root_fingerprint: fingerprint}}
  end

  defp invalid_state(message), do: {:error, Error.new(:invalid_pki_state, message)}

  defp io_error(action, reason) do
    {:error,
     Error.new(:pki_storage_error, "Unable to #{action}", %{reason: sanitized_reason(reason)})}
  end

  defp sanitized_reason(reason)
       when reason in [:eacces, :eexist, :enoent, :enospc, :enotdir, :erofs],
       do: reason

  defp sanitized_reason(_reason), do: :io_failure
end
