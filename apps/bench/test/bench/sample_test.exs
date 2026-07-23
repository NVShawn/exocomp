defmodule Bench.SampleTest do
  use ExUnit.Case, async: true

  alias Bench.Sample

  test "round-trips every sample field through JSON" do
    original = %Sample{
      timestamp: 1_700_000_000_000,
      source: :host,
      metric_name: "cpu.percent",
      value: 5.25,
      unit: "percent"
    }

    assert {:ok, json} = Sample.to_json(original)
    assert {:ok, ^original} = Sample.from_json(json)
  end

  test "supports every sample source" do
    for source <- [:beam, :host, :node, :coordinator, :llama] do
      sample = %Sample{
        timestamp: "2026-07-23T21:00:00Z",
        source: source,
        metric_name: "requests",
        value: 1,
        unit: "count"
      }

      assert {:ok, json} = Sample.to_json(sample)
      assert {:ok, ^sample} = Sample.from_json(json)
    end
  end

  test "round-trips unavailable values and metric tags" do
    original = %Sample{
      timestamp: 1_700_000_000_000,
      source: :node,
      metric_name: "cpu.percent",
      value: nil,
      unit: "percent",
      tags: [:missing]
    }

    assert {:ok, json} = Sample.to_json(original)
    assert {:ok, ^original} = Sample.from_json(json)
  end

  test "defaults tags for records written before tags were added" do
    assert {:ok, %Sample{tags: []}} =
             Sample.from_json(
               ~s({"timestamp":1,"source":"host","metric_name":"cpu","value":2,"unit":"percent"})
             )
  end

  test "rejects invalid JSON and unknown sources" do
    assert {:error, _reason} = Sample.from_json("not json {")

    assert {:error, {:invalid_sample_field, :source}} =
             Sample.from_json(
               ~s({"timestamp":1,"source":"other","metric_name":"cpu","value":2,"unit":"percent"})
             )
  end
end
