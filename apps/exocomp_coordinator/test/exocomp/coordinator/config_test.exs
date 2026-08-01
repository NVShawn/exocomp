# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ConfigTest do
  use ExUnit.Case, async: true

  alias Exocomp.ClusterProfile.Ceph
  alias Exocomp.Coordinator.Config

  @fixtures_dir Path.expand("../../../../fixtures", __DIR__)
  @valid_config Path.join(@fixtures_dir, "coordinator_config_valid.json")
  @missing_fields_config Path.join(@fixtures_dir, "coordinator_config_missing_fields.json")
  @unknown_version_config Path.join(@fixtures_dir, "coordinator_config_unknown_version.json")
  @malformed_config Path.join(@fixtures_dir, "coordinator_config_malformed.json")
  @ceph_config Path.join(@fixtures_dir, "coordinator_config_ceph.json")
  @ceph_relative_config Path.join(@fixtures_dir, "coordinator_config_ceph_relative.json")
  @ceph_wrong_version_config Path.join(
                               @fixtures_dir,
                               "coordinator_config_ceph_wrong_version.json"
                             )

  # ---------------------------------------------------------------------------
  # Fixtures are created inline for portability
  # ---------------------------------------------------------------------------

  @base_config %{
    "version" => 1,
    "coordinator_id" => "coord-test",
    "tls" => %{
      "ca_cert" => "/tmp/ca.crt",
      "coord_cert" => "/tmp/coordinator.crt",
      "coord_key" => "/tmp/coordinator.key"
    },
    "listen" => %{"host" => "127.0.0.1", "port" => 4443}
  }

  setup do
    File.mkdir_p!(@fixtures_dir)

    File.write!(@valid_config, Jason.encode!(@base_config))

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

    File.write!(
      @ceph_config,
      Jason.encode!(
        Map.put(@base_config, "cluster_profiles", %{
          "ceph" => %{
            "version" => 1,
            "ceph_binary_path" => "/usr/bin/ceph",
            "ceph_conf_path" => "/etc/ceph/ceph.conf",
            "keyring_path" => "/etc/ceph/ceph.client.exocomp.keyring"
          }
        })
      )
    )

    File.write!(
      @ceph_relative_config,
      Jason.encode!(
        Map.put(@base_config, "cluster_profiles", %{
          "ceph" => %{
            "version" => 1,
            "ceph_binary_path" => "ceph",
            "ceph_conf_path" => "/etc/ceph/ceph.conf",
            "keyring_path" => "/etc/ceph/ceph.client.exocomp.keyring"
          }
        })
      )
    )

    File.write!(
      @ceph_wrong_version_config,
      Jason.encode!(
        Map.put(@base_config, "cluster_profiles", %{
          "ceph" => %{
            "version" => 99,
            "ceph_binary_path" => "/usr/bin/ceph",
            "ceph_conf_path" => "/etc/ceph/ceph.conf",
            "keyring_path" => "/etc/ceph/ceph.client.exocomp.keyring"
          }
        })
      )
    )

    on_exit(fn ->
      Enum.each(
        [
          @valid_config,
          @missing_fields_config,
          @unknown_version_config,
          @malformed_config,
          @ceph_config,
          @ceph_relative_config,
          @ceph_wrong_version_config
        ],
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

  test "load/1 returns nil ceph_profile when cluster_profiles section is absent" do
    assert {:ok, config} = Config.load(@valid_config)
    assert config.ceph_profile == nil
  end

  # ---------------------------------------------------------------------------
  # Ceph profile configuration
  # ---------------------------------------------------------------------------

  test "load/1 parses cluster_profiles.ceph into a Ceph.Config struct" do
    assert {:ok, config} = Config.load(@ceph_config)
    assert %Ceph.Config{} = config.ceph_profile
    assert config.ceph_profile.version == 1
    assert config.ceph_profile.ceph_binary_path == "/usr/bin/ceph"
    assert config.ceph_profile.ceph_conf_path == "/etc/ceph/ceph.conf"
    assert config.ceph_profile.keyring_path == "/etc/ceph/ceph.client.exocomp.keyring"
  end

  test "load/1 rejects cluster_profiles.ceph with a relative ceph_binary_path" do
    assert {:error, {:invalid_ceph_profile, reason}} = Config.load(@ceph_relative_config)
    assert String.contains?(reason, "absolute path")
    assert String.contains?(reason, "ceph_binary_path")
  end

  test "load/1 rejects cluster_profiles.ceph with an unsupported version" do
    assert {:error, {:invalid_ceph_profile, reason}} = Config.load(@ceph_wrong_version_config)
    assert String.contains?(reason, "version")
  end

  test "load/1 rejects cluster_profiles.ceph with relative ceph_conf_path" do
    config_json =
      Jason.encode!(
        Map.put(@base_config, "cluster_profiles", %{
          "ceph" => %{
            "version" => 1,
            "ceph_binary_path" => "/usr/bin/ceph",
            "ceph_conf_path" => "etc/ceph/ceph.conf",
            "keyring_path" => "/etc/ceph/ceph.client.exocomp.keyring"
          }
        })
      )

    path = Path.join(@fixtures_dir, "coord_ceph_rel_conf.json")
    File.write!(path, config_json)
    on_exit(fn -> File.rm(path) end)

    assert {:error, {:invalid_ceph_profile, reason}} = Config.load(path)
    assert String.contains?(reason, "absolute path")
    assert String.contains?(reason, "ceph_conf_path")
  end

  test "load/1 rejects cluster_profiles.ceph with relative keyring_path" do
    config_json =
      Jason.encode!(
        Map.put(@base_config, "cluster_profiles", %{
          "ceph" => %{
            "version" => 1,
            "ceph_binary_path" => "/usr/bin/ceph",
            "ceph_conf_path" => "/etc/ceph/ceph.conf",
            "keyring_path" => "ceph.client.exocomp.keyring"
          }
        })
      )

    path = Path.join(@fixtures_dir, "coord_ceph_rel_keyring.json")
    File.write!(path, config_json)
    on_exit(fn -> File.rm(path) end)

    assert {:error, {:invalid_ceph_profile, reason}} = Config.load(path)
    assert String.contains?(reason, "absolute path")
    assert String.contains?(reason, "keyring_path")
  end

  test "load/1 rejects cluster_profiles.ceph that is not a JSON object" do
    config_json =
      Jason.encode!(
        Map.put(@base_config, "cluster_profiles", %{"ceph" => "not-a-map"})
      )

    path = Path.join(@fixtures_dir, "coord_ceph_not_map.json")
    File.write!(path, config_json)
    on_exit(fn -> File.rm(path) end)

    assert {:error, {:invalid_ceph_profile, _reason}} = Config.load(path)
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
