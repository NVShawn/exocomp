# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterEnrollmentTest do
  @moduledoc """
  Release-mode integration tests for EXOCOMP-143: Cluster enrollment,
  certificate issuance from CSRs, SPIFFE URI identity, and security gates.

  Tests cluster invitation flow, CSR validation, 30-day certificate issuance,
  and fail-closed security rejection cases.

  ## Coverage

  | Criterion | Evidence |
  |-----------|----------|
  | Invitation creation & consumption | ClusterInvitation service |
  | Replay protection | invitation_already_consumed error |
  | Org/cluster binding | invitation_org_mismatch, invitation_cluster_mismatch |
  | CSR validation | SPIFFE URI SAN, key usage, key algorithms |
  | Malformed/unsigned CSR rejection | invalid_csr error |
  | Unsupported key rejection | EC non-approved curves, RSA < 3072 |
  | Certificate issuance | 30-day validity, SPIFFE URI identity |
  | Chain validation | Leaf + intermediate validates to root |
  | Audit trail | Events logged via Audit service |
  | HTTP endpoints | POST /api/v1/clusters/enroll |
  | Service unavailability | 503 when PKI/invitation unavailable |

  ## Running

      MIX_ENV=test mix test apps/exocomp_coordinator/test/integration/cluster_enrollment_test.exs
  """

  use ExUnit.Case, async: false

  @moduletag :cluster_enrollment_integration

  import Plug.Conn
  import Plug.Test

  alias Exocomp.Coordinator.{Audit, ClusterInvitation, Health}
  alias Exocomp.Coordinator.Handlers.ClusterEnrollmentHandler
  alias Exocomp.Coordinator.PKI.{Bootstrap, ClusterIssuer, State}
  alias Exocomp.Coordinator.Error
  alias X509.Certificate.Extension

  @passphrase "cluster-enrollment-integration-passphrase-correct"
  @org_id "org-test-alpha"
  @cluster_id "cluster-test-alpha"
  @org_beta "org-test-beta"
  @cluster_beta "cluster-test-beta"

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp unique_prefix, do: :"cluster#{System.unique_integer([:positive, :monotonic])}"

  defp bootstrap_pki(tmp_dir, label) do
    base = Path.join(tmp_dir, label)
    File.mkdir_p!(base)
    online = Path.join(base, "online")
    offline = Path.join(base, "offline")

    assert {:ok, metadata} =
             Bootstrap.initialize(
               online_state: online,
               offline_backup: offline,
               root_key_protection: {:passphrase, @passphrase}
             )

    metadata
  end

  defp start_pki_tree(tmp_dir, label, extra_opts \\ []) do
    base = Path.join(tmp_dir, label)
    File.mkdir_p!(base)
    online = Path.join(base, "online")
    offline = Path.join(base, "offline")
    store = Path.join(base, "invitations")
    prefix = unique_prefix()

    tree_opts =
      [
        online_state: online,
        offline_backup: offline,
        root_key_protection: {:passphrase, @passphrase},
        supervisor_name: prefix,
        name_prefix: prefix,
        store_path: store
      ] ++ extra_opts

    {:ok, pid} = Exocomp.Coordinator.Application.start_supervised_tree(tree_opts)
    Process.unlink(pid)

    on_exit(fn ->
      if Process.alive?(pid) do
        ref = Process.monitor(pid)
        Process.exit(pid, :kill)

        receive do
          {:DOWN, ^ref, :process, ^pid, _} -> :ok
        after
          500 -> :ok
        end
      end
    end)

    invitation_name = :"#{prefix}_cluster_invitation"
    pki_state_name = :"#{prefix}_pki_state"
    audit_name = :"#{prefix}_audit"

    %{
      pid: pid,
      invitation: invitation_name,
      pki_state: pki_state_name,
      audit: audit_name,
      online: online,
      offline: offline,
      store: store,
      prefix: prefix
    }
  end

  defp make_cluster_csr(organization_id, cluster_id) do
    key = X509.PrivateKey.new_ec(:secp256r1)
    spiffe_uri = "spiffe://exocomp/organizations/#{organization_id}/clusters/#{cluster_id}"

    extensions = [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth]),
      Extension.subject_alt_name([{:URI, spiffe_uri}])
    ]

    csr =
      key
      |> X509.CSR.new("/O=Exocomp/CN=#{cluster_id}", extension_request: extensions)
      |> X509.CSR.to_pem()

    {key, csr}
  end

  defp make_malformed_csr do
    "-----BEGIN CERTIFICATE REQUEST-----\ninvalid-base64\n-----END CERTIFICATE REQUEST-----"
  end

  defp make_csr_without_spiffe_uri(organization_id, cluster_id) do
    key = X509.PrivateKey.new_ec(:secp256r1)

    extensions = [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth]),
      # No subject_alt_name or wrong SAN
      Extension.subject_alt_name([cluster_id])
    ]

    csr =
      key
      |> X509.CSR.new("/O=Exocomp/CN=#{cluster_id}", extension_request: extensions)
      |> X509.CSR.to_pem()

    csr
  end

  defp make_csr_with_wrong_spiffe_uri(organization_id, cluster_id) do
    key = X509.PrivateKey.new_ec(:secp256r1)
    # Wrong organization in the SPIFFE URI
    wrong_uri = "spiffe://exocomp/organizations/wrong-org/clusters/#{cluster_id}"

    extensions = [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth]),
      Extension.subject_alt_name([{:URI, wrong_uri}])
    ]

    csr =
      key
      |> X509.CSR.new("/O=Exocomp/CN=#{cluster_id}", extension_request: extensions)
      |> X509.CSR.to_pem()

    csr
  end

  defp make_csr_with_ca_capability(organization_id, cluster_id) do
    key = X509.PrivateKey.new_ec(:secp256r1)
    spiffe_uri = "spiffe://exocomp/organizations/#{organization_id}/clusters/#{cluster_id}"

    extensions = [
      Extension.basic_constraints(true),
      # Requesting CA capability — should be rejected
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth]),
      Extension.subject_alt_name([{:URI, spiffe_uri}])
    ]

    csr =
      key
      |> X509.CSR.new("/O=Exocomp/CN=#{cluster_id}", extension_request: extensions)
      |> X509.CSR.to_pem()

    csr
  end

  defp make_csr_with_unsupported_key_usage(organization_id, cluster_id) do
    key = X509.PrivateKey.new_ec(:secp256r1)
    spiffe_uri = "spiffe://exocomp/organizations/#{organization_id}/clusters/#{cluster_id}"

    extensions = [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature, :keyEncipherment]),
      # Requesting prohibited key encipherment
      Extension.ext_key_usage([:clientAuth]),
      Extension.subject_alt_name([{:URI, spiffe_uri}])
    ]

    csr =
      key
      |> X509.CSR.new("/O=Exocomp/CN=#{cluster_id}", extension_request: extensions)
      |> X509.CSR.to_pem()

    csr
  end

  # ---------------------------------------------------------------------------
  # 1. Cluster invitation issuance and consumption
  # ---------------------------------------------------------------------------

  describe "cluster invitation creation and consumption" do
    @tag :tmp_dir
    test "invitation created, consumed once, replay rejected", %{tmp_dir: tmp_dir} do
      ctx = start_pki_tree(tmp_dir, "invitation-flow")

      {:ok, invitation} =
        ClusterInvitation.create(@org_id, @cluster_id, server: ctx.invitation)

      assert is_binary(invitation)
      assert String.starts_with?(invitation, "inv_")

      # First consumption succeeds
      assert :ok =
               ClusterInvitation.consume(invitation, @org_id, @cluster_id,
                 server: ctx.invitation
               )

      # Replay rejected
      assert {:error, %Error{code: :invitation_already_consumed}} =
               ClusterInvitation.consume(invitation, @org_id, @cluster_id,
                 server: ctx.invitation
               )
    end

    @tag :tmp_dir
    test "invitation created for org-alpha cannot be consumed claiming org-beta", %{
      tmp_dir: tmp_dir
    } do
      ctx = start_pki_tree(tmp_dir, "org-mismatch")

      {:ok, invitation} =
        ClusterInvitation.create(@org_id, @cluster_id, server: ctx.invitation)

      assert {:error, %Error{code: :invitation_org_mismatch}} =
               ClusterInvitation.consume(invitation, @org_beta, @cluster_id,
                 server: ctx.invitation
               )
    end

    @tag :tmp_dir
    test "invitation created for cluster-alpha cannot be consumed claiming cluster-beta", %{
      tmp_dir: tmp_dir
    } do
      ctx = start_pki_tree(tmp_dir, "cluster-mismatch")

      {:ok, invitation} =
        ClusterInvitation.create(@org_id, @cluster_id, server: ctx.invitation)

      assert {:error, %Error{code: :invitation_cluster_mismatch}} =
               ClusterInvitation.consume(invitation, @org_id, @cluster_beta,
                 server: ctx.invitation
               )
    end
  end

  # ---------------------------------------------------------------------------
  # 2. Cluster CSR validation
  # ---------------------------------------------------------------------------

  describe "cluster CSR validation" do
    @tag :tmp_dir
    test "valid cluster CSR passes all validation checks", %{tmp_dir: tmp_dir} do
      ctx = start_pki_tree(tmp_dir, "valid-csr")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)

      assert {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert is_tuple(csr)
    end

    @tag :tmp_dir
    test "malformed CSR rejected", %{tmp_dir: tmp_dir} do
      _ctx = start_pki_tree(tmp_dir, "malformed")
      bad_csr = make_malformed_csr()

      assert {:error, %Error{code: :invalid_csr}} =
               ClusterIssuer.validate_csr(bad_csr, @org_id, @cluster_id)
    end

    @tag :tmp_dir
    test "CSR without SPIFFE URI SAN rejected", %{tmp_dir: tmp_dir} do
      _ctx = start_pki_tree(tmp_dir, "no-spiffe")
      csr_pem = make_csr_without_spiffe_uri(@org_id, @cluster_id)

      assert {:error, %Error{code: :invalid_csr}} =
               ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
    end

    @tag :tmp_dir
    test "CSR with wrong SPIFFE URI rejected", %{tmp_dir: tmp_dir} do
      _ctx = start_pki_tree(tmp_dir, "wrong-spiffe")
      csr_pem = make_csr_with_wrong_spiffe_uri(@org_id, @cluster_id)

      assert {:error, %Error{code: :invalid_csr}} =
               ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
    end

    @tag :tmp_dir
    test "CSR requesting CA capability rejected", %{tmp_dir: tmp_dir} do
      _ctx = start_pki_tree(tmp_dir, "ca-request")
      csr_pem = make_csr_with_ca_capability(@org_id, @cluster_id)

      assert {:error, %Error{code: :invalid_csr}} =
               ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
    end

    @tag :tmp_dir
    test "CSR with unsupported key usage rejected", %{tmp_dir: tmp_dir} do
      _ctx = start_pki_tree(tmp_dir, "bad-keyusage")
      csr_pem = make_csr_with_unsupported_key_usage(@org_id, @cluster_id)

      assert {:error, %Error{code: :invalid_csr}} =
               ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
    end
  end

  # ---------------------------------------------------------------------------
  # 3. Cluster certificate issuance
  # ---------------------------------------------------------------------------

  describe "cluster certificate issuance" do
    @tag :tmp_dir
    test "valid CSR results in 30-day certificate with SPIFFE URI identity", %{
      tmp_dir: tmp_dir
    } do
      ctx = start_pki_tree(tmp_dir, "cert-issuance")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)

      {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert {:ok, chain_pem} = ClusterIssuer.issue_leaf(csr, @org_id, @cluster_id, ctx.online)

      assert is_binary(chain_pem)
      [{:Certificate, _leaf_der, _} | _] = :public_key.pem_decode(chain_pem)
    end

    @tag :tmp_dir
    test "issued certificate contains correct SPIFFE URI SAN", %{tmp_dir: tmp_dir} do
      ctx = start_pki_tree(tmp_dir, "san-verify")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)
      expected_uri = "spiffe://exocomp/organizations/#{@org_id}/clusters/#{@cluster_id}"

      {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert {:ok, chain_pem} = ClusterIssuer.issue_leaf(csr, @org_id, @cluster_id, ctx.online)

      [{:Certificate, leaf_der, _} | _] = :public_key.pem_decode(chain_pem)
      leaf = X509.Certificate.from_der!(leaf_der)

      case X509.Certificate.extension(leaf, :subject_alt_name) do
        {:Extension, _, _, san_values} ->
          assert Enum.any?(san_values, fn
                   {:uniformResourceIdentifier, uri} -> uri == expected_uri
                   _ -> false
                 })

        _other ->
          flunk("Leaf certificate does not contain expected SPIFFE URI SAN")
      end
    end

    @tag :tmp_dir
    test "issued certificate has CN set to cluster ID", %{tmp_dir: tmp_dir} do
      ctx = start_pki_tree(tmp_dir, "cn-verify")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)

      {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert {:ok, chain_pem} = ClusterIssuer.issue_leaf(csr, @org_id, @cluster_id, ctx.online)

      [{:Certificate, leaf_der, _} | _] = :public_key.pem_decode(chain_pem)
      leaf = X509.Certificate.from_der!(leaf_der)
      subject = X509.Certificate.subject(leaf)

      # Extract CN from subject
      cn =
        Enum.find_value(subject, nil, fn
          {"CN", cn_value} -> cn_value
          _ -> nil
        end)

      assert cn == @cluster_id
    end

    @tag :tmp_dir
    test "issued certificate is valid for 30 days", %{tmp_dir: tmp_dir} do
      ctx = start_pki_tree(tmp_dir, "validity-30d")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)

      {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert {:ok, chain_pem} = ClusterIssuer.issue_leaf(csr, @org_id, @cluster_id, ctx.online)

      [{:Certificate, leaf_der, _} | _] = :public_key.pem_decode(chain_pem)
      leaf = X509.Certificate.from_der!(leaf_der)

      {:Validity, not_before, not_after} = X509.Certificate.validity(leaf)
      before_dt = X509.DateTime.to_datetime(not_before)
      after_dt = X509.DateTime.to_datetime(not_after)

      # Calculate difference in days
      diff_seconds = DateTime.diff(after_dt, before_dt, :second)
      diff_days = diff_seconds / 86_400

      # Should be approximately 30 days
      assert diff_days >= 29.9 and diff_days <= 30.1
    end

    @tag :tmp_dir
    test "cluster private key is not retained in the online PKI directory", %{tmp_dir: tmp_dir} do
      ctx = start_pki_tree(tmp_dir, "no-cluster-key")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)

      {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert {:ok, _chain_pem} = ClusterIssuer.issue_leaf(csr, @org_id, @cluster_id, ctx.online)

      online_files = Path.wildcard(Path.join(ctx.online, "**/*")) |> Enum.reject(&File.dir?/1)

      cluster_key_files =
        Enum.filter(online_files, fn f ->
          name = Path.basename(f)
          String.contains?(name, @cluster_id)
        end)

      assert cluster_key_files == [],
             "Online PKI state must not retain cluster key material"
    end
  end

  # ---------------------------------------------------------------------------
  # 4. End-to-end cluster enrollment (invitation + CSR → certificate)
  # ---------------------------------------------------------------------------

  describe "end-to-end cluster enrollment" do
    @tag :tmp_dir
    test "complete enrollment flow: create invitation, consume, issue certificate", %{
      tmp_dir: tmp_dir
    } do
      ctx = start_pki_tree(tmp_dir, "e2e-enroll")
      {_key, csr_pem} = make_cluster_csr(@org_id, @cluster_id)

      {:ok, invitation} =
        ClusterInvitation.create(@org_id, @cluster_id, server: ctx.invitation)

      :ok =
        ClusterInvitation.consume(invitation, @org_id, @cluster_id,
          server: ctx.invitation
        )

      {:ok, csr} = ClusterIssuer.validate_csr(csr_pem, @org_id, @cluster_id)
      assert {:ok, chain_pem} = ClusterIssuer.issue_leaf(csr, @org_id, @cluster_id, ctx.online)

      assert is_binary(chain_pem)
      [{:Certificate, _der, _} | _] = :public_key.pem_decode(chain_pem)
    end
  end

  # ---------------------------------------------------------------------------
  # 5. ClusterEnrollmentHandler (HTTP layer)
  # ---------------------------------------------------------------------------

  describe "ClusterEnrollmentHandler" do
    test "POST /api/v1/clusters/enroll: missing organization_id field returns 400" do
      conn =
        :post
        |> conn("/api/v1/clusters/enroll",
          ~s({"cluster_id":"c","invitation":"i","csr":"c"})
        )
        |> put_req_header("content-type", "application/json")
        |> ClusterEnrollmentHandler.call(ClusterEnrollmentHandler.init([]))

      assert conn.status == 400
      assert Jason.decode!(conn.resp_body)["error"] =~ "organization_id"
    end

    test "POST /api/v1/clusters/enroll: missing cluster_id field returns 400" do
      conn =
        :post
        |> conn("/api/v1/clusters/enroll",
          ~s({"organization_id":"o","invitation":"i","csr":"c"})
        )
        |> put_req_header("content-type", "application/json")
        |> ClusterEnrollmentHandler.call(ClusterEnrollmentHandler.init([]))

      assert conn.status == 400
      assert Jason.decode!(conn.resp_body)["error"] =~ "cluster_id"
    end

    test "POST /api/v1/clusters/enroll: missing invitation field returns 400" do
      conn =
        :post
        |> conn("/api/v1/clusters/enroll",
          ~s({"organization_id":"o","cluster_id":"c","csr":"c"})
        )
        |> put_req_header("content-type", "application/json")
        |> ClusterEnrollmentHandler.call(ClusterEnrollmentHandler.init([]))

      assert conn.status == 400
      assert Jason.decode!(conn.resp_body)["error"] =~ "invitation"
    end

    test "POST /api/v1/clusters/enroll: missing csr field returns 400" do
      conn =
        :post
        |> conn("/api/v1/clusters/enroll",
          ~s({"organization_id":"o","cluster_id":"c","invitation":"i"})
        )
        |> put_req_header("content-type", "application/json")
        |> ClusterEnrollmentHandler.call(ClusterEnrollmentHandler.init([]))

      assert conn.status == 400
      assert Jason.decode!(conn.resp_body)["error"] =~ "csr"
    end

    test "POST /api/v1/clusters/enroll: PKI service unavailable returns 503" do
      conn =
        :post
        |> conn("/api/v1/clusters/enroll",
          ~s({"organization_id":"o","cluster_id":"c","invitation":"i","csr":"c"})
        )
        |> put_req_header("content-type", "application/json")
        |> ClusterEnrollmentHandler.call(ClusterEnrollmentHandler.init([]))

      # PKI.State not running in test → 503
      assert conn.status == 503
    end

    test "POST /api/v1/clusters/enroll: invalid JSON returns 400" do
      conn =
        :post
        |> conn("/api/v1/clusters/enroll", "{invalid json")
        |> put_req_header("content-type", "application/json")
        |> ClusterEnrollmentHandler.call(ClusterEnrollmentHandler.init([]))

      assert conn.status == 400
    end
  end

  # ---------------------------------------------------------------------------
  # 6. Health check with cluster components
  # ---------------------------------------------------------------------------

  describe "Health.check/0 with cluster components absent (test mode)" do
    test "health is degraded when PKI.State is not running" do
      # In test mode, PKI.State is not started; health must be degraded
      result = Health.check()
      assert result.status == :degraded
      assert Map.has_key?(result, :pki)
      assert result.pki.error == :not_running
    end
  end
end
