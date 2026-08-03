# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterEnrollmentTest do
  use ExUnit.Case, async: false

  @moduletag :tmp_dir

  import Plug.Conn
  import Plug.Test

  alias Exocomp.Coordinator.{Audit, ClusterInvitationStore, Error}
  alias Exocomp.Coordinator.CoordinatorRouter
  alias Exocomp.Coordinator.PKI.{Bootstrap, ClusterIssuer, State}
  alias X509.Certificate.Extension

  @passphrase "cluster-enrollment-integration-passphrase-correct"
  @organization_id "org-test-alpha"
  @other_organization_id "org-test-beta"

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive, :monotonic])}"

  defp setup_context(tmp_dir, store_opts \\ []) do
    base = Path.join(tmp_dir, "cluster-enrollment")
    online = Path.join(base, "online")
    offline = Path.join(base, "offline")
    store_path = Path.join(base, "invitations")
    audit_path = Path.join(base, "audit.jsonl")
    audit = unique_name("cluster_enrollment_audit")
    pki_state = unique_name("cluster_enrollment_pki_state")
    store = unique_name("cluster_enrollment_store")

    File.mkdir_p!(base)

    assert {:ok, metadata} =
             Bootstrap.initialize(
               online_state: online,
               offline_backup: offline,
               root_key_protection: {:passphrase, @passphrase}
             )

    start_supervised!(
      {Audit, name: audit, sink: {Audit.JSONLines, path: audit_path}}
    )

    start_supervised!({State, metadata: metadata, name: pki_state})

    store_options =
      [name: store, store_path: store_path, audit_server: audit]
      |> Keyword.merge(store_opts)

    start_supervised!({ClusterInvitationStore, store_options})

    %{
      online: online,
      audit_path: audit_path,
      store: store,
      handler_opts: [pki_state: pki_state, cluster_invitation_store: store, audit_server: audit]
    }
  end

  defp issue_invitation(context, organization_id \\ @organization_id, name \\ "cluster-alpha") do
    ClusterInvitationStore.create(
      %{organization_id: organization_id, name: name},
      server: context.store
    )
  end

  defp enrollment_request(context, organization_id, cluster_id, token, csr) do
    :post
    |> conn(
      "/api/v1/clusters/enroll",
      Jason.encode!(%{
        "organization_id" => organization_id,
        "cluster_id" => cluster_id,
        "invitation" => token,
        "csr" => csr
      })
    )
    |> put_req_header("content-type", "application/json")
    |> CoordinatorRouter.call(CoordinatorRouter.init(context.handler_opts))
  end

  defp csr_pem(key, organization_id, cluster_id, extensions \\ nil) do
    extensions = extensions || valid_extensions(organization_id, cluster_id)

    key
    |> X509.CSR.new("/O=Exocomp/CN=#{cluster_id}", extension_request: extensions)
    |> X509.CSR.to_pem()
  end

  defp valid_csr(organization_id, cluster_id) do
    key = X509.PrivateKey.new_ec(:secp256r1)
    {key, csr_pem(key, organization_id, cluster_id)}
  end

  defp valid_extensions(organization_id, cluster_id) do
    [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth]),
      Extension.subject_alt_name([
        {:URI, "spiffe://exocomp/organizations/#{organization_id}/clusters/#{cluster_id}"}
      ])
    ]
  end

  defp issued_chain(chain_pem) do
    [
      {:Certificate, leaf_der, :not_encrypted},
      {:Certificate, intermediate_der, :not_encrypted}
    ] = :public_key.pem_decode(chain_pem)

    {X509.Certificate.from_der!(leaf_der), X509.Certificate.from_der!(intermediate_der)}
  end

  defp assert_chain_validates_to_root(chain_pem, online) do
    {leaf, intermediate} = issued_chain(chain_pem)
    root = online |> Path.join("root_ca.pem") |> File.read!() |> X509.Certificate.from_pem!()

    assert {:ok, _validation} =
             :public_key.pkix_path_validation(
               X509.Certificate.to_der(root),
               [X509.Certificate.to_der(intermediate), X509.Certificate.to_der(leaf)],
               max_path_length: 1
             )
  end

  defp tamper_signature(pem) do
    {:ok, csr} = X509.CSR.from_pem(pem)
    der = X509.CSR.to_der(csr)
    prefix_size = byte_size(der) - 1
    <<prefix::binary-size(^prefix_size), last>> = der

    [{:CertificationRequest, prefix <> <<Bitwise.bxor(last, 1)>>, :not_encrypted}]
    |> :public_key.pem_encode()
    |> IO.iodata_to_binary()
  end

  test "issues a 30-day cluster certificate from a valid invitation and CSR", %{tmp_dir: tmp_dir} do
    context = setup_context(tmp_dir)
    assert {:ok, invitation, token} = issue_invitation(context)
    {_key, csr} = valid_csr(@organization_id, invitation.cluster_id)

    response = enrollment_request(context, @organization_id, invitation.cluster_id, token, csr)

    assert response.status == 200
    %{"chain_pem" => chain_pem, "certificate" => certificate} = Jason.decode!(response.resp_body)
    assert is_binary(certificate["serial"])
    assert byte_size(certificate["sha256"]) == 64

    {leaf, _intermediate} = issued_chain(chain_pem)
    {:Validity, not_before, not_after} = X509.Certificate.validity(leaf)
    assert DateTime.diff(X509.DateTime.to_datetime(not_after), X509.DateTime.to_datetime(not_before)) == 30 * 86_400
    assert X509.Certificate.subject(leaf, :commonName) == [invitation.cluster_id]
    assert X509.Certificate.subject(leaf, :organizationName) == ["Exocomp"]

    assert {:Extension, _oid, _critical, san_values} =
             X509.Certificate.extension(leaf, :subject_alt_name)

    assert {:uniformResourceIdentifier,
            "spiffe://exocomp/organizations/#{@organization_id}/clusters/#{invitation.cluster_id}"} in san_values

    assert_chain_validates_to_root(chain_pem, context.online)

    audit_events =
      context.audit_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)

    assert Enum.any?(audit_events, fn event ->
             event["event_type"] == "cluster_certificate_issued" and
               event["attributes"]["organization_id"] == @organization_id and
               event["attributes"]["cluster_id"] == invitation.cluster_id and
               event["attributes"]["certificate_serial"] == certificate["serial"]
           end)

    assert {:error, %Error{code: :invitation_already_consumed}} =
             ClusterInvitationStore.consume(token, @organization_id, invitation.cluster_id,
               server: context.store
             )
  end

  test "rejects malformed and tampered CSRs without consuming the invitation", %{tmp_dir: tmp_dir} do
    context = setup_context(tmp_dir)
    assert {:ok, invitation, token} = issue_invitation(context)
    {_key, valid_csr_pem} = valid_csr(@organization_id, invitation.cluster_id)

    malformed =
      "-----BEGIN CERTIFICATE REQUEST-----\ninvalid-base64\n-----END CERTIFICATE REQUEST-----"

    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, malformed).status == 422
    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, tamper_signature(valid_csr_pem)).status == 422
    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, valid_csr_pem).status == 200
  end

  test "rejects unsupported RSA key parameters", %{tmp_dir: tmp_dir} do
    context = setup_context(tmp_dir)
    assert {:ok, invitation, _token} = issue_invitation(context)
    key = X509.PrivateKey.new_rsa(2_048)
    csr = csr_pem(key, @organization_id, invitation.cluster_id)

    assert {:error, %Error{code: :invalid_csr, message: message}} =
             ClusterIssuer.validate_csr(csr, @organization_id, invitation.cluster_id)

    assert message =~ "3072"
  end

  test "rejects expired and replayed invitations", %{tmp_dir: tmp_dir} do
    {:ok, clock} = Agent.start_link(fn -> 1_000 end)
    on_exit(fn -> Agent.stop(clock) end)

    context =
      setup_context(tmp_dir,
        now_fn: fn -> Agent.get(clock, & &1) end,
        max_lifetime: 1
      )

    assert {:ok, invitation, token} = issue_invitation(context)
    Agent.update(clock, fn _ -> 1_001 end)
    {_key, csr} = valid_csr(@organization_id, invitation.cluster_id)

    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, csr).status == 401
    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, csr).status == 401
  end

  test "rejects organization and cluster bindings without burning the invitation", %{tmp_dir: tmp_dir} do
    context = setup_context(tmp_dir)
    assert {:ok, invitation, token} = issue_invitation(context)
    {_key, wrong_organization_csr} = valid_csr(@other_organization_id, invitation.cluster_id)
    {_key, wrong_cluster_csr} = valid_csr(@organization_id, "other-cluster")
    {_key, valid_csr_pem} = valid_csr(@organization_id, invitation.cluster_id)

    assert enrollment_request(
             context,
             @other_organization_id,
             invitation.cluster_id,
             token,
             wrong_organization_csr
           ).status == 401

    assert enrollment_request(context, @organization_id, "other-cluster", token, wrong_cluster_csr).status ==
             401

    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, valid_csr_pem).status ==
             200
  end

  test "returns service unavailable when signing fails", %{tmp_dir: tmp_dir} do
    context = setup_context(tmp_dir)
    assert {:ok, invitation, token} = issue_invitation(context)
    {_key, csr} = valid_csr(@organization_id, invitation.cluster_id)

    File.write!(Path.join(context.online, "intermediate_ca_key.pem"), "not a private key")

    assert enrollment_request(context, @organization_id, invitation.cluster_id, token, csr).status == 503
  end

  test "rejects a CSR with multiple URI identities", %{tmp_dir: tmp_dir} do
    context = setup_context(tmp_dir)
    assert {:ok, invitation, _token} = issue_invitation(context)
    key = X509.PrivateKey.new_ec(:secp256r1)

    extensions =
      valid_extensions(@organization_id, invitation.cluster_id)
      |> List.replace_at(
        3,
        Extension.subject_alt_name([
          {:URI, "spiffe://exocomp/organizations/#{@organization_id}/clusters/#{invitation.cluster_id}"},
          {:URI, "spiffe://exocomp/organizations/#{@organization_id}/clusters/other"}
        ])
      )

    assert {:error, %Error{code: :invalid_csr}} =
             key
             |> csr_pem(@organization_id, invitation.cluster_id, extensions)
             |> ClusterIssuer.validate_csr(@organization_id, invitation.cluster_id)
  end
end
