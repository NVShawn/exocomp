defmodule Bench.DriverTest do
  use ExUnit.Case, async: true

  @valid_opts [
    schema_version: 1,
    name: "idle-node",
    version: "0.1.0",
    warm_up_duration: 30,
    run_duration: 300,
    repetitions: 3,
    concurrency: 1,
    sample_interval: 1000,
    host_profile: "amd64-linux",
    workload_scenario: "idle"
  ]

  describe "run/1" do
    test "returns :ok when all required config options are provided and valid" do
      assert :ok = Bench.Driver.run(@valid_opts)
    end

    test "returns {:error, {:invalid_config, _}} for missing required fields" do
      assert {:error, {:invalid_config, {:missing_fields, _}}} = Bench.Driver.run([])
    end

    test "returns {:error, {:invalid_config, _}} for unknown options" do
      assert {:error, {:invalid_config, {:unknown_fields, _}}} =
               Bench.Driver.run(unknown_option: "bad")
    end

    test "returns {:error, {:invalid_config, :incompatible_version}} for wrong schema_version" do
      opts = Keyword.put(@valid_opts, :schema_version, 99)
      assert {:error, {:invalid_config, :incompatible_version}} = Bench.Driver.run(opts)
    end
  end
end
