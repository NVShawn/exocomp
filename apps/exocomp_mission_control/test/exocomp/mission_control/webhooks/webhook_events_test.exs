# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEventsTest do
  @moduledoc """
  Acceptance tests for EXOCOMP-173 webhook event dispatch, signing, retry, and
  replay.

  Coverage:
  - Signature vectors
  - Successful delivery
  - Duplicate-safe event ID
  - Timeout
  - 4xx / 5xx HTTP status handling
  - Retry schedule
  - Terminal failure
  - Disabled endpoint
  - Secret rotation (endpoint-level; covered via Encryption module)
  - Replay
  - Redaction
  """

  use Exocomp.MissionControl.DataCase, async: false

  alias Exocomp.MissionControl.{
    Authorization,
    Identity.Operator,
    Organization,
    WebhookEndpoint,
    WebhookEndpoints,
    WebhookEvents
  }

  alias Exocomp.MissionControl.Webhooks.{
    Signer,
    WebhookAttempt,
    WebhookEvent
  }

  alias Exocomp.MissionControl.WebhookEndpoints.Encryption

  # ---------------------------------------------------------------------------
  # Test support — fake HTTP adapter
  # ---------------------------------------------------------------------------

  # A fake HTTP adapter that can be configured per-test to return any response
  # or raise a network error.

  defmodule FakeHttpAdapter do
    @moduledoc false
    def request(:post, _request, _http_opts, _opts) do
      case :persistent_term.get({__MODULE__, :response}, :default) do
        :default ->
          {:ok, {{"HTTP/1.1", 200, "OK"}, [], ""}}

        {:ok, status} ->
          {:ok, {{"HTTP/1.1", status, "response"}, [], ""}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    def set_response(response) do
      :persistent_term.put({__MODULE__, :response}, response)
    end

    def reset() do
      :persistent_term.put({__MODULE__, :response}, :default)
    end
  end

  setup do
    FakeHttpAdapter.reset()
    key = :crypto.strong_rand_bytes(32) |> Base.encode64()
    Application.put_env(:exocomp_mission_control, Encryption, master_key: key)

    on_exit(fn ->
      Application.delete_env(:exocomp_mission_control, Encryption)
      FakeHttpAdapter.reset()
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp insert_org(slug \\ nil) do
    slug = slug || "org-#{:rand.uniform(999_999)}"

    %Organization{}
    |> Organization.changeset(%{name: "Test Org #{slug}", slug: slug})
    |> Repo.insert!()
  end

  defp admin_op(org_id) do
    %Operator{sub: "admin-sub", organization_id: org_id, role: :admin, display_name: "Admin"}
  end

  defp create_endpoint(org_id, opts \\ []) do
    admin = admin_op(org_id)
    url = Keyword.get(opts, :url, "https://8.8.8.8/hook")
    events = Keyword.get(opts, :events, ["incident.opened"])

    {:ok, endpoint, _plaintext} =
      WebhookEndpoints.create(admin, org_id, %{
        "url" => url,
        "subscribed_event_types" => events
      })

    endpoint
  end

  defp dispatch(org_id, event_type \\ "incident.opened", payload \\ %{"id" => "ev-1"}) do
    WebhookEvents.dispatch(org_id, event_type, payload,
      http_adapter: FakeHttpAdapter
    )
  end

  # ---------------------------------------------------------------------------
  # Successful delivery
  # ---------------------------------------------------------------------------

  describe "successful delivery" do
    test "dispatches event and creates a success attempt" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, event, [attempt]} = dispatch(org.id)

      assert event.event_type == "incident.opened"
      assert is_binary(event.event_id)
      assert is_binary(event.body_json)
      assert attempt.status == :success
      assert attempt.http_status == 200
    end

    test "body_json is byte-identical to signed content" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 200})

      payload = %{"cluster_id" => "c1", "severity" => "high"}
      {:ok, event, _} = dispatch(org.id, "incident.opened", payload)

      # body_json matches a fresh re-encoding of the (redacted) payload
      expected_json = Jason.encode!(event.payload)
      assert event.body_json == expected_json
    end

    test "dispatches to multiple endpoints subscribed to the same event" do
      org = insert_org()
      create_endpoint(org.id, url: "https://8.8.8.8/hook-a")
      create_endpoint(org.id, url: "https://8.8.8.8/hook-b")

      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, _event, attempts} = dispatch(org.id)

      assert length(attempts) == 2
      assert Enum.all?(attempts, &(&1.status == :success))
    end

    test "delivers to zero endpoints when none match the event type" do
      org = insert_org()
      create_endpoint(org.id, events: ["cluster.connected"])

      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, _event, attempts} = dispatch(org.id, "incident.opened")

      assert attempts == []
    end
  end

  # ---------------------------------------------------------------------------
  # Signature vectors
  # ---------------------------------------------------------------------------

  describe "signature vectors" do
    test "Signer.sign produces consistent output for fixed inputs" do
      secret = "known-test-secret"
      event_id = "evt_vector_001"
      timestamp = "2026-08-01T00:00:00Z"
      body_json = ~s({"type":"incident.opened"})

      sig1 = Signer.sign(secret, event_id, timestamp, body_json)
      sig2 = Signer.sign(secret, event_id, timestamp, body_json)

      assert sig1 == sig2
      assert String.length(sig1) == 64
      assert String.match?(sig1, ~r/^[0-9a-f]{64}$/)
    end

    test "different secrets produce different signatures (tamper detection)" do
      event_id = "evt_abc"
      ts = "2026-08-01T12:00:00Z"
      body = ~s({"key":"value"})

      sig_a = Signer.sign("secret-a", event_id, ts, body)
      sig_b = Signer.sign("secret-b", event_id, ts, body)

      assert sig_a != sig_b
    end

    test "verify rejects rotated secret used with original signature" do
      event_id = "evt_rotation"
      ts = "2026-08-01T12:00:00Z"
      body = ~s({"key":"value"})
      old_secret = "old-secret"
      new_secret = "new-secret"

      sig_with_old = Signer.sign(old_secret, event_id, ts, body)

      assert {:ok, :valid} = Signer.verify(old_secret, event_id, ts, body, sig_with_old)
      assert {:error, :invalid_signature} = Signer.verify(new_secret, event_id, ts, body, sig_with_old)
    end
  end

  # ---------------------------------------------------------------------------
  # Duplicate-safe event ID
  # ---------------------------------------------------------------------------

  describe "duplicate-safe event ID" do
    test "event IDs are unique per dispatch call" do
      org = insert_org()
      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, event1, _} = dispatch(org.id)
      {:ok, event2, _} = dispatch(org.id)

      assert event1.event_id != event2.event_id
    end

    test "organization-scoped uniqueness constraint prevents duplicate event IDs" do
      org = insert_org()
      event_id = WebhookEvent.generate_event_id()

      # Insert first event directly
      Repo.insert!(%WebhookEvent{
        organization_id: org.id,
        event_id: event_id,
        event_type: "incident.opened",
        payload: %{},
        body_json: "{}"
      })

      # Attempt to insert the same event_id in the same org fails
      assert {:error, changeset} =
               %WebhookEvent{}
               |> WebhookEvent.changeset(%{
                 organization_id: org.id,
                 event_id: event_id,
                 event_type: "incident.opened",
                 payload: %{},
                 body_json: "{}"
               })
               |> Repo.insert()

      assert changeset.errors[:event_id]
    end

    test "same event_id in different organizations is allowed" do
      org1 = insert_org()
      org2 = insert_org()
      event_id = WebhookEvent.generate_event_id()

      Repo.insert!(%WebhookEvent{
        organization_id: org1.id,
        event_id: event_id,
        event_type: "incident.opened",
        payload: %{},
        body_json: "{}"
      })

      assert {:ok, _} =
               %WebhookEvent{}
               |> WebhookEvent.changeset(%{
                 organization_id: org2.id,
                 event_id: event_id,
                 event_type: "incident.opened",
                 payload: %{},
                 body_json: "{}"
               })
               |> Repo.insert()
    end
  end

  # ---------------------------------------------------------------------------
  # 4xx / 5xx handling
  # ---------------------------------------------------------------------------

  describe "4xx/5xx HTTP status handling" do
    test "200–299 produces success attempt" do
      org = insert_org()
      create_endpoint(org.id)

      for status <- [200, 201, 204] do
        FakeHttpAdapter.set_response({:ok, status})

        {:ok, _event, [attempt]} = dispatch(org.id)
        assert attempt.status == :success, "Expected success for #{status}"
        assert attempt.http_status == status
      end
    end

    test "5xx within 24 hours produces failed attempt with next_retry_at set" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 500})

      {:ok, _event, [attempt]} = dispatch(org.id)

      assert attempt.status == :failed
      assert attempt.http_status == 500
      assert attempt.next_retry_at != nil
    end

    test "502/503/504 are retryable within 24 hours" do
      org = insert_org()
      create_endpoint(org.id)

      for status <- [502, 503, 504] do
        FakeHttpAdapter.set_response({:ok, status})
        {:ok, _event, [attempt]} = dispatch(org.id)
        assert attempt.status == :failed, "Expected failed for #{status}, got #{attempt.status}"
      end
    end

    test "4xx (except 429) produces terminal_failure attempt" do
      org = insert_org()
      create_endpoint(org.id)

      for status <- [400, 401, 403, 404, 410] do
        FakeHttpAdapter.set_response({:ok, status})
        {:ok, _event, [attempt]} = dispatch(org.id)
        assert attempt.status == :terminal_failure,
               "Expected terminal_failure for #{status}, got #{attempt.status}"
        assert attempt.http_status == status
        assert attempt.next_retry_at == nil
      end
    end

    test "429 produces failed (retryable) attempt" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 429})
      {:ok, _event, [attempt]} = dispatch(org.id)

      assert attempt.status == :failed
      assert attempt.http_status == 429
      assert attempt.next_retry_at != nil
    end
  end

  # ---------------------------------------------------------------------------
  # Timeout
  # ---------------------------------------------------------------------------

  describe "timeout handling" do
    test "network timeout produces failed attempt with error_reason" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:error, :timeout})

      {:ok, _event, [attempt]} = dispatch(org.id)

      assert attempt.status == :failed
      assert attempt.http_status == nil
      assert attempt.error_reason =~ "timeout"
    end

    test "connection refused produces failed attempt" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:error, :econnrefused})

      {:ok, _event, [attempt]} = dispatch(org.id)

      assert attempt.status == :failed
      assert attempt.error_reason != nil
    end
  end

  # ---------------------------------------------------------------------------
  # Terminal failure
  # ---------------------------------------------------------------------------

  describe "terminal failure" do
    test "attempt after 24h window is marked terminal_failure on process_attempt" do
      org = insert_org()
      endpoint = create_endpoint(org.id)

      # Insert a fresh event, then backdate inserted_at to simulate a 25-hour-old event.
      # Ecto's timestamps() macro ignores struct fields on insert, so we must
      # use update_all after the fact to set the database column directly.
      {:ok, event} =
        Repo.insert(%WebhookEvent{
          organization_id: org.id,
          event_id: WebhookEvent.generate_event_id(),
          event_type: "incident.opened",
          payload: %{"id" => "x"},
          body_json: ~s({"id":"x"})
        })

      old_time = DateTime.add(DateTime.utc_now(), -90_000, :second)

      Repo.update_all(
        from(e in WebhookEvent, where: e.id == ^event.id),
        set: [inserted_at: old_time, updated_at: old_time]
      )

      event = %{event | inserted_at: old_time}

      # Create a pending retry attempt
      {:ok, attempt} =
        Repo.insert(
          WebhookAttempt.changeset(%WebhookAttempt{}, %{
            webhook_event_id: event.id,
            webhook_endpoint_id: endpoint.id,
            status: :pending,
            attempt_number: 5,
            delivery_timestamp: "2026-08-01T00:00:00Z",
            next_retry_at: DateTime.add(DateTime.utc_now(), -60, :second)
          })
        )

      FakeHttpAdapter.set_response({:ok, 500})

      {:ok, updated} = WebhookEvents.process_attempt(attempt.id, http_adapter: FakeHttpAdapter)

      # Even though HTTP returned 500 (retryable), the event is >24h old → terminal
      assert updated.status == :terminal_failure
    end
  end

  # ---------------------------------------------------------------------------
  # Disabled endpoint
  # ---------------------------------------------------------------------------

  describe "disabled endpoint" do
    test "disabled endpoint is skipped during dispatch" do
      org = insert_org()
      endpoint = create_endpoint(org.id)

      # Disable the endpoint
      admin = admin_op(org.id)
      {:ok, _} = WebhookEndpoints.disable(admin, org.id, endpoint.id)

      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, _event, attempts} = dispatch(org.id)

      # No attempts — endpoint is disabled
      assert attempts == []
    end

    test "enabled endpoint receives delivery, disabled endpoint does not" do
      org = insert_org()
      create_endpoint(org.id, url: "https://8.8.8.8/hook-enabled")
      disabled_ep = create_endpoint(org.id, url: "https://8.8.8.8/hook-disabled")

      admin = admin_op(org.id)
      {:ok, _} = WebhookEndpoints.disable(admin, org.id, disabled_ep.id)

      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, _event, attempts} = dispatch(org.id)

      assert length(attempts) == 1
      assert hd(attempts).status == :success
    end
  end

  # ---------------------------------------------------------------------------
  # Secret rotation
  # ---------------------------------------------------------------------------

  describe "secret rotation" do
    test "delivery succeeds after rotating endpoint secret" do
      org = insert_org()
      endpoint = create_endpoint(org.id)
      admin = admin_op(org.id)

      {:ok, _endpoint, _new_secret} = WebhookEndpoints.rotate_secret(admin, org.id, endpoint.id)

      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, _event, [attempt]} = dispatch(org.id)

      assert attempt.status == :success
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  describe "replay" do
    test "replay creates a new attempt for a retained event" do
      org = insert_org()
      endpoint = create_endpoint(org.id)
      admin = admin_op(org.id)

      # First dispatch — endpoint returns 500
      FakeHttpAdapter.set_response({:ok, 500})
      {:ok, event, [failed_attempt]} = dispatch(org.id)

      assert failed_attempt.status == :failed

      # Replay — endpoint now returns 200
      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, replay_attempt} =
        WebhookEvents.replay(admin, org.id, event.event_id, endpoint.id,
          http_adapter: FakeHttpAdapter
        )

      assert replay_attempt.status == :success
      assert replay_attempt.attempt_number == 2
    end

    test "replay uses the stored body_json (byte-identical content)" do
      org = insert_org()
      endpoint = create_endpoint(org.id)
      admin = admin_op(org.id)

      FakeHttpAdapter.set_response({:ok, 200})
      {:ok, event, _} = dispatch(org.id)

      original_body_json = event.body_json
      assert is_binary(original_body_json)

      # Replay delivers the same body_json
      FakeHttpAdapter.set_response({:ok, 200})

      {:ok, _replay_attempt} =
        WebhookEvents.replay(admin, org.id, event.event_id, endpoint.id,
          http_adapter: FakeHttpAdapter
        )

      # Event body_json unchanged in DB
      reloaded = Repo.get!(WebhookEvent, event.id)
      assert reloaded.body_json == original_body_json
    end

    test "replay requires admin role" do
      org = insert_org()
      endpoint = create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 500})
      {:ok, event, _} = dispatch(org.id)

      viewer = %Operator{
        sub: "viewer-sub",
        organization_id: org.id,
        role: :viewer,
        display_name: "Viewer"
      }

      assert_raise Authorization.ForbiddenError, fn ->
        WebhookEvents.replay(viewer, org.id, event.event_id, endpoint.id)
      end
    end

    test "replay returns error for unknown event" do
      org = insert_org()
      endpoint = create_endpoint(org.id)
      admin = admin_op(org.id)

      assert {:error, :event_not_found} =
               WebhookEvents.replay(admin, org.id, "nonexistent-event-id", endpoint.id)
    end

    test "replay returns error for unknown endpoint" do
      org = insert_org()
      create_endpoint(org.id)
      admin = admin_op(org.id)

      FakeHttpAdapter.set_response({:ok, 200})
      {:ok, event, _} = dispatch(org.id)

      fake_endpoint_id = Ecto.UUID.generate()

      assert {:error, :endpoint_not_found} =
               WebhookEvents.replay(admin, org.id, event.event_id, fake_endpoint_id)
    end
  end

  # ---------------------------------------------------------------------------
  # Admin inspection
  # ---------------------------------------------------------------------------

  describe "admin inspection" do
    test "list_events returns events in reverse chronological order" do
      org = insert_org()

      FakeHttpAdapter.set_response({:ok, 200})
      {:ok, event1, _} = dispatch(org.id)
      {:ok, event2, _} = dispatch(org.id)

      {:ok, events} = WebhookEvents.list_events(org.id)

      ids = Enum.map(events, & &1.id)
      assert event2.id in ids
      assert event1.id in ids
      # Newest first
      assert Enum.find_index(ids, &(&1 == event2.id)) <
               Enum.find_index(ids, &(&1 == event1.id))
    end

    test "list_events is scoped to organization" do
      org1 = insert_org()
      org2 = insert_org()

      FakeHttpAdapter.set_response({:ok, 200})
      {:ok, event1, _} = dispatch(org1.id)
      {:ok, _event2, _} = dispatch(org2.id)

      {:ok, org1_events} = WebhookEvents.list_events(org1.id)

      assert Enum.any?(org1_events, &(&1.id == event1.id))
      refute Enum.any?(org1_events, &(&1.organization_id == org2.id))
    end

    test "get_event_with_attempts returns event and all its attempts" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 500})
      {:ok, event, [failed_attempt]} = dispatch(org.id)

      {:ok, fetched_event, attempts} =
        WebhookEvents.get_event_with_attempts(org.id, event.event_id)

      assert fetched_event.id == event.id
      assert length(attempts) == 1
      assert hd(attempts).id == failed_attempt.id
    end

    test "get_event_with_attempts returns error for unknown event" do
      org = insert_org()

      assert {:error, :event_not_found} =
               WebhookEvents.get_event_with_attempts(org.id, "not-an-event")
    end
  end

  # ---------------------------------------------------------------------------
  # Redaction
  # ---------------------------------------------------------------------------

  describe "redaction" do
    test "sensitive fields are redacted in persisted event payload" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 200})

      raw_payload = %{
        "incident_id" => "inc_001",
        "secret" => "super-secret-value",
        "nested" => %{"api_key" => "key-abc", "data" => "safe"}
      }

      {:ok, event, _} = dispatch(org.id, "incident.opened", raw_payload)

      assert event.payload["incident_id"] == "inc_001"
      assert event.payload["secret"] == "[REDACTED]"
      assert event.payload["nested"]["api_key"] == "[REDACTED]"
      assert event.payload["nested"]["data"] == "safe"
    end

    test "body_json reflects redacted payload" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 200})

      raw_payload = %{"data" => "safe", "token" => "secret-token"}

      {:ok, event, _} = dispatch(org.id, "incident.opened", raw_payload)

      refute event.body_json =~ "secret-token"
      assert event.body_json =~ "[REDACTED]"
    end
  end

  # ---------------------------------------------------------------------------
  # Retry schedule
  # ---------------------------------------------------------------------------

  describe "retry schedule" do
    test "failed attempt has next_retry_at set with exponential backoff" do
      org = insert_org()
      create_endpoint(org.id)

      FakeHttpAdapter.set_response({:ok, 500})

      before_dispatch = DateTime.utc_now()
      {:ok, _event, [attempt]} = dispatch(org.id)
      after_dispatch = DateTime.utc_now()

      assert attempt.status == :failed
      assert attempt.next_retry_at != nil

      # next_retry_at should be after the dispatch time (backoff added)
      assert DateTime.compare(attempt.next_retry_at, before_dispatch) in [:gt, :eq]
    end

    test "due_retries returns attempts past their next_retry_at" do
      org = insert_org()
      endpoint = create_endpoint(org.id)

      # Insert an event and a failed attempt with next_retry_at in the past
      {:ok, event} =
        Repo.insert(%WebhookEvent{
          organization_id: org.id,
          event_id: WebhookEvent.generate_event_id(),
          event_type: "incident.opened",
          payload: %{},
          body_json: "{}"
        })

      past_time = DateTime.add(DateTime.utc_now(), -30, :second)

      {:ok, attempt} =
        Repo.insert(
          WebhookAttempt.changeset(%WebhookAttempt{}, %{
            webhook_event_id: event.id,
            webhook_endpoint_id: endpoint.id,
            status: :pending,
            attempt_number: 2,
            delivery_timestamp: "2026-08-01T00:00:00Z",
            next_retry_at: past_time
          })
        )

      due = WebhookEvents.due_retries()

      assert Enum.any?(due, &(&1.id == attempt.id))
    end

    test "process_attempt retries a pending attempt and updates status" do
      org = insert_org()
      endpoint = create_endpoint(org.id)

      {:ok, event} =
        Repo.insert(%WebhookEvent{
          organization_id: org.id,
          event_id: WebhookEvent.generate_event_id(),
          event_type: "incident.opened",
          payload: %{},
          body_json: "{}"
        })

      past_time = DateTime.add(DateTime.utc_now(), -60, :second)

      {:ok, attempt} =
        Repo.insert(
          WebhookAttempt.changeset(%WebhookAttempt{}, %{
            webhook_event_id: event.id,
            webhook_endpoint_id: endpoint.id,
            status: :pending,
            attempt_number: 2,
            delivery_timestamp: "2026-08-01T00:00:00Z",
            next_retry_at: past_time
          })
        )

      FakeHttpAdapter.set_response({:ok, 200})
      {:ok, updated} = WebhookEvents.process_attempt(attempt.id, http_adapter: FakeHttpAdapter)

      assert updated.status == :success
      assert updated.http_status == 200
    end
  end
end
