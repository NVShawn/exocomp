# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Health do
  @moduledoc """
  Structured health snapshot for coordinator subsystems.

  Returns `:healthy` only when all required components are running: Audit,
  Registry, Inventory, PKI.State, EnrollmentToken, and Listener.  Any absent
  or unhealthy component produces `:degraded`.

  In environments where PKI and enrollment are not started (e.g. test mode
  with `require_pki: false`), health is `:degraded` because PKI.State,
  EnrollmentToken, and Listener are absent.
  """

  alias Exocomp.Coordinator.{Audit, EnrollmentToken, Inventory, Listener, Registry}
  alias Exocomp.Coordinator.PKI.State, as: PKIState

  @spec check() :: map()
  def check do
    inventory = safe_call(Inventory, &Inventory.status/0)
    audit = safe_call(Audit, &Audit.status/0)
    registry = safe_call(Registry, fn -> %{node_count: length(Registry.all())} end)
    pki = safe_call(PKIState, &PKIState.status/0)
    listener = process_running(Listener)
    enrollment_token = process_running(EnrollmentToken)

    status =
      if healthy?(inventory) and healthy?(registry) and healthy_audit?(audit) and
           healthy?(pki) and listener and enrollment_token,
        do: :healthy,
        else: :degraded

    %{
      status: status,
      inventory: inventory,
      registry: registry,
      audit: audit,
      pki: pki,
      listener: %{running: listener},
      enrollment_token: %{running: enrollment_token}
    }
  end

  defp safe_call(process, function) do
    if Process.whereis(process) do
      try do
        function.()
      catch
        :exit, reason -> %{healthy: false, error: inspect(reason)}
      end
    else
      %{healthy: false, error: :not_running}
    end
  end

  defp process_running(process), do: is_pid(Process.whereis(process))

  defp healthy?(%{healthy: false}), do: false
  defp healthy?(%{error: error}) when not is_nil(error), do: false
  defp healthy?(_status), do: true

  defp healthy_audit?(%{healthy: healthy}), do: healthy
  defp healthy_audit?(_status), do: false
end
