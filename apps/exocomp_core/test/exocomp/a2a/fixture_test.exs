defmodule Exocomp.A2A.FixtureTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{
    AgentCard,
    Artifact,
    Codec,
    InvalidRequestError,
    Message,
    Task,
    TaskNotFoundError
  }

  @fixture_dir Path.expand("../../fixtures/a2a", __DIR__)

  # Maps each fixture filename to the A2A type used to decode it.
  @fixtures [
    {"agent_card_minimal.json", AgentCard},
    {"agent_card_full.json", AgentCard},
    {"message_user_text.json", Message},
    {"message_agent_data.json", Message},
    {"task_submitted.json", Task},
    {"task_completed_with_artifact.json", Task},
    {"task_failed.json", Task},
    {"artifact_text.json", Artifact},
    {"error_invalid_request.json", InvalidRequestError},
    {"error_task_not_found.json", TaskNotFoundError}
  ]

  defp load_fixture(filename) do
    @fixture_dir
    |> Path.join(filename)
    |> File.read!()
    |> Jason.decode!()
  end

  for {filename, type} <- @fixtures do
    @tag fixture: filename, type: type
    test "#{filename} round-trips through #{inspect(type)} without semantic loss" do
      json_map = load_fixture(unquote(filename))
      assert {:ok, struct} = Codec.decode(json_map, unquote(type))
      encoded_map = Codec.encode(struct)
      assert encoded_map == json_map
    end
  end

  test "all fixture files exist and are valid JSON" do
    for {filename, _type} <- @fixtures do
      path = Path.join(@fixture_dir, filename)
      assert File.exists?(path), "fixture file missing: #{filename}"
      content = File.read!(path)
      assert {:ok, _} = Jason.decode(content), "fixture is not valid JSON: #{filename}"
    end
  end
end
