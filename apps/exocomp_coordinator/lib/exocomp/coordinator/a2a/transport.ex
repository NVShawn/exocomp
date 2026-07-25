# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.Transport do
  @moduledoc """
  Transport boundary for coordinator-to-node diagnostic A2A requests.

  The request map deliberately carries the registry's verified address and
  expected certificate identity separately. Transports must connect to
  `address` while using `certificate_identity` for SNI/peer verification.
  """

  @type request :: %{
          required(:method) => :get | :post,
          required(:path) => String.t(),
          required(:headers) => [{String.t(), String.t()}],
          required(:body) => binary(),
          required(:timeout_ms) => pos_integer(),
          required(:node_id) => String.t(),
          required(:address) => String.t(),
          required(:hostname) => String.t(),
          required(:port) => pos_integer(),
          required(:certificate_identity) => String.t(),
          required(:tls) => keyword()
        }

  @callback request(request(), keyword()) ::
              {:ok, non_neg_integer(), [{String.t(), String.t()}], binary()}
              | {:error, :timeout | term()}
end
