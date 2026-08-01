# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControlWebSocketTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.MissionControl.WebSocket

  @cert_dir Path.expand("../../../../exocomp_node/test/fixtures/certs", __DIR__)

  defmodule EchoPlug do
    @behaviour Plug

    @impl Plug
    def init(_opts), do: []

    @impl Plug
    def call(conn, _opts) do
      Plug.Conn.upgrade_adapter(conn, :websocket, {EchoSocket, [], []})
    end
  end

  defmodule EchoSocket do
    @behaviour WebSock

    @impl WebSock
    def init(state), do: {:push, {:text, "ready"}, state}

    @impl WebSock
    def handle_in({payload, opcode: :text}, state),
      do: {:push, {:text, payload}, state}
  end

  test "connects over TLS 1.3 with the enrolled client certificate and exchanges frames" do
    server = start_server()

    assert {:ok, socket} = WebSocket.connect(client_options(server.port))
    assert {:ok, {:text, "ready"}, socket} = WebSocket.recv(socket)

    assert {:ok, socket} = WebSocket.send_text(socket, %{"message" => "hello"})
    assert {:ok, {:text, payload}, _socket} = WebSocket.recv(socket)
    assert Jason.decode!(payload) == %{"message" => "hello"}

    WebSocket.close(socket)
  end

  test "wrong trust root prevents the outbound WebSocket handshake" do
    server = start_server()

    assert {:error, _reason} =
             WebSocket.connect(client_options(server.port, ca_cert: cert("rogue.crt")))
  end

  test "missing or wrong client certificate prevents mTLS connection" do
    server = start_server()

    assert {:error, _reason} =
             WebSocket.connect(
               client_options(server.port,
                 client_cert: cert("rogue.crt"),
                 client_key: cert("rogue.key")
               )
             )

    assert {:error, _reason} =
             WebSocket.connect(
               client_options(server.port, client_cert: "/tmp/no-such-cluster.crt")
             )
  end

  defp start_server do
    port = 20_000 + rem(System.unique_integer([:positive]), 1_000)

    {:ok, pid} =
      Bandit.start_link(
        plug: {EchoPlug, []},
        scheme: :https,
        port: port,
        ip: {127, 0, 0, 1},
        startup_log: false,
        thousand_island_options: [
          transport_options: [
            certfile: cert("node.crt"),
            keyfile: cert("node.key"),
            cacertfile: cert("ca.crt"),
            verify: :verify_peer,
            fail_if_no_peer_cert: true,
            versions: [:"tlsv1.3"]
          ]
        ]
      )

    on_exit(fn -> if Process.alive?(pid), do: Process.exit(pid, :shutdown) end)
    Process.sleep(50)
    %{pid: pid, port: port}
  end

  defp client_options(port, overrides \\ []) do
    [
      endpoint: "wss://exocomp-test-node:#{port}",
      connect_host: "127.0.0.1",
      server_name: "exocomp-test-node",
      ca_cert: cert("ca.crt"),
      client_cert: cert("node.crt"),
      client_key: cert("node.key")
    ]
    |> Keyword.merge(overrides)
  end

  defp cert(name), do: Path.join(@cert_dir, name)
end
