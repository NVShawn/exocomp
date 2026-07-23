defmodule Bench.Run do
  @moduledoc """
  Metadata and raw observations belonging to one benchmark run.

  JSON Lines output repeats the run metadata on every sample record. This
  keeps individual records self-contained and allows a run to be reconstructed
  without a separate sidecar file.
  """

  alias Bench.Sample

  @metadata_fields [
    :build_metadata,
    :host_profile,
    :model_version,
    :workload_name,
    :config_ref
  ]
  @required_fields @metadata_fields
  @json_metadata_fields Enum.map(@metadata_fields, &Atom.to_string/1)
  @json_run_fields @json_metadata_fields ++ ["samples"]
  @sample_fields ~w(timestamp source metric_name value unit tags)

  @enforce_keys @required_fields
  defstruct @required_fields ++ [samples: []]

  @type t :: %__MODULE__{
          build_metadata: map(),
          host_profile: term(),
          model_version: String.t(),
          workload_name: String.t(),
          config_ref: term(),
          samples: [Sample.t()]
        }

  @doc """
  Creates a run from a keyword list or map.

  `:samples` is optional and defaults to an empty list.
  """
  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs
    |> Map.new()
    |> normalize_keys()
    |> Map.update(:samples, [], & &1)
    |> then(&struct!(__MODULE__, &1))
  end

  @doc """
  Appends a sample while retaining observation order.
  """
  @spec append_sample(t(), Sample.t()) :: t()
  def append_sample(%__MODULE__{} = run, %Sample{} = sample) do
    %{run | samples: run.samples ++ [sample]}
  end

  @doc """
  Writes one self-contained JSON object per sample to `path`.
  """
  @spec write_jsonl(t(), Path.t()) :: :ok | {:error, term()}
  def write_jsonl(%__MODULE__{} = run, path) when is_binary(path) do
    with {:ok, lines} <- encode_lines(run) do
      File.write(path, lines)
    end
  end

  @spec write_jsonl(Path.t(), t()) :: :ok | {:error, term()}
  def write_jsonl(path, %__MODULE__{} = run) when is_binary(path),
    do: write_jsonl(run, path)

  @doc """
  Reads a run from a JSON Lines file.

  Malformed records return `{:error, {:malformed_line, line_number, reason}}`.
  Records with metadata different from the first record are rejected.
  """
  @spec read_jsonl(Path.t()) :: {:ok, t()} | {:error, term()}
  def read_jsonl(path) when is_binary(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, records} <- decode_lines(contents),
         {:ok, run} <- records_to_run(records) do
      {:ok, run}
    end
  end

  defp encode_lines(%__MODULE__{samples: []}), do: {:error, :run_has_no_samples}

  defp encode_lines(%__MODULE__{} = run) do
    metadata = metadata_map(run)

    run.samples
    |> Enum.reduce_while({:ok, []}, fn sample, {:ok, lines} ->
      case Jason.encode(Map.merge(metadata, Sample.to_map(sample))) do
        {:ok, json} -> {:cont, {:ok, [[json, "\n"] | lines]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, lines} -> {:ok, lines |> Enum.reverse() |> IO.iodata_to_binary()}
      error -> error
    end
  end

  defp decode_lines(contents) do
    contents
    |> jsonl_lines()
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {line, line_number}, {:ok, records} ->
      case Jason.decode(line) do
        {:ok, record} when is_map(record) ->
          {:cont, {:ok, [record | records]}}

        {:ok, _other} ->
          {:halt, {:error, {:malformed_line, line_number, :expected_object}}}

        {:error, reason} ->
          {:halt, {:error, {:malformed_line, line_number, reason}}}
      end
    end)
    |> case do
      {:ok, records} -> {:ok, Enum.reverse(records)}
      error -> error
    end
  end

  defp jsonl_lines(""), do: []

  defp jsonl_lines(contents) do
    lines = String.split(contents, "\n")

    if List.last(lines) == "" do
      List.delete_at(lines, -1)
    else
      lines
    end
  end

  defp records_to_run([]), do: {:error, :empty_file}

  defp records_to_run([first | rest]) do
    metadata = Map.take(first, @json_metadata_fields)

    with :ok <- validate_metadata(metadata, 1),
         {:ok, first_sample} <- sample_from_record(first, 1),
         {:ok, samples} <- collect_samples(rest, metadata, [first_sample], 2) do
      attrs =
        metadata
        |> Map.put("samples", samples)
        |> normalize_keys()

      {:ok, struct!(__MODULE__, attrs)}
    end
  end

  defp collect_samples([], _metadata, samples, _line_number),
    do: {:ok, Enum.reverse(samples)}

  defp collect_samples([record | rest], metadata, samples, line_number) do
    with :ok <- validate_metadata(record, line_number),
         :ok <- metadata_matches(record, metadata, line_number),
         {:ok, sample} <- sample_from_record(record, line_number) do
      collect_samples(rest, metadata, [sample | samples], line_number + 1)
    end
  end

  defp validate_metadata(record, line_number) do
    missing = Enum.reject(@json_metadata_fields, &Map.has_key?(record, &1))

    case missing do
      [] -> :ok
      fields -> {:error, {:malformed_line, line_number, {:missing_fields, fields}}}
    end
  end

  defp metadata_matches(record, expected, line_number) do
    if Map.take(record, @json_metadata_fields) == expected do
      :ok
    else
      {:error, {:malformed_line, line_number, :inconsistent_run_metadata}}
    end
  end

  defp sample_from_record(record, line_number) do
    case Sample.from_map(Map.take(record, @sample_fields)) do
      {:ok, sample} -> {:ok, sample}
      {:error, reason} -> {:error, {:malformed_line, line_number, reason}}
    end
  end

  defp metadata_map(run) do
    Map.new(@metadata_fields, fn field ->
      {Atom.to_string(field), Map.fetch!(run, field)}
    end)
  end

  defp normalize_keys(map) do
    Map.new(map, fn
      {key, value} when key in @json_run_fields ->
        {String.to_existing_atom(key), value}

      {key, value} ->
        {key, value}
    end)
  end
end
