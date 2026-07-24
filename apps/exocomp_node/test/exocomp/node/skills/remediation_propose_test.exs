defmodule Exocomp.Node.Skills.RemediationProposeTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.RemediationPropose

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp fake_proposal do
    %{
      "schema_version" => "1",
      "proposal_id" => "restart_service",
      "rationale" => "The service has been failing repeatedly.",
      "affected_resource" => "nginx.service",
      "confidence" => 0.85
    }
  end

  defp install_client(fun) do
    Application.put_env(:exocomp_node, :remediation_propose_client, fun)
    on_exit(fn -> Application.delete_env(:exocomp_node, :remediation_propose_client) end)
  end

  # ---------------------------------------------------------------------------
  # Test: success path — ProposalClient returns a valid proposal
  # ---------------------------------------------------------------------------

  test "success returns artifact with proposal" do
    install_client(fn _ctx -> {:ok, fake_proposal()} end)

    assert {:ok, %Artifact{} = artifact} = RemediationPropose.execute(%{"cpu" => 95}, %{})

    assert [%DataPart{data: data}] = artifact.parts
    assert data["schema_version"] == "1"
    assert data["skill"] == "exocomp.remediation.propose"

    proposal = data["proposal"]
    assert is_map(proposal)
    assert proposal["proposal_id"] == "restart_service"
    assert proposal["rationale"] == "The service has been failing repeatedly."
    assert proposal["affected_resource"] == "nginx.service"
    assert proposal["confidence"] == 0.85
  end

  # ---------------------------------------------------------------------------
  # Test: ProposalClient returns {:error, :timeout} → {:error, :timeout}
  # ---------------------------------------------------------------------------

  test "ProposalClient returns {:error, :timeout} propagated as {:error, :timeout}" do
    install_client(fn _ctx -> {:error, :inference_timeout} end)

    assert {:error, :inference_timeout} = RemediationPropose.execute(%{}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: ProposalClient returns {:error, :inference_unavailable}
  # ---------------------------------------------------------------------------

  test "inference unavailable returns {:error, :inference_unavailable}" do
    install_client(fn _ctx -> {:error, :inference_unavailable} end)

    assert {:error, :inference_unavailable} = RemediationPropose.execute(%{}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: various error codes are propagated unchanged
  # ---------------------------------------------------------------------------

  test "schema error from ProposalClient is propagated unchanged" do
    install_client(fn _ctx -> {:error, {:schema_error, :unknown_proposal_id}} end)

    assert {:error, {:schema_error, :unknown_proposal_id}} =
             RemediationPropose.execute(%{}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: artifact structure
  # ---------------------------------------------------------------------------

  test "returned artifact has a non-empty artifactId" do
    install_client(fn _ctx -> {:ok, fake_proposal()} end)

    assert {:ok, %Artifact{artifactId: id}} = RemediationPropose.execute(%{}, %{})
    assert is_binary(id) and id != ""
  end

  test "returned artifact has exactly one DataPart" do
    install_client(fn _ctx -> {:ok, fake_proposal()} end)

    assert {:ok, %Artifact{parts: [%DataPart{}]}} = RemediationPropose.execute(%{}, %{})
  end
end
