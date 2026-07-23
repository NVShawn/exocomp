defmodule Bench.Report.SummaryTest do
  use ExUnit.Case, async: true

  describe "to_json/1" do
    test "encodes a summary struct to JSON" do
      summary = %Bench.Report.Summary{
        run_id: "run-001",
        host_profile: "amd64-ci",
        workload: :idle,
        metrics: %{}
      }

      assert {:ok, json} = Bench.Report.Summary.to_json(summary)
      assert is_binary(json)
      assert {:ok, decoded} = Jason.decode(json)
      assert decoded["run_id"] == "run-001"
    end
  end
end
