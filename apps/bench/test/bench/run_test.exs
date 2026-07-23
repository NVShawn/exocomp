defmodule Bench.RunTest do
  use ExUnit.Case, async: true

  alias Bench.{Run, Sample}

  setup do
    path =
      Path.join(
        System.tmp_dir!(),
        "bench-run-#{System.unique_integer([:positive])}.jsonl"
      )

    on_exit(fn -> File.rm(path) end)
    %{path: path}
  end

  test "new/1 creates an empty run and append_sample/2 retains order" do
    run = new_run()
    first = sample(:beam, "memory.bytes", 100)
    second = sample(:host, "cpu.percent", 4.5)

    assert run.samples == []
    assert Run.append_sample(run, first).samples == [first]
    assert Run.append_sample(Run.append_sample(run, first), second).samples == [first, second]
  end

  test "JSONL round trip is lossless and preserves run metadata", %{path: path} do
    run =
      new_run()
      |> Run.append_sample(sample(:beam, "memory.bytes", 100))
      |> Run.append_sample(sample(:llama, "tokens.total", 42))

    assert :ok = Run.write_jsonl(run, path)
    assert {:ok, recovered} = Run.read_jsonl(path)
    assert recovered == run
  end

  test "write_jsonl/2 produces one valid JSON object per sample", %{path: path} do
    run =
      new_run()
      |> Run.append_sample(sample(:node, "requests", 1))
      |> Run.append_sample(sample(:coordinator, "queue.depth", 2))

    assert :ok = Run.write_jsonl(run, path)

    lines = path |> File.read!() |> String.split("\n", trim: true)
    assert length(lines) == 2

    for line <- lines do
      assert {:ok, decoded} = Jason.decode(line)
      assert is_map(decoded)
      assert is_binary(decoded["metric_name"])
      assert decoded["workload_name"] == "idle-node"
    end
  end

  test "read_jsonl/1 reports the malformed line number", %{path: path} do
    File.write!(path, valid_line() <> "\n{invalid json}\n")

    assert {:error, {:malformed_line, 2, %Jason.DecodeError{}}} = Run.read_jsonl(path)
  end

  test "read_jsonl/1 rejects records with missing fields", %{path: path} do
    File.write!(path, ~s({"timestamp":1,"source":"beam"}) <> "\n")

    assert {:error, {:malformed_line, 1, {:missing_fields, _fields}}} =
             Run.read_jsonl(path)
  end

  test "read_jsonl/1 rejects blank records", %{path: path} do
    File.write!(path, valid_line() <> "\n\n" <> valid_line() <> "\n")

    assert {:error, {:malformed_line, 2, %Jason.DecodeError{}}} = Run.read_jsonl(path)
  end

  defp new_run do
    Run.new(
      build_metadata: %{"git_sha" => "abc123", "otp_version" => "28.0"},
      host_profile: "amd64-ci",
      model_version: "llama-3.2",
      workload_name: "idle-node",
      config_ref: "bench/idle-node-v1.toml"
    )
  end

  defp sample(source, metric_name, value) do
    %Sample{
      timestamp: 1_700_000_000_000,
      source: source,
      metric_name: metric_name,
      value: value,
      unit: "count"
    }
  end

  defp valid_line do
    Jason.encode!(
      Map.merge(
        %{
          "build_metadata" => %{"git_sha" => "abc123"},
          "host_profile" => "amd64-ci",
          "model_version" => "llama-3.2",
          "workload_name" => "idle-node",
          "config_ref" => "bench/idle-node-v1.toml"
        },
        Sample.to_map(sample(:beam, "memory.bytes", 100))
      )
    )
  end
end
