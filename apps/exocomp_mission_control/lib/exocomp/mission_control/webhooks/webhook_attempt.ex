# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.WebhookAttempt do
  @moduledoc """
  Schema for webhook delivery attempts.

  Tracks each delivery attempt with response status, headers, and error details.
  Failed attempts are retried with jittered exponential backoff for up to 24 hours.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          webhook_event_id: Ecto.UUID.t() | nil,
          webhook_id: Ecto.UUID.t() | nil,
          status: :pending | :success | :failed | :terminal_failure,
          http_status: non_neg_integer | nil,
          error_reason: binary | nil,
          attempt_number: non_neg_integer,
          next_retry_at: NaiveDateTime.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @statuses [:pending, :success, :failed, :terminal_failure]

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "webhook_attempts" do
    field(:webhook_event_id, Ecto.UUID)
    field(:webhook_id, Ecto.UUID)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:http_status, :integer)
    field(:error_reason, :string)
    field(:attempt_number, :integer, default: 1)
    field(:next_retry_at, :naive_datetime)

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [
      :webhook_event_id,
      :webhook_id,
      :status,
      :http_status,
      :error_reason,
      :attempt_number,
      :next_retry_at
    ])
    |> validate_required([:webhook_event_id, :webhook_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_attempt_number()
  end

  defp validate_attempt_number(changeset) do
    validate_change(changeset, :attempt_number, fn :attempt_number, attempt_number ->
      if attempt_number > 0 do
        []
      else
        [attempt_number: "must be greater than 0"]
      end
    end)
  end

  @doc """
  Calculates the next retry time using jittered exponential backoff.

  Retry schedule for up to 24 hours:
  - Attempt 1 (0s): first attempt
  - Attempt 2 (~2s): 1s base + jitter
  - Attempt 3 (~6s): 2s base + jitter
  - Attempt 4 (~14s): 4s base + jitter
  - ...up to 24 hours total

  The backoff formula is: base_delay = min(2^(attempt - 1), 3600) seconds
  Jitter is random between 0 and base_delay to prevent thundering herd.
  """
  @spec next_retry_time(attempt_number :: non_neg_integer, current_time :: NaiveDateTime.t()) ::
          NaiveDateTime.t()
  def next_retry_time(attempt_number, current_time) when attempt_number >= 1 do
    # Base delay: 2^(attempt-1), capped at 3600 seconds (1 hour)
    base_delay_seconds = min(:math.pow(2, attempt_number - 1), 3600) |> trunc()

    # Add jitter: random value between 0 and base_delay
    jitter_seconds = :rand.uniform(base_delay_seconds + 1) - 1

    total_delay_seconds = base_delay_seconds + jitter_seconds

    NaiveDateTime.add(current_time, total_delay_seconds, :second)
  end

  @doc """
  Checks if an attempt should be abandoned (terminal failure).

  Terminal failures occur after 24 hours or specific HTTP status codes (4xx except 429).
  """
  @spec terminal_failure?(attempt :: t(), current_time :: NaiveDateTime.t()) :: boolean
  def terminal_failure?(
        %__MODULE__{
          http_status: http_status,
          inserted_at: inserted_at
        },
        current_time
      ) do
    # 24 hours = 86400 seconds
    time_elapsed = NaiveDateTime.diff(current_time, inserted_at, :second)
    exceeded_24_hours = time_elapsed >= 86_400

    # Terminal HTTP statuses: 4xx (except 429) and 5xx that indicate permanent failure
    terminal_http_status =
      case http_status do
        status when status >= 400 and status < 500 and status != 429 -> true
        # 5xx are retryable
        status when status >= 500 and status < 600 -> false
        _ -> false
      end

    exceeded_24_hours or terminal_http_status
  end
end
