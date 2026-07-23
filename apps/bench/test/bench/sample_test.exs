defmodule Bench.SampleTest do
  use ExUnit.Case, async: true

  describe "to_json/1" do
    test "encodes a sample to JSON" do
      sample = %Bench.Sample{
        timestamp_ms: 1_700_000_000_000,
        source: :beam,
        metrics: %{scheduler_usage: 0.02}
      }

      assert {:ok, json} = Bench.Sample.to_json(sample)
      assert is_binary(json)
      assert {:ok, decoded} = Jason.decode(json)
      assert decoded["timestamp_ms"] == 1_700_000_000_000
    end
  end

  describe "from_json/1" do
    test "round-trips a sample through JSON" do
      original = %Bench.Sample{
        timestamp_ms: 1_700_000_000_000,
        source: :host,
        metrics: %{cpu_percent: 5.0}
      }

      assert {:ok, json} = Bench.Sample.to_json(original)
      assert {:ok, recovered} = Bench.Sample.from_json(json)
      assert recovered.timestamp_ms == original.timestamp_ms
    end

    test "returns error for invalid JSON" do
      assert {:error, _reason} = Bench.Sample.from_json("not json {")
    end
  end
end
