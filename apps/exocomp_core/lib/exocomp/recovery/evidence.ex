# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Recovery.Evidence do
  @moduledoc """
  Versioned, target-bound evidence collected by deterministic code.

  Evidence is the factual basis for every recovery decision. It must be fresh
  (collected within `max_age_seconds` of the decision that consumes it) and
  must belong to the same node and service as the recovery episode.

  The state machine checks freshness at every transition that carries evidence.
  Stale evidence causes the transition to fail without advancing state, so no
  external action is taken on outdated observations.
  """

  @type t :: %__MODULE__{
          evidence_id: String.t(),
          collected_at: DateTime.t(),
          node_id: String.t(),
          service: String.t(),
          collector_version: String.t(),
          data: map()
        }

  defstruct [
    :evidence_id,
    :collected_at,
    :node_id,
    :service,
    :collector_version,
    :data
  ]

  @default_max_age_seconds 300

  @doc """
  Build a new evidence record.

  Options:
    - `:evidence_id` — override the generated ID.
    - `:collected_at` — override the collection timestamp (useful in tests).
    - `:collector_version` — semantic version string (default `"1.0"`).
  """
  @spec new(String.t(), String.t(), map(), keyword()) :: t()
  def new(node_id, service, data, opts \\ []) do
    %__MODULE__{
      evidence_id: opts[:evidence_id] || generate_id(),
      collected_at: opts[:collected_at] || DateTime.utc_now(),
      node_id: node_id,
      service: service,
      collector_version: opts[:collector_version] || "1.0",
      data: data
    }
  end

  @doc """
  Returns `:ok` when the evidence is fresh relative to `now`, or
  `{:error, {:stale_evidence, age_seconds, max_age_seconds}}` when it has aged
  beyond `max_age_seconds`.

  A negative age (evidence collected in the future) is also considered stale.
  """
  @spec check_freshness(t(), DateTime.t(), non_neg_integer()) ::
          :ok | {:error, {:stale_evidence, integer(), non_neg_integer()}}
  def check_freshness(
        %__MODULE__{collected_at: collected_at},
        now,
        max_age_seconds \\ @default_max_age_seconds
      ) do
    age = DateTime.diff(now, collected_at, :second)

    if age >= 0 and age <= max_age_seconds do
      :ok
    else
      {:error, {:stale_evidence, age, max_age_seconds}}
    end
  end

  # ------------------------------------------------------------------

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
