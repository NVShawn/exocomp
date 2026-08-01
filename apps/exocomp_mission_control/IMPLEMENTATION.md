# Proposal Controls and Timeline Implementation

## Overview

EXOCOMP-169 implements proposal controls and action timeline visualization for the Mission Control LiveView interface. This document describes the architecture, components, and integration points.

## Components

### 1. Core Domain Model (`Exocomp.MissionControl`)

Defines the domain types and business logic for proposals:

- **Proposal State**: `pending | approved | denied | offline | expired | stale | terminal`
- **Timeline Events**: Decision, command delivery, execution, verification, terminal
- **Control Enable/Disable Logic**: Determines when approval/denial buttons should be available
- **Permission Checks**: Role-based access (viewer, operator, admin)

Key functions:
- `controls_enabled?(state)` - Check if decision controls should be enabled
- `can_approve?(role, state, has_decision)` - Check if operator can approve
- `can_deny?(role, state, has_decision)` - Check if operator can deny

### 2. LiveView Component (`ExocompMissionControlWeb.ProposalLive`)

Phoenix LiveView component that renders the proposal details, controls, and timeline.

**Rendered Fields:**
- Proposal target ID and action ID
- Parameters (flat string map)
- Evidence hash and age (formatted as human-readable duration)
- Risk and disruption assessments
- Rationale (from LLM)
- Policy result (deterministic policy engine output)
- Expiry timestamp with warning if expiring soon

**Controls:**
- Approve button (enabled when: operator role, pending state, controls enabled, no concurrent decision)
- Deny button (same conditions as approve)
- Disabled state shows reason tooltip
- Viewer role sees notice that decisions unavailable

**Timeline:**
- Sequential display of events: decision → delivery → execution → verification → terminal
- Each event shows: timestamp, result (success/failure), error message if present
- Terminal artifacts shown in expandable details
- Timeline empty state when no events

**State Transitions:**
- Pending → Approved/Denied (operator action)
- Approved → Delivered → Executing → Verified/Failed
- Any state can go to Terminal (final outcome)
- Controls disabled in offline, expired, stale, terminal states

**Critical Invariant:**
- Approved proposals **never display as executed** until an execution event arrives from the cluster
- This is enforced by checking `timeline_contains_type?(timeline, :execution)`

### 3. Phoenix Integration

**Router** (`lib/exocomp_mission_control_web/router.ex`):
- Route: `GET /proposals/:proposal_id` → ProposalLive
- Browser pipeline with OIDC session extraction (to be implemented by backend)

**Endpoint** (`lib/exocomp_mission_control_web/endpoint.ex`):
- Phoenix LiveView WebSocket at `/live`
- Static file serving
- Code reloading in dev
- Session management

**Telemetry** (`lib/exocomp_mission_control_web/telemetry.ex`):
- VM memory metrics
- Foundation for Mission Control operational metrics

### 4. Styling (`proposal_styles.css`)

Responsive CSS for:
- Proposal details panel (info grid, state badge, alert styles)
- Control buttons (approve/deny, disabled states, tooltips)
- Timeline visualization (vertical connector, event markers, colored by type)
- Responsive breakpoints (1024px, 640px)
- Accessibility: color + icon combination for status, sufficient contrast

## Test Coverage

### Unit Tests (`test/exocomp_mission_control_test.exs`)

Tests for domain model:
- `controls_enabled?/1` - All state scenarios
- `can_approve?/3` - Operator, admin, viewer; state-based disabling; decision conflict
- `can_deny?/3` - Same as approve

### LiveView Tests (`test/exocomp_mission_control_web/live/proposal_live_test.exs`)

Comprehensive coverage:
- **Display**: All proposal fields render, timeline has expected events
- **Approval**: Operator/admin can see button, viewers cannot, button disabled appropriately
- **Denial**: Same as approval
- **Timeline**: Events for decision, delivery, execution, verification, terminal
- **Failures**: Execution failure, verification failure with error display
- **Approved Invariant**: Approved without execution shows as approved, not executed
- **Concurrent Conflicts**: Detection and operator name in conflict message
- **Evidence**: Age formatting, expiry warning, stale state handling

## Integration Points with Backend Tasks

The implementation references these features that will be provided by blocking tasks:

### From EXOCOMP-162, 163, 168 (TBD):
- Proposal creation and storage (database model)
- Timeline event generation and storage
- Cluster connection state (online/offline)
- Evidence freshness calculation
- Policy engine result (risk, disruption, policy_result fields)
- Command execution and verification tracking

### Backend Integration Expected:

1. **Proposal Fetching**
   ```elixir
   def mount(params, session, socket) do
     proposal_id = params["proposal_id"]
     proposal = fetch_proposal(proposal_id)  # To be implemented by backend
     timeline = fetch_timeline(proposal_id)  # To be implemented by backend
   ```

2. **OIDC Session**
   ```elixir
   defp put_user_session(conn, _opts) do
     # Backend will extract from OIDC token in session
     user_role = conn.assigns.user_role  # :viewer, :operator, or :admin
   ```

3. **Event Publishing**
   ```elixir
   def handle_info({:proposal_updated, proposal, timeline}, socket) do
     # Backend publishes via Phoenix.PubSub when cluster sends updates
   ```

4. **Approval/Denial Handling**
   ```elixir
   def handle_event("approve", _params, socket) do
     # Backend will:
     # - Re-collect evidence
     # - Verify freshness
     # - Rerun policy
     # - Send command to cluster
     # - Record decision
   ```

## Development Notes

### Current Status

- ✅ Domain model and permission logic
- ✅ LiveView component with full UI
- ✅ Styling (responsive, accessible)
- ✅ Unit and LiveView tests
- ⏳ Integration with actual backend (blocked on EXOCOMP-162, 163, 168)

### Placeholders for Backend Integration

- `fetch_proposal/1` - Mock implementation, needs backend
- `fetch_timeline/1` - Mock implementation, needs backend
- `handle_approval/2` - Mock implementation, needs backend API
- `handle_denial/2` - Mock implementation, needs backend API
- OIDC user extraction in `put_user_session/2`

### To Run Tests

```bash
# In the repo root, run the container-based test:
make test

# Or specifically for mission control:
mix test --app exocomp_mission_control
```

### To Run Linter

```bash
# Format check:
make fmt-check

# Full lint:
make lint
```

## Architecture Decisions

1. **Separate Domain Module**: `Exocomp.MissionControl` keeps business logic separate from LiveView, making it testable without Phoenix.

2. **State Machine via Atom**: Proposal states are clearly defined atoms with explicit transitions, making state handling obvious.

3. **Permission Checks at Two Levels**:
   - Domain model has declarative permission rules
   - LiveView enforces at render time (show/hide controls)
   - Backend enforces on approval/denial action (security boundary)

4. **Timeline as Event List**: Events are ordered by timestamp, allowing easy display and analysis of proposal lifecycle.

5. **Approved Invariant Enforcement**: The check `timeline_contains_type?(timeline, :execution)` explicitly prevents showing approved as executed without proof.

6. **Responsive Styling**: CSS respects mobile devices (640px breakpoint for single column, full-width buttons).

## Future Enhancements

- Analytics: Track approval rates, decision times, failure reasons
- Conflict Resolution UI: Show which operator made conflicting decision
- Retry UI: Allow re-proposing after failure
- Bulk Operations: Approve/deny multiple proposals
- Policy Explanation: Show why policy approved/denied action
- Evidence Details: Link to raw evidence in cluster diagnostics
