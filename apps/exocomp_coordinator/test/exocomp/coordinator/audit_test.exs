defmodule Exocomp.Coordinator.AuditTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Audit
  alias Exocomp.Coordinator.Audit.JSONLines

  defmodule OfflineSink do
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(_opts), do: {:error, :offline}

    @impl true
    def write(_state, _event), do: {:error, :offline}

    @impl true
    def close(_state), do: :ok
  end

  @tag :tmp_dir
  test "writes correlated JSON lines and recursively redacts secrets", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "audit.jsonl")
    server = start_audit({JSONLines, path: path, max_bytes: 4_096})

    assert :ok =
             Audit.emit(
               :enrollment,
               %{
                 node_id: "node-a",
                 token: "plain-token",
                 nested: %{private_key: "plain-key", safe: "visible"}
               },
               server: server,
               correlation_id: "corr_test"
             )

    event = path |> File.read!() |> String.trim() |> :json.decode()
    assert event["event_type"] == "enrollment"
    assert event["correlation_id"] == "corr_test"
    assert event["attributes"]["token"] == "[REDACTED]"
    assert event["attributes"]["nested"]["private_key"] == "[REDACTED]"
    assert event["attributes"]["nested"]["safe"] == "visible"
  end

  @tag :tmp_dir
  test "rotates before the configured bound is exceeded", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "bounded.jsonl")
    server = start_audit({JSONLines, path: path, max_bytes: 250})

    assert :ok = Audit.emit(:first, %{value: String.duplicate("a", 40)}, server: server)
    assert :ok = Audit.emit(:second, %{value: String.duplicate("b", 40)}, server: server)

    assert File.exists?(path <> ".1")
    assert File.stat!(path).size <= 250
    assert File.stat!(path <> ".1").size <= 250
  end

  test "reports an outage without crashing and retries the sink" do
    server = start_audit({OfflineSink, []})

    assert %{healthy: false, last_error: %{code: :audit_unavailable}} = Audit.status(server)

    assert {:error, %{code: :audit_unavailable, details: %{correlation_id: correlation_id}}} =
             Audit.emit(:state_change, %{token: "hidden"}, server: server)

    assert String.starts_with?(correlation_id, "corr_")
    assert Process.alive?(server)
    assert %{healthy: false} = Audit.status(server)
  end

  test "creates unique correlation identifiers and redacts string keys" do
    first = Audit.correlation_id()
    second = Audit.correlation_id()

    assert first != second

    assert Audit.redact(%{"authorization" => "Bearer secret", "safe" => 1}) ==
             %{"authorization" => "[REDACTED]", "safe" => 1}
  end

  test "redact covers passphrase and digest fields" do
    # These keys must never appear in audit output — verify the sensitive-key
    # list covers them so any future audit event that accidentally includes
    # them is scrubbed before reaching the sink.
    assert Audit.redact(%{"passphrase" => "secret phrase"}) ==
             %{"passphrase" => "[REDACTED]"}

    assert Audit.redact(%{"digest" => "raw-digest-bytes"}) ==
             %{"digest" => "[REDACTED]"}

    assert Audit.redact(%{"stored_digest" => "raw-digest-bytes"}) ==
             %{"stored_digest" => "[REDACTED]"}

    assert Audit.redact(%{"pin" => "1234"}) == %{"pin" => "[REDACTED]"}

    # Non-sensitive keys must pass through unmodified.
    assert Audit.redact(%{"root_fingerprint" => "AA:BB"}) == %{"root_fingerprint" => "AA:BB"}
    assert Audit.redact(%{"node_id" => "node-a"}) == %{"node_id" => "node-a"}
  end

  @tag :tmp_dir
  test "audit log file has mode 0600 after initialization", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "audit.jsonl")
    _server = start_audit({JSONLines, path: path})
    assert {:ok, %{mode: mode}} = File.stat(path)
    assert Bitwise.band(mode, 0o777) == 0o600
  end

  @tag :tmp_dir
  test "rotated audit log file has mode 0600", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "rotate_perm.jsonl")
    # max_bytes: 250 matches the existing rotation test. Each event is ~177
    # bytes at a 40-char value, so the second write pushes past the limit.
    server = start_audit({JSONLines, path: path, max_bytes: 250})

    # First write — fills most of the 250-byte budget.
    Audit.emit(:first, %{value: String.duplicate("x", 40)}, server: server)
    # Second write — cumulative size exceeds 250, triggering rotation.
    Audit.emit(:second, %{value: String.duplicate("y", 40)}, server: server)

    rotated = path <> ".1"
    assert File.exists?(rotated), "expected rotated file to exist at #{rotated}"
    assert {:ok, %{mode: rot_mode}} = File.stat(rotated)
    assert Bitwise.band(rot_mode, 0o777) == 0o600

    # The active file after rotation must also be 0600.
    assert {:ok, %{mode: active_mode}} = File.stat(path)
    assert Bitwise.band(active_mode, 0o777) == 0o600
  end

  defp start_audit(sink) do
    name = :"audit_test_#{System.unique_integer([:positive])}"
    start_supervised!({Audit, name: name, sink: sink})
  end
end
