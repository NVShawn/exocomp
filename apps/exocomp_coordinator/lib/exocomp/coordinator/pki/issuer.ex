defmodule Exocomp.Coordinator.PKI.Issuer do
  @moduledoc """
  Validates node certificate signing requests and issues node leaf certificates.

  This module performs no network operations. It reads only the online
  intermediate material required while issuing a certificate.
  """

  alias Exocomp.Coordinator.Error
  alias X509.Certificate.Extension

  @basic_constraints_oid {2, 5, 29, 19}
  @key_usage_oid {2, 5, 29, 15}
  @subject_alt_name_oid {2, 5, 29, 17}
  @ext_key_usage_oid {2, 5, 29, 37}
  @extension_request_oid {1, 2, 840, 113_549, 1, 9, 14}
  @server_auth_oid {1, 3, 6, 1, 5, 5, 7, 3, 1}
  @client_auth_oid {1, 3, 6, 1, 5, 5, 7, 3, 2}
  @approved_ec_curves [
    {1, 2, 840, 10_045, 3, 1, 7},
    {1, 3, 132, 0, 34},
    {1, 3, 132, 0, 35}
  ]

  @spec validate_csr(binary(), String.t()) :: {:ok, X509.CSR.t()} | {:error, Error.t()}
  def validate_csr(pem, node_id) when is_binary(pem) and is_binary(node_id) and node_id != "" do
    with {:ok, csr} <- parse_csr(pem),
         :ok <- validate_public_key(X509.CSR.public_key(csr)),
         extensions <- csr_extensions(csr),
         :ok <- validate_san(extensions, node_id),
         :ok <- validate_basic_constraints(extensions),
         :ok <- validate_key_usage(extensions),
         :ok <- validate_extended_key_usage(extensions),
         true <- X509.CSR.valid?(csr) do
      {:ok, csr}
    else
      false -> invalid_csr("CSR self-signature is invalid")
      {:error, %Error{} = error} -> {:error, error}
      _other -> invalid_csr("CSR is invalid")
    end
  rescue
    _exception -> invalid_csr("CSR is malformed or uses unsupported cryptography")
  catch
    _kind, _reason -> invalid_csr("CSR is malformed or uses unsupported cryptography")
  end

  def validate_csr(_pem, _node_id), do: invalid_csr("CSR and node identity must be non-empty")

  @spec issue_leaf(X509.CSR.t(), Path.t(), keyword()) ::
          {:ok, binary()} | {:error, Error.t()}
  def issue_leaf(csr, online_state, options \\ [])

  def issue_leaf(csr, online_state, options)
      when is_binary(online_state) and is_list(options) do
    with {:ok, validity_days} <- validity_days(options),
         {:ok, intermediate, intermediate_pem, intermediate_key} <-
           load_intermediate(online_state),
         :ok <- validate_intermediate(intermediate, intermediate_key),
         :ok <- reject_intermediate_key(csr, intermediate_key),
         {:ok, node_id} <- node_id(csr),
         {:ok, leaf} <-
           sign_leaf(csr, node_id, intermediate, intermediate_key, validity_days) do
      {:ok, X509.Certificate.to_pem(leaf) <> intermediate_pem}
    else
      {:error, %Error{} = error} -> {:error, error}
    end
  rescue
    _exception -> issuance_error()
  catch
    _kind, _reason -> issuance_error()
  end

  def issue_leaf(_csr, _online_state, _options), do: issuance_error()

  defp parse_csr(pem) do
    case X509.CSR.from_pem(pem) do
      {:ok, csr} -> {:ok, csr}
      {:error, _reason} -> invalid_csr("CSR is not valid PEM-encoded PKCS#10 data")
    end
  end

  defp validate_public_key({:RSAPublicKey, modulus, _exponent}) when is_integer(modulus) do
    if modulus |> Integer.to_string(2) |> byte_size() >= 3_072 do
      :ok
    else
      invalid_csr("CSR RSA key must be at least 3072 bits")
    end
  end

  defp validate_public_key({{:ECPoint, point}, {:namedCurve, curve}})
       when is_binary(point) and curve in @approved_ec_curves,
       do: :ok

  defp validate_public_key(_public_key) do
    invalid_csr("CSR key must use P-256 or a stronger approved EC curve, or RSA-3072 or stronger")
  end

  defp validate_san(extensions, node_id) do
    case extensions_for(extensions, @subject_alt_name_oid) do
      [{:Extension, @subject_alt_name_oid, _critical, [{:dNSName, dns_name}]}] ->
        if to_string(dns_name) == node_id do
          :ok
        else
          invalid_csr("CSR SAN does not match the expected node identity")
        end

      [] ->
        invalid_csr("CSR must contain exactly one DNS SAN")

      _other ->
        invalid_csr("CSR must contain exactly one DNS SAN and no additional names")
    end
  end

  defp validate_basic_constraints(extensions) do
    if Enum.any?(extensions_for(extensions, @basic_constraints_oid), fn
         {:Extension, @basic_constraints_oid, _critical, {:BasicConstraints, true, _path_len}} ->
           true

         _extension ->
           false
       end) do
      invalid_csr("CSR must not request CA capability")
    else
      :ok
    end
  end

  defp validate_key_usage(extensions) do
    case extensions_for(extensions, @key_usage_oid) do
      [{:Extension, @key_usage_oid, _critical, usages}] when is_list(usages) ->
        cond do
          :digitalSignature not in usages ->
            invalid_csr("CSR key usage must include digitalSignature")

          :keyEncipherment in usages or :keyCertSign in usages ->
            invalid_csr("CSR requests a prohibited key usage")

          true ->
            :ok
        end

      _other ->
        invalid_csr("CSR must contain one keyUsage extension")
    end
  end

  defp validate_extended_key_usage(extensions) do
    case extensions_for(extensions, @ext_key_usage_oid) do
      [{:Extension, @ext_key_usage_oid, _critical, usages}] when is_list(usages) ->
        if @client_auth_oid in usages and @server_auth_oid in usages do
          :ok
        else
          invalid_csr("CSR extended key usage must include clientAuth and serverAuth")
        end

      _other ->
        invalid_csr("CSR must contain one extendedKeyUsage extension")
    end
  end

  defp extensions_for(extensions, oid) when is_list(extensions) do
    Enum.filter(extensions, fn
      {:Extension, extension_oid, _critical, _value} -> extension_oid == oid
      _other -> false
    end)
  end

  defp validity_days(options) do
    case Keyword.get(options, :validity_days, 30) do
      days when is_integer(days) and days > 0 -> {:ok, days}
      _other -> issuance_error()
    end
  end

  defp load_intermediate(online_state) do
    cert_path = Path.join(online_state, "intermediate_ca.pem")
    key_path = Path.join(online_state, "intermediate_ca_key.pem")

    with {:ok, intermediate_pem} <- File.read(cert_path),
         {:ok, intermediate} <- X509.Certificate.from_pem(intermediate_pem),
         {:ok, key_pem} <- File.read(key_path),
         {:ok, intermediate_key} <- X509.PrivateKey.from_pem(key_pem) do
      {:ok, intermediate, intermediate_pem, intermediate_key}
    else
      _failure -> issuance_error()
    end
  end

  defp validate_intermediate(intermediate, intermediate_key) do
    ca? =
      case X509.Certificate.extension(intermediate, :basic_constraints) do
        {:Extension, @basic_constraints_oid, _critical, {:BasicConstraints, true, _path_len}} ->
          true

        _other ->
          false
      end

    if ca? and
         X509.Certificate.public_key(intermediate) == X509.PublicKey.derive(intermediate_key) do
      :ok
    else
      issuance_error()
    end
  end

  defp reject_intermediate_key(csr, intermediate_key) do
    if X509.CSR.public_key(csr) == X509.PublicKey.derive(intermediate_key) do
      invalid_csr("CSR must use a dedicated node key")
    else
      :ok
    end
  end

  defp node_id(csr) do
    case extensions_for(csr_extensions(csr), @subject_alt_name_oid) do
      [{:Extension, @subject_alt_name_oid, _critical, [{:dNSName, dns_name}]}] ->
        {:ok, to_string(dns_name)}

      _other ->
        invalid_csr("Validated CSR no longer contains one DNS SAN")
    end
  end

  defp sign_leaf(csr, node_id, intermediate, intermediate_key, validity_days) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    not_after = DateTime.add(now, validity_days, :day)
    validity = X509.Certificate.Validity.new(now, not_after)
    subject = X509.RDNSequence.new([{"CN", node_id}, {"O", "Exocomp"}], :otp)

    leaf =
      csr
      |> X509.CSR.public_key()
      |> X509.Certificate.new(subject, intermediate, intermediate_key,
        template: :server,
        validity: validity,
        extensions: [
          basic_constraints: Extension.basic_constraints(false),
          key_usage: Extension.key_usage([:digitalSignature]),
          ext_key_usage: Extension.ext_key_usage([:clientAuth, :serverAuth]),
          subject_alt_name: Extension.subject_alt_name([node_id])
        ]
      )

    {:ok, leaf}
  end

  # OTP decodes the PKCS#10 attribute record as either `:Attribute` or
  # `:"AttributePKCS-10"` depending on its public_key version. x509 0.9.2 only
  # recognizes the former, so extract the extensionRequest without relying on
  # the record tag.
  defp csr_extensions(
         {:CertificationRequest,
          {:CertificationRequestInfo, _version, _subject, _subject_key_info, attributes},
          _signature_algorithm, _signature}
       ) do
    Enum.find_value(attributes, [], fn
      {_record_tag, @extension_request_oid, [{:asn1_OPENTYPE, der}]} ->
        Extension.from_der!(der, :Extensions)

      _attribute ->
        nil
    end)
  end

  defp invalid_csr(message), do: {:error, Error.new(:invalid_csr, message)}

  defp issuance_error do
    {:error,
     Error.new(
       :pki_operation_failed,
       "Node certificate issuance failed; no private material was retained"
     )}
  end
end
