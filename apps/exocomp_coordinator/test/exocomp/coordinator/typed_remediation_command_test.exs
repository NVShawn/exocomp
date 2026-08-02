# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.TypedRemediationCommandTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.RemediationCommandHandler
  alias Exocomp.Coordinator.RemediationLifecycle
  alias Exocomp.Coordinator.Safety.ApprovalSigner
  alias Exocomp.Core.ApprovalToken

  defmodule Adapter do
    @behaviour Exocomp.Coordinator.RemediationAdapter

    def validate_proposal(proposal) do
      record(:validate, proposal)

      case response(:validate, :ok) do
        :ok ->
          {:ok, %{id: "systemd.service.restart", target: "demo.service"}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    def collect_evidence(proposal) do
      record(:collect, proposal)
      {:ok, response(:evidence, %{"state" => "failed", "unit" => "demo.service"})}
    end

    def decide(proposal, evidence) do
      record(:decide, {proposal, evidence})

      case response(:policy, :approval_required) do
        :approval_required ->
          {:approval_required, %{id: "systemd.service.restart", target: "demo.service"}, %{}}

        decision ->
          decision
      end
    end

    def execute(action, evidence, token) do
      record(:execute, {action, evidence, token})
      response(:execute, {:ok, %{exit_code: 0, output_digest: "digest"}})
    end

    def verify(action, evidence, result) do
      record(:verify, {action, evidence, result})
      response(:verify, {:ok, %{service_state: "active"}})
    end

    defp response(key, default), do: Agent.get(agent(), &Map.get(&1.responses, key, default))

    defp record(key, value) do
      Agent.update(agent(), fn state ->
        update_in(state.calls[key], fn values -> (values || []) ++ [value] end)
      end)
    end

    defp agent, do: Application.fetch_env!(:exocomp_coordinator, :typed_remediation_test_agent)
  end

  setup do
    agent =
      start_supervised!(
        {Agent,
         fn ->
           %{responses: %{}, calls: %{}, events: []}
         end}
      )

    Application.put_env(:exocomp_coordinator, :typed_remediation_test_agent, agent)

    on_exit(fn -> Application.delete_env(:exocomp_coordinator, :typed_remediation_test_agent) end)
    :ok
  end

  test "rejects command kinds outside the typed remedy contract" do
    assert {:error, :unsupported_remediation_command} =
             RemediationCommandHandler.handle(%{}, %{kind: "chat.message"})
  end

  test "revalidates, signs, executes, verifies, and returns correlated artifacts" do
    {server, agent, private_key} = start_lifecycle()
    evidence = evidence()
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)

    assert waiting.status.state == :input_required

    assert {:ok, result} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(evidence), waiting.id),
               command_context(),
               server: server
             )

    assert result["status"] == "completed"
    assert result["correlation_id"] == "corr-typed"
    assert Enum.any?(result["history"], &(&1["event"] == "execution_started"))
    assert Enum.any?(result["history"], &(&1["event"] == "execution_completed"))
    assert length(result["artifacts"]) == 1
    assert length(calls(agent, :validate)) == 2
    assert length(calls(agent, :collect)) == 2
    assert length(calls(agent, :decide)) == 2
    assert length(calls(agent, :execute)) == 1
    assert length(calls(agent, :verify)) == 1

    audit_events = Agent.get(agent, & &1.events)
    assert Enum.any?(audit_events, &match?({:action_started, _, "corr-typed"}, &1))
    assert Enum.any?(audit_events, &match?({:action_completed, _, "corr-typed"}, &1))

    [{_action, _fresh_evidence, token}] = calls(agent, :execute)
    assert {:ok, decoded_signature} = Base.url_decode64(token["signature"], padding: false)
    assert byte_size(decoded_signature) == 64
    assert token["payload"]["operator"] == "operator-1"
    assert token["payload"]["parameter_hash"] == ApprovalToken.hash_params(parameters())
    assert token["payload"]["evidence_hash"] == evidence_hash(evidence)
    refute token["payload"]["operator"] == Base.encode64(private_key)
  end

  test "rehydrates a typed approval after coordinator state is lost" do
    {server, agent, _private_key} = start_lifecycle()

    assert {:ok, result} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(evidence())),
               command_context(),
               server: server
             )

    assert result["status"] == "completed"
    assert length(calls(agent, :execute)) == 1
  end

  test "stale evidence is terminal and never reaches execution", %{} do
    {server, agent, _private_key} = start_lifecycle()
    original = evidence()
    {:ok, task} = RemediationLifecycle.submit(proposal(), server: server)
    set_response(agent, :evidence, %{"state" => "active", "unit" => "demo.service"})

    assert {:error, {:approval_rejected, :stale_evidence, result}} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(original), task.id),
               command_context(),
               server: server
             )

    assert result["status"] == "failed"
    assert calls(agent, :execute) == []
    assert task.id == result["task_id"]
  end

  test "a command evidence hash mismatch is terminal and never reaches execution" do
    {server, agent, _private_key} = start_lifecycle()
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
    wrong_hash = String.duplicate("0", 64)

    assert {:error, {:approval_rejected, :evidence_mismatch, result}} =
             RemediationLifecycle.approve_command(
               command(wrong_hash, waiting.id),
               command_context(),
               server: server
             )

    assert result["status"] == "failed"
    assert calls(agent, :execute) == []
  end

  test "a changed local policy is rejected before execution" do
    {server, agent, _private_key} = start_lifecycle()
    evidence = evidence()
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
    set_response(agent, :policy, {:deny, :now_safe})

    assert {:error, {:approval_rejected, :policy_changed, result}} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(evidence), waiting.id),
               command_context(),
               server: server
             )

    assert result["status"] == "failed"
    assert calls(agent, :execute) == []
  end

  test "target and parameter changes are terminally rejected" do
    for {field, value, reason} <- [
          {:target_id, "other.service", :target_mismatch},
          {:parameters, %{"unit" => "other.service"}, :parameter_mismatch}
        ] do
      {server, agent, _private_key} = start_lifecycle()
      evidence = evidence()
      {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
      changed = Map.put(command(evidence_hash(evidence), waiting.id), field, value)

      assert {:error, {:approval_rejected, ^reason, result}} =
               RemediationLifecycle.approve_command(changed, command_context(), server: server)

      assert result["status"] == "failed"
      assert calls(agent, :execute) == []
    end
  end

  test "expired command does not receive a signing token" do
    {server, agent, _private_key} = start_lifecycle()
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)

    assert {:error, {:approval_rejected, :approval_expired, _result}} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(evidence()), waiting.id),
               %{command_context() | expires_at: ~U[2026-08-01 11:59:00Z]},
               server: server
             )

    assert calls(agent, :execute) == []
  end

  test "a duplicate typed approval cannot execute a completed task twice" do
    {server, agent, _private_key} = start_lifecycle()
    command = command(evidence_hash(evidence()))
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)
    command = Map.put(command, "task_id", waiting.id)

    assert {:ok, _result} =
             RemediationLifecycle.approve_command(command, command_context(), server: server)

    assert {:error, :approval_not_pending} =
             RemediationLifecycle.approve_command(command, command_context(), server: server)

    assert length(calls(agent, :execute)) == 1
  end

  test "typed denial completes a waiting task without invoking the adapter" do
    {server, agent, _private_key} = start_lifecycle()
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)

    denial =
      command(evidence_hash(evidence()), waiting.id)
      |> Map.merge(%{"decision" => "denied", "denial_reason" => "operator declined"})

    assert {:ok, result} =
             RemediationLifecycle.deny_command(
               denial,
               %{command_context() | kind: "proposal.deny"},
               server: server
             )

    assert result["status"] == "completed"
    assert Enum.any?(result["history"], &(&1["event"] == "approval_denied"))
    assert calls(agent, :execute) == []
  end

  test "execution failure is reported with an artifact" do
    {server, agent, _private_key} = start_lifecycle()
    set_response(agent, :execute, {:error, :node_unavailable})
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)

    assert {:error, {:typed_approval_failed, result}} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(evidence()), waiting.id),
               command_context(),
               server: server
             )

    assert result["status"] == "failed"
    assert Enum.any?(result["history"], &(&1["event"] == "execution_failed"))
    assert length(result["artifacts"]) == 1
  end

  test "verification failure is reported separately from execution failure" do
    {server, agent, _private_key} = start_lifecycle()
    set_response(agent, :verify, {:error, :health_not_stable})
    {:ok, waiting} = RemediationLifecycle.submit(proposal(), server: server)

    assert {:error, {:typed_approval_failed, result}} =
             RemediationLifecycle.approve_command(
               command(evidence_hash(evidence()), waiting.id),
               command_context(),
               server: server
             )

    assert Enum.any?(result["history"], &(&1["event"] == "verification_failed"))
    assert Enum.any?(result["history"], &(&1["event"] == "execution_completed"))
    assert length(calls(agent, :execute)) == 1
  end

  test "approval signer accepts a raw local Ed25519 key and emits only a wire token" do
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    payload = token_payload()

    assert {:ok, token} = ApprovalSigner.sign(payload, private_key: private_key)
    assert is_binary(token["signature"])
    assert token["payload"] == payload

    {:ok, signature} = Base.url_decode64(token["signature"], padding: false)

    assert :crypto.verify(
             :eddsa,
             :none,
             ApprovalToken.canonical_encode(payload),
             signature,
             [public_key, :ed25519]
           )
  end

  defp start_lifecycle do
    agent = Application.fetch_env!(:exocomp_coordinator, :typed_remediation_test_agent)
    {_public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    name = :"typed_remediation_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        {RemediationLifecycle,
         [
           name: name,
           adapter: Adapter,
           signer: fn payload -> ApprovalSigner.sign(payload, private_key: private_key) end,
           audit_fun: fn type, attrs, correlation_id ->
             Agent.update(agent, fn state ->
               %{state | events: state.events ++ [{type, attrs, correlation_id}]}
             end)

             :ok
           end,
           now_fn: fn -> ~U[2026-08-01 12:00:00Z] end
         ]},
        id: name
      )

    {pid, agent, private_key}
  end

  defp proposal do
    %{
      "schema_version" => "1",
      "proposal_id" => "proposal-typed",
      "correlation_id" => "corr-typed",
      "node_id" => "node-1",
      "action_id" => "systemd.service.restart",
      "target_id" => "demo.service",
      "parameters" => parameters(),
      "evidence_refs" => ["evidence-1"],
      "rationale" => "restore service"
    }
  end

  defp parameters, do: %{"unit" => "demo.service"}
  defp evidence, do: %{"state" => "failed", "unit" => "demo.service"}
  defp evidence_hash(value), do: ApprovalToken.hash_evidence(value)

  defp command(hash, task_id \\ task_id()) do
    %{
      "proposal_id" => "proposal-typed",
      "task_id" => task_id,
      "correlation_id" => "corr-typed",
      "node_id" => "node-1",
      "target_id" => "demo.service",
      "action_id" => "systemd.service.restart",
      "parameters" => parameters(),
      "evidence_hash" => hash,
      "decision" => "approved",
      "denial_reason" => nil,
      "operator" => %{"sub" => "operator-1"}
    }
  end

  defp token_payload do
    %{
      "schema_version" => "1",
      "nonce" => "nonce",
      "task_id" => task_id(),
      "correlation_id" => "corr-typed",
      "node_id" => "node-1",
      "action_id" => "systemd.service.restart",
      "parameter_hash" => ApprovalToken.hash_params(parameters()),
      "evidence_hash" => evidence_hash(evidence()),
      "issued_at" => "2026-08-01T12:00:00Z",
      "expires_at" => "2026-08-01T12:05:00Z",
      "operator" => "operator-1"
    }
  end

  defp command_context do
    %{
      kind: "proposal.approve",
      command_id: "command-typed",
      correlation_id: "corr-typed",
      issued_at: ~U[2026-08-01 11:59:00Z],
      expires_at: ~U[2026-08-01 12:05:00Z]
    }
  end

  defp task_id, do: "task-typed"

  defp calls(agent, key), do: Agent.get(agent, &Map.get(&1.calls, key, []))

  defp set_response(agent, key, value) do
    Agent.update(agent, &put_in(&1.responses[key], value))
  end
end
