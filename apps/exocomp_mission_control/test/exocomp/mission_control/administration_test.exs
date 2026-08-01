# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdministrationTest do
  use ExUnit.Case, async: false

  alias Exocomp.MissionControl.{AdminInvitation, Administration, Identity.Operator}

  setup do
    Administration.reset!()
    :ok
  end

  defp admin(organization_id),
    do: %Operator{sub: "admin-#{organization_id}", organization_id: organization_id, role: :admin}

  describe "invitations" do
    test "returns plaintext once, stores only its digest, and consumes atomically" do
      assert {:ok, %AdminInvitation{} = invitation, token} =
               Administration.create_invitation(admin("org-a"), %{
                 "cluster_name" => "edge-a",
                 "expires_in_days" => "7"
               })

      assert is_binary(token)
      refute Map.has_key?(invitation, :token)
      refute inspect(invitation) =~ token
      assert {:ok, public} = Administration.consume_invitation("org-a", token)
      assert public.consumed_at

      assert {:error, :invalid_or_expired_invitation} =
               Administration.consume_invitation("org-a", token)
    end

    test "does not list or mutate another organization's invitation" do
      assert {:ok, _invitation, _token} =
               Administration.create_invitation(admin("org-a"), %{"cluster_name" => "edge-a"})

      assert {:ok, []} = Administration.list_invitations(admin("org-b"))

      assert {:error, :cross_organization} =
               Administration.create_invitation(admin("org-a"), "org-b", %{
                 "cluster_name" => "edge-b"
               })
    end
  end

  describe "clusters" do
    test "revocation records the administrator action and never stores key material" do
      assert {:ok, cluster} =
               Administration.register_cluster(admin("org-a"), %{
                 "id" => "cluster-a",
                 "name" => "edge-a",
                 "status" => "connected",
                 "certificate_serial" => "serial-a",
                 "certificate_fingerprint" => "sha256:a",
                 "private_key" => "must-not-be-stored"
               })

      refute Map.has_key?(cluster, :private_key)

      assert {:ok, %{certificate_status: :revoked}, action} =
               Administration.revoke_cluster(admin("org-a"), "org-a", cluster.id)

      assert action.action == "cluster.revoked"
      assert action.operator_sub == "admin-org-a"

      assert {:error, :already_revoked} =
               Administration.revoke_cluster(admin("org-a"), "org-a", cluster.id)
    end

    test "organization isolation prevents a foreign administrator from revoking" do
      assert {:ok, cluster} =
               Administration.register_cluster(admin("org-a"), %{
                 "id" => "cluster-a",
                 "name" => "edge-a"
               })

      assert {:error, :cross_organization} =
               Administration.revoke_cluster(admin("org-b"), "org-a", cluster.id)

      assert {:ok, []} = Administration.list_clusters(admin("org-b"))
    end
  end

  describe "role mappings and retention" do
    test "rejects invalid OIDC roles" do
      assert {:error, :invalid_role} =
               Administration.create_role_mapping(admin("org-a"), %{
                 "claim" => "groups:unknown",
                 "role" => "root"
               })
    end

    test "rejects retention values outside the documented bounds" do
      assert {:error, {:retention_out_of_bounds, "status_history_days", 1, 365}} =
               Administration.update_retention(admin("org-a"), %{"status_history_days" => 0})

      assert {:error, {:retention_out_of_bounds, "incident_days", 30, 3650}} =
               Administration.update_retention(admin("org-a"), %{"incident_days" => 3651})

      assert {:ok, retention} =
               Administration.update_retention(admin("org-a"), %{
                 "status_history_days" => "365",
                 "incident_days" => "3650"
               })

      assert retention.status_history_days == 365
      assert retention.incident_days == 3650
    end
  end
end
