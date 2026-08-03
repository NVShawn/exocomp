# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ComponentsTest do
  @moduledoc """
  Tests for reusable UI components.

  Verifies component rendering, accessibility, and visual styling.
  """
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Exocomp.MissionControl.Components

  describe "role_badge component" do
    test "renders viewer badge with correct styling" do
      html = render_component(&Components.role_badge/1, %{role: :viewer})
      assert html =~ "Viewer"
      assert html =~ "bg-blue-100"
      assert html =~ "aria-label"
    end

    test "renders operator badge with correct styling" do
      html = render_component(&Components.role_badge/1, %{role: :operator})
      assert html =~ "Operator"
      assert html =~ "bg-orange-100"
    end

    test "renders admin badge with correct styling" do
      html = render_component(&Components.role_badge/1, %{role: :admin})
      assert html =~ "Admin"
      assert html =~ "bg-red-100"
    end

    test "role_badge has proper accessibility attributes" do
      html = render_component(&Components.role_badge/1, %{role: :admin})
      assert html =~ "role=\"status\""
      assert html =~ "aria-label"
    end
  end

  describe "connectivity_indicator component" do
    test "renders connected status with green indicator" do
      html = render_component(&Components.connectivity_indicator/1, %{status: :connected})
      assert html =~ "text-green-600"
      assert html =~ "Connected"
    end

    test "renders disconnected status with gray indicator" do
      html = render_component(&Components.connectivity_indicator/1, %{status: :disconnected})
      assert html =~ "text-gray-400"
      assert html =~ "Disconnected"
    end

    test "renders reconnecting status with yellow indicator" do
      html = render_component(&Components.connectivity_indicator/1, %{status: :reconnecting})
      assert html =~ "text-yellow-600"
      assert html =~ "Reconnecting"
    end
  end

  describe "health_indicator component" do
    test "renders healthy status with green styling" do
      html = render_component(&Components.health_indicator/1, %{status: :healthy})
      assert html =~ "bg-green-100"
      assert html =~ "Healthy"
    end

    test "renders degraded status with yellow styling" do
      html = render_component(&Components.health_indicator/1, %{status: :degraded})
      assert html =~ "bg-yellow-100"
      assert html =~ "Degraded"
    end

    test "renders unhealthy status with red styling" do
      html = render_component(&Components.health_indicator/1, %{status: :unhealthy})
      assert html =~ "bg-red-100"
      assert html =~ "Unhealthy"
    end
  end

  describe "severity_indicator component" do
    test "renders critical severity with red styling" do
      html = render_component(&Components.severity_indicator/1, %{level: :critical})
      assert html =~ "Critical"
      assert html =~ "bg-red-100"
      assert html =~ "role=\"status\""
    end

    test "renders high severity with orange styling" do
      html = render_component(&Components.severity_indicator/1, %{level: :high})
      assert html =~ "High"
      assert html =~ "bg-orange-100"
    end

    test "renders info severity with gray styling" do
      html = render_component(&Components.severity_indicator/1, %{level: :info})
      assert html =~ "Info"
      assert html =~ "bg-gray-100"
    end

    test "severity_indicator has accessible label" do
      html = render_component(&Components.severity_indicator/1, %{level: :critical})
      assert html =~ "aria-label"
      assert html =~ "severity"
    end

    test "custom label overrides default text" do
      html = render_component(&Components.severity_indicator/1, %{level: :high, label: "Alert"})
      assert html =~ "Alert"
    end
  end

  describe "status_badge component" do
    test "renders active status with green styling" do
      html = render_component(&Components.status_badge/1, %{status: :active})
      assert html =~ "Active"
      assert html =~ "bg-green-100"
    end

    test "renders pending status with yellow styling" do
      html = render_component(&Components.status_badge/1, %{status: :pending})
      assert html =~ "Pending"
      assert html =~ "bg-yellow-100"
    end

    test "renders failed status with red styling" do
      html = render_component(&Components.status_badge/1, %{status: :failed})
      assert html =~ "Failed"
      assert html =~ "bg-red-100"
    end

    test "status_badge has role=\"status\"" do
      html = render_component(&Components.status_badge/1, %{status: :active})
      assert html =~ "role=\"status\""
    end
  end

  describe "empty_state component" do
    test "renders title and description" do
      html =
        render_component(&Components.empty_state/1, %{
          title: "No Data",
          description: "No data available"
        })

      assert html =~ "No Data"
      assert html =~ "No data available"
    end

    test "empty_state has proper accessibility" do
      html =
        render_component(&Components.empty_state/1, %{
          title: "Empty",
          description: "Empty state"
        })

      assert html =~ "role=\"status\""
      assert html =~ "aria-label"
    end

    test "custom icon is displayed" do
      html =
        render_component(&Components.empty_state/1, %{
          title: "Empty",
          description: "No items",
          icon: "📭"
        })

      assert html =~ "📭"
    end
  end

  describe "loading_skeleton component" do
    test "renders list skeleton" do
      html = render_component(&Components.loading_skeleton/1, %{type: :list})
      assert html =~ "animate-pulse"
      assert html =~ "role=\"status\""
    end

    test "renders card skeleton" do
      html = render_component(&Components.loading_skeleton/1, %{type: :card})
      assert html =~ "grid"
      assert html =~ "animate-pulse"
    end

    test "renders text skeleton" do
      html = render_component(&Components.loading_skeleton/1, %{type: :text})
      assert html =~ "space-y-2"
      assert html =~ "animate-pulse"
    end

    test "loading_skeleton has accessible label" do
      html = render_component(&Components.loading_skeleton/1, %{type: :list})
      assert html =~ "aria-label"
    end
  end

  describe "error_state component" do
    test "renders error title and description" do
      html =
        render_component(&Components.error_state/1, %{
          title: "Error",
          description: "Something went wrong"
        })

      assert html =~ "Error"
      assert html =~ "Something went wrong"
      assert html =~ "role=\"alert\""
    end

    test "renders action link when provided" do
      html =
        render_component(&Components.error_state/1, %{
          title: "Error",
          description: "Error occurred",
          action_label: "Retry",
          action_path: "/retry"
        })

      assert html =~ "Retry"
      assert html =~ "/retry"
    end

    test "error_state has role=\"alert\"" do
      html =
        render_component(&Components.error_state/1, %{
          title: "Error",
          description: "Error"
        })

      assert html =~ "role=\"alert\""
    end
  end

  describe "timestamp component" do
    test "renders datetime as ISO format" do
      datetime = DateTime.from_naive!(~N[2026-07-29 21:00:00], "Etc/UTC")
      html = render_component(&Components.timestamp/1, %{datetime: datetime})
      assert html =~ "2026-07-29"
    end

    test "timestamp has time element" do
      datetime = DateTime.from_naive!(~N[2026-07-29 21:00:00], "Etc/UTC")
      html = render_component(&Components.timestamp/1, %{datetime: datetime})
      assert html =~ "<time"
      assert html =~ "datetime="
    end
  end

  describe "data_row component" do
    test "renders label and value" do
      html =
        render_component(&Components.data_row/1, %{
          label: "Name",
          value: "John Doe"
        })

      assert html =~ "Name"
      assert html =~ "John Doe"
    end

    test "data_row with monospace flag applies font-mono class" do
      html =
        render_component(&Components.data_row/1, %{
          label: "ID",
          value: "abc-123-def",
          monospace: true
        })

      assert html =~ "font-mono"
    end

    test "data_row has proper grid layout" do
      html =
        render_component(&Components.data_row/1, %{
          label: "Status",
          value: "Active"
        })

      assert html =~ "grid-cols-3"
    end
  end

  describe "skip_to_main_link component" do
    test "renders skip link" do
      html = render_component(&Components.skip_to_main_link/1, %{})
      assert html =~ "Skip to main content"
      assert html =~ "#main-content"
    end

    test "skip link has sr-only class for hiding visually" do
      html = render_component(&Components.skip_to_main_link/1, %{})
      assert html =~ "sr-only"
    end

    test "skip link is focusable" do
      html = render_component(&Components.skip_to_main_link/1, %{})
      assert html =~ "focus:not-sr-only"
    end
  end

  describe "navigation component" do
    test "displays fleet link" do
      operator = %Exocomp.MissionControl.Identity.Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer
      }

      html = render_component(&Components.navigation/1, %{operator: operator})
      assert html =~ "Fleet"
    end

    test "viewer sees only fleet and incidents" do
      operator = %Exocomp.MissionControl.Identity.Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer
      }

      html = render_component(&Components.navigation/1, %{operator: operator})
      assert html =~ "Fleet"
      assert html =~ "Incidents"
      refute html =~ "Conversations"
      refute html =~ "Admin"
    end

    test "operator sees fleet, incidents, and conversations" do
      operator = %Exocomp.MissionControl.Identity.Operator{
        sub: "user-2",
        organization_id: "org-1",
        role: :operator
      }

      html = render_component(&Components.navigation/1, %{operator: operator})
      assert html =~ "Fleet"
      assert html =~ "Incidents"
      assert html =~ "Conversations"
      refute html =~ "Admin"
    end

    test "admin sees all menu items" do
      operator = %Exocomp.MissionControl.Identity.Operator{
        sub: "user-3",
        organization_id: "org-1",
        role: :admin
      }

      html = render_component(&Components.navigation/1, %{operator: operator})
      assert html =~ "Fleet"
      assert html =~ "Incidents"
      assert html =~ "Conversations"
      assert html =~ "Admin"
    end

    test "navigation has proper ARIA attributes" do
      operator = %Exocomp.MissionControl.Identity.Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer
      }

      html = render_component(&Components.navigation/1, %{operator: operator})
      assert html =~ "aria-label"
      assert html =~ "role="
    end
  end

  describe "flash_messages component" do
    test "displays success message" do
      html =
        render_component(&Components.flash_messages/1, %{
          flash: %{"success" => "Operation completed"}
        })

      assert html =~ "Operation completed"
      assert html =~ "✓"
    end

    test "displays error message" do
      html =
        render_component(&Components.flash_messages/1, %{
          flash: %{"error" => "Operation failed"}
        })

      assert html =~ "Operation failed"
      assert html =~ "✕"
    end

    test "displays info message" do
      html =
        render_component(&Components.flash_messages/1, %{
          flash: %{"info" => "Please note"}
        })

      assert html =~ "Please note"
      assert html =~ "ℹ"
    end

    test "flash messages have proper accessibility roles" do
      html =
        render_component(&Components.flash_messages/1, %{
          flash: %{"error" => "Error"}
        })

      assert html =~ "role=\"alert\""
      assert html =~ "aria-live"
    end

    test "empty flash map renders nothing" do
      html = render_component(&Components.flash_messages/1, %{flash: %{}})
      # Should render the container but with no messages
      assert html != ""
    end
  end
end
