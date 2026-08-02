# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.CephCooldown do
  @moduledoc """
  Cooldown tracking for Ceph daemon restart recovery.

  Prevents flapping when verification fails by tracking failed restart attempts
  and enforcing a configurable cooldown period. The cooldown is durable across
  coordinator restarts through audit event tracking.

  A daemon enters cooldown when:
  - Verification of a restart attempt fails
  - Cluster health has regressed after the restart
  - The node or daemon mapping has changed unexpectedly

  During cooldown, new restart requests are rejected with `:in_cooldown` reason
  until the cooldown period expires.
  """

  @type cooldown_event :: %{
          node_id: String.t(),
          daemon_id: String.t(),
          target_unit: String.t(),
          reason: atom(),
          timestamp: String.t(),
          expires_at: String.t()
        }

  @default_cooldown_ms 30 * 60 * 1000  # 30 minutes

  @doc """
  Check if a daemon is currently in cooldown.

  Returns `true` if the daemon has a recent failed verification and the cooldown
  period has not yet expired. Otherwise returns `false`.
  """
  @spec in_cooldown?(String.t(), String.t(), keyword()) :: boolean()
  def in_cooldown?(daemon_id, node_id, opts \\ []) do
    cooldown_ms = Keyword.get(opts, :cooldown_ms, @default_cooldown_ms)
    audit_reader = Keyword.get(opts, :audit_reader, &default_audit_reader/1)

    case audit_reader.(daemon_id) do
      {:ok, events} ->
        check_active_cooldown(events, node_id, cooldown_ms)

      {:error, _reason} ->
        # If we can't read the audit trail, assume no cooldown
        false
    end
  end

  @doc """
  Record a cooldown event when verification fails.

  This function should be called after verification failure to record the
  cooldown period in the audit trail.
  """
  @spec record_cooldown(String.t(), String.t(), String.t(), atom(), keyword()) ::
          {:ok, cooldown_event()} | {:error, term()}
  def record_cooldown(daemon_id, node_id, target_unit, reason, opts \\ []) do
    cooldown_ms = Keyword.get(opts, :cooldown_ms, @default_cooldown_ms)
    audit_writer = Keyword.get(opts, :audit_writer, &default_audit_writer/2)

    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    expires_at = DateTime.utc_now() |> DateTime.add(cooldown_ms, :millisecond) |> DateTime.to_iso8601()

    event = %{
      "node_id" => node_id,
      "daemon_id" => daemon_id,
      "target_unit" => target_unit,
      "reason" => Atom.to_string(reason),
      "timestamp" => timestamp,
      "expires_at" => expires_at
    }

    case audit_writer.(daemon_id, event) do
      :ok -> {:ok, to_atom_keys(event)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Clear cooldown for a daemon after successful recovery.

  This function should be called after successful verification to clear any
  existing cooldown.
  """
  @spec clear_cooldown(String.t(), keyword()) :: :ok | {:error, term()}
  def clear_cooldown(daemon_id, opts \\ []) do
    audit_writer = Keyword.get(opts, :audit_writer, &default_audit_writer/2)

    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    event = %{
      daemon_id: daemon_id,
      type: "cooldown_cleared",
      timestamp: timestamp
    }

    case audit_writer.(daemon_id, event) do
      :ok -> :ok
      {:error, _} = error -> error
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp check_active_cooldown(events, node_id, cooldown_ms) do
    now = DateTime.utc_now()

    # Check for active cooldown: find the most recent cooldown event
    # and verify it hasn't been cleared and hasn't expired
    events
    |> Enum.reverse()
    |> Enum.reduce_while(false, fn event, _acc ->
      case event do
        %{"type" => "cooldown_cleared"} ->
          # Hit a cleared event, stop looking - no active cooldown
          {:halt, false}

        %{type: "cooldown_cleared"} ->
          # Hit a cleared event (atom keys), stop looking - no active cooldown
          {:halt, false}

        event when is_map(event) ->
          event_node_id = Map.get(event, "node_id") || Map.get(event, :node_id)
          expires_at = Map.get(event, "expires_at") || Map.get(event, :expires_at)

          if event_node_id == node_id and is_binary(expires_at) do
            case DateTime.from_iso8601(expires_at) do
              {:ok, expiry, _} ->
                # Found a cooldown event for this node, check if it's still active
                is_active = DateTime.compare(now, expiry) == :lt
                {:halt, is_active}

              _ ->
                {:cont, false}
            end
          else
            {:cont, false}
          end

        _ ->
          {:cont, false}
      end
    end)
  end

  defp default_audit_reader(_daemon_id) do
    # When no custom audit reader is provided, return empty event list
    {:ok, []}
  end

  defp default_audit_writer(_daemon_id, _event) do
    # When no custom audit writer is provided, succeed silently
    :ok
  end

  defp to_atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {"node_id", v} -> {:node_id, v}
      {"daemon_id", v} -> {:daemon_id, v}
      {"target_unit", v} -> {:target_unit, v}
      {"reason", v} when is_binary(v) -> {:reason, String.to_existing_atom(v)}
      {"reason", v} -> {:reason, v}
      {"timestamp", v} -> {:timestamp, v}
      {"expires_at", v} -> {:expires_at, v}
      {k, v} -> {k, v}
    end)
  end

  defp to_atom_keys(other), do: other
end
