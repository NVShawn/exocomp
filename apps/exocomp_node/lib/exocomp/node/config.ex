defmodule Exocomp.Node.Config do
  @moduledoc """
  Loads, validates, and exposes Exocomp node configuration from a versioned
  JSON file.

  ## Config file schema (version 1)

  ```json
  {
    "version": 1,
    "node_id": "exocomp-test-node",
    "tls": {
      "ca_cert":   "/path/to/ca.crt",
      "node_cert": "/path/to/node.crt",
      "node_key":  "/path/to/node.key"
    },
    "listen": {
      "host": "0.0.0.0",
      "port": 4433
    }
  }
  ```

  ## File resolution order

  `load/1` resolves the config path in this order:

  1. The `path` argument (when non-`nil`)
  2. The `EXOCOMP_CONFIG_FILE` environment variable
  3. The compiled-in default (`/etc/exocomp/config.json`)

  ## Environment overrides

  The following environment variables override values read from the file.
  They are applied *after* file load and *before* validation.

  | Variable                | Overrides       |
  |-------------------------|-----------------|
  | `EXOCOMP_NODE_ID`       | `node_id`       |
  | `EXOCOMP_LISTEN_ADDRESS`| `listen.host`   |
  | `EXOCOMP_LISTEN_PORT`   | `listen.port`   |
  | `EXOCOMP_TLS_CERT_PATH` | `tls.node_cert` |
  | `EXOCOMP_TLS_KEY_PATH`  | `tls.node_key`  |
  | `EXOCOMP_TLS_CA_PATH`   | `tls.ca_cert`   |

  ## Secret redaction

  Error messages and log output produced by this module never include the
  *value* of `tls.node_key`, `tls.node_cert`, or `tls.ca_cert`.  Only the
  field label is reported.  See `Exocomp.Node.Redact`.
  """

  require Logger

  alias Exocomp.Node.Redact

  @default_config_path "/etc/exocomp/config.json"
  @supported_version 1

  defmodule TLS do
    @moduledoc "TLS certificate and key paths for the node."
    @enforce_keys [:ca_cert, :node_cert, :node_key]
    defstruct [:ca_cert, :node_cert, :node_key]

    @type t :: %__MODULE__{
            ca_cert: String.t(),
            node_cert: String.t(),
            node_key: String.t()
          }
  end

  defmodule Listen do
    @moduledoc "Network interface the node listens on."
    @enforce_keys [:host, :port]
    defstruct [:host, :port]

    @type t :: %__MODULE__{
            host: String.t(),
            port: pos_integer()
          }
  end

  @enforce_keys [:version, :node_id, :tls, :listen]
  defstruct [:version, :node_id, :tls, :listen]

  @type t :: %__MODULE__{
          version: pos_integer(),
          node_id: String.t(),
          tls: TLS.t(),
          listen: Listen.t()
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
    System.get_env("EXOCOMP_CONFIG_FILE") || @default_config_path
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
    |> env_override_top("node_id", "EXOCOMP_NODE_ID")
    |> env_override_listen_host()
    |> env_override_listen_port()
    |> env_override_tls("node_cert", "EXOCOMP_TLS_CERT_PATH")
    |> env_override_tls("node_key", "EXOCOMP_TLS_KEY_PATH")
    |> env_override_tls("ca_cert", "EXOCOMP_TLS_CA_PATH")
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

  @required_top_fields ["node_id", "tls", "listen"]
  @required_tls_fields ["ca_cert", "node_cert", "node_key"]
  @required_listen_fields ["host", "port"]

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

    top_missing ++ tls_missing ++ listen_missing
  end

  # ── Validation: field types ──────────────────────────────────────────────────

  defp validate_field_types(parsed) do
    errors =
      []
      |> check_type(parsed, "node_id", &is_binary/1, "string")
      |> check_nested_type(parsed["tls"], "tls.ca_cert", "ca_cert", &is_binary/1, "string")
      |> check_nested_type(parsed["tls"], "tls.node_cert", "node_cert", &is_binary/1, "string")
      |> check_nested_type(parsed["tls"], "tls.node_key", "node_key", &is_binary/1, "string")
      |> check_nested_type(parsed["listen"], "listen.host", "host", &is_binary/1, "string")
      |> check_nested_type(parsed["listen"], "listen.port", "port", &is_integer/1, "integer")

    if errors == [] do
      :ok
    else
      {:error, {:type_errors, errors}}
    end
  end

  defp check_type(errors, map, field, type_check, expected_type) do
    value = Map.get(map, field)

    if value != nil and not type_check.(value) do
      # Never include the value itself — it may be sensitive.
      # Use Redact to ensure we only emit the field label.
      label = field
      _ = Redact.sensitive?(label)
      Logger.warning("Config field #{inspect(label)} expected #{expected_type}")
      [label | errors]
    else
      errors
    end
  end

  defp check_nested_type(errors, nil, _label, _key, _type_check, _expected_type), do: errors

  defp check_nested_type(errors, nested_map, label, key, type_check, expected_type) do
    value = Map.get(nested_map, key)

    if value != nil and not type_check.(value) do
      # Use Redact to guarantee sensitive field labels do not leak their values.
      _ = Redact.redact_value(label, value)
      Logger.warning("Config field #{inspect(label)} expected #{expected_type}")
      [label | errors]
    else
      errors
    end
  end

  # ── Struct construction ──────────────────────────────────────────────────────

  defp to_struct(%{
         "version" => version,
         "node_id" => node_id,
         "tls" => tls,
         "listen" => listen
       }) do
    %__MODULE__{
      version: version,
      node_id: node_id,
      tls: %TLS{
        ca_cert: tls["ca_cert"],
        node_cert: tls["node_cert"],
        node_key: tls["node_key"]
      },
      listen: %Listen{
        host: listen["host"],
        port: listen["port"]
      }
    }
  end
end
