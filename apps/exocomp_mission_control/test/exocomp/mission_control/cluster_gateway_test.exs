# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterGatewayTest do
  use ExUnit.Case, async: false

  import Plug.Test

  alias Exocomp.MissionControl.{
    CertificateIdentity,
    ClusterEventIngestor,
    ClusterGateway,
    ClusterSessions
  }

  alias X509.Certificate.Extension

  @identity "spiffe://exocomp/organizations/acme/clusters/cluster-a"

  test "extracts organization and cluster only from the SPIFFE URI SAN" do
    der = certificate_der(@identity)

    assert {:ok, identity} = CertificateIdentity.from_peer_data(%{ssl_cert: der})
    assert identity.organization_id == "acme"
    assert identity.cluster_id == "cluster-a"
    assert identity.spiffe_id == @identity
  end

  test "rejects a missing certificate and a certificate without a SPIFFE identity" do
    assert {:error, :missing_client_certificate} =
             CertificateIdentity.from_peer_data(%{})

    dns_der = certificate_der("cluster-a.example.test", :dns)

    assert {:error, :missing_cluster_identity} =
             CertificateIdentity.from_peer_data(%{ssl_cert: dns_der})
  end

  test "certificate identity validation rejects a wrong trust root" do
    root_key = X509.PrivateKey.new_ec(:secp256r1)

    root =
      X509.Certificate.self_signed(root_key, "/O=Exocomp/CN=Trusted Root", template: :root_ca)

    wrong_key = X509.PrivateKey.new_ec(:secp256r1)

    wrong_root =
      X509.Certificate.self_signed(wrong_key, "/O=Exocomp/CN=Wrong Root", template: :root_ca)

    leaf_key = X509.PrivateKey.new_ec(:secp256r1)

    leaf =
      X509.Certificate.new(
        X509.PublicKey.derive(leaf_key),
        "/O=Exocomp/CN=cluster",
        root,
        root_key,
        template: :server,
        extensions: [subject_alt_name: Extension.subject_alt_name([{:URI, @identity}])]
      )

    assert {:error, {:invalid_certificate_chain, _reason}} =
             CertificateIdentity.from_peer_data(
               %{ssl_cert: X509.Certificate.to_der(leaf)},
               trusted_root: X509.Certificate.to_der(wrong_root)
             )
  end

  test "registering a newer session supersedes the old session" do
    registry = start_registry()
    old_owner = spawn(fn -> receive do: (_message -> :ok) end)
    identity = identity()

    assert {:ok, old_session} = ClusterSessions.register(registry, identity, old_owner)
    assert {:ok, new_session} = ClusterSessions.register(registry, identity, self())
    assert old_session != new_session

    assert_receive {:mission_control_session_replaced, ^new_session}
    assert {:ok, %{session_id: ^new_session, pid: pid}} = ClusterSessions.get(registry, identity)
    assert pid == self()

    # A late terminate from the superseded socket cannot remove its replacement.
    assert :ok = ClusterSessions.unregister(registry, identity, old_session, old_owner)
    assert {:ok, %{session_id: ^new_session}} = ClusterSessions.get(registry, identity)
  end

  test "revoked identity is refused before a WebSocket upgrade" do
    registry = start_registry()
    identity = identity()
    assert :ok = ClusterSessions.revoke(registry, identity)

    conn =
      :get
      |> conn("/api/v1/clusters/connect")
      |> Plug.Conn.put_peer_data(%{ssl_cert: certificate_der(@identity)})
      |> Plug.Conn.put_req_header("connection", "Upgrade")
      |> Plug.Conn.put_req_header("upgrade", "websocket")
      |> Plug.Conn.put_req_header(
        "sec-websocket-key",
        Base.encode64(:crypto.strong_rand_bytes(16))
      )
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> ClusterGateway.call(ClusterGateway.init(session_registry: registry))

    assert conn.status == 403
    assert Jason.decode!(conn.resp_body)["error"] == "client certificate revoked"
  end

  test "missing certificate is rejected without attempting an upgrade" do
    registry = start_registry()

    conn =
      :get
      |> conn("/api/v1/clusters/connect")
      |> ClusterGateway.call(ClusterGateway.init(session_registry: registry))

    assert conn.status == 401
  end

  test "a validated certificate upgrades and creates a session" do
    registry = start_registry()

    conn =
      :get
      |> conn("/api/v1/clusters/connect")
      |> Plug.Conn.put_peer_data(%{ssl_cert: certificate_der(@identity)})
      |> Plug.Conn.put_req_header("connection", "Upgrade")
      |> Plug.Conn.put_req_header("upgrade", "websocket")
      |> Plug.Conn.put_req_header(
        "sec-websocket-key",
        Base.encode64(:crypto.strong_rand_bytes(16))
      )
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> ClusterGateway.call(ClusterGateway.init(session_registry: registry))

    assert conn.state == :upgraded

    assert {:ok, %{session_id: session_id, identity: identity}} =
             ClusterSessions.get(registry, @identity)

    assert String.starts_with?(session_id, "sess_")
    assert identity.organization_id == "acme"
  end

  test "socket acknowledgements retain certificate identity" do
    ingestor = start_ingestor()

    state = %{
      session_registry: self(),
      event_ingestor: ingestor,
      session_id: "sess_test",
      identity: identity()
    }

    {:push, {:text, connected}, ^state} = ClusterGateway.Socket.init(state)
    assert Jason.decode!(connected)["organization_id"] == "acme"

    {:push, {:text, ack}, ^state} =
      ClusterGateway.Socket.handle_in(
        {Jason.encode!(event()), opcode: :text},
        state
      )

    decoded = Jason.decode!(ack)
    assert decoded["organization_id"] == "acme"
    assert decoded["cluster_id"] == "cluster-a"
    assert decoded["acknowledged_sequence"] == 1
  end

  test "Mission Control server TLS requires peer certificates and TLS 1.3" do
    assert {:ok, options} =
             ClusterGateway.server_tls_options(
               certfile: "/tmp/server.pem",
               keyfile: "/tmp/server.key",
               cacertfile: "/tmp/root.pem"
             )

    assert options[:verify] == :verify_peer
    assert options[:fail_if_no_peer_cert] == true
    assert options[:versions] == [:"tlsv1.3"]
  end

  defp start_registry do
    name = :"mission_control_sessions_#{System.unique_integer([:positive])}"
    start_supervised!({ClusterSessions, name: name})
    name
  end

  defp start_ingestor do
    name = :"mission_control_event_ingestor_#{System.unique_integer([:positive])}"
    start_supervised!({ClusterEventIngestor, name: name})
    name
  end

  defp event do
    %{
      "schema_version" => 1,
      "event_id" => "gateway-event-#{System.unique_integer([:positive])}",
      "cluster_seq" => 1,
      "kind" => "cluster.heartbeat",
      "occurred_at" => "2026-08-03T00:00:00Z",
      "correlation_id" => "corr-gateway",
      "payload" => %{}
    }
  end

  defp identity do
    %{
      spiffe_id: @identity,
      organization_id: "acme",
      cluster_id: "cluster-a",
      certificate_der: certificate_der(@identity)
    }
  end

  defp certificate_der(value, kind \\ :uri) do
    root_key = X509.PrivateKey.new_ec(:secp256r1)
    root = X509.Certificate.self_signed(root_key, "/O=Exocomp/CN=Test Root", template: :root_ca)
    leaf_key = X509.PrivateKey.new_ec(:secp256r1)

    san =
      case kind do
        :uri -> Extension.subject_alt_name([{:URI, value}])
        :dns -> Extension.subject_alt_name([value])
      end

    leaf =
      X509.Certificate.new(
        X509.PublicKey.derive(leaf_key),
        "/O=Exocomp/CN=cluster",
        root,
        root_key,
        template: :server,
        extensions: [
          basic_constraints: Extension.basic_constraints(false),
          key_usage: Extension.key_usage([:digitalSignature]),
          ext_key_usage: Extension.ext_key_usage([:clientAuth]),
          subject_alt_name: san
        ]
      )

    X509.Certificate.to_der(leaf)
  end
end
