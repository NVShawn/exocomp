# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ConfigTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.Config

  @fixtures_dir Path.expand("../../../../fixtures", __DIR__)
  @valid_config Path.join(@fixtures_dir, "coordinator_config_valid.json")
  @missing_fields_config Path.join(@fixtures_dir, "coordinator_config_missing_fields.json")
  @unknown_version_config Path.join(@fixtures_dir, "coordinator_config_unknown_version.json")
  @malformed_config Path.join(@fixtures_dir, "coordinator_config_malformed.json")

  # ---------------------------------------------------------------------------
  # Fixtures are created inline for portability
  # ---------------------------------------------------------------------------

  setup do
    File.mkdir_p!(@fixtures_dir)

    File.write!(
      @valid_config,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/coordinator.crt",
          "coord_key" => "/tmp/coordinator.key"
        },
        "listen" => %{"host" => "127.0.0.1", "port" => 4443}
      })
    )

    File.write!(
      @missing_fields_config,
      Jason.encode!(%{
        "version" => 1,
        "tls" => %{"ca_cert" => "/tmp/ca.crt"}
      })
    )

    File.write!(
      @unknown_version_config,
      Jason.encode!(%{
        "version" => 99,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443}
      })
    )

    File.write!(@malformed_config, "{ not valid json }")

    on_exit(fn ->
      Enum.each(
        [@valid_config, @missing_fields_config, @unknown_version_config, @malformed_config],
        &File.rm/1
      )
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Successful load
  # ---------------------------------------------------------------------------

  test "load/1 returns {:ok, config} for a valid config file" do
    assert {:ok, config} = Config.load(@valid_config)
    assert config.coordinator_id == "coord-test"
    assert config.version == 1
    assert config.tls.ca_cert == "/tmp/ca.crt"
    assert config.tls.coord_cert == "/tmp/coordinator.crt"
    assert config.tls.coord_key == "/tmp/coordinator.key"
    assert config.listen.host == "127.0.0.1"
    assert config.listen.port == 4443
  end

  # ---------------------------------------------------------------------------
  # File errors
  # ---------------------------------------------------------------------------

  test "load/1 returns {:error, :enoent} when file does not exist" do
    assert {:error, :enoent} = Config.load("/tmp/this-file-does-not-exist-coord.json")
  end

  # ---------------------------------------------------------------------------
  # Parsing errors
  # ---------------------------------------------------------------------------

  test "load/1 returns {:error, {:json_parse, _}} for malformed JSON" do
    assert {:error, {:json_parse, _}} = Config.load(@malformed_config)
  end

  # ---------------------------------------------------------------------------
  # Version errors
  # ---------------------------------------------------------------------------

  test "load/1 returns {:error, {:unsupported_version, 99}} for unknown version" do
    assert {:error, {:unsupported_version, 99}} = Config.load(@unknown_version_config)
  end

  # ---------------------------------------------------------------------------
  # Missing field errors
  # ---------------------------------------------------------------------------

  test "load/1 returns {:error, {:missing_fields, _}} when required fields are absent" do
    assert {:error, {:missing_fields, missing}} = Config.load(@missing_fields_config)
    assert "coordinator_id" in missing
    assert "listen" in missing
    assert "tls.coord_cert" in missing
    assert "tls.coord_key" in missing
  end
end
