defmodule Bench.Sample do
  @moduledoc """
  A single timestamped benchmark observation.

  Timestamps are stored as either Unix milliseconds or ISO-8601 strings.
  """

  @sources [:beam, :host, :node, :coordinator, :llama]

  @enforce_keys [:timestamp, :source, :metric_name, :value, :unit]
  defstruct @enforce_keys

  @type source :: :beam | :host | :node | :coordinator | :llama

  @type t :: %__MODULE__{
          timestamp: integer() | String.t(),
          source: source(),
          metric_name: String.t(),
          value: number(),
          unit: String.t()
        }

  @doc """
  Encodes a sample as JSON.
  """
  @spec to_json(t()) :: {:ok, String.t()} | {:error, term()}
  def to_json(%__MODULE__{} = sample) do
    sample
    |> to_map()
    |> Jason.encode()
  end

  @doc """
  Decodes and validates a sample from JSON.
  """
  @spec from_json(String.t()) :: {:ok, t()} | {:error, term()}
  def from_json(json) when is_binary(json) do
    with {:ok, map} <- Jason.decode(json) do
      from_map(map)
    end
  end

  @doc false
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = sample) do
    %{
      "timestamp" => sample.timestamp,
      "source" => Atom.to_string(sample.source),
      "metric_name" => sample.metric_name,
      "value" => sample.value,
      "unit" => sample.unit
    }
  end

  @doc false
  @spec from_map(map()) :: {:ok, t()} | {:error, term()}
  def from_map(map) when is_map(map) do
    with {:ok, timestamp} <- fetch_timestamp(map),
         {:ok, source} <- fetch_source(map),
         {:ok, metric_name} <- fetch_string(map, "metric_name"),
         {:ok, value} <- fetch_number(map, "value"),
         {:ok, unit} <- fetch_string(map, "unit") do
      {:ok,
       %__MODULE__{
         timestamp: timestamp,
         source: source,
         metric_name: metric_name,
         value: value,
         unit: unit
       }}
    end
  end

  def from_map(_), do: {:error, :invalid_sample}

  defp fetch_timestamp(map) do
    case Map.fetch(map, "timestamp") do
      {:ok, timestamp} when is_integer(timestamp) or is_binary(timestamp) ->
        {:ok, timestamp}

      _ ->
        {:error, {:invalid_sample_field, :timestamp}}
    end
  end

  defp fetch_source(map) do
    with {:ok, source} when is_binary(source) <- Map.fetch(map, "source"),
         atom when atom in @sources <- source_atom(source) do
      {:ok, atom}
    else
      _ -> {:error, {:invalid_sample_field, :source}}
    end
  end

  defp source_atom("beam"), do: :beam
  defp source_atom("host"), do: :host
  defp source_atom("node"), do: :node
  defp source_atom("coordinator"), do: :coordinator
  defp source_atom("llama"), do: :llama
  defp source_atom(_), do: nil

  defp fetch_string(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      _ -> {:error, {:invalid_sample_field, String.to_existing_atom(key)}}
    end
  end

  defp fetch_number(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_number(value) -> {:ok, value}
      _ -> {:error, {:invalid_sample_field, String.to_existing_atom(key)}}
    end
  end
end
