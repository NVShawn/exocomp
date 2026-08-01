# Exocomp Mission Control

Phoenix LiveView web application for managing Exocomp clusters.

Operators authenticate with OIDC, view fleet and incident state, converse with cluster-local models, and approve or deny typed remedies.

## Features Implemented

- **Proposal Controls**: Operator approve/deny buttons with context guards
- **Action Timeline**: Visual timeline of decision, delivery, execution, verification, and terminal events
- **Proposal Display**: Render proposal target, action, parameters, evidence age/hash, risk, disruption, rationale, policy result, and expiry
- **State Management**: Proper state handling for offline, expired, stale, and terminal proposals
- **Role-Based Access**: Viewer, operator, and admin roles with appropriate permissions
- **Concurrent Decision Conflict**: Detection and prevention of duplicate decisions

## Development

The app depends on:
- Phoenix 1.7 for web framework
- Phoenix LiveView 0.20 for real-time UI
- OIDC for operator authentication (configured separately)
- Mission Control backend services (from blocking tasks)

## Tests

Run tests with:

```bash
mix test --app exocomp_mission_control
```

Test coverage includes:
- Control enable/disable scenarios (offline, expired, stale, terminal)
- Role-based access control (viewer denial, operator approval)
- Timeline event rendering and state transitions
- Approved invariant (never show as executed until execution event)
- Execution and verification failure scenarios
- Concurrent decision conflict detection
