# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.WebSocketOptionsTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.MissionControl.WebSocket

  test "outbound client requires a wss endpoint and all enrolled TLS files" do
    assert {:error, {:unsupported_endpoint_scheme, "https"}} =
             WebSocket.connect(endpoint: "https://control.example.test/api/v1/clusters/connect")

    assert {:error, {:missing_tls_option, :ca_cert}} =
             WebSocket.connect(endpoint: "wss://control.example.test")

    assert {:ok, tls_options} =
             WebSocket.tls_options(
               endpoint: "wss://control.example.test",
               ca_cert: "/tmp/control-root.pem",
               client_cert: "/tmp/cluster.pem",
               client_key: "/tmp/cluster.key"
             )

    assert tls_options[:verify] == :verify_peer
    assert tls_options[:versions] == [:"tlsv1.3"]
    assert tls_options[:cacertfile] == ~c"/tmp/control-root.pem"
  end
end
