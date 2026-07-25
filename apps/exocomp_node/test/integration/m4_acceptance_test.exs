# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Integration.M4AcceptanceTest do
  @moduledoc """
  Fixture-free M4 acceptance coverage for the automatic failed-service path.

  The privileged systemd fixture remains available through `make
  test-integration`; this suite proves the shipped orchestration, exact action,
  audit boundary, one-attempt invariant, dual health requirement, and terminal
  artifact in the ordinary repository gate.
  """

  use ExUnit.Case, async: false

  alias Exocomp.Node.Recovery.FailedService
  alias Exocomp.Recovery.Evidence

  @moduletag :m4_acceptance
  @now ~U[2026-07-25 14:00:00Z]

  test "M4-CRIT-2/4/5/7: failed fixture completes one audited stable restart" do
    {:ok, audits} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> 0 end)

    evidence = evidence("failed", "failed", "unhealthy", "observed")
    refreshed = evidence("failed", "failed", "unhealthy", "refreshed")
    healthy = evidence("active", "running", "healthy", "healthy")

    opts = [
      task_id: "m4-acceptance-episode",
      allow_list: ["exocomp-fixture.service"],
      now_fun: fn -> @now end,
      audit_fun: fn event ->
        Agent.update(audits, &(&1 ++ [event]))
        :ok
      end,
      refresh_fun: fn _, _ -> {:ok, refreshed} end,
      verify_fun: fn _, _ -> {:ok, healthy} end,
      executor: fn :restart_service, "exocomp-fixture.service", allow_list ->
        assert allow_list == ["exocomp-fixture.service"]
        Agent.update(executions, &(&1 + 1))
        {:ok, %{exit_code: 0, argv: ["systemctl", "restart", "exocomp-fixture.service"]}}
      end,
      stability_samples: 2,
      verification_attempts: 2
    ]

    assert {:ok, result} = FailedService.recover(evidence, opts)
    assert result.machine.state == :completed
    assert result.task.status.state == :completed
    assert Agent.get(executions, & &1) == 1
    assert length(result.task.artifacts) == 1

    assert Enum.map(Agent.get(audits, & &1), & &1.event_tag) == [
             :unhealthy_observation,
             :evidence_complete,
             :validate,
             :failed_and_allowed,
             :execution_complete,
             :stable_health
           ]
  end

  defp evidence(active, sub, health, id) do
    Evidence.new(
      "node-m4",
      "exocomp-fixture.service",
      %{
        "active_state" => active,
        "sub_state" => sub,
        "health" => health,
        "unit_name" => "exocomp-fixture.service"
      },
      evidence_id: id,
      collected_at: @now
    )
  end
end
