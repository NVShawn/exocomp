# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.BaselineTest do
  use ExUnit.Case, async: true

  alias Bench.Baseline

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "bench-baseline-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root}
  end

  test "selects the checked-in baseline by exact version and architecture" do
    assert {:ok, baseline} = Baseline.select("0.1.0", current_architecture())
    assert baseline.artifact_version == "0.1.0"
    assert baseline.architecture == current_architecture()
    assert Enum.map(baseline.gates, & &1.name) == ["beam_cpu_percent", "beam_ram_percent"]
    assert Enum.all?(baseline.gates, &(&1.budget == 5.0))
  end

  test "selects the exact release-candidate baseline without falling back" do
    assert {:ok, baseline} = Baseline.select("0.1.0-rc.2", current_architecture())
    assert baseline.artifact_version == "0.1.0-rc.2"
    assert baseline.path =~ "/v0.1.0-rc.2/"
  end

  test "accepts a leading v while retaining exact prerelease identity", %{root: root} do
    write_baseline(root, "1.2.3-rc.4", "amd64", "amd64-ci")

    assert {:ok, baseline} =
             Baseline.select("v1.2.3-rc.4", "amd64", root: root)

    assert baseline.artifact_version == "1.2.3-rc.4"
  end

  test "missing version returns the requested identity and selected path", %{root: root} do
    assert {:error, {:baseline_not_found, "9.9.9", "arm64", path}} =
             Baseline.select("9.9.9", "arm64", root: root)

    assert String.ends_with?(path, "v9.9.9/arm64.toml")
  end

  test "rejects a baseline whose embedded identity differs from its path", %{root: root} do
    write_baseline(root, "1.0.0", "amd64", "amd64-ci", embedded_version: "2.0.0")

    assert {:error, {:baseline_identity_mismatch, mismatch}} =
             Baseline.select("1.0.0", "amd64", root: root)

    assert mismatch.actual_version == "2.0.0"
    assert mismatch.expected_version == "1.0.0"
  end

  test "load reports malformed and missing gate fields", %{root: root} do
    malformed = Path.join(root, "malformed.toml")
    File.write!(malformed, "schema_version = nope\n")
    assert {:error, {:baseline_parse_error, 1, :unsupported_value}} = Baseline.load(malformed)

    incomplete = Path.join(root, "incomplete.toml")
    File.write!(incomplete, "schema_version = 1\n")

    assert {:error, {:baseline_missing_fields, fields}} = Baseline.load(incomplete)
    assert "gates" in fields
  end

  test "requires both documented M5 hard gates", %{root: root} do
    write_baseline(root, "1.0.0", "amd64", "amd64-ci", include_ram: false)
    path = Path.join([root, "v1.0.0", "amd64.toml"])

    assert {:error, {:baseline_missing_gates, ["beam_ram_percent"]}} =
             Baseline.load(path)
  end

  test "rejects a baseline that relaxes a documented M5 budget", %{root: root} do
    write_baseline(root, "1.0.0", "amd64", "amd64-ci", cpu_budget: 5.1)
    path = Path.join([root, "v1.0.0", "amd64.toml"])

    assert {:error, {:invalid_gate, "beam_cpu_percent", attrs}} =
             Baseline.load(path)

    assert attrs["budget"] == 5.1
  end

  defp current_architecture do
    Bench.HostProfile.detect().architecture
  end

  defp write_baseline(root, version, architecture, profile, opts \\ []) do
    directory = Path.join(root, "v#{version}")
    File.mkdir_p!(directory)
    embedded_version = Keyword.get(opts, :embedded_version, version)
    cpu_budget = Keyword.get(opts, :cpu_budget, 5.0)

    ram_gate =
      if Keyword.get(opts, :include_ram, true) do
        """

        [gates.beam_ram_percent]
        metric = "beam.memory.node_plus_coordinator.peak_percent"
        budget = 5.0
        unit = "percent"
        direction = "lower_is_better"
        """
      else
        ""
      end

    File.write!(
      Path.join(directory, "#{architecture}.toml"),
      """
      schema_version = 1
      artifact_version = "#{embedded_version}"
      architecture = "#{architecture}"
      host_profile = "#{profile}"

      [gates.beam_cpu_percent]
      metric = "beam.cpu.node_plus_coordinator.mean_percent"
      budget = #{cpu_budget}
      unit = "percent"
      direction = "lower_is_better"
      #{ram_gate}
      """
    )
  end
end
