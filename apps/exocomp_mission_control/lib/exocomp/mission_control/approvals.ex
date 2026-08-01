# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Approvals do
  @moduledoc """
  Organization-scoped operator decisions for typed remedy proposals.

  Approval is a durable decision, not execution.  The approval transaction
  locks the proposal, records the decision and stable operator attribution,
  and inserts exactly one typed command in the durable outbox.  A failed
  outbox insert rolls the proposal decision back with the transaction.
  """

  import Ecto.Query

  alias Exocomp.MissionControl.{Authorization, CommandOutbox, Proposal, Repo, SessionRegistry}
  alias Exocomp.MissionControl.Identity.Operator

  @command_ttl_seconds 300
  @max_denial_reason_bytes 4_096

  @type decision_error ::
          :unauthenticated
          | :insufficient_role
          | :cross_organization
          | :organization_mismatch
          | :not_found
          | :cluster_disconnected
          | :proposal_expired
          | :evidence_stale
          | :proposal_terminal
          | :invalid_denial_reason

  @doc "Approves one pending proposal for an operator or administrator."
  @spec approve(String.t(), String.t(), Operator.t() | nil, keyword()) ::
          {:ok, Proposal.t()} | {:error, term()}
  def approve(organization_id, proposal_id, operator, opts)
      when is_binary(organization_id) and is_binary(proposal_id) do
    decide(:approved, organization_id, proposal_id, operator, nil, opts)
  end

  def approve(organization_id, proposal_id, operator)
      when is_binary(organization_id) and is_binary(proposal_id) do
    approve(organization_id, proposal_id, operator, [])
  end

  @doc "Approves one proposal using the operator-first calling convention."
  @spec approve(Operator.t() | nil, String.t(), keyword()) ::
          {:ok, Proposal.t()} | {:error, term()}
  def approve(operator, proposal_id, opts) when is_binary(proposal_id) and is_list(opts) do
    approve(operator_organization(operator), proposal_id, operator, opts)
  end

  @doc "Denies one pending proposal and requires a non-empty operator reason."
  @spec deny(String.t(), String.t(), Operator.t() | nil, String.t(), keyword()) ::
          {:ok, Proposal.t()} | {:error, term()}
  def deny(organization_id, proposal_id, operator, reason, opts)
      when is_binary(organization_id) and is_binary(proposal_id) do
    with :ok <- validate_denial_reason(reason) do
      decide(:denied, organization_id, proposal_id, operator, reason, opts)
    end
  end

  def deny(organization_id, proposal_id, operator, reason)
      when is_binary(organization_id) and is_binary(proposal_id) and is_binary(reason) do
    deny(organization_id, proposal_id, operator, reason, [])
  end

  @doc "Denies one proposal using the operator-first calling convention."
  @spec deny(Operator.t() | nil, String.t(), String.t(), keyword()) ::
          {:ok, Proposal.t()} | {:error, term()}
  def deny(operator, proposal_id, reason, opts)
      when is_binary(proposal_id) and is_binary(reason) and is_list(opts) do
    deny(operator_organization(operator), proposal_id, operator, reason, opts)
  end

  @doc "Alias used by proposal-facing callers."
  def approve_proposal(organization_id, proposal_id, operator, opts \\ []),
    do: approve(organization_id, proposal_id, operator, opts)

  @doc "Alias used by proposal-facing callers."
  def deny_proposal(organization_id, proposal_id, operator, reason, opts \\ []),
    do: deny(organization_id, proposal_id, operator, reason, opts)

  defp decide(decision, organization_id, proposal_id, operator, denial_reason, opts) do
    with :ok <- authorize(operator, organization_id),
         {:ok, result} <-
           run_transaction(decision, organization_id, proposal_id, operator, denial_reason, opts) do
      {:ok, result}
    end
  end

  defp run_transaction(decision, organization_id, proposal_id, operator, denial_reason, opts) do
    repo = Keyword.get(opts, :repo, Repo)
    now = option_now(opts)
    opts = Keyword.put_new(opts, :command_id, command_id(opts))

    transaction_result =
      repo.transaction(fn ->
        with {:ok, proposal} <- fetch_locked(repo, proposal_id),
             :ok <- organization_scope(proposal, organization_id),
             :ok <- ensure_decidable(proposal, now),
             :ok <- connected_if_required(decision, proposal, organization_id, opts),
             {:ok, updated} <-
               persist_decision(repo, proposal, decision, operator, denial_reason, now, opts),
             {:ok, _command} <-
               enqueue_command(repo, updated, decision, operator, denial_reason, now, opts) do
          {:ok, updated}
        else
          {:error, reason} -> rollback(repo, reason)
        end
      end)

    normalize_transaction_result(transaction_result)
  rescue
    error in [Ecto.Query.CastError, Ecto.NoResultsError] ->
      {:error, {:persistence_failed, Exception.message(error)}}
  end

  defp authorize(operator, organization_id) do
    Authorization.authorize(operator, organization_id, :operate)
  end

  defp fetch_locked(repo, proposal_id) do
    query =
      from(proposal in Proposal,
        where: proposal.proposal_id == ^proposal_id,
        lock: "FOR UPDATE"
      )

    cond do
      function_exported?(repo, :one, 1) ->
        case repo.one(query) do
          nil -> {:error, :not_found}
          proposal -> {:ok, proposal}
        end

      function_exported?(repo, :get, 2) ->
        case repo.get(Proposal, proposal_id) do
          nil -> {:error, :not_found}
          proposal -> {:ok, proposal}
        end

      true ->
        {:error, :not_found}
    end
  end

  defp organization_scope(%{organization_id: organization_id}, organization_id), do: :ok
  defp organization_scope(_proposal, _organization_id), do: {:error, :organization_mismatch}

  defp ensure_decidable(%Proposal{} = proposal, now) do
    cond do
      Proposal.terminal?(proposal) -> {:error, :proposal_terminal}
      expired?(proposal.expires_at, now) -> {:error, :proposal_expired}
      not evidence_fresh?(proposal, now) -> {:error, :evidence_stale}
      true -> :ok
    end
  end

  defp ensure_decidable(%{status: status} = proposal, now) do
    cond do
      normalize_status(status) != "pending" -> {:error, :proposal_terminal}
      expired?(Map.get(proposal, :expires_at), now) -> {:error, :proposal_expired}
      not evidence_fresh?(proposal, now) -> {:error, :evidence_stale}
      true -> :ok
    end
  end

  defp ensure_decidable(_proposal, _now), do: {:error, :proposal_terminal}

  defp connected_if_required(:denied, _proposal, _organization_id, _opts), do: :ok

  defp connected_if_required(:approved, proposal, organization_id, opts) do
    cluster_id = Map.get(proposal, :cluster_id)

    if connected?(organization_id, cluster_id, opts) do
      :ok
    else
      {:error, :cluster_disconnected}
    end
  end

  defp connected?(organization_id, cluster_id, opts) do
    case Keyword.get(opts, :connected?) || Keyword.get(opts, :cluster_connected?) do
      function when is_function(function) ->
        invoke_connected?(function, organization_id, cluster_id)

      nil ->
        registry_connected?(
          Keyword.get(opts, :session_registry, SessionRegistry),
          organization_id,
          cluster_id
        )

      value ->
        value in [true, :connected, {:ok, :connected}]
    end
  end

  defp invoke_connected?(function, organization_id, cluster_id) do
    result =
      case :erlang.fun_info(function, :arity) do
        {:arity, 1} -> function.(cluster_id)
        {:arity, 2} -> function.(organization_id, cluster_id)
        _ -> false
      end

    result in [true, :connected, {:ok, :connected}]
  rescue
    _error -> false
  end

  defp registry_connected?(registry, organization_id, cluster_id) do
    if is_atom(registry) and is_nil(Process.whereis(registry)) do
      false
    else
      case SessionRegistry.owner(organization_id, cluster_id, registry) do
        {:ok, _owner} -> true
        _ -> false
      end
    end
  rescue
    _error -> false
  end

  defp persist_decision(repo, proposal, decision, operator, denial_reason, now, opts) do
    correlation_id = Keyword.get(opts, :correlation_id) || generate_correlation_id()
    command_id = command_id(opts)
    actor = actor_audit(operator, correlation_id, now)

    attrs = %{
      status: Atom.to_string(decision),
      decision: Atom.to_string(decision),
      decided_at: now,
      decided_by_sub: operator.sub,
      decided_by_display_name: operator.display_name,
      decided_by_organization_id: operator.organization_id,
      decision_correlation_id: correlation_id,
      decision_actor: actor,
      denial_reason: denial_reason,
      approval_command_id: command_id
    }

    changeset = Proposal.changeset(proposal, attrs)

    case repo.update(changeset) do
      {:ok, updated} -> {:ok, updated}
      {:error, reason} -> {:error, {:persistence_failed, reason}}
      updated when is_map(updated) -> {:ok, updated}
      other -> {:error, {:persistence_failed, other}}
    end
  end

  defp enqueue_command(repo, proposal, decision, operator, denial_reason, now, opts) do
    outbox = Keyword.get(opts, :outbox, CommandOutbox)
    command_id = proposal.approval_command_id || command_id(opts)
    kind = if decision == :approved, do: "proposal.approve", else: "proposal.deny"
    expires_at = command_expires_at(proposal, now)

    attrs = %{
      command_id: command_id,
      kind: kind,
      issued_at: now,
      expires_at: expires_at,
      organization_id: proposal.organization_id,
      cluster_id: proposal.cluster_id,
      payload: command_payload(proposal, decision, operator, denial_reason)
    }

    case outbox.enqueue(attrs, repo: repo, now: now) do
      {:ok, command} -> {:ok, command}
      {:error, reason} -> rollback(repo, {:queue_failed, reason})
      other -> rollback(repo, {:queue_failed, other})
    end
  end

  defp command_payload(proposal, decision, operator, denial_reason) do
    %{
      "proposal_id" => proposal.proposal_id,
      "task_id" => proposal.task_id,
      "correlation_id" => proposal.correlation_id,
      "node_id" => proposal.node_id,
      "target_id" => proposal.target_id,
      "action_id" => proposal.action_id,
      "parameters" => proposal.parameters || %{},
      "evidence_hash" => proposal.evidence_hash,
      "decision" => Atom.to_string(decision),
      "denial_reason" => denial_reason,
      "operator" => %{
        "sub" => operator.sub,
        "display_name" => operator.display_name,
        "organization_id" => operator.organization_id
      }
    }
  end

  defp command_expires_at(%{expires_at: proposal_expiry}, now) do
    default_expiry = DateTime.add(now, @command_ttl_seconds, :second)

    case timestamp(proposal_expiry) do
      {:ok, expiry} ->
        if DateTime.compare(expiry, default_expiry) == :lt, do: expiry, else: default_expiry

      :error ->
        default_expiry
    end
  end

  defp evidence_fresh?(proposal, now) do
    freshness =
      Map.get(proposal, :evidence_fresh_until) ||
        Map.get(proposal, :evidence_expires_at) ||
        Map.get(proposal, :evidence_freshness_until)

    case timestamp(freshness) do
      {:ok, fresh_until} -> DateTime.compare(now, fresh_until) == :lt
      :error -> false
    end
  end

  defp expired?(value, now) do
    case timestamp(value) do
      {:ok, expiry} -> DateTime.compare(now, expiry) != :lt
      :error -> true
    end
  end

  defp timestamp(%DateTime{} = value), do: {:ok, value}
  defp timestamp(%NaiveDateTime{} = value), do: {:ok, DateTime.from_naive!(value, "Etc/UTC")}

  defp timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> {:ok, parsed}
      {:error, _reason} -> :error
    end
  end

  defp timestamp(_value), do: :error

  defp option_now(opts) do
    case Keyword.get(opts, :now) || Keyword.get(opts, :now_fn) do
      function when is_function(function, 0) -> function.()
      %DateTime{} = now -> now
      nil -> DateTime.utc_now()
      value -> value
    end
  end

  defp rollback(repo, reason) do
    if function_exported?(repo, :rollback, 1) do
      repo.rollback(reason)
    else
      {:error, reason}
    end
  end

  defp normalize_transaction_result({:ok, {:ok, result}}), do: {:ok, result}
  defp normalize_transaction_result({:ok, {:error, reason}}), do: {:error, reason}
  defp normalize_transaction_result({:error, reason}), do: {:error, reason}
  defp normalize_transaction_result({:ok, result}), do: result
  defp normalize_transaction_result(result), do: result

  defp validate_denial_reason(reason)
       when is_binary(reason) and byte_size(reason) > 0 and
              byte_size(reason) <= @max_denial_reason_bytes do
    if String.trim(reason) == "", do: {:error, :invalid_denial_reason}, else: :ok
  end

  defp validate_denial_reason(_reason), do: {:error, :invalid_denial_reason}

  defp actor_audit(operator, correlation_id, now) do
    %{
      "sub" => operator.sub,
      "display_name" => operator.display_name,
      "organization_id" => operator.organization_id,
      "correlation_id" => correlation_id,
      "at" => DateTime.to_iso8601(now)
    }
  end

  defp command_id(opts) do
    case Keyword.get(opts, :command_id) || Keyword.get(opts, :command_id_fn) do
      function when is_function(function, 0) -> function.()
      value when is_binary(value) -> value
      _ -> Ecto.UUID.generate()
    end
  end

  defp generate_correlation_id do
    "corr_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status
  defp normalize_status(_status), do: nil

  defp operator_organization(%Operator{organization_id: organization_id}), do: organization_id
  defp operator_organization(_operator), do: ""
end
