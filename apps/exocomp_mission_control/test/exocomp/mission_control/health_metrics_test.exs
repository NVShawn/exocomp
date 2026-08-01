# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.HealthMetricsTest do
  use ExUnit.Case, async: false

  import Plug.Test

  alias Exocomp.MissionControl.{Health, Metrics, Telemetry}

  setup do
    Metrics.reset()
    previous_token = Application.get_env(:exocomp_mission_control, :readiness_token)

    on_exit(fn ->
      if is_nil(previous_token) do
        Application.delete_env(:exocomp_mission_control, :readiness_token)
      else
        Application.put_env(:exocomp_mission_control, :readiness_token, previous_token)
      end
    end)

    :ok
  end

  describe "health endpoints" do
    test "liveness is unauthenticated and does not inspect the database" do
      conn = request(:get, "/health/live")

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"status" => "ok"}
    end

    test "readiness reports a healthy local service" do
      report =
        Health.evaluate(
          database: fn -> :ok end,
          migrations: fn -> :ok end,
          supervision: fn -> :ok end
        )

      assert report == %{
               status: :ok,
               ready?: true,
               checks: %{database: :ok, migrations: :ok, supervision: :ok}
             }
    end

    test "database unavailability returns a redacted not-ready report" do
      report =
        Health.evaluate(
          database: fn -> {:error, "sensitive-detail"} end,
          migrations: fn -> :ok end,
          supervision: fn -> :ok end
        )

      assert report.ready? == false
      assert report.checks.database == :failed
      refute inspect(report) =~ "sensitive-detail"

      previous = Application.get_env(:exocomp_mission_control, :database_check)
      Application.put_env(:exocomp_mission_control, :database_check, fn -> {:error, :down} end)

      on_exit(fn ->
        if is_nil(previous) do
          Application.delete_env(:exocomp_mission_control, :database_check)
        else
          Application.put_env(:exocomp_mission_control, :database_check, previous)
        end
      end)

      conn = request(:get, "/health/ready")
      assert conn.status == 503
      assert conn.resp_body =~ "failed"
      refute conn.resp_body =~ "sensitive-detail"
      refute conn.resp_body =~ "organization"
    end

    test "pending migrations make readiness fail without leaking migration details" do
      report =
        Health.evaluate(
          database: fn -> :ok end,
          migrations: fn -> :pending end,
          supervision: fn -> :ok end
        )

      assert report.ready? == false
      assert report.checks.migrations == :pending
    end

    test "a degraded critical worker fails readiness and recovery restores it" do
      worker = Agent.start_link(fn -> :down end) |> elem(1)
      on_exit(fn -> Agent.stop(worker) end)
      check = fn -> if Agent.get(worker, & &1) == :up, do: :ok, else: {:error, :worker_down} end

      assert Health.ready?(database: fn -> :ok end, migrations: fn -> :ok end, supervision: check) ==
               false

      Agent.update(worker, fn _ -> :up end)
      assert Health.ready?(database: fn -> :ok end, migrations: fn -> :ok end, supervision: check)
    end

    test "readiness can be guarded without changing the liveness probe" do
      Application.put_env(:exocomp_mission_control, :readiness_token, "probe-token")

      assert request(:get, "/health/ready").status == 401
      assert request(:get, "/health/live").status == 200

      authorized =
        :get
        |> conn("/health/ready")
        |> put_req_header("authorization", "Bearer probe-token")
        |> Exocomp.MissionControl.Endpoint.call([])

      assert authorized.status == 200
    end
  end

  describe "Prometheus schema" do
    test "metric names, types, and label keys are stable and low cardinality" do
      definitions = Metrics.definitions()
      names = Enum.map(definitions, & &1.name)

      assert length(names) == length(Enum.uniq(names))
      assert Enum.all?(definitions, &(&1.type in [:counter, :gauge, :histogram]))

      assert Enum.flat_map(definitions, & &1.labels)
             |> Enum.all?(&(&1 in ["state", "outcome", "severity", "status", "from", "to"]))

      refute Enum.any?(definitions, fn definition ->
               Enum.any?(
                 definition.labels,
                 &(&1 in ["cluster_id", "node_id", "organization_id", "tenant_id"])
               )
             end)

      assert "exocomp_mission_control_events_ingested_total" in names
      assert "exocomp_mission_control_webhook_deliveries_total" in names
      assert "exocomp_mission_control_database_queue_length" in names
      assert "exocomp_mission_control_retention_job_status" in names
      assert "exocomp_mission_control_service_transitions_total" in names
      assert "exocomp_mission_control_recovery_cooldowns_total" in names
    end

    test "metrics render zero-valued series and reject unbounded labels" do
      output = Metrics.render()

      assert output =~ "# TYPE exocomp_mission_control_events_ingested_total counter"
      assert output =~ ~s(exocomp_mission_control_events_ingested_total{outcome="accepted"} 0)
      assert output =~ "# TYPE exocomp_mission_control_event_ingest_lag_seconds histogram"

      assert {:error, :unknown_metric} ==
               Metrics.increment("exocomp_mission_control_not_a_metric", 1)

      assert {:error, :invalid_labels} ==
               Metrics.increment(
                 "exocomp_mission_control_events_ingested_total",
                 %{outcome: "event-123"},
                 1
               )

      assert {:error, :invalid_observation} ==
               Metrics.observe("exocomp_mission_control_event_ingest_lag_seconds", -1)
    end

    test "metrics endpoint returns exposition without identifiers" do
      conn = request(:get, "/metrics")

      assert conn.status == 200
      assert [content_type] = get_resp_header(conn, "content-type")
      assert String.starts_with?(content_type, "text/plain; version=0.0.4")
      refute conn.resp_body =~ "cluster_id"
      refute conn.resp_body =~ "tenant_id"
      refute conn.resp_body =~ "organization_id"
    end

    test "telemetry updates aggregate connection, ingest, latency, and webhook metrics" do
      :ok = Telemetry.emit(:connection, %{connected: 2, disconnected: 1})
      :ok = Telemetry.emit(:ingest, %{lag_seconds: 0.25}, %{outcome: :accepted})
      :ok = Telemetry.emit(:conversation, %{latency_seconds: 0.5})
      :ok = Telemetry.emit(:webhook, %{}, %{outcome: :success})

      output = Metrics.render()
      assert output =~ ~s(exocomp_mission_control_connections{state="connected"} 2)
      assert output =~ ~s(exocomp_mission_control_events_ingested_total{outcome="accepted"} 1)
      assert output =~ "exocomp_mission_control_event_ingest_lag_seconds_sum 0.250000"
      assert output =~ ~s(exocomp_mission_control_webhook_deliveries_total{outcome="success"} 1)
    end

    test "desired-service telemetry stays aggregate and low cardinality" do
      :ok = Telemetry.emit(:desired_state, %{count: 2}, %{state: :healthy})
      :ok = Telemetry.emit(:desired_state, %{}, %{from: :healthy, to: :stale})
      :ok = Telemetry.emit(:discovery)
      :ok = Telemetry.emit(:profile, %{coverage: 0.75})
      :ok = Telemetry.emit(:ceph, %{}, %{severity: :warning})
      :ok = Telemetry.emit(:recovery, %{}, %{outcome: :cooldown})

      output = Metrics.render()
      assert output =~ ~s(exocomp_mission_control_services{state="healthy"} 2)

      assert output =~
               ~s(exocomp_mission_control_service_transitions_total{from="healthy",to="stale"} 1)

      assert output =~ "exocomp_mission_control_discovery_failures_total 1"
      assert output =~ "exocomp_mission_control_profile_coverage 0.750000"
      assert output =~ ~s(exocomp_mission_control_ceph_health{severity="warning"} 1)
      assert output =~ ~s(exocomp_mission_control_ceph_health{severity="critical"} 0)
      assert output =~ "exocomp_mission_control_recovery_cooldowns_total 1"
    end
  end

  defp request(method, path) do
    method
    |> conn(path)
    |> Exocomp.MissionControl.Endpoint.call([])
  end
end
