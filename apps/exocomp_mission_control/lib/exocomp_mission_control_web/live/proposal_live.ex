# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule ExocompMissionControlWeb.ProposalLive do
  @moduledoc """
  LiveView for displaying a proposal with controls and decision timeline.

  Displays:
  - Proposal details (action, target, parameters, evidence, risk, etc.)
  - Operator approval/denial controls (bound to context guards)
  - Timeline of decision, delivery, execution, verification, and terminal events

  State transitions:
  - Pending → Approved/Denied (operator decides)
  - Approved → Delivered (cluster acks command)
  - Delivered → Executing → Verified/Failed
  - Failed state shows error artifacts
  - Terminal states disable further action

  Never shows Approved as Executed until execution event arrives from cluster.
  """

  use Phoenix.LiveView

  alias Exocomp.MissionControl

  @impl true
  def render(assigns) do
    ~H"""
    <div class="proposal-container">
      <div class="proposal-details">
        <div class="proposal-header">
          <h2><%= @proposal.action_id %></h2>
          <span class="proposal-state" data-state={@state}>
            <%= format_state(@state) %>
          </span>
        </div>

        <div class="proposal-info">
          <dl>
            <dt>Cluster</dt>
            <dd><code><%= @proposal.cluster_id %></code></dd>

            <dt>Target</dt>
            <dd><code><%= @proposal.target_id %></code></dd>

            <dt>Parameters</dt>
            <dd>
              <pre><code><%= format_parameters(@proposal.parameters) %></code></pre>
            </dd>

            <dt>Evidence Hash</dt>
            <dd><code class="hash"><%= @proposal.evidence_hash %></code></dd>

            <dt>Evidence Age</dt>
            <dd><%= format_age(@proposal.evidence_age_seconds) %></dd>

            <dt>Risk Assessment</dt>
            <dd><%= @proposal.risk %></dd>

            <dt>Expected Disruption</dt>
            <dd><%= @proposal.disruption %></dd>

            <dt>Rationale</dt>
            <dd><em><%= @proposal.rationale %></em></dd>

            <dt>Policy Result</dt>
            <dd><code><%= @proposal.policy_result %></code></dd>

            <dt>Expires At</dt>
            <dd>
              <%= format_datetime(@proposal.expires_at) %>
              <span class="expiry-warning" :if={is_expiring_soon?(@proposal.expires_at)}>
                Expiring soon
              </span>
            </dd>
          </dl>
        </div>

        <div class="proposal-controls">
          <div :if={has_decision?(@decision)}>
            <p class="decision-made">
              <strong>Decision:</strong>
              <%= format_decision(@decision) %>
              <span class="decided-by">by <%= @decision.decided_by %> at <%= format_datetime(@decision.decided_at) %></span>
            </p>
          </div>

          <div :if={!has_decision?(@decision)} class="control-buttons">
            <button
              :if={MissionControl.can_approve?(@user_role, @state, false)}
              phx-click="approve"
              class="btn btn-approve"
              disabled={!MissionControl.controls_enabled?(@state)}
              title={button_title(@state, :approve)}
            >
              Approve
            </button>

            <button
              :if={MissionControl.can_deny?(@user_role, @state, false)}
              phx-click="deny"
              class="btn btn-deny"
              disabled={!MissionControl.controls_enabled?(@state)}
              title={button_title(@state, :deny)}
            >
              Deny
            </button>

            <span :if={!MissionControl.controls_enabled?(@state)} class="control-disabled-reason">
              <%= disabled_reason(@state) %>
            </span>
          </div>

          <div :if={@user_role == :viewer} class="viewer-notice">
            <p>You have viewer-only access. Decision controls are not available.</p>
          </div>
        </div>
      </div>

      <div class="proposal-timeline">
        <h3>Timeline</h3>
        <div class="timeline">
          <div :for={event <- @timeline} class="timeline-event" data-type={event.type}>
            <div class="timeline-marker">
              <span class="timeline-icon" title={event_type_label(event.type)}>
                <%= event_type_icon(event.type) %>
              </span>
            </div>
            <div class="timeline-content">
              <h4><%= event_type_label(event.type) %></h4>
              <p class="timestamp"><%= format_datetime(event.timestamp) %></p>
              <p :if={event.result}>
                <strong>Result:</strong>
                <span class="result" data-result={event.result}>
                  <%= String.upcase(Atom.to_string(event.result)) %>
                </span>
              </p>
              <p :if={event.error} class="error"><strong>Error:</strong> <%= event.error %></p>
              <div :if={!Enum.empty?(event.artifacts)} class="artifacts">
                <details>
                  <summary>Artifacts</summary>
                  <pre><code><%= Jason.encode!(event.artifacts, pretty: true) %></code></pre>
                </details>
              </div>
            </div>
          </div>
        </div>

        <div :if={Enum.empty?(@timeline)} class="timeline-empty">
          <p>No timeline events yet.</p>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, session, socket) do
    proposal_id = params["proposal_id"]
    user_role = session["user_role"] || :viewer

    # In a real implementation, fetch proposal and timeline from the backend
    proposal = fetch_proposal(proposal_id)
    timeline = fetch_timeline(proposal_id)
    state = determine_state(proposal, timeline)
    decision = extract_decision(proposal)

    socket =
      socket
      |> assign(
        proposal_id: proposal_id,
        proposal: proposal,
        timeline: timeline,
        state: state,
        decision: decision,
        user_role: user_role
      )
      |> subscribe_to_updates(proposal_id)

    {:ok, socket}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    %{proposal: proposal, user_role: user_role} = socket.assigns

    if MissionControl.can_approve?(user_role, socket.assigns.state, false) do
      case handle_approval(proposal, user_role) do
        {:ok, updated_proposal} ->
          {:noreply,
           socket
           |> assign(proposal: updated_proposal, decision: extract_decision(updated_proposal))
           |> put_flash(:info, "Proposal approved. Cluster is processing the decision.")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Approval failed: #{reason}")}
      end
    else
      {:noreply,
       put_flash(socket, :error, "You do not have permission to approve this proposal.")}
    end
  end

  def handle_event("deny", _params, socket) do
    %{proposal: proposal, user_role: user_role} = socket.assigns

    if MissionControl.can_deny?(user_role, socket.assigns.state, false) do
      case handle_denial(proposal, user_role) do
        {:ok, updated_proposal} ->
          {:noreply,
           socket
           |> assign(proposal: updated_proposal, decision: extract_decision(updated_proposal))
           |> put_flash(:info, "Proposal denied.")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Denial failed: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "You do not have permission to deny this proposal.")}
    end
  end

  @impl true
  def handle_info({:proposal_updated, proposal, timeline}, socket) do
    {:noreply,
     socket
     |> assign(proposal: proposal, timeline: timeline)
     |> assign(state: determine_state(proposal, timeline))
     |> assign(decision: extract_decision(proposal))}
  end

  def handle_info({:concurrent_decision_conflict, operator}, socket) do
    {:noreply,
     socket
     |> put_flash(
       :error,
       "Another operator (#{operator}) has already made a decision on this proposal."
     )
     |> assign(state: :terminal)}
  end

  # ── Private Helpers ──────────────────────────────────────────────────

  defp fetch_proposal(proposal_id) do
    # This will be implemented by the backend task that sets up the proposal
    # data model. For now, return a placeholder structure.
    %{
      proposal_id: proposal_id,
      cluster_id: "cluster-123",
      target_id: "node-456",
      action_id: "restart_service",
      parameters: %{"service_name" => "nginx"},
      evidence_hash: "sha256:abc123...",
      evidence_age_seconds: 45,
      risk: "low",
      disruption: "service_restart",
      rationale: "Service is unresponsive",
      policy_result: "approved_by_policy",
      expires_at: DateTime.utc_now() |> DateTime.add(300, :second)
    }
  end

  defp fetch_timeline(proposal_id) do
    # This will be implemented by the backend task. For now, return empty.
    []
  end

  defp determine_state(proposal, timeline) do
    cond do
      timeline_contains_type?(timeline, :terminal) ->
        :terminal

      timeline_contains_type?(timeline, :verification) ->
        :verified

      timeline_contains_type?(timeline, :execution) ->
        :executing

      timeline_contains_type?(timeline, :command_delivery) ->
        :delivered

      has_approval?(proposal) ->
        :approved

      has_denial?(proposal) ->
        :denied

      is_expired?(proposal) ->
        :expired

      is_evidence_stale?(proposal) ->
        :stale

      true ->
        :pending
    end
  end

  defp has_decision?(decision) do
    decision.decision_type != nil
  end

  defp has_approval?(proposal) do
    Map.get(proposal, :approved_by) != nil
  end

  defp has_denial?(proposal) do
    Map.get(proposal, :denied_by) != nil
  end

  defp is_expired?(proposal) do
    DateTime.compare(DateTime.utc_now(), proposal.expires_at) == :gt
  end

  defp is_evidence_stale?(proposal) do
    # Evidence is stale if older than configured window (e.g., 5 minutes)
    proposal.evidence_age_seconds > 300
  end

  defp extract_decision(proposal) do
    %{
      decision_type:
        (Map.get(proposal, :approved_by) && :approved) ||
          (Map.get(proposal, :denied_by) && :denied),
      decided_by: Map.get(proposal, :approved_by) || Map.get(proposal, :denied_by),
      decided_at: Map.get(proposal, :decided_at)
    }
  end

  defp handle_approval(proposal, user_role) do
    # This will be implemented by the backend to:
    # 1. Authenticate the operator decision
    # 2. Re-collect evidence and verify freshness
    # 3. Rerun deterministic local policy
    # 4. Send command to cluster to create approval token
    # 5. Record decision in the database

    # For now, return a simulated success
    {:ok, Map.merge(proposal, %{approved_by: user_role, decided_at: DateTime.utc_now()})}
  end

  defp handle_denial(proposal, user_role) do
    # Similar to approval, but records denial
    {:ok, Map.merge(proposal, %{denied_by: user_role, decided_at: DateTime.utc_now()})}
  end

  defp subscribe_to_updates(socket, proposal_id) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Exocomp.MissionControl.PubSub, "proposal:#{proposal_id}")
    end

    socket
  end

  defp timeline_contains_type?(timeline, type) do
    Enum.any?(timeline, &(&1.type == type))
  end

  defp is_expiring_soon?(expires_at) do
    DateTime.diff(expires_at, DateTime.utc_now()) < 60
  end

  defp format_state(:pending), do: "Pending"
  defp format_state(:approved), do: "Approved"
  defp format_state(:denied), do: "Denied"
  defp format_state(:offline), do: "Offline"
  defp format_state(:expired), do: "Expired"
  defp format_state(:stale), do: "Stale Evidence"
  defp format_state(:terminal), do: "Terminal"
  defp format_state(:delivered), do: "Delivered"
  defp format_state(:executing), do: "Executing"
  defp format_state(:verified), do: "Verified"

  defp format_parameters(params) when is_map(params) do
    params
    |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
    |> Enum.join("\n")
  end

  defp format_age(seconds) when is_integer(seconds) do
    cond do
      seconds < 60 -> "#{seconds}s ago"
      seconds < 3600 -> "#{div(seconds, 60)}m #{rem(seconds, 60)}s ago"
      true -> "#{div(seconds, 3600)}h #{rem(div(seconds, 60), 60)}m ago"
    end
  end

  defp format_datetime(datetime) do
    DateTime.to_string(datetime)
  end

  defp format_decision(decision) do
    case decision.decision_type do
      :approved -> "✓ Approved"
      :denied -> "✗ Denied"
      nil -> "No decision"
    end
  end

  defp event_type_label(:decision), do: "Decision"
  defp event_type_label(:command_delivery), do: "Command Delivery"
  defp event_type_label(:execution), do: "Execution"
  defp event_type_label(:verification), do: "Verification"
  defp event_type_label(:terminal), do: "Terminal"

  defp event_type_icon(:decision), do: "✎"
  defp event_type_icon(:command_delivery), do: "→"
  defp event_type_icon(:execution), do: "⚙"
  defp event_type_icon(:verification), do: "✓"
  defp event_type_icon(:terminal), do: "■"

  defp button_title(:offline, _), do: "Cluster is offline"
  defp button_title(:expired, _), do: "Proposal has expired"
  defp button_title(:stale, _), do: "Evidence freshness window elapsed"
  defp button_title(:terminal, _), do: "Proposal is in terminal state"
  defp button_title(_, :approve), do: "Send approval decision to cluster"
  defp button_title(_, :deny), do: "Send denial decision to cluster"

  defp disabled_reason(:offline), do: "Cluster is offline"
  defp disabled_reason(:expired), do: "Proposal has expired"
  defp disabled_reason(:stale), do: "Evidence freshness window elapsed"
  defp disabled_reason(:terminal), do: "Proposal is in terminal state"
  defp disabled_reason(_), do: "Controls disabled"
end
