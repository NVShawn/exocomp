# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.WebhookAttempt do
  @moduledoc """
  Schema for webhook delivery attempts.

  Tracks each delivery attempt with response status, headers, and error
  details. Failed attempts are retried with jittered exponential backoff
  for up to 24 hours. Each attempt record captures the timestamp that was
  included in the signed headers so that signatures can be verified.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:pending, :success, :failed, :terminal_failure]

  schema "webhook_attempts" do
    field(:webhook_event_id, :binary_id)
    field(:webhook_endpoint_id, :binary_id)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:http_status, :integer)
    field(:error_reason, :string)
    field(:attempt_number, :integer, default: 1)
    field(:next_retry_at, :utc_datetime)
    # Delivery timestamp included in the signed request headers.
    field(:delivery_timestamp, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          webhook_event_id: Ecto.UUID.t() | nil,
          webhook_endpoint_id: Ecto.UUID.t() | nil,
          status: :pending | :success | :failed | :terminal_failure,
          http_status: non_neg_integer() | nil,
          error_reason: binary() | nil,
          attempt_number: non_neg_integer(),
          next_retry_at: DateTime.t() | nil,
          delivery_timestamp: binary() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc false
  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [
      :webhook_event_id,
      :webhook_endpoint_id,
      :status,
      :http_status,
      :error_reason,
      :attempt_number,
      :next_retry_at,
      :delivery_timestamp
    ])
    |> validate_required([:webhook_event_id, :webhook_endpoint_id, :status])
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

  The backoff formula is: base_delay = min(2^(attempt - 1), 3600) seconds.
  Jitter is a random value between 0 and base_delay to prevent thundering
  herds.
  """
  @spec next_retry_time(attempt_number :: non_neg_integer(), current_time :: NaiveDateTime.t()) ::
          NaiveDateTime.t()
  def next_retry_time(attempt_number, current_time) when attempt_number >= 1 do
    # Base delay: 2^(attempt-1), capped at 3600 seconds (1 hour).
    base_delay_seconds = min(:math.pow(2, attempt_number - 1), 3600) |> trunc()

    # Add jitter: random value between 0 and base_delay.
    jitter_seconds = :rand.uniform(base_delay_seconds + 1) - 1

    total_delay_seconds = base_delay_seconds + jitter_seconds

    NaiveDateTime.add(current_time, total_delay_seconds, :second)
  end

  @doc """
  Checks whether this attempt represents a terminal failure.

  Terminal failures occur after 24 hours or on specific HTTP status codes
  (4xx except 429, which is retried). 5xx codes are retryable.

  The `event_inserted_at` argument is the original webhook event's
  insertion time, used to bound the total retry window to 24 hours from
  event receipt.
  """
  @spec terminal_failure?(
          attempt :: t(),
          event_inserted_at :: NaiveDateTime.t(),
          current_time :: NaiveDateTime.t()
        ) :: boolean()
  def terminal_failure?(
        %__MODULE__{http_status: http_status},
        event_inserted_at,
        current_time
      ) do
    # 24 hours = 86400 seconds from the original event insertion time.
    time_since_event = NaiveDateTime.diff(current_time, event_inserted_at, :second)
    exceeded_24_hours = time_since_event >= 86_400

    # Terminal HTTP statuses: 4xx except 429 (too many requests).
    terminal_http_status =
      case http_status do
        status when status >= 400 and status < 500 and status != 429 -> true
        # 5xx are retryable.
        _other -> false
      end

    exceeded_24_hours or terminal_http_status
  end

  @doc """
  Two-arity variant for backward-compatible unit tests that pass the
  attempt's own `inserted_at` as the event anchor (deprecated).
  """
  @spec terminal_failure?(attempt :: t(), current_time :: NaiveDateTime.t()) :: boolean()
  def terminal_failure?(%__MODULE__{inserted_at: inserted_at} = attempt, current_time) do
    naive_inserted_at =
      case inserted_at do
        %NaiveDateTime{} = n -> n
        %DateTime{} = dt -> DateTime.to_naive(dt)
        nil -> NaiveDateTime.utc_now()
      end

    terminal_failure?(attempt, naive_inserted_at, current_time)
  end
end
