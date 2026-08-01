# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Metrics do
  @moduledoc """
  Stable, low-cardinality Prometheus metric registry for Mission Control.

  The registry intentionally accepts only the schema below. In particular,
  cluster, node, organization, URL, session, and event identifiers can never
  become label values.
  """

  use GenServer

  @type labels :: %{optional(String.t() | atom()) => String.t() | atom()}

  @definitions [
    %{
      name: "exocomp_mission_control_connections",
      type: :gauge,
      help: "Current cluster connections by state.",
      labels: ["state"],
      values: %{state: ["connected", "disconnected"]}
    },
    %{
      name: "exocomp_mission_control_events_ingested_total",
      type: :counter,
      help: "Cluster events processed by outcome.",
      labels: ["outcome"],
      values: %{outcome: ["accepted", "duplicate", "sequence_gap", "rejected"]}
    },
    %{
      name: "exocomp_mission_control_event_ingest_lag_seconds",
      type: :histogram,
      help: "Age of accepted cluster events at ingest.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_incidents_open",
      type: :gauge,
      help: "Open incidents by severity.",
      labels: ["severity"],
      values: %{severity: ["info", "warning", "critical"]}
    },
    %{
      name: "exocomp_mission_control_conversation_latency_seconds",
      type: :histogram,
      help: "Conversation response latency.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_proposal_latency_seconds",
      type: :histogram,
      help: "Proposal creation latency.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_commands",
      type: :gauge,
      help: "Commands by lifecycle state.",
      labels: ["state"],
      values: %{state: ["pending", "expired", "failed"]}
    },
    %{
      name: "exocomp_mission_control_webhook_deliveries_total",
      type: :counter,
      help: "Webhook delivery attempts by outcome.",
      labels: ["outcome"],
      values: %{outcome: ["success", "retry", "terminal_failure"]}
    },
    %{
      name: "exocomp_mission_control_database_pool_size",
      type: :gauge,
      help: "Configured database pool size.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_database_pool_available",
      type: :gauge,
      help: "Available database connections.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_database_queue_length",
      type: :gauge,
      help: "Database checkout queue length.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_retention_job_status",
      type: :gauge,
      help: "Retention job status (idle, running, or failed).",
      labels: ["status"],
      values: %{status: ["idle", "running", "failed"]}
    },
    %{
      name: "exocomp_mission_control_services",
      type: :gauge,
      help: "Current desired-service counts by health state.",
      labels: ["state"],
      values: %{state: ["healthy", "unhealthy", "stale", "retired"]}
    },
    %{
      name: "exocomp_mission_control_service_transitions_total",
      type: :counter,
      help: "Desired-service health transitions.",
      labels: ["from", "to"],
      values: %{
        from: ["healthy", "unhealthy", "stale", "retired"],
        to: ["healthy", "unhealthy", "stale", "retired"]
      }
    },
    %{
      name: "exocomp_mission_control_discovery_failures_total",
      type: :counter,
      help: "Automatic desired-service discovery failures.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_profile_coverage",
      type: :gauge,
      help: "Profile coverage ratio for observed services.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_ceph_health",
      type: :gauge,
      help: "Current Ceph health severity.",
      labels: ["severity"],
      values: %{severity: ["healthy", "warning", "critical", "unknown"]}
    },
    %{
      name: "exocomp_mission_control_helper_denials_total",
      type: :counter,
      help: "Denied profile helper actions.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_recovery_verification_failures_total",
      type: :counter,
      help: "Recovery actions whose post-action verification failed.",
      labels: [],
      values: %{}
    },
    %{
      name: "exocomp_mission_control_recovery_cooldowns_total",
      type: :counter,
      help: "Recovery actions entering cooldown.",
      labels: [],
      values: %{}
    }
  ]

  @events [
    [:exocomp, :mission_control, :connection],
    [:exocomp, :mission_control, :ingest],
    [:exocomp, :mission_control, :incident],
    [:exocomp, :mission_control, :conversation],
    [:exocomp, :mission_control, :proposal],
    [:exocomp, :mission_control, :command],
    [:exocomp, :mission_control, :webhook],
    [:exocomp, :mission_control, :database],
    [:exocomp, :mission_control, :retention],
    [:exocomp, :mission_control, :desired_state],
    [:exocomp, :mission_control, :discovery],
    [:exocomp, :mission_control, :profile],
    [:exocomp, :mission_control, :ceph],
    [:exocomp, :mission_control, :recovery]
  ]

  @histogram_bounds [0.1, 0.5, 1.0, 5.0, 10.0, :infinity]

  @doc false
  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, type: :worker}
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Returns the versioned metric schema without runtime values."
  @spec definitions() :: [map()]
  def definitions, do: @definitions

  @doc "Alias for callers validating the public metric contract."
  @spec schema() :: [map()]
  def schema, do: definitions()

  @spec increment(String.t(), number()) :: :ok | {:error, term()}
  def increment(name, amount) when is_number(amount), do: increment(name, %{}, amount)

  def increment(_name, _amount), do: {:error, :invalid_metric_value}

  @spec increment(String.t(), labels(), number()) :: :ok | {:error, term()}
  def increment(name, labels, amount) when is_number(amount) do
    GenServer.call(__MODULE__, {:increment, name, labels, amount})
  end

  def increment(_name, _labels, _amount), do: {:error, :invalid_metric_value}

  @spec set(String.t(), number()) :: :ok | {:error, term()}
  def set(name, value) when is_number(value), do: set(name, %{}, value)

  def set(_name, _value), do: {:error, :invalid_metric_value}

  @spec set(String.t(), labels(), number()) :: :ok | {:error, term()}
  def set(name, labels, value) when is_number(value) do
    GenServer.call(__MODULE__, {:set, name, labels, value})
  end

  def set(_name, _labels, _value), do: {:error, :invalid_metric_value}

  @spec observe(String.t(), number()) :: :ok | {:error, term()}
  def observe(name, value) when is_number(value), do: observe(name, %{}, value)

  def observe(_name, _value), do: {:error, :invalid_observation}

  @spec observe(String.t(), labels(), number()) :: :ok | {:error, term()}
  def observe(name, labels, value) when is_number(value) and value >= 0 do
    GenServer.call(__MODULE__, {:observe, name, labels, value})
  end

  def observe(_name, _labels, _value), do: {:error, :invalid_observation}

  @doc "Returns a read-only snapshot useful for tests and internal diagnostics."
  @spec snapshot() :: map()
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @doc "Clears values while retaining the public schema. Intended for tests."
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  @doc "Renders all defined metrics, including zero-valued series."
  @spec render() :: binary()
  def render, do: GenServer.call(__MODULE__, :render)

  @impl true
  def init(_opts) do
    attach_telemetry()
    {:ok, %{values: initial_values()}}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach({__MODULE__, self()})
    :ok
  end

  @impl true
  def handle_call({operation, name, labels, value}, _from, state)
      when operation in [:increment, :set, :observe] do
    case update(state.values, operation, name, labels, value) do
      {:ok, values} -> {:reply, :ok, %{state | values: values}}
      {:error, _reason} = error -> {:reply, error, state}
    end
  end

  def handle_call(:snapshot, _from, state), do: {:reply, state.values, state}
  def handle_call(:render, _from, state), do: {:reply, render_values(state.values), state}
  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{values: initial_values()}}

  @doc false
  def handle_event([:exocomp, :mission_control, :connection], measurements, metadata, _config) do
    connected = Map.get(measurements, :connected, Map.get(metadata, :connected, 0))
    disconnected = Map.get(measurements, :disconnected, Map.get(metadata, :disconnected, 0))
    _ = set("exocomp_mission_control_connections", %{state: "connected"}, connected)
    _ = set("exocomp_mission_control_connections", %{state: "disconnected"}, disconnected)
  end

  def handle_event([:exocomp, :mission_control, :ingest], measurements, metadata, _config) do
    outcome = Map.get(metadata, :outcome, Map.get(measurements, :outcome))
    _ = increment("exocomp_mission_control_events_ingested_total", %{outcome: outcome}, 1)
    maybe_observe("exocomp_mission_control_event_ingest_lag_seconds", measurements, :lag_seconds)
  end

  def handle_event([:exocomp, :mission_control, :incident], measurements, metadata, _config) do
    if severity = Map.get(metadata, :severity, Map.get(measurements, :severity)) do
      _ =
        set(
          "exocomp_mission_control_incidents_open",
          %{severity: severity},
          Map.get(measurements, :open, 0)
        )
    end
  end

  def handle_event([:exocomp, :mission_control, domain], measurements, _metadata, _config)
      when domain in [:conversation, :proposal] do
    metric = "exocomp_mission_control_#{domain}_latency_seconds"
    maybe_observe(metric, measurements, :latency_seconds)
  end

  def handle_event([:exocomp, :mission_control, :command], measurements, metadata, _config) do
    if state = Map.get(metadata, :state, Map.get(measurements, :state)) do
      _ =
        set("exocomp_mission_control_commands", %{state: state}, Map.get(measurements, :value, 0))
    end
  end

  def handle_event([:exocomp, :mission_control, :webhook], measurements, metadata, _config) do
    outcome = Map.get(metadata, :outcome, Map.get(measurements, :outcome))
    _ = increment("exocomp_mission_control_webhook_deliveries_total", %{outcome: outcome}, 1)
  end

  def handle_event([:exocomp, :mission_control, :database], measurements, _metadata, _config) do
    for {key, metric} <- [
          {"pool_size", "exocomp_mission_control_database_pool_size"},
          {"pool_available", "exocomp_mission_control_database_pool_available"},
          {"queue_length", "exocomp_mission_control_database_queue_length"}
        ],
        value <- [Map.get(measurements, String.to_existing_atom(key))],
        is_number(value) do
      _ = set(metric, value)
    end
  end

  def handle_event([:exocomp, :mission_control, :retention], measurements, metadata, _config) do
    status = Map.get(metadata, :status, Map.get(measurements, :status))
    value = if status == "running" or status == :running, do: 1, else: 0
    _ = set("exocomp_mission_control_retention_job_status", %{status: status}, value)
  end

  def handle_event([:exocomp, :mission_control, :desired_state], measurements, metadata, _config) do
    state = Map.get(metadata, :state, Map.get(measurements, :state))

    if state do
      _ =
        set("exocomp_mission_control_services", %{state: state}, Map.get(measurements, :count, 0))
    end

    from = Map.get(metadata, :from, Map.get(measurements, :from))
    to = Map.get(metadata, :to, Map.get(measurements, :to))

    if from && to do
      _ =
        increment(
          "exocomp_mission_control_service_transitions_total",
          %{from: from, to: to},
          1
        )
    end
  end

  def handle_event([:exocomp, :mission_control, :discovery], _measurements, _metadata, _config),
    do: increment("exocomp_mission_control_discovery_failures_total", 1)

  def handle_event([:exocomp, :mission_control, :profile], measurements, _metadata, _config) do
    case Map.get(measurements, :coverage) do
      coverage when is_number(coverage) ->
        set("exocomp_mission_control_profile_coverage", coverage)

      _ ->
        :ok
    end
  end

  def handle_event([:exocomp, :mission_control, :ceph], measurements, metadata, _config) do
    severity = Map.get(metadata, :severity, Map.get(measurements, :severity))

    if severity do
      for known_severity <- ["healthy", "warning", "critical", "unknown"] do
        _ =
          set(
            "exocomp_mission_control_ceph_health",
            %{severity: known_severity},
            if(to_string(severity) == known_severity, do: 1, else: 0)
          )
      end
    end
  end

  def handle_event([:exocomp, :mission_control, :recovery], _measurements, metadata, _config) do
    case Map.get(metadata, :outcome) do
      :helper_denied ->
        increment("exocomp_mission_control_helper_denials_total", 1)

      :verification_failed ->
        increment("exocomp_mission_control_recovery_verification_failures_total", 1)

      :cooldown ->
        increment("exocomp_mission_control_recovery_cooldowns_total", 1)

      _ ->
        :ok
    end
  end

  def handle_event(_event, _measurements, _metadata, _config), do: :ok

  defp attach_telemetry do
    case :telemetry.attach_many({__MODULE__, self()}, @events, &__MODULE__.handle_event/4, nil) do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
  end

  defp maybe_observe(metric, measurements, key) do
    case Map.get(measurements, key) do
      value when is_number(value) and value >= 0 -> observe(metric, value)
      _ -> :ok
    end
  end

  defp update(values, operation, name, labels, value) do
    with {:ok, definition} <- definition(name),
         {:ok, key} <- label_key(definition, labels),
         :ok <- valid_value?(definition.type, operation, value),
         :ok <- valid_operation?(definition.type, operation) do
      metric_key = {name, key}

      updated =
        case {definition.type, operation} do
          {:histogram, :observe} -> update_histogram(Map.get(values, metric_key), value)
          {_type, :increment} -> Map.get(values, metric_key, 0) + value
          {_type, :set} -> value
          {_type, :observe} -> {:error, :invalid_metric_operation}
        end

      case updated do
        {:error, _reason} = error -> error
        value -> {:ok, Map.put(values, metric_key, value)}
      end
    end
  end

  defp update_histogram(%{buckets: buckets, sum: sum, count: count}, value) do
    updated_buckets =
      Enum.reduce(buckets, buckets, fn {upper_bound, bucket_count}, acc ->
        if value <= upper_bound, do: Map.put(acc, upper_bound, bucket_count + 1), else: acc
      end)

    %{buckets: updated_buckets, sum: sum + value, count: count + 1}
  end

  defp definition(name) do
    case Enum.find(@definitions, &(&1.name == name)) do
      nil -> {:error, :unknown_metric}
      definition -> {:ok, definition}
    end
  end

  defp label_key(%{labels: [], values: %{}}, labels) when labels in [%{}, []], do: {:ok, []}

  defp label_key(%{labels: expected, values: allowed}, labels) when is_map(labels) do
    normalized = Map.new(labels, fn {key, value} -> {to_string(key), to_string(value)} end)

    cond do
      Map.keys(normalized) |> Enum.sort() != Enum.sort(expected) ->
        {:error, :invalid_labels}

      Enum.any?(expected, &(normalized[&1] not in Map.fetch!(allowed, String.to_atom(&1)))) ->
        {:error, :invalid_labels}

      true ->
        {:ok, Enum.map(expected, &{&1, normalized[&1]})}
    end
  end

  defp label_key(_definition, _labels), do: {:error, :invalid_labels}

  defp valid_operation?(:counter, :increment), do: :ok
  defp valid_operation?(:gauge, operation) when operation in [:increment, :set], do: :ok
  defp valid_operation?(:histogram, :observe), do: :ok
  defp valid_operation?(_type, _operation), do: {:error, :invalid_metric_operation}

  defp valid_value?(:counter, :increment, value) when value >= 0, do: :ok
  defp valid_value?(:gauge, _operation, value) when value >= 0, do: :ok
  defp valid_value?(:histogram, :observe, value) when value >= 0, do: :ok
  defp valid_value?(_type, _operation, _value), do: {:error, :invalid_metric_value}

  defp initial_values do
    Enum.reduce(@definitions, %{}, fn definition, values ->
      for labels <- label_combinations(definition), into: values do
        {{definition.name, labels}, initial_value(definition)}
      end
    end)
  end

  defp initial_value(%{type: :histogram}), do: histogram()
  defp initial_value(_definition), do: 0

  defp histogram do
    %{buckets: Enum.into(@histogram_bounds, %{}, &{&1, 0}), sum: 0, count: 0}
  end

  defp label_combinations(%{labels: [], values: %{}}), do: [[]]

  defp label_combinations(%{labels: labels, values: values}) do
    Enum.reduce(labels, [[]], fn label, combinations ->
      for combination <- combinations, value <- Map.fetch!(values, String.to_atom(label)) do
        combination ++ [{label, value}]
      end
    end)
  end

  defp render_values(values) do
    @definitions
    |> Enum.map(&render_definition(&1, values))
    |> IO.iodata_to_binary()
  end

  defp render_definition(definition, values) do
    header = [
      "# HELP ",
      definition.name,
      " ",
      definition.help,
      "\n",
      "# TYPE ",
      definition.name,
      " ",
      Atom.to_string(definition.type),
      "\n"
    ]

    body =
      for labels <- label_combinations(definition) do
        render_value(definition, labels, Map.fetch!(values, {definition.name, labels}))
      end

    [header, body]
  end

  defp render_value(%{type: :histogram, name: name}, labels, value) do
    bucket_lines =
      Enum.map(@histogram_bounds, fn upper_bound ->
        count = Map.fetch!(value.buckets, upper_bound)

        bucket_labels = [
          {"le", if(upper_bound == :infinity, do: "+Inf", else: format_number(upper_bound))}
          | labels
        ]

        [name, "_bucket", render_labels(bucket_labels), " ", format_number(count), "\n"]
      end)

    [
      bucket_lines,
      name,
      "_sum",
      render_labels(labels),
      " ",
      format_number(value.sum),
      "\n",
      name,
      "_count",
      render_labels(labels),
      " ",
      format_number(value.count),
      "\n"
    ]
  end

  defp render_value(%{name: name}, labels, value),
    do: [name, render_labels(labels), " ", format_number(value), "\n"]

  defp render_labels([]), do: ""

  defp render_labels(labels) do
    encoded =
      Enum.map_join(labels, ",", fn {key, value} -> key <> "=\"" <> escape(value) <> "\"" end)

    "{" <> encoded <> "}"
  end

  defp escape(value),
    do:
      value
      |> to_string()
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", "\\n")

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)
  defp format_number(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 6)
  defp format_number(value), do: to_string(value)
end
