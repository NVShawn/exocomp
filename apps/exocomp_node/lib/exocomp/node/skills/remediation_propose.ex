defmodule Exocomp.Node.Skills.RemediationPropose do
  @moduledoc """
  Skill handler for `exocomp.remediation.propose`.

  Sends the diagnostic context map to `ProposalClient.propose/1` and wraps
  the validated proposal in an A2A Artifact. If the inference server is
  unavailable or the model returns an error, the error is propagated as-is
  without raising an exception.

  ## Configuration

  - `:remediation_propose_client` (Application config, `:exocomp_node`) —
    1-arity function `fn context -> {:ok, proposal} | {:error, reason} end`
    injected for tests. Defaults to `Exocomp.Node.ProposalClient.propose/1`.

  ## Params

    Any map — the diagnostic context forwarded verbatim to the inference client.

  ## Errors

  - `{:error, :inference_unavailable}` — inference server is not ready.
  - `{:error, reason}` — any other error from `ProposalClient`.
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @impl true
  def execute(params, _context) when is_map(params) do
    client =
      Application.get_env(
        :exocomp_node,
        :remediation_propose_client,
        &default_propose/1
      )

    case client.(params) do
      {:ok, proposal} ->
        build_artifact(proposal)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(proposal) do
    # Normalize proposal keys to strings for consistent serialization.
    serialized_proposal = Map.new(proposal, fn {k, v} -> {to_string(k), v} end)

    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.remediation.propose",
      "proposal" => %{
        "proposal_id" =>
          Map.get(serialized_proposal, "proposal_id") ||
            Map.get(serialized_proposal, ":proposal_id"),
        "rationale" =>
          Map.get(serialized_proposal, "rationale") ||
            Map.get(serialized_proposal, ":rationale"),
        "affected_resource" =>
          Map.get(serialized_proposal, "affected_resource") ||
            Map.get(serialized_proposal, ":affected_resource"),
        "confidence" =>
          Map.get(serialized_proposal, "confidence") ||
            Map.get(serialized_proposal, ":confidence")
      }
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "remediation-propose",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp default_propose(context), do: Exocomp.Node.ProposalClient.propose(context)

  defp generate_artifact_id do
    "remediation-propose-#{System.unique_integer([:positive, :monotonic])}"
  end
end
