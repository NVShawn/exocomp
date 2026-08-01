# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Exocomp.MissionControl.{Administration, Identity.Operator}

  @endpoint Exocomp.MissionControl.Endpoint

  setup do
    Administration.reset!()
    :ok
  end

  defp operator(role, organization_id \\ "org-a") do
    %Operator{
      sub: "#{role}-#{organization_id}",
      organization_id: organization_id,
      role: role,
      display_name: "Test #{role}"
    }
  end

  defp session_conn(%Operator{} = principal) do
    build_conn()
    |> init_test_session(%{
      operator_id: principal.sub,
      operator_role: principal.role,
      organization_id: principal.organization_id,
      operator_name: principal.display_name
    })
  end

  test "only an administrator can access administration" do
    assert {:ok, _view, html} = live(session_conn(operator(:admin)), "/admin")
    assert html =~ "Administration"

    assert {:error, {:redirect, %{to: "/forbidden"}}} =
             live(session_conn(operator(:viewer)), "/admin")

    assert {:error, {:redirect, %{to: "/forbidden"}}} =
             live(session_conn(operator(:operator)), "/admin")
  end

  test "invitation plaintext is rendered once and cleared on navigation" do
    {:ok, view, _html} = live(session_conn(operator(:admin)), "/admin/invitations")

    html =
      view
      |> form("#invitation-form", invitation: %{cluster_name: "edge-a", expires_in_days: "7"})
      |> render_submit()

    [_, token] = Regex.run(~r/<code[^>]*>([^<]+)<\/code>/, html)
    assert byte_size(token) > 20

    html =
      view
      |> element("a", "Clusters & certificates")
      |> render_click()

    refute html =~ token
    refute html =~ "invitation-plaintext"
  end

  test "revocation requires confirmation before recording the action" do
    assert {:ok, cluster} =
             Administration.register_cluster(operator(:admin), %{
               "id" => "cluster-a",
               "name" => "edge-a",
               "certificate_fingerprint" => "sha256:a"
             })

    {:ok, view, _html} = live(session_conn(operator(:admin)), "/admin/clusters")
    html = view |> element("#revoke-cluster-#{cluster.id}") |> render_click()
    assert html =~ "Confirm cluster revocation"
    assert {:ok, []} = Administration.list_admin_actions(operator(:admin))

    html = view |> element("#confirm-cluster-revocation") |> render_click()
    assert html =~ "administrative action was recorded"
    assert {:ok, [action]} = Administration.list_admin_actions(operator(:admin))
    assert action.action == "cluster.revoked"
  end

  test "admin LiveView does not render private key fields" do
    assert {:ok, _cluster} =
             Administration.register_cluster(operator(:admin), %{
               "id" => "cluster-a",
               "name" => "edge-a",
               "private_key" => "private-key-material",
               "certificate_pem" => "certificate-body"
             })

    {:ok, _view, html} = live(session_conn(operator(:admin)), "/admin/clusters")
    refute html =~ "private-key-material"
    refute html =~ "certificate-body"
    refute html =~ "BEGIN PRIVATE KEY"
  end
end
