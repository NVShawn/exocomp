<!-- BEGIN OOMPAH PROJECT BOOTSTRAP v:1 -->
# Plans

Design and implementation documentation for this project. Architecture notes,
proposed features, internal mechanism inventories, and design records belong
here.

If you are trying to learn how this project works inside or how it might work
in the future, you are in the right place. If you are trying to learn how to
use it, see [`../docs/`](../docs/).

## Plans Are Not Tasks

Creating or updating a design document here does not require a corresponding
oompah task. Plans can explore possible work before it is accepted or
scheduled. Create an oompah task when implementation begins or when the work
needs status, ownership, dependencies, or orchestration; the task can link to
the plan rather than duplicate it.

## Plan Docs Are Living Specifications

Every non-trivial plan should include acceptance criteria that define what
"done" means in testable terms.

```markdown
## Acceptance Criteria

- [ ] CRIT-1: <testable claim and verification path>
- [ ] CRIT-2: ...
```

Vague criteria such as "works well" or "is robust" do not count. Tie each item
to a passing test, command, or manual procedure with a clear pass/fail result.
These checklists describe the specification; they are not a substitute task
tracker.

## Exocomp Plans

- [Project plan](exocomp.md)
- [Milestone 1: Prototype Elixir node agent](milestone-1-node-agent.md)
- [Milestone 2: Coordinator, discovery, and enrollment](milestone-2-coordinator.md)
- [Milestone 3: Safety validation and controlled remediation](milestone-3-safety-validation.md)
- [Milestone 4: Minimal-impact systemd service recovery](milestone-4-service-recovery.md)
- [Milestone 5: Performance and resource analysis](milestone-5-performance.md)
- [Milestone 6: Documentation and open-source release](milestone-6-release.md)
<!-- END OOMPAH PROJECT BOOTSTRAP -->
