# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.WebhookAttemptTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Webhooks.WebhookAttempt

  describe "next_retry_time/2" do
    test "calculates exponential backoff for attempt 1" do
      current_time = ~N[2026-08-01 14:30:00]

      next_time = WebhookAttempt.next_retry_time(1, current_time)

      # Attempt 1: 2^0 = 1 second base + jitter (0-1 second)
      diff = NaiveDateTime.diff(next_time, current_time, :second)
      assert diff >= 0 and diff <= 2
    end

    test "calculates exponential backoff for attempt 2" do
      current_time = ~N[2026-08-01 14:30:00]

      next_time = WebhookAttempt.next_retry_time(2, current_time)

      # Attempt 2: 2^1 = 2 seconds base + jitter (0-2 seconds)
      diff = NaiveDateTime.diff(next_time, current_time, :second)
      assert diff >= 0 and diff <= 4
    end

    test "calculates exponential backoff for attempt 3" do
      current_time = ~N[2026-08-01 14:30:00]

      next_time = WebhookAttempt.next_retry_time(3, current_time)

      # Attempt 3: 2^2 = 4 seconds base + jitter (0-4 seconds)
      diff = NaiveDateTime.diff(next_time, current_time, :second)
      assert diff >= 0 and diff <= 8
    end

    test "caps backoff at 3600 seconds (1 hour)" do
      current_time = ~N[2026-08-01 14:30:00]

      next_time = WebhookAttempt.next_retry_time(20, current_time)

      # Attempt 20: 2^19 is huge, so it should be capped at 3600 + jitter
      diff = NaiveDateTime.diff(next_time, current_time, :second)
      assert diff >= 0 and diff <= 7200
    end

    test "includes jitter for same attempt number" do
      current_time = ~N[2026-08-01 14:30:00]

      # Call multiple times with the same attempt number
      times = Enum.map(1..10, fn _ -> WebhookAttempt.next_retry_time(5, current_time) end)
      diffs = Enum.map(times, &NaiveDateTime.diff(&1, current_time, :second))

      # With jitter, most should be different
      assert length(Enum.uniq(diffs)) > 1
    end
  end

  describe "terminal_failure?/3 (event-anchored 24h window)" do
    test "returns false for attempts within 24 hours of event" do
      now = ~N[2026-08-01 14:30:00]
      # Event was created 1 hour ago
      event_inserted_at = NaiveDateTime.add(now, -3600, :second)

      attempt = %WebhookAttempt{
        attempt_number: 5,
        http_status: 500,
        inserted_at: now
      }

      refute WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now)
    end

    test "returns true when event is older than 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      # Event was created 25 hours ago
      event_inserted_at = NaiveDateTime.add(now, -90_000, :second)

      attempt = %WebhookAttempt{
        attempt_number: 5,
        http_status: 500,
        inserted_at: now
      }

      assert WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now)
    end

    test "returns true for 4xx status codes (except 429)" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = now

      for status <- [400, 401, 403, 404, 410] do
        attempt = %WebhookAttempt{
          attempt_number: 1,
          http_status: status,
          inserted_at: now
        }

        assert WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now),
               "Status #{status} should be terminal"
      end
    end

    test "returns false for 429 (too many requests)" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = now

      attempt = %WebhookAttempt{
        attempt_number: 1,
        http_status: 429,
        inserted_at: now
      }

      refute WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now)
    end

    test "returns false for 5xx within 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = now

      for status <- [500, 502, 503, 504] do
        attempt = %WebhookAttempt{
          attempt_number: 1,
          http_status: status,
          inserted_at: now
        }

        refute WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now),
               "Status #{status} should be retryable"
      end
    end

    test "returns false for nil http_status within 24 hours (network error)" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = now

      attempt = %WebhookAttempt{
        attempt_number: 1,
        http_status: nil,
        inserted_at: now
      }

      refute WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now)
    end

    test "returns true for nil http_status after 24 hours (network error, expired)" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = NaiveDateTime.add(now, -90_000, :second)

      attempt = %WebhookAttempt{
        attempt_number: 1,
        http_status: nil,
        inserted_at: now
      }

      assert WebhookAttempt.terminal_failure?(attempt, event_inserted_at, now)
    end
  end

  describe "terminal_failure?/2 (backward-compatible 2-arity)" do
    test "returns false for attempts within 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      # 1 hour ago
      inserted_at = NaiveDateTime.add(now, -3600, :second)

      attempt = %WebhookAttempt{
        attempt_number: 5,
        http_status: 500,
        inserted_at: inserted_at
      }

      refute WebhookAttempt.terminal_failure?(attempt, now)
    end

    test "returns true for attempts after 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      # 25 hours ago
      inserted_at = NaiveDateTime.add(now, -90_000, :second)

      attempt = %WebhookAttempt{
        attempt_number: 5,
        http_status: 500,
        inserted_at: inserted_at
      }

      assert WebhookAttempt.terminal_failure?(attempt, now)
    end

    test "returns true for 4xx status codes (except 429)" do
      now = ~N[2026-08-01 14:30:00]
      inserted_at = now

      for status <- [400, 401, 403, 404, 410] do
        attempt = %WebhookAttempt{
          attempt_number: 1,
          http_status: status,
          inserted_at: inserted_at
        }

        assert WebhookAttempt.terminal_failure?(attempt, now),
               "Status #{status} should be terminal"
      end
    end

    test "returns false for 429 status code (too many requests)" do
      now = ~N[2026-08-01 14:30:00]
      inserted_at = now

      attempt = %WebhookAttempt{
        attempt_number: 1,
        http_status: 429,
        inserted_at: inserted_at
      }

      refute WebhookAttempt.terminal_failure?(attempt, now)
    end

    test "returns false for 5xx status codes within 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      inserted_at = now

      for status <- [500, 502, 503, 504] do
        attempt = %WebhookAttempt{
          attempt_number: 1,
          http_status: status,
          inserted_at: inserted_at
        }

        refute WebhookAttempt.terminal_failure?(attempt, now),
               "Status #{status} should be retryable"
      end
    end

    test "returns false for nil http_status within 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      inserted_at = now

      attempt = %WebhookAttempt{
        attempt_number: 1,
        http_status: nil,
        inserted_at: inserted_at
      }

      refute WebhookAttempt.terminal_failure?(attempt, now)
    end

    test "returns true for nil http_status after 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      inserted_at = NaiveDateTime.add(now, -90_000, :second)

      attempt = %WebhookAttempt{
        attempt_number: 1,
        http_status: nil,
        inserted_at: inserted_at
      }

      assert WebhookAttempt.terminal_failure?(attempt, now)
    end
  end

  describe "changeset/2" do
    test "creates valid changeset with required fields" do
      event_id = Ecto.UUID.generate()
      endpoint_id = Ecto.UUID.generate()

      changeset =
        WebhookAttempt.changeset(%WebhookAttempt{}, %{
          "webhook_event_id" => event_id,
          "webhook_endpoint_id" => endpoint_id,
          "status" => "pending"
        })

      assert changeset.valid?
    end

    test "validates required fields" do
      changeset = WebhookAttempt.changeset(%WebhookAttempt{}, %{})

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :webhook_event_id)
      assert Keyword.has_key?(changeset.errors, :webhook_endpoint_id)
    end

    test "validates attempt_number is positive" do
      event_id = Ecto.UUID.generate()
      endpoint_id = Ecto.UUID.generate()

      changeset =
        WebhookAttempt.changeset(%WebhookAttempt{}, %{
          "webhook_event_id" => event_id,
          "webhook_endpoint_id" => endpoint_id,
          "status" => "pending",
          "attempt_number" => 0
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :attempt_number)
    end

    test "validates status is one of the allowed values" do
      event_id = Ecto.UUID.generate()
      endpoint_id = Ecto.UUID.generate()

      changeset =
        WebhookAttempt.changeset(%WebhookAttempt{}, %{
          "webhook_event_id" => event_id,
          "webhook_endpoint_id" => endpoint_id,
          "status" => "invalid_status"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :status)
    end

    test "accepts all valid status values" do
      event_id = Ecto.UUID.generate()
      endpoint_id = Ecto.UUID.generate()

      for status <- ["pending", "success", "failed", "terminal_failure"] do
        changeset =
          WebhookAttempt.changeset(%WebhookAttempt{}, %{
            "webhook_event_id" => event_id,
            "webhook_endpoint_id" => endpoint_id,
            "status" => status
          })

        assert changeset.valid?, "Status #{status} should be valid"
      end
    end
  end
end
