# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterInvitationTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Exocomp.Coordinator.{ClusterInvitation, ClusterInvitationStore, Error}
  alias Exocomp.Coordinator.CoordinatorRouter
  alias Exocomp.Coordinator.Handlers.ClusterInvitationHandler

  @organization_id "org-a"
  @other_organization_id "org-b"

  defp unique_name(prefix), do: String.to_atom("#{prefix}_#{System.unique_integer([:positive])}")

  defp clock(initial \\ 1_000) do
    agent = start_supervised!({Agent, fn -> initial end})
    now = fn -> Agent.get(agent, & &1) end
    set = fn value -> Agent.update(agent, fn _ -> value end) end
    {now, set}
  end

  defp start_store(opts \\ []) do
    name = unique_name("cluster_invitation_store")
    start_supervised!({ClusterInvitationStore, Keyword.put(opts, :name, name)})
    name
  end

  defp issue(store, attrs \\ %{}) do
    attrs = if is_map(attrs), do: attrs, else: Map.new(attrs)

    ClusterInvitationStore.create(
      Map.merge(%{organization_id: @organization_id, name: "cluster-a"}, attrs),
      server: store
    )
  end

  defp admin_conn(body, store, organization_id \\ @organization_id, role \\ :admin) do
    :post
    |> conn("/api/v1/cluster-invitations", Jason.encode!(body))
    |> put_req_header("content-type", "application/json")
    |> assign(:current_user, %{organization_id: organization_id, role: role})
    |> ClusterInvitationHandler.call(ClusterInvitationHandler.init(server: store))
  end

  test "creates an organization-scoped invitation and never persists its plaintext" do
    path =
      Path.join(System.tmp_dir!(), "cluster-invitations-#{System.unique_integer([:positive])}")

    store = start_store(store_path: path)

    assert {:ok, %ClusterInvitation{} = invitation, token} =
             issue(store, labels: %{"env" => "prod"})

    assert invitation.organization_id == @organization_id
    assert invitation.cluster_name == "cluster-a"
    assert invitation.labels == %{"env" => "prod"}
    assert invitation.token_digest == :crypto.hash(:sha256, token)
    refute Map.has_key?(Map.from_struct(invitation), :token)

    document = File.read!(Path.join(path, "cluster_invitations.json"))
    refute document =~ token
    assert document =~ Base.encode64(invitation.token_digest, padding: false)
  end

  test "rejects an expired invitation and does not allow a replay" do
    {now, set} = clock()
    store = start_store(now_fn: now, max_lifetime: 10)

    assert {:ok, _invitation, token} = issue(store)
    set.(1_010)

    assert {:error, %Error{code: :invitation_expired}} =
             ClusterInvitationStore.consume(token, @organization_id, server: store)

    assert {:error, %Error{code: :invitation_expired}} =
             ClusterInvitationStore.consume(token, @organization_id, server: store)
  end

  test "consumes once and rejects a second use" do
    store = start_store()
    assert {:ok, invitation, token} = issue(store)

    assert {:ok, %ClusterInvitation{consumed_at: consumed_at}} =
             ClusterInvitationStore.consume(token, @organization_id, server: store)

    assert is_integer(consumed_at)

    assert {:error, %Error{code: :invitation_already_consumed}} =
             ClusterInvitationStore.consume(token, @organization_id, server: store)

    assert {:ok, %ClusterInvitation{consumed_at: ^consumed_at}} =
             ClusterInvitationStore.get(invitation.id, @organization_id, server: store)
  end

  test "wrong organization cannot consume and does not burn the invitation" do
    store = start_store()
    assert {:ok, _invitation, token} = issue(store)

    assert {:error, %Error{code: :organization_mismatch}} =
             ClusterInvitationStore.consume(token, @other_organization_id, server: store)

    assert {:ok, _invitation} =
             ClusterInvitationStore.consume(token, @organization_id, server: store)
  end

  test "wrong cluster cannot consume and does not burn the invitation" do
    store = start_store()
    assert {:ok, invitation, token} = issue(store)

    assert {:error, %Error{code: :cluster_mismatch}} =
             ClusterInvitationStore.consume(token, @organization_id, "other-cluster", server: store)

    assert {:ok, _invitation} =
             ClusterInvitationStore.consume(token, @organization_id, invitation.cluster_id, server: store)
  end

  test "cluster names are unique per organization" do
    store = start_store()
    assert {:ok, _invitation, _token} = issue(store)

    assert {:error, %Error{code: :duplicate_cluster_name}} = issue(store)

    assert {:ok, _invitation, _token} =
             ClusterInvitationStore.create(
               %{organization_id: @other_organization_id, name: "cluster-a"},
               server: store
             )
  end

  test "concurrent consumption succeeds exactly once" do
    store = start_store()
    assert {:ok, _invitation, token} = issue(store)

    results =
      1..16
      |> Enum.map(fn _ ->
        Task.async(fn ->
          ClusterInvitationStore.consume(token, @organization_id, server: store)
        end)
      end)
      |> Task.await_many(5_000)

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1

    assert Enum.count(results, &match?({:error, %Error{code: :invitation_already_consumed}}, &1)) ==
             15
  end

  describe "POST /api/v1/cluster-invitations" do
    test "admin receives the one-time token" do
      store = start_store()

      response =
        admin_conn(%{"cluster_name" => "cluster-a", "labels" => %{"tier" => "edge"}}, store)

      assert response.status == 201
      body = Jason.decode!(response.resp_body)
      assert is_binary(body["token"])
      assert body["cluster_name"] == "cluster-a"
      assert body["organization_id"] == @organization_id
    end

    test "coordinator router dispatches the API route" do
      store = start_store()

      response =
        :post
        |> conn("/api/v1/cluster-invitations", Jason.encode!(%{"cluster_name" => "cluster-a"}))
        |> put_req_header("content-type", "application/json")
        |> CoordinatorRouter.call(
          CoordinatorRouter.init(
            server: store,
            auth_context: %{organization_id: @organization_id, role: :admin}
          )
        )

      assert response.status == 201
      assert is_binary(Jason.decode!(response.resp_body)["token"])
    end

    test "viewer and operator are forbidden" do
      store = start_store()

      for role <- [:viewer, :operator] do
        response =
          admin_conn(%{"cluster_name" => "cluster-#{role}"}, store, @organization_id, role)

        assert response.status == 403
      end
    end

    test "missing authentication is rejected" do
      store = start_store()

      response =
        :post
        |> conn("/api/v1/cluster-invitations", Jason.encode!(%{"cluster_name" => "cluster-a"}))
        |> put_req_header("content-type", "application/json")
        |> ClusterInvitationHandler.call(ClusterInvitationHandler.init(server: store))

      assert response.status == 401
    end
  end
end
