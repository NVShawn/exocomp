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

  # ---------------------------------------------------------------------------
  # Mission Control configuration (optional)
  # ---------------------------------------------------------------------------

  test "load/1 returns config with mission_control=nil when mission_control block is absent" do
    assert {:ok, config} = Config.load(@valid_config)
    assert is_nil(config.mission_control)
  end

  test "load/1 returns config with mission_control=nil when mission_control.enabled=false" do
    fixture_path = Path.join(@fixtures_dir, "coordinator_config_mc_disabled.json")

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => %{"enabled" => false}
      })
    )

    assert {:ok, config} = Config.load(fixture_path)
    assert is_nil(config.mission_control)

    File.rm(fixture_path)
  end

  test "load/1 returns config with mission_control struct when mission_control.enabled=true and all fields present" do
    # Create temporary cert files
    ca_cert_path = Path.join(@fixtures_dir, "mc-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-outbox")

    File.write!(ca_cert_path, "ca cert data")
    File.write!(client_cert_path, "client cert data")
    File.write!(client_key_path, "client key data")
    File.mkdir_p!(outbox_dir)

    fixture_path = Path.join(@fixtures_dir, "coordinator_config_mc_enabled.json")

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => %{
          "enabled" => true,
          "url" => "wss://mission-control.example.com:443",
          "trust_root" => ca_cert_path,
          "client_cert" => client_cert_path,
          "client_key" => client_key_path,
          "heartbeat_interval_seconds" => 30,
          "reconnect_min_backoff_seconds" => 1,
          "reconnect_max_backoff_seconds" => 60,
          "outbox_path" => outbox_dir
        }
      })
    )

    assert {:ok, config} = Config.load(fixture_path)
    assert config.mission_control.enabled == true
    assert config.mission_control.url == "wss://mission-control.example.com:443"
    assert config.mission_control.heartbeat_interval_seconds == 30
    assert config.mission_control.reconnect_min_backoff_seconds == 1
    assert config.mission_control.reconnect_max_backoff_seconds == 60

    File.rm!(fixture_path)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  test "load/1 returns error when mission_control.enabled=true but required fields are missing" do
    fixture_path = Path.join(@fixtures_dir, "coordinator_config_mc_missing.json")

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => %{
          "enabled" => true,
          "url" => "wss://mission-control.example.com:443"
          # Missing other required fields
        }
      })
    )

    assert {:error, {:missing_fields, missing}} = Config.load(fixture_path)
    assert "mission_control.trust_root" in missing
    assert "mission_control.client_cert" in missing

    File.rm(fixture_path)
  end

  test "load/1 returns error when mission_control.heartbeat_interval_seconds is invalid" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-outbox")

    File.write!(ca_cert_path, "ca cert data")
    File.write!(client_cert_path, "client cert data")
    File.write!(client_key_path, "client key data")
    File.mkdir_p!(outbox_dir)

    fixture_path = Path.join(@fixtures_dir, "coordinator_config_mc_invalid_heartbeat.json")

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => %{
          "enabled" => true,
          "url" => "wss://mission-control.example.com:443",
          "trust_root" => ca_cert_path,
          "client_cert" => client_cert_path,
          "client_key" => client_key_path,
          "heartbeat_interval_seconds" => 0,
          "reconnect_min_backoff_seconds" => 1,
          "reconnect_max_backoff_seconds" => 60,
          "outbox_path" => outbox_dir
        }
      })
    )

    assert {:error, {:type_errors, errors}} = Config.load(fixture_path)
    assert "mission_control.heartbeat_interval_seconds" in errors

    File.rm(fixture_path)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  test "load/1 returns error when mission_control.reconnect_max_backoff < reconnect_min_backoff" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-outbox")

    File.write!(ca_cert_path, "ca cert data")
    File.write!(client_cert_path, "client cert data")
    File.write!(client_key_path, "client key data")
    File.mkdir_p!(outbox_dir)

    fixture_path = Path.join(@fixtures_dir, "coordinator_config_mc_invalid_backoff.json")

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => %{
          "enabled" => true,
          "url" => "wss://mission-control.example.com:443",
          "trust_root" => ca_cert_path,
          "client_cert" => client_cert_path,
          "client_key" => client_key_path,
          "heartbeat_interval_seconds" => 30,
          "reconnect_min_backoff_seconds" => 60,
          "reconnect_max_backoff_seconds" => 10,
          "outbox_path" => outbox_dir
        }
      })
    )

    assert {:error, {:type_errors, errors}} = Config.load(fixture_path)
    assert "mission_control.reconnect_max_backoff_seconds" in errors

    File.rm(fixture_path)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  test "load/1 returns error when mission_control cert files do not exist" do
    fixture_path = Path.join(@fixtures_dir, "coordinator_config_mc_missing_certs.json")

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => %{
          "enabled" => true,
          "url" => "wss://mission-control.example.com:443",
          "trust_root" => "/tmp/nonexistent-mc-ca.crt",
          "client_cert" => "/tmp/nonexistent-mc-client.crt",
          "client_key" => "/tmp/nonexistent-mc-client.key",
          "heartbeat_interval_seconds" => 30,
          "reconnect_min_backoff_seconds" => 1,
          "reconnect_max_backoff_seconds" => 60,
          "outbox_path" => "/tmp/mc-outbox"
        }
      })
    )

    assert {:error, {:type_errors, errors}} = Config.load(fixture_path)
    assert "mission_control.trust_root" in errors
    assert "mission_control.client_cert" in errors
    assert "mission_control.client_key" in errors

    File.rm(fixture_path)
  end

  test "load/1 returns a bounded type error for a non-object mission_control block" do
    fixture_path =
      Path.join(
        System.tmp_dir!(),
        "exocomp-coordinator-mc-invalid-shape-#{System.unique_integer([:positive])}.json"
      )

    File.write!(
      fixture_path,
      Jason.encode!(%{
        "version" => 1,
        "coordinator_id" => "coord-test",
        "tls" => %{
          "ca_cert" => "/tmp/ca.crt",
          "coord_cert" => "/tmp/c.crt",
          "coord_key" => "/tmp/k.key"
        },
        "listen" => %{"host" => "0.0.0.0", "port" => 4443},
        "mission_control" => ["enabled", true]
      })
    )

    on_exit(fn -> File.rm(fixture_path) end)

    assert {:error, {:type_errors, errors}} = Config.load(fixture_path)
    assert "mission_control" in errors
  end
end
