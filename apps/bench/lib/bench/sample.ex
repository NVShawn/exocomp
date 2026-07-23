defmodule Bench.Sample do
  @moduledoc """
  Raw benchmark sample model.

  A `Bench.Sample` captures a single time-stamped observation emitted by a
  `Bench.Sampler` implementation.  Samples are persisted as
  newline-delimited JSON (one JSON object per line) so they can be streamed
  and post-processed independently of the harness.

  The full field schema and JSON encoding are extended in EXOCOMP-54.
  """

  @typedoc "Opaque raw sample."
  @type t :: %__MODULE__{}

  defstruct [
    :timestamp_ms,
    :source,
    :metrics
  ]

  @doc """
  Encodes a `Bench.Sample` to a JSON string suitable for newline-delimited
  output.

  Returns `{:ok, json}` or `{:error, reason}`.
  """
  @spec to_json(t()) :: {:ok, String.t()} | {:error, term()}
  def to_json(%__MODULE__{} = sample) do
    Jason.encode(Map.from_struct(sample))
  end

  @doc """
  Decodes a JSON string into a `Bench.Sample`.

  Returns `{:ok, %Bench.Sample{}}` or `{:error, reason}`.
  """
  @spec from_json(String.t()) :: {:ok, t()} | {:error, term()}
  def from_json(json) when is_binary(json) do
    case Jason.decode(json, keys: :atoms) do
      {:ok, map} -> {:ok, struct!(__MODULE__, map)}
      {:error, _} = err -> err
    end
  end
end
