# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.IncidentLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Exocomp.MissionControl.Incidents

  @endpoint Exocomp.MissionControl.Endpoint
  @now ~U[2026-01-01 00:00:00Z]

  setup do
    :ok = Incidents.reset()
    :ok
  end

  test "inbox filters by severity, status, cluster, and label and keeps pages scoped" do
    assert {:ok, critical} =
             Incidents.record(evidence("critical", severity: "critical", labels: ["prod"]))

    assert {:ok, acknowledged} =
             Incidents.record(
               evidence(
                 "ack",
                 severity: "low",
                 labels: ["test"],
                 cluster_id: "cluster-b",
                 event_type: :acknowledged
               )
             )

    assert {:ok, _foreign} =
             Incidents.record(evidence("foreign", organization_id: "org-b", labels: ["prod"]))

    assert {:ok, view, html} =
             live(
               conn(%{organization_id: "org-a", subject: "viewer", role: :viewer}),
               "/incidents"
             )

    assert html =~ critical.id
    refute html =~ "foreign"

    filtered =
      view
      |> element("#incident-filters")
      |> render_change(%{
        "filters" => %{
          "severity" => "critical",
          "status" => "open",
          "cluster" => "cluster-a",
          "label" => "prod"
        }
      })

    assert filtered =~ critical.id
    refute filtered =~ acknowledged.id
    refute filtered =~ "foreign"
  end

  test "inbox paginates newest incidents and exposes page navigation" do
    for index <- 1..21 do
      assert {:ok, _incident} =
               Incidents.record(
                 evidence("node-#{index}", occurred_at: DateTime.add(@now, index, :second))
               )
    end

    {:ok, view, html} =
      live(conn(%{organization_id: "org-a", subject: "viewer", role: :viewer}), "/incidents")

    assert html =~ "Page 1 of 2"
    assert html =~ "node-21"
    refute html =~ "node-1</a>"

    {:ok, _page_two_view, page_two} =
      live(
        conn(%{organization_id: "org-a", subject: "viewer", role: :viewer}),
        "/incidents?page=2"
      )

    assert page_two =~ "Page 2 of 2"
    assert page_two =~ "node-1"
  end

  test "detail renders evidence, related incidents, and snooze wake time" do
    assert {:ok, incident} =
             Incidents.record(evidence("target", service: "api", software_version: "1.2.3"))

    assert {:ok, _related} =
             Incidents.record(
               evidence(
                 "related",
                 occurred_at: DateTime.add(@now, 30, :second),
                 service: "api",
                 software_version: "1.2.3"
               )
             )

    {:ok, _view, html} =
      live(
        conn(%{organization_id: "org-a", subject: "viewer", role: :viewer}),
        "/incidents/#{incident.id}"
      )

    assert html =~ "Timeline and evidence"
    assert html =~ "safe evidence"
    assert html =~ "Related incidents"
    assert html =~ "Viewer access is read-only"
    refute html =~ "Acknowledge"
  end

  test "operator controls acknowledge, assign, snooze, and resolve with a required reason" do
    assert {:ok, incident} = Incidents.record(evidence("operator"))

    {:ok, view, _html} =
      live(
        conn(%{organization_id: "org-a", subject: "operator@example.com", role: :operator}),
        "/incidents/#{incident.id}"
      )

    view
    |> element("form[phx-submit=acknowledge]")
    |> render_submit(%{"expected_state" => "open"})

    assert render(view) =~ "acknowledged"

    view
    |> element("form[phx-submit=assign]")
    |> render_submit(%{"expected_state" => "acknowledged", "assignee" => "alice@example.com"})

    wake = DateTime.utc_now() |> DateTime.add(3_600, :second)

    view
    |> element("form[phx-submit=snooze]")
    |> render_submit(%{
      "expected_state" => "acknowledged",
      "snooze_until" => DateTime.to_iso8601(wake)
    })

    assert render(view) =~ "Snoozed until"
    assert render(view) =~ Calendar.strftime(wake, "%Y-%m-%d")

    view
    |> element("form[phx-submit=resolve]")
    |> render_submit(%{"expected_state" => "acknowledged", "reason" => "Service restarted"})

    assert render(view) =~ "resolved"

    assert Incidents.get("org-a", incident.id) |> elem(1) |> Map.get(:resolution_reason) ==
             "Service restarted"
  end

  test "required reason, invalid transition, and stale forms fail closed" do
    assert {:ok, incident} = Incidents.record(evidence("stale"))

    {:ok, view, _html} =
      live(
        conn(%{organization_id: "org-a", subject: "operator", role: :operator}),
        "/incidents/#{incident.id}"
      )

    empty_reason =
      view
      |> element("form[phx-submit=resolve]")
      |> render_submit(%{"expected_state" => "open", "reason" => ""})

    assert empty_reason =~ "A reason is required"

    assert {:ok, _resolved} =
             Incidents.resolve(
               "org-a",
               incident.id,
               "external resolution",
               "other",
               "org-a",
               :operator
             )

    stale =
      view
      |> element("form[phx-submit=acknowledge]")
      |> render_submit(%{"expected_state" => "open"})

    assert stale =~ "Incident changed"
    refute has_element?(view, "form[phx-submit=acknowledge]")
  end

  test "open, resolve, and reopen updates reach a subscribed detail view" do
    assert {:ok, incident} = Incidents.record(evidence("realtime"))

    {:ok, view, _html} =
      live(
        conn(%{organization_id: "org-a", subject: "operator", role: :operator}),
        "/incidents/#{incident.id}"
      )

    assert {:ok, _resolved} =
             Incidents.resolve(
               "org-a",
               incident.id,
               "resolved for test",
               "operator",
               "org-a",
               :operator
             )

    assert render(view) =~ "resolved"

    assert {:ok, _reopened} =
             Incidents.record(
               evidence("realtime",
                 occurred_at: DateTime.add(@now, 10, :second),
                 correlation_id: "reopen"
               )
             )

    assert render(view) =~ "open"
    assert render(view) =~ "reopened"
  end

  test "viewer cannot mutate an incident and another organization cannot view it" do
    assert {:ok, incident} = Incidents.record(evidence("private"))

    {:ok, viewer, html} =
      live(
        conn(%{organization_id: "org-a", subject: "viewer", role: :viewer}),
        "/incidents/#{incident.id}"
      )

    refute has_element?(viewer, "form[phx-submit=resolve]")
    assert html =~ "read-only"

    {:ok, _other_view, other_html} =
      live(
        conn(%{organization_id: "org-b", subject: "operator", role: :operator}),
        "/incidents/#{incident.id}"
      )

    assert other_html =~ "Incident not found"
  end

  defp conn(user) do
    Phoenix.ConnTest.build_conn()
    |> Plug.Test.init_test_session(current_user: user)
  end

  defp evidence(target, overrides \\ []) do
    Map.merge(
      %{
        organization_id: "org-a",
        cluster_id: "cluster-a",
        alert_type: "service.failed",
        source: "systemd",
        target_type: "node",
        target_identity: target,
        occurred_at: @now,
        correlation_id: "corr-#{target}",
        severity: "high",
        labels: ["prod"],
        payload: %{"message" => "safe evidence"}
      },
      Map.new(overrides)
    )
  end
end
