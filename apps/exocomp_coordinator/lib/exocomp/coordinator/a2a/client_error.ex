# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.ClientError do
  @moduledoc """
  Normalized coordinator diagnostic-client failure.

  `kind` is one of `:configuration`, `:transport`, or `:protocol`. Transport
  implementation details remain in `details`; callers can make decisions from
  the stable `reason`, `operation`, and optional HTTP `status` fields.
  """

  @enforce_keys [:kind, :reason, :operation, :node_id]
  defstruct [:kind, :reason, :operation, :node_id, :status, :details]

  @type t :: %__MODULE__{
          kind: :configuration | :transport | :protocol,
          reason: atom(),
          operation: :send | :get_task | :cancel,
          node_id: String.t(),
          status: non_neg_integer() | nil,
          details: term()
        }
end
