defmodule Exocomp.Coordinator.PKI.IssuerTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.PKI.{Bootstrap, Issuer}
  alias X509.Certificate.Extension

  @node_id "node-87.example.internal"
  @passphrase "correct horse battery staple"
  @seconds_per_day 86_400

  setup do
    base =
      Path.join(
        System.tmp_dir!(),
        "exocomp-issuer-#{System.unique_integer([:positive, :monotonic])}"
      )

    online = Path.join(base, "online")
    offline = Path.join(base, "offline")
    File.mkdir_p!(base)
    File.chmod!(base, 0o700)
    on_exit(fn -> File.rm_rf!(base) end)

    assert {:ok, _metadata} =
             Bootstrap.initialize(
               online_state: online,
               offline_backup: offline,
               root_key_protection: {:passphrase, @passphrase}
             )

    %{online: online}
  end

  test "validates a P-256 CSR and issues a chain verifiable against the root", %{
    online: online
  } do
    key = X509.PrivateKey.new_ec(:secp256r1)
    pem = csr_pem(key)

    assert {:ok, csr} = Issuer.validate_csr(pem, @node_id)
    assert {:ok, chain_pem} = Issuer.issue_leaf(csr, online)
    assert is_binary(chain_pem)

    {leaf, intermediate} = issued_chain(chain_pem)
    root = certificate(online, "root_ca.pem")

    assert {:ok, _validation} =
             :public_key.pkix_path_validation(
               X509.Certificate.to_der(root),
               [
                 X509.Certificate.to_der(intermediate),
                 X509.Certificate.to_der(leaf)
               ],
               max_path_length: 1
             )
  end

  test "rejects input that is not a PEM-encoded CSR" do
    assert {:error, %{code: :invalid_csr}} =
             Issuer.validate_csr("this is not a certificate request", @node_id)
  end

  test "rejects RSA keys below 3072 bits" do
    key = X509.PrivateKey.new_rsa(2_048)

    assert {:error, %{code: :invalid_csr, message: message}} =
             key
             |> csr_pem()
             |> Issuer.validate_csr(@node_id)

    assert message =~ "3072"
  end

  test "rejects a missing SAN" do
    key = X509.PrivateKey.new_ec(:secp256r1)
    extensions = valid_extensions() |> Keyword.delete(:subject_alt_name)

    assert {:error, %{code: :invalid_csr}} =
             key
             |> csr_pem(extensions)
             |> Issuer.validate_csr(@node_id)
  end

  test "rejects a SAN that does not match the expected node identity" do
    key = X509.PrivateKey.new_ec(:secp256r1)
    extensions = Keyword.put(valid_extensions(), :subject_alt_name, san(["other-node"]))

    assert {:error, %{code: :invalid_csr}} =
             key
             |> csr_pem(extensions)
             |> Issuer.validate_csr(@node_id)
  end

  test "rejects additional SAN identities" do
    key = X509.PrivateKey.new_ec(:secp256r1)

    extensions =
      Keyword.put(
        valid_extensions(),
        :subject_alt_name,
        san([@node_id, "other-node.example.internal"])
      )

    assert {:error, %{code: :invalid_csr}} =
             key
             |> csr_pem(extensions)
             |> Issuer.validate_csr(@node_id)
  end

  test "rejects a request for CA capability" do
    key = X509.PrivateKey.new_ec(:secp256r1)

    extensions =
      Keyword.put(
        valid_extensions(),
        :basic_constraints,
        Extension.basic_constraints(true)
      )

    assert {:error, %{code: :invalid_csr}} =
             key
             |> csr_pem(extensions)
             |> Issuer.validate_csr(@node_id)
  end

  test "rejects key usage without digitalSignature" do
    key = X509.PrivateKey.new_ec(:secp256r1)
    extensions = Keyword.put(valid_extensions(), :key_usage, Extension.key_usage([:keyAgreement]))

    assert {:error, %{code: :invalid_csr}} =
             key
             |> csr_pem(extensions)
             |> Issuer.validate_csr(@node_id)
  end

  test "rejects prohibited key usages" do
    key = X509.PrivateKey.new_ec(:secp256r1)

    for usage <- [:keyEncipherment, :keyCertSign] do
      extensions =
        Keyword.put(
          valid_extensions(),
          :key_usage,
          Extension.key_usage([:digitalSignature, usage])
        )

      assert {:error, %{code: :invalid_csr}} =
               key
               |> csr_pem(extensions)
               |> Issuer.validate_csr(@node_id)
    end
  end

  test "requires both client and server authentication EKUs" do
    key = X509.PrivateKey.new_ec(:secp256r1)

    for usages <- [[:clientAuth], [:serverAuth], []] do
      extensions =
        Keyword.put(valid_extensions(), :ext_key_usage, Extension.ext_key_usage(usages))

      assert {:error, %{code: :invalid_csr}} =
               key
               |> csr_pem(extensions)
               |> Issuer.validate_csr(@node_id)
    end
  end

  test "rejects a CSR with a tampered self-signature" do
    key = X509.PrivateKey.new_ec(:secp256r1)

    assert {:error, %{code: :invalid_csr}} =
             key
             |> csr_pem()
             |> tamper_signature()
             |> Issuer.validate_csr(@node_id)
  end

  test "issues a leaf with the requested identity, constrained usages, and 30-day validity", %{
    online: online
  } do
    before_issue = current_seconds()
    csr = validated_csr()
    assert {:ok, chain_pem} = Issuer.issue_leaf(csr, online)
    after_issue = current_seconds()

    {leaf, _intermediate} = issued_chain(chain_pem)
    {:Validity, not_before, not_after} = X509.Certificate.validity(leaf)
    not_before_seconds = time_seconds(not_before)
    not_after_seconds = time_seconds(not_after)

    assert not_before_seconds in before_issue..after_issue
    assert not_after_seconds - not_before_seconds == 30 * @seconds_per_day
    assert X509.Certificate.subject(leaf, :commonName) == [@node_id]
    assert X509.Certificate.subject(leaf, :organizationName) == ["Exocomp"]

    assert {:Extension, _oid, _critical, [dNSName: dns_name]} =
             X509.Certificate.extension(leaf, :subject_alt_name)

    assert to_string(dns_name) == @node_id

    assert {:Extension, _oid, _critical, [:digitalSignature]} =
             X509.Certificate.extension(leaf, :key_usage)

    assert {:Extension, _oid, _critical, eku} =
             X509.Certificate.extension(leaf, :ext_key_usage)

    assert {1, 3, 6, 1, 5, 5, 7, 3, 1} in eku
    assert {1, 3, 6, 1, 5, 5, 7, 3, 2} in eku

    assert {:Extension, _oid, _critical, {:BasicConstraints, false, _path_len}} =
             X509.Certificate.extension(leaf, :basic_constraints)
  end

  test "supports an explicit shorter validity", %{online: online} do
    csr = validated_csr()
    assert {:ok, chain_pem} = Issuer.issue_leaf(csr, online, validity_days: 7)
    {leaf, _intermediate} = issued_chain(chain_pem)
    {:Validity, not_before, not_after} = X509.Certificate.validity(leaf)

    assert time_seconds(not_after) - time_seconds(not_before) == 7 * @seconds_per_day
  end

  test "rejects use of the online intermediate key as a node key", %{online: online} do
    intermediate_key =
      online
      |> Path.join("intermediate_ca_key.pem")
      |> File.read!()
      |> X509.PrivateKey.from_pem!()

    assert {:ok, csr} =
             intermediate_key
             |> csr_pem()
             |> Issuer.validate_csr(@node_id)

    assert {:error, %{code: :invalid_csr}} = Issuer.issue_leaf(csr, online)
  end

  test "returns a redacted error when intermediate material cannot be loaded", %{online: online} do
    secret = File.read!(Path.join(online, "intermediate_ca_key.pem"))
    File.write!(Path.join(online, "intermediate_ca_key.pem"), "not a key")

    assert {:error, error} = Issuer.issue_leaf(validated_csr(), online)
    refute inspect(error) =~ secret
    refute error.message =~ "intermediate_ca_key.pem"
  end

  defp validated_csr do
    key = X509.PrivateKey.new_ec(:secp256r1)
    {:ok, csr} = key |> csr_pem() |> Issuer.validate_csr(@node_id)
    csr
  end

  defp csr_pem(key, extensions \\ valid_extensions()) do
    extensions = Keyword.values(extensions)

    key
    |> X509.CSR.new("/O=Exocomp/CN=#{@node_id}", extension_request: extensions)
    |> X509.CSR.to_pem()
  end

  defp valid_extensions do
    [
      basic_constraints: Extension.basic_constraints(false),
      key_usage: Extension.key_usage([:digitalSignature]),
      ext_key_usage: Extension.ext_key_usage([:clientAuth, :serverAuth]),
      subject_alt_name: san([@node_id])
    ]
  end

  defp san(names), do: Extension.subject_alt_name(names)

  defp tamper_signature(pem) do
    {:ok, csr} = X509.CSR.from_pem(pem)
    der = X509.CSR.to_der(csr)
    prefix_size = byte_size(der) - 1
    <<prefix::binary-size(^prefix_size), last>> = der
    tampered_der = prefix <> <<Bitwise.bxor(last, 1)>>

    [{:CertificationRequest, tampered_der, :not_encrypted}]
    |> :public_key.pem_encode()
    |> IO.iodata_to_binary()
  end

  defp issued_chain(chain_pem) do
    [
      {:Certificate, leaf_der, :not_encrypted},
      {:Certificate, intermediate_der, :not_encrypted}
    ] = :public_key.pem_decode(chain_pem)

    {
      X509.Certificate.from_der!(leaf_der),
      X509.Certificate.from_der!(intermediate_der)
    }
  end

  defp certificate(directory, filename) do
    directory
    |> Path.join(filename)
    |> File.read!()
    |> X509.Certificate.from_pem!()
  end

  defp time_seconds(time) do
    {year, month, day, hour, minute, second} = time_parts(time)
    :calendar.datetime_to_gregorian_seconds({{year, month, day}, {hour, minute, second}})
  end

  defp current_seconds do
    DateTime.utc_now()
    |> DateTime.to_naive()
    |> NaiveDateTime.to_erl()
    |> :calendar.datetime_to_gregorian_seconds()
  end

  defp time_parts({:utcTime, value}) do
    <<year::binary-size(2), rest::binary>> = to_string(value)
    year = String.to_integer(year)
    year = if year < 50, do: year + 2_000, else: year + 1_900

    {year, rest}
    |> parse_time_parts()
  end

  defp time_parts({:generalTime, value}) do
    <<year::binary-size(4), rest::binary>> = to_string(value)

    {String.to_integer(year), rest}
    |> parse_time_parts()
  end

  defp parse_time_parts({year, value}) do
    <<month::binary-size(2), day::binary-size(2), hour::binary-size(2), minute::binary-size(2),
      second::binary-size(2), "Z">> = value

    {
      year,
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second)
    }
  end
end
