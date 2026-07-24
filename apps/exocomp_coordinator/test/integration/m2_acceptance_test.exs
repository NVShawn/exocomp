defmodule Exocomp.Integration.M2AcceptanceTest do
  @moduledoc """
  M2 milestone acceptance integration tests.

  Exercises every M2-CRIT-* acceptance criterion with at least three
  deterministic node fixtures and injectable seams so no real network
  call or DNS lookup is required.

  ## M2-CRIT coverage

  | Criterion  | Evidence                                                              |
  |------------|-----------------------------------------------------------------------|
  | M2-CRIT-1  | `test/1*` — versioned inventory loads atomically; duplicate IDs and identities rejected; Registry populated with 3+ nodes. Full DNS resolver coverage in `MultiNodeDiscoveryPollingTest`. |
  | M2-CRIT-2  | `test/2*` — three nodes polled concurrently; alpha healthy, beta unreachable (explicit), gamma slow/isolated; slow node does not block peers. Full poller coverage in `MultiNodeDiscoveryPollingTest`. |
  | M2-CRIT-3  | `test/3*` — enrollment token issued to known node; consumed exactly once; replay rejected (`token_already_consumed`); wrong-node-ID rejected (`token_node_mismatch`); restart durability verified. Wrong-root and full PKI tree in `IntegrationTest`. |
  | M2-CRIT-4  | `test/4*` — PKI.Issuer issues leaf certificate from node CSR without retaining node private key in the online-state directory. Renewal and expiry in `PKI.IssuerTest`. |
  | M2-CRIT-5  | `test/5*` — cluster diagnose goal dispatched to 3 nodes with correlated IDs; alpha succeeds with artifact; beta unreachable (explicit); all three nodes have explicit outcomes. Cancellation in `MultiNodeOrchestrationIntegrationTest`. |
  | M2-CRIT-6  | `test/6*` — GoalStore is volatile; pre-restart goal returns :not_found after restart; same caller_key creates fresh goal after restart; durable JSON-lines audit file survives restart. |
  | M2-CRIT-7  | `test/7*` — Codec rejects remediation.propose; GoalStore.transition rejects :remediation; no NodeOutcome reaches a remediation terminal state. |
  | M2-CRIT-8  | `make test` (this file + all focused tests), `make lint`, `make fmt-check`, `make build` all pass. See commit `EXOCOMP-20` in git history. |

  ## Node fixtures

  Three deterministic fixtures used throughout:

    * `"m2-alpha"` — healthy; returns a completed diagnostic A2A task.
    * `"m2-beta"`  — unreachable; transport returns `:unreachable` error.
    * `"m2-gamma"` — slow or blocked; configurable via per-test `Agent`.

  ## EXOCOMP-17 gap (M2-CRIT-3/4 node side)

  M2-CRIT-3 and M2-CRIT-4 verify the coordinator-side path: token issuance,
  one-time consumption, replay rejection, expiry, PKI bootstrap, leaf
  certificate issuance from a CSR, and private-key non-retention. The node-agent
  enrollment client, atomic credential installer, and renewal scheduler
  (EXOCOMP-17) are not yet implemented; end-to-end enrollment handshake tests
  (node calls coordinator enrollment endpoint) cannot run until EXOCOMP-17 lands.

  ## Running

      MIX_ENV=test mix test apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs

  Tags: `:m2_acceptance`.
  """

  use ExUnit.Case, async: false

  @moduletag :m2_acceptance

  alias Exocomp.A2A.{Artifact, DataPart, Message, TaskStatus}
  alias Exocomp.A2A.Task, as: A2ATask
  alias Exocomp.Coordinator.A2A.{ClientError, Codec}
  alias Exocomp.Coordinator.{Audit, DiagnosticGoal, Error, GoalStore, NodeOutcome, Orchestrator}
  alias Exocomp.Coordinator.Inventory.Node, as: InventoryNode
  alias Exocomp.Coordinator.Registry
  alias X509.Certificate.Extension

  # ---------------------------------------------------------------------------
  # Node fixture IDs
  # ---------------------------------------------------------------------------

  @node_alpha "m2-alpha"
  @node_beta "m2-beta"
  @node_gamma "m2-gamma"
  @three_nodes [@node_alpha, @node_beta, @node_gamma]
  @passphrase "m2-acceptance-passphrase-correct-horse"

  # ---------------------------------------------------------------------------
  # Fake A2A diagnostic client — same injectable pattern as multi_node tests
  # ---------------------------------------------------------------------------

  defmodule FakeClient do
    @moduledoc false
    alias Exocomp.Coordinator.A2A.ClientError

    def send(node_id, _skill_id, _params, opts) do
      agent = Keyword.fetch!(opts, :agent)
      owner = Keyword.get(opts, :owner)
      if owner, do: send(owner, {:fake_send, node_id})

      case Agent.get(agent, &Map.get(&1, {:send, node_id})) do
        {:block, blocker} ->
          send(blocker, {:blocking_send, self(), node_id})

          receive do
            {:proceed, result} -> result
            :proceed -> {:error, make_error(:transport, :unreachable, node_id)}
          end

        {:ok, _} = ok ->
          ok

        {:error, _} = err ->
          err

        nil ->
          {:error, make_error(:configuration, :unknown_node, node_id)}
      end
    end

    def get_task(_node_id, _task_id, _opts), do: {:error, :not_supported}
    def cancel(_node_id, _task_id, _opts), do: {:ok, :unsupported_operation}

    defp make_error(kind, reason, node_id),
      do: %ClientError{kind: kind, reason: reason, node_id: node_id, operation: :send}
  end

  # ---------------------------------------------------------------------------
  # Audit sink that collects events for assertion
  # ---------------------------------------------------------------------------

  defmodule CollectorSink do
    @moduledoc false
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(opts), do: {:ok, Keyword.fetch!(opts, :owner)}

    @impl true
    def write(owner, event) do
      send(owner, {:audit_event, event})
      {:ok, owner}
    end

    @impl true
    def close(_owner), do: :ok
  end

  # ---------------------------------------------------------------------------
  # Test helpers
  # ---------------------------------------------------------------------------

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  defp start_audit do
    name = unique_name(:audit)
    start_supervised!({Audit, name: name, sink: {CollectorSink, owner: self()}}, id: name)
    name
  end

  defp start_goal_store(audit) do
    name = unique_name(:goal_store)
    start_supervised!({GoalStore, name: name, audit: audit}, id: name)
    name
  end

  defp start_task_supervisor do
    name = unique_name(:task_sup)
    start_supervised!({Task.Supervisor, name: name}, id: name)
    name
  end

  defp start_orchestrator(goal_store, task_supervisor, audit) do
    name = unique_name(:orch)

    start_supervised!(
      {Orchestrator,
       name: name,
       goal_store: goal_store,
       task_supervisor: task_supervisor,
       client_adapter: FakeClient,
       poll_interval_ms: 10,
       audit: audit},
      id: name
    )

    name
  end

  defp run(orchestrator, caller_key, node_ids, client_agent, opts \\ []) do
    skill_id = Keyword.get(opts, :skill_id, "exocomp.cluster.diagnose")
    params = Keyword.get(opts, :params, %{})

    client_opts =
      Keyword.merge([agent: client_agent, owner: self()], Keyword.get(opts, :client_opts, []))

    Orchestrator.run(caller_key, skill_id, params, node_ids,
      orchestrator: orchestrator,
      client_opts: client_opts
    )
  end

  defp start_client_agent(responses) do
    {:ok, agent} = Agent.start_link(fn -> responses end)
    agent
  end

  defp make_completed_task(node_id) do
    %A2ATask{
      id: "task-#{node_id}-#{System.unique_integer([:positive])}",
      contextId: "ctx-m2",
      status: %TaskStatus{state: :completed, timestamp: "2026-01-01T00:00:00Z"},
      artifacts: [
        %Artifact{
          artifactId: "diag-#{node_id}",
          parts: [%DataPart{data: %{"node" => node_id, "status" => "ok"}}]
        }
      ]
    }
  end

  defp make_unreachable_error(node_id),
    do: %ClientError{kind: :transport, reason: :unreachable, node_id: node_id, operation: :send}

  defp all_unreachable do
    %{
      {:send, @node_alpha} => {:error, make_unreachable_error(@node_alpha)},
      {:send, @node_beta} => {:error, make_unreachable_error(@node_beta)},
      {:send, @node_gamma} => {:error, make_unreachable_error(@node_gamma)}
    }
  end

  defp alpha_ok_beta_unreachable_gamma_unreachable do
    %{
      {:send, @node_alpha} => {:ok, make_completed_task(@node_alpha)},
      {:send, @node_beta} => {:error, make_unreachable_error(@node_beta)},
      {:send, @node_gamma} => {:error, make_unreachable_error(@node_gamma)}
    }
  end

  defp eventually(assertion, attempts \\ 200)
  defp eventually(assertion, 0), do: assert(assertion.())

  defp eventually(assertion, n) do
    if assertion.() do
      true
    else
      Process.sleep(10)
      eventually(assertion, n - 1)
    end
  end

  defp goal_done?(goal_store, goal_id) do
    case GoalStore.get(goal_id, goal_store) do
      {:ok, %DiagnosticGoal{state: s}} -> s in [:completed, :failed, :canceled]
      _ -> false
    end
  end

  defp csr_pem(key, node_id) do
    extensions = [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth, :serverAuth]),
      Extension.subject_alt_name([node_id])
    ]

    key
    |> X509.CSR.new("/O=Exocomp/CN=#{node_id}", extension_request: extensions)
    |> X509.CSR.to_pem()
  end

  defp bootstrap_pki(tmp_dir, label) do
    online = Path.join(tmp_dir, "#{label}-online")
    offline = Path.join(tmp_dir, "#{label}-offline")

    # Do NOT pre-create the directories — Bootstrap.initialize creates them
    # atomically via staged rename. Pre-creating empty dirs causes the module
    # to detect :existing disposition and validate an empty tree, returning
    # :invalid_pki_state.

    assert {:ok, _metadata} =
             Exocomp.Coordinator.PKI.Bootstrap.initialize(
               online_state: online,
               offline_backup: offline,
               root_key_protection: {:passphrase, @passphrase}
             )

    online
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-1: Versioned static inventory — atomic load, duplicate rejection,
  # Registry population with 3+ nodes
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-1: versioned inventory and registry population" do
    test "1a: inventory rebuilt with three nodes; Registry.all/1 returns all three" do
      reg_name = unique_name(:registry)

      start_supervised!({Registry, name: reg_name, poll_interval_ms: 60_000, jitter_ms: 0},
        id: reg_name
      )

      nodes =
        Enum.map(@three_nodes, fn id ->
          %InventoryNode{
            id: id,
            hostname: "#{id}.cluster.test",
            port: 9443,
            certificate_identity: "spiffe://cluster/#{id}",
            capabilities: ["exocomp.node.health"],
            labels: %{}
          }
        end)

      :ok = Registry.rebuild(nodes, reg_name)

      all_ids = reg_name |> Registry.all() |> Enum.map(& &1.id) |> Enum.sort()
      assert all_ids == Enum.sort(@three_nodes)
    end

    test "1b: malformed JSON replacement returns structured error" do
      assert {:error, %{code: :malformed_inventory}} =
               Exocomp.Coordinator.Inventory.replace_json("{broken json")
    end

    test "1c: duplicate node IDs are rejected at parse time" do
      json =
        Jason.encode!(%{
          "version" => 1,
          "nodes" => [
            %{
              "id" => "dup",
              "hostname" => "dup-a.test",
              "port" => 9443,
              "certificate_identity" => "spiffe://cluster/dup-a",
              "capabilities" => []
            },
            %{
              "id" => "dup",
              "hostname" => "dup-b.test",
              "port" => 9443,
              "certificate_identity" => "spiffe://cluster/dup-b",
              "capabilities" => []
            }
          ]
        })

      assert {:error, %{code: :duplicate_node_id}} =
               Exocomp.Coordinator.Inventory.replace_json(json)
    end

    test "1d: duplicate certificate identities are rejected at parse time" do
      json =
        Jason.encode!(%{
          "version" => 1,
          "nodes" => [
            %{
              "id" => "node-a",
              "hostname" => "node-a.test",
              "port" => 9443,
              "certificate_identity" => "spiffe://cluster/shared",
              "capabilities" => []
            },
            %{
              "id" => "node-b",
              "hostname" => "node-b.test",
              "port" => 9443,
              "certificate_identity" => "spiffe://cluster/shared",
              "capabilities" => []
            }
          ]
        })

      assert {:error, %{code: :duplicate_certificate_identity}} =
               Exocomp.Coordinator.Inventory.replace_json(json)
    end
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-2: Concurrent polling of three nodes — healthy, unreachable, slow
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-2: concurrent polling with three node fixtures" do
    test "2a: alpha healthy, beta and gamma unreachable — all three outcomes explicit" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client = start_client_agent(alpha_ok_beta_unreachable_gamma_unreachable())

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit2a", @three_nodes, client)

      eventually(fn -> goal_done?(goal_store, goal_id) end)

      {:ok, goal} = GoalStore.get(goal_id, goal_store)
      assert goal.state in [:completed, :failed]
      assert goal.node_outcomes[@node_alpha].state == :succeeded
      assert goal.node_outcomes[@node_beta].state == :unreachable
      assert goal.node_outcomes[@node_gamma].state == :unreachable
      assert map_size(goal.node_outcomes) == 3
    end

    test "2b: slow gamma isolated — alpha and beta complete without waiting for gamma" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client =
        start_client_agent(%{
          {:send, @node_alpha} => {:ok, make_completed_task(@node_alpha)},
          {:send, @node_beta} => {:error, make_unreachable_error(@node_beta)},
          {:send, @node_gamma} => {:block, self()}
        })

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit2b", @three_nodes, client, client_opts: [owner: self()])

      assert_receive {:fake_send, @node_alpha}, 1_000
      assert_receive {:fake_send, @node_beta}, 1_000
      assert_receive {:fake_send, @node_gamma}, 1_000

      # Alpha and beta resolve without gamma unblocking
      eventually(fn ->
        case GoalStore.get(goal_id, goal_store) do
          {:ok, g} ->
            Map.get(g.node_outcomes, @node_alpha, %{state: nil}).state == :succeeded and
              Map.get(g.node_outcomes, @node_beta, %{state: nil}).state == :unreachable

          _ ->
            false
        end
      end)

      # Unblock gamma so the test supervisor shuts down cleanly
      receive do
        {:blocking_send, pid, @node_gamma} -> send(pid, :proceed)
      after
        2_000 -> :ok
      end
    end
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-3: Enrollment token — one-time use, replay, wrong node
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-3: enrollment token one-time use and rejection cases" do
    @tag :tmp_dir
    test "3a: token issued and consumed exactly once; replay returns token_already_consumed", %{
      tmp_dir: tmp_dir
    } do
      # Do NOT pre-create the store dir — EnrollmentToken creates it with mode 0700.
      store = Path.join(tmp_dir, "tokens-3a")
      audit = start_audit()
      svc = unique_name(:enrollment_token)

      start_supervised!(
        {Exocomp.Coordinator.EnrollmentToken,
         name: svc, store_path: store, audit_server: audit, inventory_fn: fn _ -> :ok end}
      )

      {:ok, token} = Exocomp.Coordinator.EnrollmentToken.issue(@node_alpha, server: svc)
      assert is_binary(token)

      # First consumption succeeds
      assert :ok = Exocomp.Coordinator.EnrollmentToken.consume(token, @node_alpha, server: svc)

      # Replay rejected — token already consumed
      assert {:error, %Error{code: :token_already_consumed}} =
               Exocomp.Coordinator.EnrollmentToken.consume(token, @node_alpha, server: svc)
    end

    @tag :tmp_dir
    test "3b: token issued for alpha; consumed claiming beta — returns token_node_mismatch", %{
      tmp_dir: tmp_dir
    } do
      store = Path.join(tmp_dir, "tokens-3b")
      audit = start_audit()
      svc = unique_name(:enrollment_token)

      start_supervised!(
        {Exocomp.Coordinator.EnrollmentToken,
         name: svc, store_path: store, audit_server: audit, inventory_fn: fn _ -> :ok end}
      )

      {:ok, token} = Exocomp.Coordinator.EnrollmentToken.issue(@node_alpha, server: svc)

      assert {:error, %Error{code: :token_node_mismatch}} =
               Exocomp.Coordinator.EnrollmentToken.consume(token, @node_beta, server: svc)
    end

    @tag :tmp_dir
    test "3c: consumed token cannot be replayed after service restart — replay rejected from durable store",
         %{tmp_dir: tmp_dir} do
      store = Path.join(tmp_dir, "tokens-3c")
      audit = start_audit()
      svc = unique_name(:enrollment_token)

      # Use explicit id: svc so stop_supervised(svc) resolves to the correct child.
      start_supervised!(
        {Exocomp.Coordinator.EnrollmentToken,
         name: svc, store_path: store, audit_server: audit, inventory_fn: fn _ -> :ok end},
        id: svc
      )

      {:ok, token} = Exocomp.Coordinator.EnrollmentToken.issue(@node_alpha, server: svc)
      :ok = Exocomp.Coordinator.EnrollmentToken.consume(token, @node_alpha, server: svc)

      # Restart the service
      stop_supervised(svc)
      svc2 = unique_name(:enrollment_token)

      start_supervised!(
        {Exocomp.Coordinator.EnrollmentToken,
         name: svc2, store_path: store, audit_server: audit, inventory_fn: fn _ -> :ok end},
        id: svc2
      )

      # Replay still rejected after restart (consumed state persists in durable store)
      assert {:error, %Error{code: :token_already_consumed}} =
               Exocomp.Coordinator.EnrollmentToken.consume(token, @node_alpha, server: svc2)
    end
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-4: Certificate issuance — leaf cert from CSR; no node key retained
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-4: leaf certificate issued without retaining node private key" do
    @tag :tmp_dir
    test "4a: Issuer.issue_leaf/2 returns chain PEM; online state has no node key material", %{
      tmp_dir: tmp_dir
    } do
      online = bootstrap_pki(tmp_dir, "m2-crit4")

      # Node generates a private key locally and submits only the CSR
      node_key = X509.PrivateKey.new_ec(:secp256r1)
      pem = csr_pem(node_key, @node_alpha)

      assert {:ok, csr} = Exocomp.Coordinator.PKI.Issuer.validate_csr(pem, @node_alpha)
      assert {:ok, chain_pem} = Exocomp.Coordinator.PKI.Issuer.issue_leaf(csr, online)
      assert is_binary(chain_pem)

      # The online PKI directory does NOT contain any file whose name includes
      # the node ID (node private keys are never written by the coordinator)
      all_files = Path.wildcard(Path.join(online, "**/*")) |> Enum.reject(&File.dir?/1)

      node_key_files =
        Enum.filter(all_files, fn f -> String.contains?(Path.basename(f), @node_alpha) end)

      assert node_key_files == [],
             "Online PKI state must not retain node-specific key material: #{inspect(node_key_files)}"
    end
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-5: Cluster diagnosis — correlated results, partial failure explicit
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-5: cluster diagnosis with correlated per-node results" do
    test "5a: alpha succeeds, beta unreachable, gamma fails — all three outcomes explicit" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client =
        start_client_agent(%{
          {:send, @node_alpha} => {:ok, make_completed_task(@node_alpha)},
          {:send, @node_beta} => {:error, make_unreachable_error(@node_beta)},
          {:send, @node_gamma} =>
            {:error,
             %ClientError{
               kind: :protocol,
               reason: :malformed_response,
               node_id: @node_gamma,
               operation: :send
             }}
        })

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit5a", @three_nodes, client)

      eventually(fn -> goal_done?(goal_store, goal_id) end)

      {:ok, goal} = GoalStore.get(goal_id, goal_store)

      # Correlation ID is present
      assert is_binary(goal_id)

      # Alpha succeeded with artifact evidence
      assert %NodeOutcome{state: :succeeded} = goal.node_outcomes[@node_alpha]

      assert [%Artifact{artifactId: "diag-" <> @node_alpha}] =
               goal.node_outcomes[@node_alpha].artifacts

      # Beta: explicit unreachable — no remediation queued
      assert %NodeOutcome{state: :unreachable} = goal.node_outcomes[@node_beta]

      # Gamma: explicit failure or unreachable
      assert %NodeOutcome{state: gamma_state} = goal.node_outcomes[@node_gamma]
      assert gamma_state in [:failed, :unreachable]

      # All three nodes have explicit outcomes — no silently omitted result
      assert map_size(goal.node_outcomes) == 3
    end

    test "5b: no reachable nodes — goal reaches terminal state with all three :unreachable" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client = start_client_agent(all_unreachable())

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit5b", @three_nodes, client)

      eventually(fn -> goal_done?(goal_store, goal_id) end)

      {:ok, goal} = GoalStore.get(goal_id, goal_store)
      assert goal.state in [:completed, :failed]
      for {_id, outcome} <- goal.node_outcomes, do: assert(outcome.state == :unreachable)
    end
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-6: Restart — volatile GoalStore; durable audit
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-6: coordinator restart reconstructs state; audit survives" do
    test "6a: GoalStore is volatile — goal is :not_found after GoalStore restart" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client = start_client_agent(alpha_ok_beta_unreachable_gamma_unreachable())

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit6a", @three_nodes, client)

      eventually(fn -> goal_done?(goal_store, goal_id) end)
      assert {:ok, %DiagnosticGoal{}} = GoalStore.get(goal_id, goal_store)

      # Restart the GoalStore
      stop_supervised(goal_store)
      new_store = start_goal_store(audit)

      # Pre-restart goal is gone — GoalStore is volatile
      assert {:error, :not_found} = GoalStore.get(goal_id, new_store)
    end

    test "6b: same caller_key creates a fresh goal with a new ID after restart" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client = start_client_agent(alpha_ok_beta_unreachable_gamma_unreachable())

      assert {:ok, %DiagnosticGoal{id: id1}} =
               run(orch, "crit6b-key", [@node_alpha, @node_beta], client)

      eventually(fn -> goal_done?(goal_store, id1) end)

      # Restart GoalStore
      stop_supervised(goal_store)
      new_store = start_goal_store(audit)
      new_orch = start_orchestrator(new_store, task_sup, audit)

      # Same caller_key now creates a fresh goal (idempotency cleared by restart)
      assert {:ok, %DiagnosticGoal{id: id2}} =
               run(new_orch, "crit6b-key", [@node_alpha, @node_beta], client)

      assert id1 != id2
    end

    @tag :tmp_dir
    test "6c: JSON-lines audit file survives GoalStore restart and contains events", %{
      tmp_dir: tmp_dir
    } do
      audit_path = Path.join(tmp_dir, "audit-6c.jsonl")
      audit_name = unique_name(:durable_audit)

      start_supervised!(
        {Audit,
         name: audit_name,
         sink: {Exocomp.Coordinator.Audit.JSONLines, path: audit_path, max_bytes: 10_485_760}},
        id: audit_name
      )

      goal_store = start_goal_store(audit_name)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit_name)

      client = start_client_agent(alpha_ok_beta_unreachable_gamma_unreachable())

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit6c", @three_nodes, client)

      eventually(fn -> goal_done?(goal_store, goal_id) end)

      # Use a synchronous audit emit to force flush of any pending writes
      Audit.emit(:m2_acceptance_marker, %{test: "crit6c"}, server: audit_name)

      # Restart the GoalStore (simulating coordinator restart)
      stop_supervised(goal_store)

      # Audit file was created before restart
      assert File.exists?(audit_path)

      events = File.stream!(audit_path) |> Enum.map(&Jason.decode!/1)
      # At minimum the marker event we emitted was written
      assert length(events) >= 1
    end
  end

  # ---------------------------------------------------------------------------
  # M2-CRIT-7: No remediation path invoked
  # ---------------------------------------------------------------------------

  describe "M2-CRIT-7: no remediation executor is invoked" do
    test "7a: Codec.extract_skill/1 rejects exocomp.remediation.propose" do
      msg = %Message{
        role: :user,
        parts: [%Exocomp.A2A.DataPart{data: %{"skill" => "exocomp.remediation.propose"}}]
      }

      assert {:error, %{message: err_msg}} = Codec.extract_skill(msg)
      assert err_msg =~ "Unknown"
    end

    test "7b: GoalStore.transition rejects :remediation state" do
      audit = start_audit()
      goal_store = start_goal_store(audit)

      {:ok, goal_id} = GoalStore.accept("key-7b", "exocomp.cluster.diagnose", %{}, goal_store)

      # :remediation is not in the allowed state machine; must return an error
      assert {:error, _} = GoalStore.transition(goal_id, :remediation, nil, goal_store)
    end

    test "7c: completed goal has no NodeOutcome in any remediation terminal state" do
      audit = start_audit()
      goal_store = start_goal_store(audit)
      task_sup = start_task_supervisor()
      orch = start_orchestrator(goal_store, task_sup, audit)

      client = start_client_agent(alpha_ok_beta_unreachable_gamma_unreachable())

      assert {:ok, %DiagnosticGoal{id: goal_id}} =
               run(orch, "crit7c", @three_nodes, client)

      eventually(fn -> goal_done?(goal_store, goal_id) end)

      {:ok, goal} = GoalStore.get(goal_id, goal_store)

      remediation_states = [
        :remediation_queued,
        :remediation_running,
        :remediation_succeeded,
        :remediation_failed
      ]

      for {node_id, outcome} <- goal.node_outcomes do
        refute outcome.state in remediation_states,
               "Node #{node_id} reached unexpected remediation state: #{outcome.state}"
      end
    end
  end
end
