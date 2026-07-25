defmodule Exocomp.Recovery.AuditEvent do
  @moduledoc """
  Durable audit record for a single state-machine transition.

  Every accepted transition in a recovery episode produces exactly one
  `AuditEvent`. The event carries the same `correlation_id`, `episode_id`,
  `node_id`, and `service` as the episode so that an audit log can reconstruct
  the full recovery timeline.

  The caller is responsible for durably persisting the audit event **before**
  taking any external action (e.g., invoking systemctl). If persistence fails,
  the caller must not proceed with the action.
  """

  @type t :: %__MODULE__{
          event_id: String.t(),
          correlation_id: String.t(),
          episode_id: String.t(),
          node_id: String.t(),
          service: String.t(),
          from_state: atom(),
          to_state: atom(),
          event_tag: atom(),
          sequence: non_neg_integer(),
          timestamp: DateTime.t(),
          meta: map()
        }

  defstruct [
    :event_id,
    :correlation_id,
    :episode_id,
    :node_id,
    :service,
    :from_state,
    :to_state,
    :event_tag,
    :sequence,
    :timestamp,
    :meta
  ]

  @doc """
  Construct an audit event from a fields map.

  Required keys: `:event_id`, `:correlation_id`, `:episode_id`, `:node_id`,
  `:service`, `:from_state`, `:to_state`, `:event_tag`, `:sequence`,
  `:timestamp`, `:meta`.
  """
  @spec new(map()) :: t()
  def new(fields) when is_map(fields) do
    struct!(__MODULE__, fields)
  end
end
