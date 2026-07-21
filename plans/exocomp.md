# Exocomp Project Plan

## Overview
Exocomp is a distributed AI agent system designed to run lightweight LLM‑based agents on individual cluster nodes, orchestrated by a central management agent via an A2A‑style protocol. The goal is to enable autonomous node‑level diagnostics, metric collection, and simple remediation while keeping resource usage minimal.

## Objectives
- Deploy a tiny LLM (1‑3B parameters) on each node using a lightweight inference runtime (llama.cpp or Ollama).
- Expose a simple HTTP/gRPC endpoint for "ask"/"act" calls on each node.
- Wrap each endpoint in a Hermes‑style agent capable of:
  - Running local diagnostics (CPU, memory, disk, service status).
  - Collecting and forwarding metrics.
  - Executing predefined remediation actions (e.g., restart service, clear logs).
- Implement a coordinator (master) Hermes agent that:
  - Discovers node agents and maintains a cluster state graph.
  - Issues high‑level goals (e.g., "rebalance‑PGs", "replace‑failed‑node").
  - Translates goals into atomic commands for node agents.
  - Validates results and triggers fallback to traditional scripts when needed.
- Ensure safety by pairing LLM suggestions with deterministic validation scripts before applying any changes.

## Architecture
```
[Coordinator Agent] <-- A2A --> [Node Agent (per node)]
                                   |
                                   v
                           [Lightweight LLM Runtime]
                                   |
                                   v
                           [Node OS / Services]
```

### Components
1. **Node Agent**
   - Inference server: llama.cpp/Ollama serving a 1‑3B model.
   - Hermes agent wrapper: exposes `/ask` and `/act` endpoints.
   - Local tools: metric collectors, diagnostic scripts, remediation scripts.
2. **Coordinator Agent**
   - Hermes agent with planning capabilities.
   - A2A client to communicate with node agents.
   - Cluster state graph (in‑memory or lightweight DB).
   - Scheduler for periodic health checks and goal execution.
3. **Validation Layer**
   - Pre‑defined policy/scripts that must approve any LLM‑suggested action.
   - Runs synchronously before state changes.

## Milestones
| Milestone | Description | Target Date |
|-----------|-------------|-------------|
| M1 | Prototype node agent with basic diagnostics endpoint | 2026-08-15 |
| M2 | Coordinator agent capable of discovering nodes and issuing simple commands | 2026-08-31 |
| M3 | Integrate validation scripts for safety‑critical actions | 2026-09-15 |
| M4 | End‑to‑end test: automated pod restart on node failure | 2026-09-30 |
| M5 | Performance overhead analysis (<5% CPU/RAM per node) | 2026-10-15 |
| M6 | Documentation and open‑source release prep | 2026-10-31 |

## Initial Tasks (Node Agent)
- [ ] Install llama.cpp/Ollama on a test node.
- [ ] Download and quantize a 2B‑parameter model (e.g., TinyLlama).
- [ ] Create Hermes agent that loads the model and exposes `/ask` (text generation) and `/act` (invoke predefined tool).
- [ ] Implement diagnostic tool: collect `top`, `df`, `free`, service status.
- [ ] Implement remediation tool: restart a given systemd service.
- [ ] Wire tools into Hermes agent so LLM can request them via structured output.
- [ ] Expose HTTP server (FastAPI or Flask) forwarding to Hermes agent.
- [ ] Write unit tests for each tool.
- [ ] Document usage and environment variables.

## Initial Tasks (Coordinator Agent)
- [ ] Set up Hermes agent with planning plugin.
- [ ] Implement A2A client to call `/ask`/`act` on node agents (discovery via static IP list or DNS).
- [ ] Create simple cluster state graph (node ID, last seen, metrics).
- [ ] Implement goal parser: translate high‑level goal into list of atomic commands.
- [ ] Add validation step: before executing any node‑agent command, run associated policy script.
- [ ] Implement periodic health‑check loop (query node agents every 30s).
- [ ] Log all interactions and decisions for audit.
- [ ] Build a basic CLI/dashboard to view cluster state and issue manual goals.

## Safety & Validation
- Every LLM‑suggested action must pass through a deterministic validation script (e.g., check service is actually failed before restart).
- Validation scripts return a boolean; only proceed if true.
- Maintain an allow‑list of allowed commands per node (e.g., `systemctl restart <service>`, `journalctl -u <service>`).
- Log LLM raw output and validation result for debugging.

## Open Questions / Risks
- Model quantization accuracy: ensure the small model still understands the limited command set.
- Network partition handling: what happens if a node agent is unreachable?
- Updating models across many nodes: consider using a configuration server or side‑car.
- Monitoring inference overhead: tune batch size and concurrency to stay under resource budget.

## Next Steps
1. Create a test VM or container to simulate a cluster node.
2. Follow the "Initial Tasks (Node Agent)" checklist.
3. Once node agent is functional, deploy to two more test nodes.
4. Build coordinator agent and validate end‑to‑end flow.

---
*Created: 2026-07-14*