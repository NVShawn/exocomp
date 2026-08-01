# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Proposal do
  @moduledoc """
  A typed remedy proposal linking cluster evidence to a catalog action.

  A proposal represents a suggested action to remediate a cluster or node issue.
  It is always organization and cluster scoped, optionally targets a specific node,
  and links to the conversation message, evidence, and task/correlation IDs that
  generated it.

  The proposal stores the action ID, validated parameters, evidence reference,
  risk and disruption assessments, rationale, deterministic policy result, and
  expiry timestamp. It is never executed from this store; execution happens only
  after separate operator approval in the coordinator's local context.

  Unknown fields are rejected, preventing arbitrary payloads from entering the
  conversation store.
  """

  @allowed_fields MapSet.new([
                    :id,
                    :organization_id,
                    :cluster_id,
                    :node_id,
                    :conversation_id,
                    :message_id,
                    :task_id,
                    :correlation_id,
                    :catalog_action_id,
                    :parameters,
                    :evidence_reference,
                    :evidence_hash,
                    :risk,
                    :expected_disruption,
                    :rationale,
                    :policy_result,
                    :created_at,
                    :expires_at
                  ])

  @type risk :: :low | :medium | :high | :critical
  @type policy_result :: :allow | :deny | :approval_required

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          cluster_id: String.t(),
          node_id: String.t() | nil,
          conversation_id: String.t() | nil,
          message_id: String.t() | nil,
          task_id: String.t() | nil,
          correlation_id: String.t() | nil,
          catalog_action_id: String.t(),
          parameters: map(),
          evidence_reference: Exocomp.MissionControl.EvidenceReference.t() | nil,
          evidence_hash: String.t(),
          risk: risk(),
          expected_disruption: String.t() | nil,
          rationale: String.t() | nil,
          policy_result: policy_result(),
          created_at: DateTime.t(),
          expires_at: DateTime.t()
        }

  defstruct [
    :id,
    :organization_id,
    :cluster_id,
    :node_id,
    :conversation_id,
    :message_id,
    :task_id,
    :correlation_id,
    :catalog_action_id,
    :parameters,
    :evidence_reference,
    :evidence_hash,
    :risk,
    :expected_disruption,
    :rationale,
    :policy_result,
    :created_at,
    :expires_at
  ]

  @doc "Build and validate a proposal from an attribute map."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    case unsupported_field(attrs) do
      nil -> build(attrs)
      field -> {:error, {:unsupported_proposal_field, field}}
    end
  end

  def new(_attrs), do: {:error, :invalid_proposal}

  @doc "Check whether a proposal has expired relative to the current time."
  @spec expired?(t()) :: boolean()
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc "Check whether evidence for a proposal is too old relative to a freshness window."
  @spec evidence_stale?(t(), non_neg_integer()) :: boolean()
  def evidence_stale?(%__MODULE__{evidence_reference: nil}, _freshness_ms), do: true

  def evidence_stale?(%__MODULE__{evidence_reference: evidence}, freshness_ms) do
    age_ms = DateTime.diff(DateTime.utc_now(), evidence.observed_at, :millisecond)
    age_ms > freshness_ms
  end

  defp build(attrs) do
    organization_id = value(attrs, :organization_id)
    cluster_id = value(attrs, :cluster_id)
    catalog_action_id = value(attrs, :catalog_action_id)
    parameters = value(attrs, :parameters) || %{}
    evidence_hash = value(attrs, :evidence_hash)
    risk = normalize_risk(value(attrs, :risk))
    policy_result = normalize_policy_result(value(attrs, :policy_result))
    expected_disruption = value(attrs, :expected_disruption)
    rationale = value(attrs, :rationale)

    with :ok <- required_id(organization_id, :organization_id),
         :ok <- required_id(cluster_id, :cluster_id),
         :ok <- required_id(catalog_action_id, :catalog_action_id),
         :ok <- required_id(evidence_hash, :evidence_hash),
         :ok <- optional_id(value(attrs, :node_id), :node_id),
         :ok <- optional_id(value(attrs, :conversation_id), :conversation_id),
         :ok <- optional_id(value(attrs, :message_id), :message_id),
         :ok <- optional_id(value(attrs, :task_id), :task_id),
         :ok <- optional_id(value(attrs, :correlation_id), :correlation_id),
         :ok <- validate_parameters(parameters),
         :ok <- validate_text_field(expected_disruption, :expected_disruption, 256),
         :ok <- validate_text_field(rationale, :rationale, 2048),
         {:ok, risk} <- risk,
         {:ok, policy_result} <- policy_result,
         {:ok, evidence_reference} <- build_evidence_reference(value(attrs, :evidence_reference)),
         {:ok, created_at} <- timestamp(value(attrs, :created_at)),
         {:ok, expires_at} <- timestamp(value(attrs, :expires_at)) do
      {:ok,
       %__MODULE__{
         id: value(attrs, :id) || generate_id("prop_"),
         organization_id: organization_id,
         cluster_id: cluster_id,
         node_id: value(attrs, :node_id),
         conversation_id: value(attrs, :conversation_id),
         message_id: value(attrs, :message_id),
         task_id: value(attrs, :task_id),
         correlation_id: value(attrs, :correlation_id),
         catalog_action_id: catalog_action_id,
         parameters: parameters,
         evidence_reference: evidence_reference,
         evidence_hash: evidence_hash,
         risk: risk,
         expected_disruption: expected_disruption,
         rationale: rationale,
         policy_result: policy_result,
         created_at: created_at,
         expires_at: expires_at
       }}
    end
  end

  defp validate_parameters(params) when is_map(params) do
    if Enum.all?(params, fn {k, _v} -> is_binary(k) end) do
      :ok
    else
      {:error, :invalid_parameters}
    end
  end

  defp validate_parameters(_params), do: {:error, :invalid_parameters}

  defp validate_text_field(nil, _field, _max), do: :ok

  defp validate_text_field(value, field, max) when is_binary(value) do
    cond do
      not String.valid?(value) -> {:error, :invalid_utf8}
      byte_size(value) > max -> {:error, {:invalid_field, field}}
      true -> :ok
    end
  end

  defp validate_text_field(_value, field, _max), do: {:error, {:invalid_field, field}}

  defp build_evidence_reference(nil), do: {:ok, nil}

  defp build_evidence_reference(%Exocomp.MissionControl.EvidenceReference{} = reference) do
    {:ok, reference}
  end

  defp build_evidence_reference(attrs) when is_map(attrs) do
    Exocomp.MissionControl.EvidenceReference.new(attrs)
  end

  defp build_evidence_reference(_), do: {:error, :invalid_evidence_reference}

  defp normalize_risk(nil), do: {:ok, :medium}
  defp normalize_risk(risk) when risk in [:low, :medium, :high, :critical], do: {:ok, risk}
  defp normalize_risk("low"), do: {:ok, :low}
  defp normalize_risk("medium"), do: {:ok, :medium}
  defp normalize_risk("high"), do: {:ok, :high}
  defp normalize_risk("critical"), do: {:ok, :critical}
  defp normalize_risk(risk), do: {:error, {:invalid_risk, risk}}

  defp normalize_policy_result(nil), do: {:error, :policy_result_required}
  defp normalize_policy_result(result) when result in [:allow, :deny, :approval_required], do: {:ok, result}
  defp normalize_policy_result("allow"), do: {:ok, :allow}
  defp normalize_policy_result("deny"), do: {:ok, :deny}
  defp normalize_policy_result("approval_required"), do: {:ok, :approval_required}
  defp normalize_policy_result(result), do: {:error, {:invalid_policy_result, result}}

  defp required_id(value, _field) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp required_id(_value, field), do: {:error, {:required, field}}

  defp optional_id(nil, _field), do: :ok
  defp optional_id(value, field), do: required_id(value, field)

  defp unsupported_field(attrs) do
    attrs
    |> Map.keys()
    |> Enum.map(&normalize_key/1)
    |> Enum.find(fn key -> key not in @allowed_fields end)
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  defp value(attrs, key), do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

  defp timestamp(nil), do: {:ok, DateTime.utc_now()}
  defp timestamp(%DateTime{} = value), do: {:ok, value}
  defp timestamp(_value), do: {:error, :invalid_timestamp}

  defp generate_id(prefix) do
    prefix <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end
end
