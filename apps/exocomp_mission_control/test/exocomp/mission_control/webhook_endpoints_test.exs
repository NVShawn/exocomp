# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpointsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{
    Authorization,
    Identity.Operator,
    WebhookEndpoints,
    WebhookEndpoint
  }

  describe "create/3" do
    setup do
      # Configure the encryption module with a test master key
      key = :crypto.strong_rand_bytes(32)
      key_b64 = Base.encode64(key)

      Application.put_env(
        :exocomp_mission_control,
        Exocomp.MissionControl.WebhookEndpoints.Encryption,
        master_key: key_b64
      )

      on_exit(fn ->
        Application.delete_env(
          :exocomp_mission_control,
          Exocomp.MissionControl.WebhookEndpoints.Encryption
        )
      end)

      :ok
    end

    test "creates endpoint with encrypted secret on success" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin,
        display_name: "Admin User"
      }

      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened", "incident.resolved"]
      }

      assert {:ok, endpoint, plaintext_secret} =
               WebhookEndpoints.create(operator, "org-1", params)

      # Verify endpoint structure
      assert is_struct(endpoint, WebhookEndpoint)
      assert endpoint.organization_id == "org-1"
      assert endpoint.url == "https://example.com/webhooks"
      assert endpoint.subscribed_event_types == ["incident.opened", "incident.resolved"]
      assert endpoint.enabled == true
      assert endpoint.creator_operator_sub == "sub-123"
      assert is_binary(endpoint.id)
      assert is_binary(endpoint.encrypted_secret)
      assert is_binary(endpoint.secret_digest)
      assert endpoint.encrypted_secret_version == 1

      # Verify secret is returned plaintext and never stored
      assert is_binary(plaintext_secret)
      assert byte_size(plaintext_secret) > 0
      # Secret should be URL-safe base64
      assert String.match?(plaintext_secret, ~r/^[A-Za-z0-9_-]+$/)
    end

    test "rejects non-HTTPS URLs" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "http://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert {:error, :url_not_https} = WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects empty URL" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert {:error, :url_empty} = WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects missing URL" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{"subscribed_event_types" => ["incident.opened"]}

      assert {:error, :url_missing} = WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects empty event types list" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => []
      }

      assert {:error, :event_types_empty} = WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects unknown event types" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened", "unknown.event"]
      }

      assert {:error, {:event_type_unknown, "unknown.event"}} =
               WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects loopback IP" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "https://localhost:8080/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert {:error, :destination_is_loopback} =
               WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects private IP ranges" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "https://192.168.1.100/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert {:error, :destination_is_private_ip} =
               WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects link-local IP" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "https://169.254.1.1/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert {:error, :destination_is_link_local} =
               WebhookEndpoints.create(operator, "org-1", params)
    end

    test "rejects insufficient role (viewer)" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :viewer
      }

      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.create(operator, "org-1", params)
      end)
    end

    test "rejects insufficient role (operator)" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :operator
      }

      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.create(operator, "org-1", params)
      end)
    end

    test "rejects cross-organization access" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.create(operator, "org-2", params)
      end)
    end

    test "rejects nil operator" do
      params = %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened"]
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.create(nil, "org-1", params)
      end)
    end
  end

  describe "update/4" do
    test "returns error for non-existent endpoint" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{"subscribed_event_types" => ["incident.opened"]}

      assert {:error, :endpoint_not_found} =
               WebhookEndpoints.update(operator, "org-1", "endpoint-1", params)
    end

    test "rejects insufficient role" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :viewer
      }

      params = %{"subscribed_event_types" => ["incident.opened"]}

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.update(operator, "org-1", "endpoint-1", params)
      end)
    end

    test "rejects cross-organization access" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      params = %{"subscribed_event_types" => ["incident.opened"]}

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.update(operator, "org-2", "endpoint-1", params)
      end)
    end
  end

  describe "disable/3" do
    test "returns error for non-existent endpoint" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      assert {:error, :endpoint_not_found} =
               WebhookEndpoints.disable(operator, "org-1", "endpoint-1")
    end

    test "rejects insufficient role" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :operator
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.disable(operator, "org-1", "endpoint-1")
      end)
    end

    test "rejects cross-organization access" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.disable(operator, "org-2", "endpoint-1")
      end)
    end
  end

  describe "rotate_secret/3" do
    test "returns error for non-existent endpoint" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      assert {:error, :endpoint_not_found} =
               WebhookEndpoints.rotate_secret(operator, "org-1", "endpoint-1")
    end

    test "rejects insufficient role" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :viewer
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.rotate_secret(operator, "org-1", "endpoint-1")
      end)
    end

    test "rejects cross-organization access" do
      operator = %Operator{
        sub: "sub-123",
        organization_id: "org-1",
        role: :admin
      }

      assert_raise(Authorization.ForbiddenError, fn ->
        WebhookEndpoints.rotate_secret(operator, "org-2", "endpoint-1")
      end)
    end
  end
end
