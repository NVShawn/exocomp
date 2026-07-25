# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.HTTPTransportTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.A2A.HTTPTransport

  test "requires complete mTLS client credentials before making a request" do
    request = %{
      method: :get,
      path: "/tasks/task-1",
      headers: [{"a2a-version", "1.0"}],
      body: "",
      timeout_ms: 100,
      node_id: "node-a",
      address: "192.0.2.10",
      hostname: "node-a.example.test",
      port: 8443,
      certificate_identity: "node-a.identity.test",
      tls: [cacertfile: "/tmp/ca.pem"]
    }

    assert HTTPTransport.request(request, []) ==
             {:error, {:missing_tls_options, [:certfile, :keyfile]}}
  end
end
