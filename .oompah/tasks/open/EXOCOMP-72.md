---
id: EXOCOMP-72
type: task
status: Open
priority: null
title: Document VM/privileged-container requirements for systemd fixture tests
parent: EXOCOMP-29
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T21:06:59.701752Z'
updated_at: '2026-07-23T21:10:37.039150Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Create documentation explaining how to run the M4 systemd fixture integration tests. Add docs/testing-systemd-fixture.md.

Content must cover:
1. Why systemd tests cannot run in a standard CI container — systemd requires PID 1 or a privileged cgroup environment
2. Supported test environments: recommended VM setup (e.g. QEMU/KVM with systemd-based Linux) and/or privileged Docker/Podman container approach (e.g. --privileged with systemd as init)
3. Step-by-step setup instructions for at least one supported environment
4. How to run the fixture tests: make target, ExUnit tag filter, expected output
5. How to verify non-fixture services are untouched after a test run
6. Cleanup procedure after testing

Also add a brief note in the top-level README.md or AGENTS.md pointing to this doc.

This task can be worked in parallel with EXOCOMP-69, EXOCOMP-70, and EXOCOMP-71 since it is documentation only. Reference: plans/milestone-4-service-recovery.md, section 'Reference Fixture'.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

