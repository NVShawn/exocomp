# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Message do
  @moduledoc """
  An ordered, text-only conversation message.

  Message size is measured in UTF-8 bytes because the storage and context
  limits are byte limits. Evidence is represented only by validated
  `EvidenceReference` values.
  """

  @max_bytes 16 * 1024
  @states [:queued, :delivered, :reasoning, :completed, :failed, :expired]
  @terminal_states [:completed, :failed, :expired]

  @allowed_fields MapSet.new([
                    :id,
                    :organization_id,
                    :conversation_id,
                    :sequence,
                    :sender_type,
                    :sender_id,
                    :body,
                    :evidence_refs,
                    :state,
                    :failure_reason,
                    :created_at,
                    :updated_at,
                    :state_history
                  ])

  @type state :: :queued | :delivered | :reasoning | :completed | :failed | :expired

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t() | nil,
          conversation_id: String.t() | nil,
          sequence: pos_integer() | nil,
          sender_type: atom(),
          sender_id: String.t() | nil,
          body: String.t(),
          evidence_refs: [Exocomp.MissionControl.EvidenceReference.t()],
          state: state(),
          failure_reason: term(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          state_history: [%{from: state() | nil, to: state(), at: DateTime.t()}]
        }

  defstruct [
    :id,
    :organization_id,
    :conversation_id,
    :sequence,
    :sender_type,
    :sender_id,
    :body,
    evidence_refs: [],
    state: :queued,
    failure_reason: nil,
    created_at: nil,
    updated_at: nil,
    state_history: []
  ]

  @doc "Maximum number of UTF-8 bytes accepted in a message body."
  @spec max_bytes() :: pos_integer()
  def max_bytes, do: @max_bytes

  @doc "All message lifecycle states."
  @spec states() :: [state()]
  def states, do: @states

  @doc "Build and validate a message. The store supplies its sequence number."
  @spec new(map() | String.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def new(value, opts \\ [])

  def new(body, opts) when is_binary(body) do
    new(Map.put(Map.new(opts), :body, body))
  end

  def new(attrs, _opts) when is_map(attrs) do
    case unsupported_field(attrs) do
      nil -> build(attrs)
      field -> {:error, {:unsupported_message_field, field}}
    end
  end

  def new(_attrs, _opts), do: {:error, :invalid_message}

  @doc "Returns the UTF-8 byte size used by context selection."
  @spec bytes(t()) :: non_neg_integer()
  def bytes(%__MODULE__{body: body}) when is_binary(body), do: byte_size(body)

  @doc "Returns whether a message state is terminal."
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{state: state}), do: state in @terminal_states

  @doc "Apply one legal lifecycle transition and record its timestamp."
  @spec transition(t(), state() | String.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def transition(%__MODULE__{} = message, target, opts \\ []) do
    with {:ok, target} <- normalize_state(target),
         true <- legal_transition?(message.state, target) do
      at = Keyword.get(opts, :at, DateTime.utc_now())
      reason = if target == :failed, do: Keyword.get(opts, :reason), else: nil

      {:ok,
       %{
         message
         | state: target,
           failure_reason: reason,
           updated_at: at,
           state_history: message.state_history ++ [%{from: message.state, to: target, at: at}]
       }}
    else
      false -> {:error, {:invalid_transition, message.state, target}}
      {:error, _} = error -> error
    end
  end

  @doc false
  @spec legal_transition?(state(), state()) :: boolean()
  def legal_transition?(:queued, target) when target in [:delivered, :failed, :expired], do: true

  def legal_transition?(:delivered, target) when target in [:reasoning, :failed, :expired],
    do: true

  def legal_transition?(:reasoning, target) when target in [:completed, :failed, :expired],
    do: true

  def legal_transition?(_from, _to), do: false

  defp build(attrs) do
    body = value(attrs, :body)
    sender_type = normalize_sender(value(attrs, :sender_type) || :operator)
    sender_id = value(attrs, :sender_id)
    state = value(attrs, :state) || :queued

    with :ok <- validate_body(body),
         {:ok, sender_type} <- sender_type,
         :ok <- validate_sender_id(sender_id),
         {:ok, state} <- normalize_state(state),
         {:ok, evidence_refs} <- evidence_references(value(attrs, :evidence_refs) || []),
         {:ok, created_at} <- timestamp(value(attrs, :created_at)),
         {:ok, updated_at} <- timestamp(value(attrs, :updated_at) || created_at) do
      {:ok,
       %__MODULE__{
         id: value(attrs, :id) || generate_id("msg_"),
         organization_id: value(attrs, :organization_id),
         conversation_id: value(attrs, :conversation_id),
         sequence: value(attrs, :sequence),
         sender_type: sender_type,
         sender_id: sender_id,
         body: body,
         evidence_refs: evidence_refs,
         state: state,
         failure_reason: value(attrs, :failure_reason),
         created_at: created_at,
         updated_at: updated_at,
         state_history: value(attrs, :state_history) || []
       }}
    end
  end

  defp validate_body(body)
       when is_binary(body) and byte_size(body) > 0 and byte_size(body) <= @max_bytes do
    if String.valid?(body), do: :ok, else: {:error, :invalid_utf8}
  end

  defp validate_body(body) when is_binary(body),
    do: {:error, {:message_too_large, byte_size(body), @max_bytes}}

  defp validate_body(_body), do: {:error, :message_body_required}

  defp validate_sender_id(nil), do: :ok
  defp validate_sender_id(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_sender_id(_value), do: {:error, :invalid_sender_id}

  defp normalize_sender(sender) when sender in [:operator, :cluster, :system], do: {:ok, sender}
  defp normalize_sender("operator"), do: {:ok, :operator}
  defp normalize_sender("cluster"), do: {:ok, :cluster}
  defp normalize_sender("system"), do: {:ok, :system}
  defp normalize_sender(sender), do: {:error, {:invalid_sender_type, sender}}

  defp normalize_state(state) when state in @states, do: {:ok, state}
  defp normalize_state("queued"), do: {:ok, :queued}
  defp normalize_state("delivered"), do: {:ok, :delivered}
  defp normalize_state("reasoning"), do: {:ok, :reasoning}
  defp normalize_state("completed"), do: {:ok, :completed}
  defp normalize_state("failed"), do: {:ok, :failed}
  defp normalize_state("expired"), do: {:ok, :expired}
  defp normalize_state(state), do: {:error, {:invalid_state, state}}

  defp evidence_references(refs) when is_list(refs) do
    Enum.reduce_while(refs, {:ok, []}, fn reference, {:ok, acc} ->
      case reference do
        %Exocomp.MissionControl.EvidenceReference{} ->
          {:cont, {:ok, acc ++ [reference]}}

        attrs when is_map(attrs) ->
          case Exocomp.MissionControl.EvidenceReference.new(attrs) do
            {:ok, reference} -> {:cont, {:ok, acc ++ [reference]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end

        _ ->
          {:halt, {:error, :invalid_evidence_reference}}
      end
    end)
  end

  defp evidence_references(_refs), do: {:error, :invalid_evidence_references}

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