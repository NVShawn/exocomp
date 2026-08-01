# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Config do
  @moduledoc """
  Loads, validates, and exposes Exocomp coordinator configuration from a
  versioned JSON file.

  ## Config file schema (version 1)

  ```json
  {
    "version": 1,
    "coordinator_id": "exocomp-coordinator",
    "tls": {
      "ca_cert":      "/path/to/ca.crt",
      "coord_cert":   "/path/to/coordinator.crt",
      "coord_key":    "/path/to/coordinator.key"
    },
    "listen": {
      "host": "0.0.0.0",
      "port": 4443
    },
    "mission_control": {
      "enabled": true,
      "url": "wss://mission-control.example.com:443",
      "trust_root": "/path/to/mc-trust-root.crt",
      "client_cert": "/path/to/mc-client.crt",
      "client_key": "/path/to/mc-client.key",
      "heartbeat_interval_seconds": 30,
      "reconnect_min_backoff_seconds": 1,
      "reconnect_max_backoff_seconds": 60,
      "outbox_path": "/var/lib/exocomp-coordinator/mc-outbox"
    }
  }
  ```

  ## File resolution order

  `load/1` resolves the config path in this order:

  1. The `path` argument (when non-`nil`)
  2. The `EXOCOMP_COORDINATOR_CONFIG_FILE` environment variable
  3. The compiled-in default (`/etc/exocomp/coordinator.json`)

  ## Environment overrides

  | Variable                              | Overrides                               |
  |---------------------------------------|----------------------------------------|
  | `EXOCOMP_COORDINATOR_ID`              | `coordinator_id`                        |
  | `EXOCOMP_LISTEN_ADDRESS`              | `listen.host`                           |
  | `EXOCOMP_LISTEN_PORT`                 | `listen.port`                           |
  | `EXOCOMP_TLS_CERT_PATH`               | `tls.coord_cert`                        |
  | `EXOCOMP_TLS_KEY_PATH`                | `tls.coord_key`                         |
  | `EXOCOMP_TLS_CA_PATH`                 | `tls.ca_cert`                           |
  | `EXOCOMP_MISSION_CONTROL_ENABLED`     | `mission_control.enabled`               |
  | `EXOCOMP_MISSION_CONTROL_URL`         | `mission_control.url`                   |
  | `EXOCOMP_MISSION_CONTROL_TRUST_ROOT`  | `mission_control.trust_root`            |
  | `EXOCOMP_MISSION_CONTROL_CLIENT_CERT` | `mission_control.client_cert`           |
  | `EXOCOMP_MISSION_CONTROL_CLIENT_KEY`  | `mission_control.client_key`            |
  | `EXOCOMP_MISSION_CONTROL_HEARTBEAT`   | `mission_control.heartbeat_interval_seconds` |
  | `EXOCOMP_MISSION_CONTROL_MIN_BACKOFF` | `mission_control.reconnect_min_backoff_seconds` |
  | `EXOCOMP_MISSION_CONTROL_MAX_BACKOFF` | `mission_control.reconnect_max_backoff_seconds` |
  | `EXOCOMP_MISSION_CONTROL_OUTBOX_PATH` | `mission_control.outbox_path`           |
  """

  require Logger

  @default_config_path "/etc/exocomp/coordinator.json"
  @supported_version 1

  defmodule TLS do
    @moduledoc "TLS certificate and key paths for the coordinator."
    @enforce_keys [:ca_cert, :coord_cert, :coord_key]
    defstruct [:ca_cert, :coord_cert, :coord_key]

    @type t :: %__MODULE__{
            ca_cert: String.t(),
            coord_cert: String.t(),
            coord_key: String.t()
          }
  end

  defmodule Listen do
    @moduledoc "Network interface the coordinator listens on."
    @enforce_keys [:host, :port]
    defstruct [:host, :port]

    @type t :: %__MODULE__{
            host: String.t(),
            port: pos_integer()
          }
  end

  defmodule MissionControl do
    @moduledoc "Mission Control client configuration (optional)."
    @enforce_keys [:enabled]
    defstruct [
      :enabled,
      :url,
      :trust_root,
      :client_cert,
      :client_key,
      :heartbeat_interval_seconds,
      :reconnect_min_backoff_seconds,
      :reconnect_max_backoff_seconds,
      :outbox_path
    ]

    @type t :: %__MODULE__{
            enabled: boolean(),
            url: String.t() | nil,
            trust_root: String.t() | nil,
            client_cert: String.t() | nil,
            client_key: String.t() | nil,
            heartbeat_interval_seconds: pos_integer() | nil,
            reconnect_min_backoff_seconds: pos_integer() | nil,
            reconnect_max_backoff_seconds: pos_integer() | nil,
            outbox_path: String.t() | nil
          }
  end

  @enforce_keys [:version, :coordinator_id, :tls, :listen]
  defstruct [:version, :coordinator_id, :tls, :listen, :mission_control]

  @type t :: %__MODULE__{
          version: pos_integer(),
          coordinator_id: String.t(),
          tls: TLS.t(),
          listen: Listen.t(),
          mission_control: MissionControl.t() | nil
        }

  # ── Public API ───────────────────────────────────────────────────────────────

  @doc """
  Loads configuration from `path`, or from the environment, or from the default.

  Returns `{:ok, %Config{}}` on success.

  Error returns:
  - `{:error, :enoent}` — file not found
  - `{:error, {:file_read, reason}}` — I/O error other than missing file
  - `{:error, {:json_parse, reason}}` — file is not valid JSON
  - `{:error, {:unsupported_version, version}}` — unsupported config version
  - `{:error, {:missing_fields, [field_path]}}` — one or more required fields absent
  - `{:error, {:type_errors, [field_path]}}` — one or more fields have wrong types
  """
  @spec load(String.t() | nil) :: {:ok, t()} | {:error, term()}
  def load(path \\ nil) do
    resolved = resolve_path(path)

    with {:ok, raw} <- read_file(resolved),
         {:ok, parsed} <- parse_json(raw),
         :ok <- check_version(parsed),
         parsed <- apply_env_overrides(parsed),
         :ok <- validate_required_fields(parsed),
         :ok <- validate_field_types(parsed) do
      {:ok, to_struct(parsed)}
    end
  end

  # ── Path resolution ──────────────────────────────────────────────────────────

  defp resolve_path(nil) do
    System.get_env("EXOCOMP_COORDINATOR_CONFIG_FILE") || @default_config_path
  end

  defp resolve_path(path), do: path

  # ── File I/O ─────────────────────────────────────────────────────────────────

  defp read_file(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, :enoent} -> {:error, :enoent}
      {:error, reason} -> {:error, {:file_read, reason}}
    end
  end

  # ── JSON parsing ─────────────────────────────────────────────────────────────

  defp parse_json(raw) do
    case Jason.decode(raw) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, reason} -> {:error, {:json_parse, reason}}
    end
  end

  # ── Version check ────────────────────────────────────────────────────────────

  defp check_version(%{"version" => @supported_version}), do: :ok
  defp check_version(%{"version" => v}), do: {:error, {:unsupported_version, v}}
  defp check_version(_), do: {:error, {:missing_fields, ["version"]}}

  # ── Environment overrides ────────────────────────────────────────────────────

  defp apply_env_overrides(parsed) do
    parsed
    |> env_override_top("coordinator_id", "EXOCOMP_COORDINATOR_ID")
    |> env_override_listen_host()
    |> env_override_listen_port()
    |> env_override_tls("coord_cert", "EXOCOMP_TLS_CERT_PATH")
    |> env_override_tls("coord_key", "EXOCOMP_TLS_KEY_PATH")
    |> env_override_tls("ca_cert", "EXOCOMP_TLS_CA_PATH")
    |> env_override_mission_control_enabled()
    |> env_override_mission_control("url", "EXOCOMP_MISSION_CONTROL_URL")
    |> env_override_mission_control("trust_root", "EXOCOMP_MISSION_CONTROL_TRUST_ROOT")
    |> env_override_mission_control("client_cert", "EXOCOMP_MISSION_CONTROL_CLIENT_CERT")
    |> env_override_mission_control("client_key", "EXOCOMP_MISSION_CONTROL_CLIENT_KEY")
    |> env_override_mission_control_int(
      "heartbeat_interval_seconds",
      "EXOCOMP_MISSION_CONTROL_HEARTBEAT"
    )
    |> env_override_mission_control_int(
      "reconnect_min_backoff_seconds",
      "EXOCOMP_MISSION_CONTROL_MIN_BACKOFF"
    )
    |> env_override_mission_control_int(
      "reconnect_max_backoff_seconds",
      "EXOCOMP_MISSION_CONTROL_MAX_BACKOFF"
    )
    |> env_override_mission_control("outbox_path", "EXOCOMP_MISSION_CONTROL_OUTBOX_PATH")
  end

  defp env_override_mission_control_enabled(parsed) do
    case System.get_env("EXOCOMP_MISSION_CONTROL_ENABLED") do
      nil ->
        parsed

      raw ->
        enabled =
          case String.downcase(raw) do
            val when val in ["true", "1", "yes"] -> true
            val when val in ["false", "0", "no"] -> false
            _ -> false
          end

        Map.update(
          parsed,
          "mission_control",
          %{"enabled" => enabled},
          &Map.put(&1, "enabled", enabled)
        )
    end
  end

  defp env_override_mission_control(parsed, mc_key, env_var) do
    case System.get_env(env_var) do
      nil ->
        parsed

      value ->
        Map.update(parsed, "mission_control", %{mc_key => value}, &Map.put(&1, mc_key, value))
    end
  end

  defp env_override_mission_control_int(parsed, mc_key, env_var) do
    case System.get_env(env_var) do
      nil ->
        parsed

      raw ->
        case Integer.parse(raw) do
          {value, ""} ->
            Map.update(parsed, "mission_control", %{mc_key => value}, &Map.put(&1, mc_key, value))

          _ ->
            Logger.warning("#{env_var} #{inspect(raw)} is not a valid integer, ignoring override")

            parsed
        end
    end
  end

  defp env_override_top(parsed, field, env_var) do
    case System.get_env(env_var) do
      nil -> parsed
      value -> Map.put(parsed, field, value)
    end
  end

  defp env_override_listen_host(parsed) do
    case System.get_env("EXOCOMP_LISTEN_ADDRESS") do
      nil -> parsed
      value -> Map.update(parsed, "listen", %{"host" => value}, &Map.put(&1, "host", value))
    end
  end

  defp env_override_listen_port(parsed) do
    case System.get_env("EXOCOMP_LISTEN_PORT") do
      nil ->
        parsed

      raw ->
        case Integer.parse(raw) do
          {port, ""} ->
            Map.update(parsed, "listen", %{"port" => port}, &Map.put(&1, "port", port))

          _ ->
            Logger.warning(
              "EXOCOMP_LISTEN_PORT #{inspect(raw)} is not a valid integer, ignoring override"
            )

            parsed
        end
    end
  end

  defp env_override_tls(parsed, tls_key, env_var) do
    case System.get_env(env_var) do
      nil ->
        parsed

      value ->
        Map.update(parsed, "tls", %{tls_key => value}, &Map.put(&1, tls_key, value))
    end
  end

  # ── Validation: required fields ──────────────────────────────────────────────

  @required_top_fields ["coordinator_id", "tls", "listen"]
  @required_tls_fields ["ca_cert", "coord_cert", "coord_key"]
  @required_listen_fields ["host", "port"]
  @required_mission_control_fields [
    "url",
    "trust_root",
    "client_cert",
    "client_key",
    "heartbeat_interval_seconds",
    "reconnect_min_backoff_seconds",
    "reconnect_max_backoff_seconds",
    "outbox_path"
  ]

  defp validate_required_fields(parsed) do
    missing = collect_missing(parsed)

    if missing == [] do
      :ok
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp collect_missing(parsed) do
    top_missing = Enum.reject(@required_top_fields, &Map.has_key?(parsed, &1))

    tls_missing =
      case parsed["tls"] do
        nil ->
          []

        tls ->
          @required_tls_fields
          |> Enum.reject(&Map.has_key?(tls, &1))
          |> Enum.map(&"tls.#{&1}")
      end

    listen_missing =
      case parsed["listen"] do
        nil ->
          []

        listen ->
          @required_listen_fields
          |> Enum.reject(&Map.has_key?(listen, &1))
          |> Enum.map(&"listen.#{&1}")
      end

    mission_control_missing =
      case parsed["mission_control"] do
        nil ->
          []

        mc ->
          if Map.get(mc, "enabled") == true do
            @required_mission_control_fields
            |> Enum.reject(&Map.has_key?(mc, &1))
            |> Enum.map(&"mission_control.#{&1}")
          else
            []
          end
      end

    top_missing ++ tls_missing ++ listen_missing ++ mission_control_missing
  end

  # ── Validation: field types ──────────────────────────────────────────────────

  defp validate_field_types(parsed) do
    errors =
      []
      |> check_type(parsed, "coordinator_id", &is_binary/1, "string")
      |> check_nested_type(parsed["tls"], "tls.ca_cert", "ca_cert", &is_binary/1, "string")
      |> check_nested_type(parsed["tls"], "tls.coord_cert", "coord_cert", &is_binary/1, "string")
      |> check_nested_type(parsed["tls"], "tls.coord_key", "coord_key", &is_binary/1, "string")
      |> check_nested_type(parsed["listen"], "listen.host", "host", &is_binary/1, "string")
      |> check_nested_type(parsed["listen"], "listen.port", "port", &is_integer/1, "integer")
      |> validate_mission_control_types(parsed["mission_control"], parsed)

    if errors == [] do
      :ok
    else
      {:error, {:type_errors, errors}}
    end
  end

  defp check_type(errors, map, field, type_check, expected_type) do
    value = Map.get(map, field)

    if value != nil and not type_check.(value) do
      Logger.warning("Config field #{inspect(field)} expected #{expected_type}")
      [field | errors]
    else
      errors
    end
  end

  defp check_nested_type(errors, nil, _label, _key, _type_check, _expected_type), do: errors

  defp check_nested_type(errors, nested_map, label, key, type_check, expected_type) do
    value = Map.get(nested_map, key)

    if value != nil and not type_check.(value) do
      Logger.warning("Config field #{inspect(label)} expected #{expected_type}")
      [label | errors]
    else
      errors
    end
  end

  # ── Validation: Mission Control types and values ──────────────────────────

  defp validate_mission_control_types(errors, nil, _parsed), do: errors

  defp validate_mission_control_types(errors, mc, _parsed) when is_map(mc) do
    if Map.get(mc, "enabled") == true do
      errors
      |> check_nested_type(mc, "mission_control.url", "url", &is_binary/1, "string")
      |> check_nested_type(mc, "mission_control.trust_root", "trust_root", &is_binary/1, "string")
      |> check_nested_type(
        mc,
        "mission_control.client_cert",
        "client_cert",
        &is_binary/1,
        "string"
      )
      |> check_nested_type(mc, "mission_control.client_key", "client_key", &is_binary/1, "string")
      |> check_nested_type(
        mc,
        "mission_control.heartbeat_interval_seconds",
        "heartbeat_interval_seconds",
        &is_integer/1,
        "integer"
      )
      |> check_nested_type(
        mc,
        "mission_control.reconnect_min_backoff_seconds",
        "reconnect_min_backoff_seconds",
        &is_integer/1,
        "integer"
      )
      |> check_nested_type(
        mc,
        "mission_control.reconnect_max_backoff_seconds",
        "reconnect_max_backoff_seconds",
        &is_integer/1,
        "integer"
      )
      |> check_nested_type(
        mc,
        "mission_control.outbox_path",
        "outbox_path",
        &is_binary/1,
        "string"
      )
      |> validate_mission_control_values(mc)
    else
      errors
    end
  end

  defp validate_mission_control_types(errors, _mc, _parsed), do: errors

  # ── Validation: Mission Control value constraints ───────────────────────────

  defp validate_mission_control_values(errors, mc) do
    errors
    |> validate_numeric_bound(mc, "heartbeat_interval_seconds", 1, nil)
    |> validate_numeric_bound(mc, "reconnect_min_backoff_seconds", 1, nil)
    |> validate_numeric_bound(mc, "reconnect_max_backoff_seconds", 1, nil)
    |> validate_backoff_bounds(mc)
    |> validate_mission_control_paths(mc)
  end

  defp validate_numeric_bound(errors, mc, field, min, max) do
    case Map.get(mc, field) do
      nil ->
        errors

      value when is_integer(value) ->
        cond do
          min && value < min ->
            Logger.warning(
              "Config field mission_control.#{field} must be >= #{min}, got #{value}"
            )

            ["mission_control.#{field}" | errors]

          max && value > max ->
            Logger.warning(
              "Config field mission_control.#{field} must be <= #{max}, got #{value}"
            )

            ["mission_control.#{field}" | errors]

          true ->
            errors
        end

      _ ->
        errors
    end
  end

  defp validate_backoff_bounds(errors, mc) do
    min = Map.get(mc, "reconnect_min_backoff_seconds")
    max = Map.get(mc, "reconnect_max_backoff_seconds")

    if is_integer(min) && is_integer(max) && max < min do
      Logger.warning(
        "Config field mission_control.reconnect_max_backoff_seconds (#{max}) must be >= " <>
          "reconnect_min_backoff_seconds (#{min})"
      )

      ["mission_control.reconnect_max_backoff_seconds" | errors]
    else
      errors
    end
  end

  defp validate_mission_control_paths(errors, mc) do
    errors
    |> validate_file_readable(mc, "trust_root")
    |> validate_file_readable(mc, "client_cert")
    |> validate_file_readable(mc, "client_key")
    |> validate_outbox_path_writable(mc, "outbox_path")
  end

  defp validate_file_readable(errors, mc, field) do
    case Map.get(mc, field) do
      nil ->
        errors

      path when is_binary(path) ->
        case File.exists?(path) do
          true ->
            errors

          false ->
            Logger.warning(
              "Config field mission_control.#{field} points to non-existent file: #{path}"
            )

            ["mission_control.#{field}" | errors]
        end

      _ ->
        errors
    end
  end

  defp validate_outbox_path_writable(errors, mc, field) do
    case Map.get(mc, field) do
      nil ->
        errors

      path when is_binary(path) ->
        case File.exists?(path) do
          true ->
            case File.dir?(path) do
              true ->
                errors

              false ->
                Logger.warning(
                  "Config field mission_control.#{field} must be a directory: #{path}"
                )

                ["mission_control.#{field}" | errors]
            end

          false ->
            # Try to create the directory
            case File.mkdir_p(path) do
              :ok ->
                errors

              {:error, reason} ->
                Logger.warning(
                  "Config field mission_control.#{field} cannot be created: #{path} (#{inspect(reason)})"
                )

                ["mission_control.#{field}" | errors]
            end
        end

      _ ->
        errors
    end
  end

  # ── Struct construction ──────────────────────────────────────────────────────

  defp to_struct(
         %{
           "version" => version,
           "coordinator_id" => coordinator_id,
           "tls" => tls,
           "listen" => listen
         } = parsed
       ) do
    %__MODULE__{
      version: version,
      coordinator_id: coordinator_id,
      tls: %TLS{
        ca_cert: tls["ca_cert"],
        coord_cert: tls["coord_cert"],
        coord_key: tls["coord_key"]
      },
      listen: %Listen{
        host: listen["host"],
        port: listen["port"]
      },
      mission_control: build_mission_control(parsed["mission_control"])
    }
  end

  # Build the mission_control config, returning nil if not present or disabled.
  defp build_mission_control(nil), do: nil

  defp build_mission_control(mc) when is_map(mc) do
    enabled = Map.get(mc, "enabled", false)

    if enabled do
      %MissionControl{
        enabled: true,
        url: mc["url"],
        trust_root: mc["trust_root"],
        client_cert: mc["client_cert"],
        client_key: mc["client_key"],
        heartbeat_interval_seconds: mc["heartbeat_interval_seconds"],
        reconnect_min_backoff_seconds: mc["reconnect_min_backoff_seconds"],
        reconnect_max_backoff_seconds: mc["reconnect_max_backoff_seconds"],
        outbox_path: mc["outbox_path"]
      }
    else
      # Mission Control is disabled; return nil
      nil
    end
  end

  defp build_mission_control(_), do: nil
end
