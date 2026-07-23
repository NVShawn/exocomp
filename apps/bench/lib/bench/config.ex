defmodule Bench.Config do
  @moduledoc """
  Versioned benchmark configuration schema with strict validation.

  A `Bench.Config` struct records all parameters needed to reproduce a
  benchmark run: timing, concurrency, sampling, and references to the
  host environment and workload being exercised.

  ## Usage

      iex> Bench.Config.parse(%{
      ...>   "schema_version" => 1,
      ...>   "name" => "idle-node",
      ...>   "version" => "0.1.0",
      ...>   "warm_up_duration" => 30,
      ...>   "run_duration" => 300,
      ...>   "repetitions" => 3,
      ...>   "concurrency" => 1,
      ...>   "sample_interval" => 1000,
      ...>   "host_profile" => "amd64-linux",
      ...>   "workload_scenario" => "idle"
      ...> })
      {:ok, %Bench.Config{...}}

  ## Schema fields

  | Field               | Type             | Description                                          |
  |---------------------|------------------|------------------------------------------------------|
  | `:schema_version`   | positive integer | Schema revision; must equal 1                        |
  | `:name`             | string           | Benchmark name (non-empty)                           |
  | `:version`          | string           | Benchmark version (non-empty)                        |
  | `:warm_up_duration` | positive integer | Warm-up period in seconds                            |
  | `:run_duration`     | positive integer | Measurement period in seconds                        |
  | `:repetitions`      | positive integer | Number of repetitions                                |
  | `:concurrency`      | positive integer | Number of concurrent workers                         |
  | `:sample_interval`  | positive integer | Sampling period in milliseconds                      |
  | `:host_profile`     | string           | Reference to a Bench.HostProfile name (non-empty)    |
  | `:workload_scenario`| string           | Reference to a workload scenario name (non-empty)    |

  ## Error reasons

  | Reason                                           | Meaning                                         |
  |--------------------------------------------------|-------------------------------------------------|
  | `:incompatible_version`                          | schema_version does not match current version   |
  | `{:missing_fields, [field]}`                     | One or more required fields are absent          |
  | `{:unknown_fields, [field]}`                     | Map contains keys not defined in the schema     |
  | `{:invalid_field, field, :must_be_positive}`     | Numeric field is zero or negative               |
  | `{:invalid_field, field, :must_be_integer}`      | Expected integer, got another type              |
  | `{:invalid_field, field, :must_be_non_empty_string}` | String field is empty or non-string         |
  | `:invalid_input`                                 | Input is not a map                              |
  """

  @current_schema_version 1

  @known_fields ~w(
    schema_version
    name
    version
    warm_up_duration
    run_duration
    repetitions
    concurrency
    sample_interval
    host_profile
    workload_scenario
  )

  defstruct [
    :schema_version,
    :name,
    :version,
    :warm_up_duration,
    :run_duration,
    :repetitions,
    :concurrency,
    :sample_interval,
    :host_profile,
    :workload_scenario
  ]

  @type t :: %__MODULE__{
          schema_version: pos_integer(),
          name: String.t(),
          version: String.t(),
          warm_up_duration: pos_integer(),
          run_duration: pos_integer(),
          repetitions: pos_integer(),
          concurrency: pos_integer(),
          sample_interval: pos_integer(),
          host_profile: String.t(),
          workload_scenario: String.t()
        }

  @doc """
  Parse and validate a benchmark configuration from a map.

  Accepts maps with either string or atom keys (e.g. from TOML parsers or
  Elixir literals). Returns `{:ok, %Bench.Config{}}` on success, or
  `{:error, reason}` on the first validation failure encountered.

  Validation order:
    1. Unknown fields
    2. Missing required fields
    3. Schema version compatibility
    4. Field type and range constraints
  """
  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(attrs) when is_map(attrs) do
    normalized = normalize_keys(attrs)

    with :ok <- check_unknown_fields(normalized),
         :ok <- check_missing_fields(normalized),
         config = build_struct(normalized),
         {:ok, config} <- validate(config) do
      {:ok, config}
    end
  end

  def parse(_), do: {:error, :invalid_input}

  @doc """
  Validate a `%Bench.Config{}` struct.

  Returns `{:ok, config}` when all fields satisfy type and range constraints,
  or `{:error, reason}` on the first failure. When given a plain map, delegates
  to `parse/1`.
  """
  @spec validate(t() | map()) :: {:ok, t()} | {:error, term()}
  def validate(%__MODULE__{} = config) do
    with :ok <- validate_schema_version(config.schema_version),
         :ok <- validate_string_field(:name, config.name),
         :ok <- validate_string_field(:version, config.version),
         :ok <- validate_positive_integer(:warm_up_duration, config.warm_up_duration),
         :ok <- validate_positive_integer(:run_duration, config.run_duration),
         :ok <- validate_positive_integer(:repetitions, config.repetitions),
         :ok <- validate_positive_integer(:concurrency, config.concurrency),
         :ok <- validate_positive_integer(:sample_interval, config.sample_interval),
         :ok <- validate_string_field(:host_profile, config.host_profile),
         :ok <- validate_string_field(:workload_scenario, config.workload_scenario) do
      {:ok, config}
    end
  end

  def validate(attrs) when is_map(attrs), do: parse(attrs)

  ## Private helpers

  # Normalize all keys to strings so we handle both atom and string key maps.
  defp normalize_keys(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp check_unknown_fields(normalized) do
    unknown = Map.keys(normalized) -- @known_fields

    if unknown == [] do
      :ok
    else
      {:error, {:unknown_fields, Enum.sort(unknown)}}
    end
  end

  defp check_missing_fields(normalized) do
    missing = Enum.reject(@known_fields, &Map.has_key?(normalized, &1))

    if missing == [] do
      :ok
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp build_struct(normalized) do
    %__MODULE__{
      schema_version: normalized["schema_version"],
      name: normalized["name"],
      version: normalized["version"],
      warm_up_duration: normalized["warm_up_duration"],
      run_duration: normalized["run_duration"],
      repetitions: normalized["repetitions"],
      concurrency: normalized["concurrency"],
      sample_interval: normalized["sample_interval"],
      host_profile: normalized["host_profile"],
      workload_scenario: normalized["workload_scenario"]
    }
  end

  defp validate_schema_version(v)
       when is_integer(v) and v == @current_schema_version,
       do: :ok

  defp validate_schema_version(_), do: {:error, :incompatible_version}

  defp validate_string_field(_field, val)
       when is_binary(val) and byte_size(val) > 0,
       do: :ok

  defp validate_string_field(field, _),
    do: {:error, {:invalid_field, field, :must_be_non_empty_string}}

  defp validate_positive_integer(_field, val)
       when is_integer(val) and val > 0,
       do: :ok

  defp validate_positive_integer(field, val) when is_integer(val),
    do: {:error, {:invalid_field, field, :must_be_positive}}

  defp validate_positive_integer(field, _),
    do: {:error, {:invalid_field, field, :must_be_integer}}
end
