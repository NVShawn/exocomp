defmodule Bench.ConfigTest do
  use ExUnit.Case, async: true

  @valid_attrs %{
    "schema_version" => 1,
    "name" => "idle-node",
    "version" => "0.1.0",
    "warm_up_duration" => 30,
    "run_duration" => 300,
    "repetitions" => 3,
    "concurrency" => 1,
    "sample_interval" => 1000,
    "host_profile" => "amd64-linux",
    "workload_scenario" => "idle"
  }

  describe "parse/1 — valid input" do
    test "valid string-key map returns {:ok, %Bench.Config{}}" do
      assert {:ok, config} = Bench.Config.parse(@valid_attrs)
      assert %Bench.Config{} = config
      assert config.schema_version == 1
      assert config.name == "idle-node"
      assert config.host_profile == "amd64-linux"
    end

    test "valid atom-key map parses correctly" do
      attrs = %{
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
      }

      assert {:ok, config} = Bench.Config.parse(attrs)
      assert config.name == "idle-node"
    end
  end

  describe "parse/1 — invalid input" do
    test "unknown fields returns {:error, {:unknown_fields, _}}" do
      attrs = Map.put(@valid_attrs, "extra", "oops")
      assert {:error, {:unknown_fields, unknown}} = Bench.Config.parse(attrs)
      assert "extra" in unknown
    end

    test "missing required fields returns {:error, {:missing_fields, _}}" do
      attrs = Map.delete(@valid_attrs, "name")
      assert {:error, {:missing_fields, missing}} = Bench.Config.parse(attrs)
      assert "name" in missing
    end

    test "wrong schema_version returns {:error, :incompatible_version}" do
      attrs = Map.put(@valid_attrs, "schema_version", 99)
      assert {:error, :incompatible_version} = Bench.Config.parse(attrs)
    end

    test "non-map input returns {:error, :invalid_input}" do
      assert {:error, :invalid_input} = Bench.Config.parse("not a map")
      assert {:error, :invalid_input} = Bench.Config.parse(nil)
    end

    test "negative numeric field returns {:error, {:invalid_field, _, :must_be_positive}}" do
      attrs = Map.put(@valid_attrs, "run_duration", -1)

      assert {:error, {:invalid_field, :run_duration, :must_be_positive}} =
               Bench.Config.parse(attrs)
    end
  end

  describe "validate/1" do
    test "valid struct returns {:ok, struct}" do
      {:ok, config} = Bench.Config.parse(@valid_attrs)
      assert {:ok, ^config} = Bench.Config.validate(config)
    end

    test "wrong schema_version on struct returns {:error, :incompatible_version}" do
      {:ok, config} = Bench.Config.parse(@valid_attrs)

      assert {:error, :incompatible_version} =
               Bench.Config.validate(%{config | schema_version: 2})
    end

    test "delegates to parse/1 when given a map" do
      assert {:ok, %Bench.Config{}} = Bench.Config.validate(@valid_attrs)
    end
  end
end
