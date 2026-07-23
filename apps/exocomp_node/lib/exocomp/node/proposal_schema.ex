defmodule Exocomp.Node.ProposalSchema do
  @moduledoc """
  Versioned schema for structured proposals produced by the Qwen2.5 inference
  client. All model output is validated through `validate/1` before it leaves
  the inference subsystem.

  The schema is intentionally closed:

  - Only the current `@schema_version` is accepted.
  - Only proposal identifiers in `@valid_proposal_ids` are accepted.
  - All five required fields must be present.
  - Extra fields whose keys contain shell-command indicators are rejected.

  The model has no execution interface. A validated proposal is a structured
  intent; deterministic policy code decides whether and how to act on it.
  """

  @schema_version "1"

  @valid_proposal_ids [
    :restart_service,
    :clear_disk_space,
    :rotate_logs,
    :increase_swap
  ]

  @required_fields [:proposal_id, :schema_version, :rationale, :affected_resource, :confidence]

  # Keywords that indicate a field looks like a shell command or forbidden
  # execution path. We match on atom keys and string keys alike.
  @forbidden_patterns ~w(cmd command exec shell script run invoke spawn eval)

  @doc """
  Returns the current schema version string.
  """
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @doc """
  Returns the list of valid proposal identifiers.
  """
  @spec valid_proposal_ids() :: [atom()]
  def valid_proposal_ids, do: @valid_proposal_ids

  @doc """
  Validates a proposal map.

  ## Return values

  - `{:ok, proposal}` – proposal is valid.
  - `{:error, :unknown_schema_version}` – `schema_version` field is missing or
    does not equal the current schema version.
  - `{:error, :unknown_proposal_id}` – `proposal_id` is not in the closed set.
  - `{:error, {:missing_field, field_name}}` – a required field is absent.
  - `{:error, :forbidden_field}` – an extra field whose key looks like a shell
    command was found.
  """
  @spec validate(map()) :: {:ok, map()} | {:error, atom() | {:missing_field, atom()}}
  def validate(proposal) when is_map(proposal) do
    with :ok <- check_schema_version(proposal),
         :ok <- check_forbidden_fields(proposal),
         :ok <- check_required_fields(proposal),
         :ok <- check_proposal_id(proposal) do
      {:ok, proposal}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp check_schema_version(proposal) do
    case Map.get(proposal, :schema_version) || Map.get(proposal, "schema_version") do
      @schema_version -> :ok
      _ -> {:error, :unknown_schema_version}
    end
  end

  defp check_proposal_id(proposal) do
    raw = Map.get(proposal, :proposal_id) || Map.get(proposal, "proposal_id")
    id = if is_binary(raw), do: String.to_existing_atom(raw), else: raw

    if id in @valid_proposal_ids do
      :ok
    else
      {:error, :unknown_proposal_id}
    end
  rescue
    ArgumentError -> {:error, :unknown_proposal_id}
  end

  defp check_required_fields(proposal) do
    Enum.find_value(@required_fields, :ok, fn field ->
      present =
        Map.has_key?(proposal, field) or Map.has_key?(proposal, Atom.to_string(field))

      unless present do
        {:error, {:missing_field, field}}
      end
    end)
  end

  defp check_forbidden_fields(proposal) do
    all_keys =
      Map.keys(proposal)
      |> Enum.map(fn
        k when is_atom(k) -> Atom.to_string(k)
        k when is_binary(k) -> k
      end)

    forbidden =
      Enum.any?(all_keys, fn key ->
        lower = String.downcase(key)
        Enum.any?(@forbidden_patterns, &String.contains?(lower, &1))
      end)

    if forbidden, do: {:error, :forbidden_field}, else: :ok
  end
end
