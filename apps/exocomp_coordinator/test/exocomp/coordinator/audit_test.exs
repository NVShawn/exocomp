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

  defp start_audit(sink) do
    name = :"audit_test_#{System.unique_integer([:positive])}"
    start_supervised!({Audit, name: name, sink: sink})
  end
end
