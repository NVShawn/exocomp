# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.AuditLogTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Recovery.AuditLog
  alias Exocomp.Recovery.AuditEvent

  test "durably appends a JSON transition record before returning" do
    path =
      Path.join(
        System.tmp_dir!(),
        "recovery-audit-#{System.unique_integer([:positive])}.jsonl"
      )

    name = :"recovery_audit_#{System.unique_integer([:positive])}"
    start_supervised!({AuditLog, name: name, path: path})
    on_exit(fn -> File.rm(path) end)

    event =
      AuditEvent.new(%{
        event_id: "event-1",
        correlation_id: "correlation-1",
        episode_id: "episode-1",
        node_id: "node-1",
        service: "fixture.service",
        from_state: :observing,
        to_state: :diagnosing,
        event_tag: :unhealthy_observation,
        sequence: 1,
        timestamp: ~U[2026-07-27 22:00:00Z],
        meta: %{}
      })

    assert :ok = AuditLog.append(event, name)
    assert [line] = path |> File.read!() |> String.split("\n", trim: true)
    decoded = Jason.decode!(line)
    assert decoded["event_id"] == "event-1"
    assert decoded["event_tag"] == "unhealthy_observation"
    assert decoded["timestamp"] == "2026-07-27T22:00:00Z"
  end
end
