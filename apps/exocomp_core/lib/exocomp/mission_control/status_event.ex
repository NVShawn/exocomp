# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.StatusEvent do
  @moduledoc """
  Versioned, bounded status events shared by coordinators and Mission Control.

  The envelope is intentionally small and strict.  A status event is an
  observation of the coordinator's local desired-state view; it is not a
  command and it never grants Mission Control recovery authority.

  `desired_state.*` and `service_status.changed` events carry one service
  record.  `service_summary.snapshot` carries a complete list of service
  records and is the replay base after a reconnect.  Every service record
  includes source coverage, health depth, recovery authority, observation
  time, and bounded evidence references.
  """

  @enforce_keys [
    :schema_version,
    :event_id,
    :cluster_seq,
    :kind,
    :occurred_at,
    :correlation_id,
    :payload
  ]
  defstruct schema_version: nil,
            event_id: nil,
            cluster_seq: nil,
            kind: nil,
            occurred_at: nil,
            correlation_id: nil,
            payload: nil

  @schema_version 1
  @max_event_bytes 64 * 1024
  @max_payload_bytes 48 * 1024
  @max_string_length 256
  @max_evidence_refs 32
  @max_services 1_000
  @redacted "[REDACTED]"

  @kinds [
    "desired_state.added",
    "desired_state.changed",
    "desired_state.removed",
    "service_status.changed",
    "service_summary.snapshot"
  ]

  @sources ["automatic", "cluster_profile", "manual"]
  @health_depths ["none", "systemd", "probe", "deep"]
  @recovery_authorities ["none", "manual_allow_list", "shipped_profile"]

  @common_fields [
    "node_id",
    "unit",
    "source_set",
    "health_depth",
    "recovery_authority",
    "profile_context",
    "observed_at",
    "evidence_refs"
  ]

  @type t :: %__MODULE__{
          schema_version: pos_integer(),
          event_id: String.t(),
          cluster_seq: non_neg_integer(),
          kind: String.t(),
          occurred_at: String.t(),
          correlation_id: String.t(),
          payload: map()
        }

  @type decode_error ::
          :invalid_status_event
          | {:missing_field, String.t()}
          | {:unknown_field, String.t()}
          | {:invalid_field, String.t(), term()}
          | {:unsupported_schema_version, term()}
          | {:payload_too_large, non_neg_integer()}
          | {:event_too_large, non_neg_integer()}

  @doc "Returns the status-event schema version understood by this release."
  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @doc "Compatibility alias for protocol implementations using current_*."
  @spec current_schema_version() :: pos_integer()
  def current_schema_version, do: schema_version()

  @doc "Returns the bounded status-event vocabulary."
  @spec kinds() :: [String.t()]
  def kinds, do: @kinds

  @doc "Compatibility alias for protocol implementations using valid_kinds/0."
  @spec valid_kinds() :: [String.t()]
  def valid_kinds, do: kinds()

  @doc "Returns the maximum encoded event size in bytes."
  @spec max_event_bytes() :: pos_integer()
  def max_event_bytes, do: @max_event_bytes

  @doc "Build and validate a status event from a JSON-compatible map."
  @spec new(map(), keyword()) :: {:ok, t()} | {:error, decode_error()}
  def new(attrs, opts \\ [])

  def new(attrs, opts) when is_map(attrs) do
    attrs = attrs |> canonicalize_map() |> redact()
    supported_version = Keyword.get(opts, :schema_version, @schema_version)
    max_event_bytes = Keyword.get(opts, :max_event_bytes, @max_event_bytes)

    with :ok <- exact_fields(attrs, envelope_fields()),
         {:ok, version} <- required(attrs, "schema_version"),
         :ok <- validate_version(version, supported_version),
         {:ok, event_id} <- bounded_string(attrs, "event_id"),
         {:ok, cluster_seq} <- nonnegative_integer(attrs, "cluster_seq"),
         {:ok, kind} <- kind(attrs),
         {:ok, occurred_at} <- timestamp(attrs, "occurred_at"),
         {:ok, correlation_id} <- bounded_string(attrs, "correlation_id"),
         {:ok, payload} <- required_map(attrs, "payload"),
         {:ok, payload} <- validate_payload(kind, payload),
         :ok <- validate_payload_size(payload),
         event = %__MODULE__{
           schema_version: version,
           event_id: event_id,
           cluster_seq: cluster_seq,
           kind: kind,
           occurred_at: occurred_at,
           correlation_id: correlation_id,
           payload: payload
         },
         :ok <- validate_encoded_size(event, max_event_bytes) do
      {:ok, event}
    end
  end

  def new(_attrs, _opts), do: {:error, :invalid_status_event}

  @doc "Alias for `new/2` for decoders that use validate terminology."
  @spec validate(map(), keyword()) :: {:ok, t()} | {:error, decode_error()}
  def validate(attrs, opts \\ []), do: new(attrs, opts)

  @doc "Encode a validated event as a JSON-compatible map with string keys."
  @spec encode(t()) :: map()
  def encode(%__MODULE__{} = event) do
    %{
      "schema_version" => event.schema_version,
      "event_id" => event.event_id,
      "cluster_seq" => event.cluster_seq,
      "kind" => event.kind,
      "occurred_at" => event.occurred_at,
      "correlation_id" => event.correlation_id,
      "payload" => redact(event.payload)
    }
  end

  @doc "Encode a validated event to JSON after applying recursive redaction."
  @spec encode_json(t()) :: {:ok, binary()} | {:error, term()}
  def encode_json(%__MODULE__{} = event), do: Jason.encode(encode(event))

  @doc "Decode a JSON-compatible map into a validated status event."
  @spec decode(term(), keyword()) :: {:ok, t()} | {:error, decode_error()}
  def decode(attrs, opts \\ [])

  def decode(attrs, opts) when is_map(attrs), do: new(attrs, opts)
  def decode(_attrs, _opts), do: {:error, :invalid_status_event}

  @doc "Decode a JSON status event."
  @spec decode_json(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def decode_json(json, opts \\ []) when is_binary(json) do
    with {:ok, attrs} <- Jason.decode(json) do
      decode(attrs, opts)
    end
  end

  @doc "Recursively replace values under sensitive keys before transport."
  @spec redact(term()) :: term()
  def redact(value), do: redact_value(value)

  @doc "Build a desired-state event from a common service record."
  @spec desired_state(String.t(), map(), map(), keyword()) ::
          {:ok, t()} | {:error, decode_error()}
  def desired_state(kind, service, envelope, opts \\ [])
      when kind in ["desired_state.added", "desired_state.changed", "desired_state.removed"] do
    new(Map.merge(envelope, %{"kind" => kind, "payload" => service}), opts)
  end

  @doc "Build a service-status delta from a common service record."
  @spec service_status(map(), map(), keyword()) :: {:ok, t()} | {:error, decode_error()}
  def service_status(service, envelope, opts \\ []) do
    new(Map.merge(envelope, %{"kind" => "service_status.changed", "payload" => service}), opts)
  end

  @doc "Build a complete periodic service-summary snapshot."
  @spec service_summary([map()], map(), keyword()) :: {:ok, t()} | {:error, decode_error()}
  def service_summary(services, envelope, opts \\ []) when is_list(services) do
    payload = %{
      "snapshot_id" => Map.get(envelope, "event_id", Map.get(envelope, :event_id)),
      "observed_at" => Map.get(envelope, "occurred_at", Map.get(envelope, :occurred_at)),
      "evidence_refs" => [],
      "services" => services
    }

    new(Map.merge(envelope, %{"kind" => "service_summary.snapshot", "payload" => payload}), opts)
  end

  defp envelope_fields,
    do: [
      "schema_version",
      "event_id",
      "cluster_seq",
      "kind",
      "occurred_at",
      "correlation_id",
      "payload"
    ]

  defp validate_payload("service_summary.snapshot", payload) do
    with :ok <-
           exact_fields(payload, ["snapshot_id", "observed_at", "evidence_refs", "services"]),
         {:ok, _snapshot_id} <- bounded_string(payload, "snapshot_id"),
         {:ok, _observed_at} <- timestamp(payload, "observed_at"),
         {:ok, _evidence_refs} <- evidence_refs(payload, "evidence_refs"),
         {:ok, services} <- bounded_list(payload, "services", @max_services),
         {:ok, services} <- validate_services(services) do
      {:ok, Map.put(payload, "services", services)}
    end
  end

  defp validate_payload(kind, payload)
       when kind in ["desired_state.added", "desired_state.changed", "desired_state.removed"] do
    with :ok <- exact_fields(payload, @common_fields ++ ["desired_state", "expected_state"]),
         {:ok, payload} <- validate_common(payload),
         {:ok, desired_state} <-
           enum(payload, "desired_state", ["running", "stopped", "present", "absent"]),
         {:ok, expected_state} <-
           enum(payload, "expected_state", ["running", "stopped", "present", "absent"]) do
      {:ok,
       Map.merge(payload, %{"desired_state" => desired_state, "expected_state" => expected_state})}
    end
  end

  defp validate_payload("service_status.changed", payload) do
    fields =
      @common_fields ++
        [
          "health_state",
          "systemd_state",
          "health_reason",
          "candidate_state",
          "consecutive_observations"
        ]

    with :ok <- exact_fields(payload, fields),
         {:ok, payload} <- validate_common(payload),
         {:ok, health_state} <-
           enum(payload, "health_state", [
             "unknown",
             "healthy",
             "degraded",
             "unhealthy",
             "stale",
             "unreachable",
             "retired"
           ]),
         {:ok, systemd_state} <-
           nullable_enum(payload, "systemd_state", ["active", "inactive", "failed", "unknown"]),
         {:ok, health_reason} <- nullable_string(payload, "health_reason"),
         {:ok, candidate_state} <-
           nullable_enum(payload, "candidate_state", ["healthy", "unhealthy"]),
         {:ok, consecutive} <- nonnegative_integer(payload, "consecutive_observations") do
      {:ok,
       Map.merge(payload, %{
         "health_state" => health_state,
         "systemd_state" => systemd_state,
         "health_reason" => health_reason,
         "candidate_state" => candidate_state,
         "consecutive_observations" => consecutive
       })}
    end
  end

  defp validate_payload(_kind, _payload), do: {:error, {:invalid_field, "kind", :unsupported}}

  defp validate_payload_size(payload) do
    case Jason.encode(payload) do
      {:ok, encoded} when byte_size(encoded) <= @max_payload_bytes -> :ok
      {:ok, encoded} -> {:error, {:payload_too_large, byte_size(encoded)}}
      {:error, _} -> {:error, :invalid_status_event}
    end
  end

  defp validate_services(services) do
    services
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {service, index}, {:ok, acc} ->
      case validate_service(service) do
        {:ok, service} ->
          {:cont, {:ok, [service | acc]}}

        {:error, {:invalid_field, field, reason}} ->
          {:halt, {:error, {:invalid_field, "services[#{index}].#{field}", reason}}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, services} -> {:ok, Enum.reverse(services)}
      error -> error
    end
  end

  defp validate_service(service) when is_map(service) do
    service = canonicalize_map(service) |> redact()

    fields =
      @common_fields ++
        [
          "health_state",
          "systemd_state",
          "health_reason",
          "candidate_state",
          "consecutive_observations",
          "desired_state",
          "expected_state"
        ]

    with :ok <- exact_fields(service, fields),
         {:ok, service} <- validate_common(service),
         {:ok, health_state} <-
           enum(service, "health_state", [
             "unknown",
             "healthy",
             "degraded",
             "unhealthy",
             "stale",
             "unreachable",
             "retired"
           ]),
         {:ok, systemd_state} <-
           nullable_enum(service, "systemd_state", ["active", "inactive", "failed", "unknown"]),
         {:ok, health_reason} <- nullable_string(service, "health_reason"),
         {:ok, candidate_state} <-
           nullable_enum(service, "candidate_state", ["healthy", "unhealthy"]),
         {:ok, consecutive} <- nonnegative_integer(service, "consecutive_observations"),
         {:ok, desired_state} <-
           nullable_enum(service, "desired_state", ["running", "stopped", "present", "absent"]),
         {:ok, expected_state} <-
           nullable_enum(service, "expected_state", ["running", "stopped", "present", "absent"]) do
      {:ok,
       Map.merge(service, %{
         "health_state" => health_state,
         "systemd_state" => systemd_state,
         "health_reason" => health_reason,
         "candidate_state" => candidate_state,
         "consecutive_observations" => consecutive,
         "desired_state" => desired_state,
         "expected_state" => expected_state
       })}
    end
  end

  defp validate_service(_service), do: {:error, {:invalid_field, "service", :not_a_map}}

  defp validate_common(payload) do
    with {:ok, _node_id} <- bounded_string(payload, "node_id"),
         {:ok, _unit} <- bounded_string(payload, "unit"),
         {:ok, sources} <- source_set(payload, "source_set"),
         {:ok, health_depth} <- enum(payload, "health_depth", @health_depths),
         {:ok, recovery_authority} <- enum(payload, "recovery_authority", @recovery_authorities),
         {:ok, profile_context} <- nullable_string(payload, "profile_context"),
         {:ok, _observed_at} <- timestamp(payload, "observed_at"),
         {:ok, _evidence_refs} <- evidence_refs(payload, "evidence_refs"),
         :ok <- validate_profile_context(sources, profile_context) do
      {:ok,
       Map.merge(payload, %{
         "source_set" => sources,
         "health_depth" => health_depth,
         "recovery_authority" => recovery_authority,
         "profile_context" => profile_context
       })}
    end
  end

  defp validate_profile_context(sources, nil) do
    if "cluster_profile" in sources,
      do: {:error, {:invalid_field, "profile_context", :required_for_cluster_profile}},
      else: :ok
  end

  defp validate_profile_context(_sources, _profile_context), do: :ok

  defp exact_fields(map, expected) do
    actual = Map.keys(map)
    unknown = actual -- expected
    missing = expected -- actual

    cond do
      unknown != [] -> {:error, {:unknown_field, hd(unknown)}}
      missing != [] -> {:error, {:missing_field, hd(missing)}}
      true -> :ok
    end
  end

  defp required(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp bounded_string(map, key) do
    with {:ok, value} <- required(map, key),
         true <- is_binary(value),
         true <- String.trim(value) != "",
         true <- String.length(value) <= @max_string_length do
      {:ok, value}
    else
      _ -> {:error, {:invalid_field, key, :bounded_string}}
    end
  end

  defp nullable_string(map, key) do
    case required(map, key) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, _value} ->
        case bounded_string(map, key) do
          {:ok, string} -> {:ok, string}
          {:error, _} -> {:error, {:invalid_field, key, :nullable_string}}
        end

      {:error, _} = error ->
        error
    end
  end

  defp nonnegative_integer(map, key) do
    case required(map, key) do
      {:ok, value} when is_integer(value) and value >= 0 -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key, :nonnegative_integer}}
      {:error, _} = error -> error
    end
  end

  defp required_map(map, key) do
    case required(map, key) do
      {:ok, value} when is_map(value) -> {:ok, canonicalize_map(value) |> redact()}
      {:ok, _value} -> {:error, {:invalid_field, key, :map}}
      {:error, _} = error -> error
    end
  end

  defp bounded_list(map, key, max) do
    case required(map, key) do
      {:ok, value} when is_list(value) and length(value) <= max -> {:ok, value}
      {:ok, value} when is_list(value) -> {:error, {:invalid_field, key, {:too_many, max}}}
      {:ok, _value} -> {:error, {:invalid_field, key, :list}}
      {:error, _} = error -> error
    end
  end

  defp source_set(map, key) do
    with {:ok, values} <- bounded_list(map, key, length(@sources)),
         true <- values != [],
         true <- Enum.all?(values, &is_binary/1),
         true <- Enum.all?(values, &(&1 in @sources)),
         true <- length(Enum.uniq(values)) == length(values) do
      {:ok, Enum.sort(values)}
    else
      {:error, _} = error -> error
      _ -> {:error, {:invalid_field, key, :source_set}}
    end
  end

  defp evidence_refs(map, key) do
    with {:ok, refs} <- bounded_list(map, key, @max_evidence_refs),
         true <-
           Enum.all?(
             refs,
             &(is_binary(&1) and String.trim(&1) != "" and String.length(&1) <= @max_string_length)
           ),
         true <- length(Enum.uniq(refs)) == length(refs) do
      {:ok, refs}
    else
      {:error, _} = error -> error
      _ -> {:error, {:invalid_field, key, :evidence_refs}}
    end
  end

  defp enum(map, key, allowed) do
    with {:ok, value} <- required(map, key),
         true <- value in allowed do
      {:ok, value}
    else
      {:error, _} = error -> error
      _ -> {:error, {:invalid_field, key, {:enum, allowed}}}
    end
  end

  defp nullable_enum(map, key, allowed) do
    case required(map, key) do
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> enum(map, key, allowed)
      {:error, _} = error -> error
    end
  end

  defp timestamp(map, key) do
    with {:ok, value} <- bounded_string(map, key) do
      case DateTime.from_iso8601(value) do
        {:ok, _datetime, _offset} -> {:ok, value}
        {:error, _reason} -> {:error, {:invalid_field, key, :iso8601}}
      end
    end
  end

  defp kind(map, key \\ "kind") do
    case enum(map, key, @kinds) do
      {:ok, value} ->
        {:ok, value}

      {:error, {:invalid_field, ^key, {:enum, _allowed}}} ->
        {:error, {:invalid_field, key, :kind}}

      {:error, _} = error ->
        error
    end
  end

  defp validate_version(version, supported_version)
       when version == @schema_version and supported_version == @schema_version,
       do: :ok

  defp validate_version(version, _supported_version),
    do: {:error, {:unsupported_schema_version, version}}

  defp validate_encoded_size(event, max_event_bytes)
       when is_integer(max_event_bytes) and max_event_bytes > 0 do
    encoded = encode(event)

    case Jason.encode(encoded) do
      {:ok, json} when byte_size(json) <= max_event_bytes ->
        :ok

      {:ok, json} ->
        {:error, {:event_too_large, byte_size(json)}}

      {:error, _} ->
        {:error, :invalid_status_event}
    end
  end

  defp validate_encoded_size(_event, _max_event_bytes), do: {:error, :invalid_status_event}

  defp canonicalize_map(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      key = to_string(key)
      Map.put(acc, key, canonicalize(value))
    end)
  end

  defp canonicalize(value) when is_map(value), do: canonicalize_map(value)
  defp canonicalize(value) when is_list(value), do: Enum.map(value, &canonicalize/1)
  defp canonicalize(value), do: value

  defp redact_value(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      if sensitive_key?(key), do: {key, @redacted}, else: {key, redact_value(value)}
    end)
  end

  defp redact_value(list) when is_list(list), do: Enum.map(list, &redact_value/1)
  defp redact_value(value), do: value

  defp sensitive_key?(key) do
    normalized = key |> to_string() |> String.downcase() |> String.replace("-", "_")

    normalized in [
      "api_key",
      "authorization",
      "cookie",
      "credential",
      "credentials",
      "password",
      "passwd",
      "private_key",
      "secret",
      "token"
    ] or
      Enum.any?(
        [
          "api_key",
          "authorization",
          "cookie",
          "credential",
          "password",
          "private_key",
          "secret",
          "token"
        ],
        &String.ends_with?(normalized, "_" <> &1)
      )
  end
end
