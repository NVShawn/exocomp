# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpointsTest do
  use ExUnit.Case, async: false

  alias Exocomp.MissionControl.{
    Authorization,
    Identity.Operator,
    WebhookEndpoint,
    WebhookEndpoints
  }

  alias Exocomp.MissionControl.WebhookEndpoints.Encryption

  setup do
    previous = Application.get_env(:exocomp_mission_control, Encryption)
    key = :crypto.strong_rand_bytes(32) |> Base.encode64()
    Application.put_env(:exocomp_mission_control, Encryption, master_key: key)

    on_exit(fn ->
      if is_nil(previous),
        do: Application.delete_env(:exocomp_mission_control, Encryption),
        else: Application.put_env(:exocomp_mission_control, Encryption, previous)
    end)

    :ok
  end

  describe "create/3 input and authorization boundary" do
    test "rejects non-HTTPS URLs before persistence" do
      assert {:error, :url_not_https} =
               WebhookEndpoints.create(admin(), "org-1", valid_params(url: "http://8.8.8.8/hook"))
    end

    test "rejects endpoint credentials, empty subscriptions, unknown events, and unsafe destinations" do
      assert {:error, :url_invalid} =
               WebhookEndpoints.create(
                 admin(),
                 "org-1",
                 valid_params(url: "https://credential@8.8.8.8/hook")
               )

      assert {:error, :url_invalid} =
               WebhookEndpoints.create(
                 admin(),
                 "org-1",
                 valid_params(url: "https://8.8.8.8/hook?token=credential")
               )

      assert {:error, :event_types_empty} =
               WebhookEndpoints.create(admin(), "org-1", valid_params(events: []))

      assert {:error, {:event_type_unknown, "unknown.event"}} =
               WebhookEndpoints.create(admin(), "org-1", valid_params(events: ["unknown.event"]))

      assert {:error, :destination_is_loopback} =
               WebhookEndpoints.create(
                 admin(),
                 "org-1",
                 valid_params(url: "https://127.0.0.1/hook")
               )

      assert {:error, :destination_is_private_ip} =
               WebhookEndpoints.create(
                 admin(),
                 "org-1",
                 valid_params(url: "https://192.168.1.10/hook")
               )
    end

    test "fails closed when the deployment master key is unavailable" do
      Application.delete_env(:exocomp_mission_control, Encryption)

      assert {:error, :master_key_unavailable} =
               WebhookEndpoints.create(admin(), "org-1", valid_params())
    end

    test "requires an administrator in the target organization" do
      for role <- [:viewer, :operator] do
        assert_raise Authorization.ForbiddenError, fn ->
          WebhookEndpoints.create(%{admin() | role: role}, "org-1", valid_params())
        end
      end

      assert_raise Authorization.ForbiddenError, fn ->
        WebhookEndpoints.create(admin(), "org-2", valid_params())
      end

      assert_raise Authorization.ForbiddenError, fn ->
        WebhookEndpoints.create(nil, "org-1", valid_params())
      end
    end
  end

  describe "other mutation authorization boundaries" do
    test "update, disable, and rotation check the role before lookup" do
      viewer = %{admin() | role: :viewer}

      assert_raise Authorization.ForbiddenError, fn ->
        WebhookEndpoints.update(viewer, "org-1", Ecto.UUID.generate(), %{"enabled" => false})
      end

      assert_raise Authorization.ForbiddenError, fn ->
        WebhookEndpoints.disable(viewer, "org-1", Ecto.UUID.generate())
      end

      assert_raise Authorization.ForbiddenError, fn ->
        WebhookEndpoints.rotate_secret(viewer, "org-1", Ecto.UUID.generate())
      end
    end
  end

  test "endpoint inspection redacts encrypted material and has no plaintext field" do
    endpoint = %WebhookEndpoint{encrypted_secret: "ciphertext", url: "https://8.8.8.8/hook"}

    refute inspect(endpoint) =~ "ciphertext"
    refute Map.has_key?(endpoint, :secret)
  end

  defp admin do
    %Operator{sub: "admin-sub", organization_id: "org-1", role: :admin, display_name: "Admin"}
  end

  defp valid_params(overrides \\ []) do
    %{
      "url" => Keyword.get(overrides, :url, "https://8.8.8.8/hook"),
      "subscribed_event_types" => Keyword.get(overrides, :events, ["incident.opened"])
    }
  end
end