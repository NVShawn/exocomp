defmodule Exocomp.Node.EnrollmentClientTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.EnrollmentClient
  alias X509.Certificate.Extension

  setup do
    directory =
      Path.join(System.tmp_dir!(), "enrollment-client-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(directory) end)

    root_key = X509.PrivateKey.new_ec(:secp384r1)

    root =
      X509.Certificate.self_signed(root_key, "/O=Exocomp/CN=Test Root",
        template: :root_ca,
        validity: 30
      )

    {:ok,
     directory: directory, root: root, root_key: root_key, root_pem: X509.Certificate.to_pem(root)}
  end

  test "generates a valid constrained CSR without exporting its private key" do
    {key, key_pem, csr_pem} = EnrollmentClient.identity_request("node-one")
    assert {:ok, csr} = X509.CSR.from_pem(csr_pem)
    assert X509.CSR.valid?(csr)
    assert X509.CSR.public_key(csr) == X509.PublicKey.derive(key)
    refute String.contains?(csr_pem, "PRIVATE KEY")
    assert String.contains?(key_pem, "PRIVATE KEY")

    assert {:Extension, _oid, _critical, [{:dNSName, ~c"node-one"}]} =
             Enum.find(
               X509.CSR.extension_request(csr),
               &match?({:Extension, {2, 5, 29, 17}, _, _}, &1)
             )
  end

  test "submits node ID and CSR then installs the returned chain", context do
    owner = self()

    transport = fn endpoint, request, _opts ->
      send(owner, {:request, endpoint, request})
      {:ok, csr} = X509.CSR.from_pem(request.csr)

      leaf =
        csr
        |> X509.CSR.public_key()
        |> X509.Certificate.new(
          "/O=Exocomp/CN=node-one",
          context.root,
          context.root_key,
          template: :server,
          validity: 10,
          extensions: [
            subject_alt_name: Extension.subject_alt_name(["node-one"]),
            key_usage: Extension.key_usage([:digitalSignature]),
            ext_key_usage: Extension.ext_key_usage([:clientAuth, :serverAuth])
          ]
        )

      {:ok, %{"chain_pem" => X509.Certificate.to_pem(leaf)}}
    end

    assert {:ok, paths} =
             EnrollmentClient.enroll(
               node_id: "node-one",
               token: "single-use-secret",
               endpoint: "https://coordinator.test/v1/enroll",
               credential_dir: context.directory,
               ca_pem: context.root_pem,
               transport: transport
             )

    assert_receive {:request, "https://coordinator.test/v1/enroll", request}
    assert request.node_id == "node-one"
    assert request.token == "single-use-secret"
    refute Map.has_key?(request, :private_key)
    assert File.exists?(paths.chain)
    assert File.exists?(paths.key)
  end

  test "does not activate a response for a different key", context do
    unrelated_key = X509.PrivateKey.new_ec(:secp256r1)

    unrelated_leaf =
      unrelated_key
      |> X509.PublicKey.derive()
      |> X509.Certificate.new(
        "/O=Exocomp/CN=node-one",
        context.root,
        context.root_key,
        extensions: [subject_alt_name: Extension.subject_alt_name(["node-one"])]
      )

    transport = fn _endpoint, _request, _opts ->
      {:ok, %{chain_pem: X509.Certificate.to_pem(unrelated_leaf)}}
    end

    assert {:error, :key_mismatch} =
             EnrollmentClient.enroll(
               node_id: "node-one",
               token: "secret",
               endpoint: "https://coordinator.test/v1/enroll",
               credential_dir: context.directory,
               ca_pem: context.root_pem,
               transport: transport
             )

    refute File.exists?(Path.join(context.directory, "current"))
  end

  test "default transport refuses non-HTTPS endpoints" do
    assert {:error, :https_required} =
             EnrollmentClient.https_transport(
               "http://coordinator.test/v1/enroll",
               %{node_id: "node", csr: "csr", token: "secret"},
               ca_file: "/unused"
             )
  end
end
