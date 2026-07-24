defmodule Exocomp.Node.Identity do
  @moduledoc """
  Validates the node's TLS identity before the listener starts.

  Performs three checks, in order, failing fast on the first error:

  1. **Key file permissions** — the private key file must not be
     group- or world-readable/writable/executable (mode `& 0o077 == 0`).
     Returns `{:error, :key_not_secure}` on failure.  The key file path is
     never included in error payloads.

  2. **Certificate chain** — the node certificate must be verifiable against
     the trust root (CA certificate) using `:public_key.pkix_path_validation/3`.
     Returns `{:error, {:invalid_chain, reason}}` on failure.

  3. **SAN match** — the leaf certificate must contain a `dNSName` Subject
     Alternative Name equal to the configured `node_id`.
     Returns `{:error, {:san_mismatch, expected: node_id}}` on failure.
     Actual SAN values are never included in error payloads.
  """

  require Record
  require Logger

  import Bitwise

  alias Exocomp.Node.Config

  # OTP certificate record definitions extracted at compile time from the
  # public_key application's header files.
  Record.defrecordp(
    :otp_certificate,
    :OTPCertificate,
    Record.extract(:OTPCertificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :otp_tbs_certificate,
    :OTPTBSCertificate,
    Record.extract(:OTPTBSCertificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :extension,
    :Extension,
    Record.extract(:Extension, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  # OID for SubjectAltName extension (2.5.29.17)
  @san_oid {2, 5, 29, 17}

  @doc """
  Validate the TLS identity described by `config`.

  Returns `:ok` when all checks pass, or `{:error, reason}` on the first
  failing check.

  ## Error reasons

  - `:key_not_secure` — key file mode bits `& 0o077 != 0`
  - `{:key_stat_failed, reason}` — could not stat the key file
  - `{:cert_read, reason}` — could not read a PEM certificate file
  - `{:invalid_pem, :no_certs}` — PEM file contained no certificate entries
  - `{:invalid_chain, reason}` — path validation failed
  - `{:san_mismatch, expected: node_id}` — no dNSName SAN matched the node_id
  """
  @spec validate(Config.t()) :: :ok | {:error, term()}
  def validate(%Config{} = config) do
    with :ok <- check_key_permissions(config.tls.node_key),
         {:ok, ca_der} <- load_pem_cert(config.tls.ca_cert),
         {:ok, leaf_der} <- load_pem_cert(config.tls.node_cert),
         :ok <- verify_chain(ca_der, leaf_der),
         :ok <- verify_san(leaf_der, config.node_id) do
      :ok
    end
  end

  # ── Key permission check ─────────────────────────────────────────────────────

  defp check_key_permissions(key_path) do
    case File.stat(key_path, time: :posix) do
      {:ok, stat} ->
        if (stat.mode &&& 0o077) == 0 do
          :ok
        else
          Logger.warning("Key file has insecure permissions (mode too permissive)")
          {:error, :key_not_secure}
        end

      {:error, reason} ->
        Logger.warning("Could not stat key file: #{inspect(reason)}")
        {:error, {:key_stat_failed, reason}}
    end
  end

  # ── PEM loading ──────────────────────────────────────────────────────────────

  defp load_pem_cert(path) do
    case File.read(path) do
      {:ok, pem} ->
        pem_entries = :public_key.pem_decode(pem)

        case Enum.find(pem_entries, fn {type, _, _} -> type == :Certificate end) do
          nil ->
            {:error, {:invalid_pem, :no_certs}}

          {:Certificate, der, _} ->
            {:ok, der}
        end

      {:error, reason} ->
        {:error, {:cert_read, reason}}
    end
  end

  # ── Chain validation ─────────────────────────────────────────────────────────

  defp verify_chain(ca_der, leaf_der) do
    case :public_key.pkix_path_validation(ca_der, [leaf_der], []) do
      {:ok, _} ->
        :ok

      {:error, {_bad_cert, reason}} ->
        Logger.warning("Certificate chain validation failed: #{inspect(reason)}")
        {:error, {:invalid_chain, reason}}
    end
  end

  # ── SAN match ────────────────────────────────────────────────────────────────

  defp verify_san(leaf_der, node_id) do
    otp = :public_key.pkix_decode_cert(leaf_der, :otp)
    tbs = otp_certificate(otp, :tbsCertificate)
    extensions = otp_tbs_certificate(tbs, :extensions)

    dns_names = extract_dns_sans(extensions)

    if node_id in dns_names do
      :ok
    else
      Logger.warning("Certificate SAN does not match node_id #{inspect(node_id)} (SANs redacted)")

      {:error, {:san_mismatch, expected: node_id}}
    end
  end

  defp extract_dns_sans(:asn1_NOVALUE), do: []

  defp extract_dns_sans(extensions) when is_list(extensions) do
    san_ext = Enum.find(extensions, fn ext -> extension(ext, :extnID) == @san_oid end)

    case san_ext do
      nil ->
        []

      ext ->
        ext
        |> extension(:extnValue)
        |> Enum.filter(fn {type, _} -> type == :dNSName end)
        |> Enum.map(fn {:dNSName, name} -> List.to_string(name) end)
    end
  end
end
