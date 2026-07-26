# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Baseline do
  @moduledoc """
  Loads and validates versioned M5 regression baselines.

  Baselines are selected by the exact shipped artifact version and detected
  architecture. The deliberately small TOML reader supports the scalar values
  and nested tables used by the checked-in baseline files without adding a
  runtime parser dependency to the qualification artifact.
  """

  @required_fields ~w(schema_version artifact_version architecture host_profile gates)
  @supported_metrics %{
    "beam_cpu_percent" => "beam.cpu.node_plus_coordinator.mean_percent",
    "beam_ram_percent" => "beam.memory.node_plus_coordinator.peak_percent"
  }
  @maximum_budgets %{
    "beam_cpu_percent" => 5.0,
    "beam_ram_percent" => 5.0
  }

  @enforce_keys [
    :schema_version,
    :artifact_version,
    :architecture,
    :host_profile,
    :gates,
    :reference,
    :path
  ]
  defstruct @enforce_keys

  @type gate :: %{
          required(:name) => String.t(),
          required(:metric) => String.t(),
          required(:budget) => number(),
          required(:unit) => String.t(),
          required(:direction) => String.t(),
          optional(:description) => String.t()
        }

  @type t :: %__MODULE__{
          schema_version: pos_integer(),
          artifact_version: String.t(),
          architecture: String.t(),
          host_profile: String.t(),
          gates: [gate()],
          reference: map(),
          path: Path.t()
        }

  @doc """
  Selects the baseline for `artifact_version` and `architecture`.

  The optional `:root` points at a baseline directory for tests. Production
  selection uses the baseline data embedded in the benchmark release.
  """
  @spec select(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def select(artifact_version, architecture, opts \\ [])
      when is_binary(artifact_version) and is_binary(architecture) do
    with {:ok, normalized_version} <- normalize_version(artifact_version),
         {:ok, root} <- baseline_root(opts) do
      path =
        Path.join([
          root,
          "v#{normalized_version}",
          "#{architecture}.toml"
        ])

      case load(path) do
        {:ok, baseline} ->
          baseline = %{
            baseline
            | path:
                Path.join([
                  "apps",
                  "bench",
                  "priv",
                  "bench",
                  "baselines",
                  "v#{normalized_version}",
                  "#{architecture}.toml"
                ])
          }

          validate_selection(baseline, normalized_version, architecture)

        {:error, :enoent} ->
          {:error, {:baseline_not_found, artifact_version, architecture, path}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc "Loads and validates one baseline TOML file."
  @spec load(Path.t()) :: {:ok, t()} | {:error, term()}
  def load(path) when is_binary(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, data} <- parse_toml(contents),
         :ok <- require_fields(data),
         {:ok, baseline} <- build(data, path) do
      {:ok, baseline}
    end
  end

  defp baseline_root(opts) do
    case Keyword.get(opts, :root) do
      nil ->
        case :code.priv_dir(:bench) do
          {:error, reason} -> {:error, {:priv_dir, reason}}
          priv -> {:ok, Path.join([to_string(priv), "bench", "baselines"])}
        end

      root when is_binary(root) ->
        {:ok, root}

      other ->
        {:error, {:invalid_baseline_root, other}}
    end
  end

  defp normalize_version("v" <> version), do: normalize_version(version)

  defp normalize_version(version) do
    if Regex.match?(~r/^[0-9A-Za-z][0-9A-Za-z._+-]*$/, version) do
      {:ok, version}
    else
      {:error, {:invalid_artifact_version, version}}
    end
  end

  defp validate_selection(baseline, version, architecture) do
    with {:ok, baseline_version} <- normalize_version(baseline.artifact_version),
         true <- baseline_version == version,
         true <- baseline.architecture == architecture do
      {:ok, baseline}
    else
      false ->
        {:error,
         {:baseline_identity_mismatch,
          %{
            expected_version: version,
            expected_architecture: architecture,
            actual_version: baseline.artifact_version,
            actual_architecture: baseline.architecture,
            path: baseline.path
          }}}

      {:error, _reason} = error ->
        error
    end
  end

  defp require_fields(data) do
    missing = Enum.reject(@required_fields, &Map.has_key?(data, &1))

    case missing do
      [] -> :ok
      fields -> {:error, {:baseline_missing_fields, fields}}
    end
  end

  defp build(data, path) do
    with :ok <- positive_schema(data["schema_version"]),
         :ok <- non_empty_string(:artifact_version, data["artifact_version"]),
         :ok <- supported_architecture(data["architecture"]),
         :ok <- non_empty_string(:host_profile, data["host_profile"]),
         {:ok, gates} <- build_gates(data["gates"]) do
      {:ok,
       %__MODULE__{
         schema_version: data["schema_version"],
         artifact_version: data["artifact_version"],
         architecture: data["architecture"],
         host_profile: data["host_profile"],
         gates: gates,
         reference: Map.get(data, "reference", %{}),
         path: path
       }}
    end
  end

  defp positive_schema(1), do: :ok
  defp positive_schema(value), do: {:error, {:unsupported_baseline_schema, value}}

  defp supported_architecture(value) when value in ["amd64", "arm64"], do: :ok
  defp supported_architecture(value), do: {:error, {:unsupported_architecture, value}}

  defp non_empty_string(_field, value) when is_binary(value) and value != "", do: :ok
  defp non_empty_string(field, value), do: {:error, {:invalid_baseline_field, field, value}}

  defp build_gates(gates) when is_map(gates) and map_size(gates) > 0 do
    gates
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce_while({:ok, []}, fn {name, attrs}, {:ok, parsed} ->
      case build_gate(name, attrs) do
        {:ok, gate} -> {:cont, {:ok, [gate | parsed]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, gates} ->
        gates = Enum.reverse(gates)

        with :ok <- required_gates(gates) do
          {:ok, gates}
        end

      error ->
        error
    end
  end

  defp build_gates(value), do: {:error, {:invalid_baseline_field, :gates, value}}

  defp build_gate(name, attrs) when is_binary(name) and is_map(attrs) do
    metric = Map.get(attrs, "metric", @supported_metrics[name])
    budget = attrs["budget"]
    unit = attrs["unit"]
    direction = attrs["direction"]
    expected_metric = @supported_metrics[name]
    maximum_budget = @maximum_budgets[name]

    with true <- is_binary(expected_metric),
         true <- metric == expected_metric,
         true <- is_number(budget) and budget >= 0,
         true <- budget <= maximum_budget,
         true <- is_binary(unit) and unit != "",
         true <- direction == "lower_is_better" do
      gate = %{
        name: name,
        metric: metric,
        budget: budget,
        unit: unit,
        direction: direction
      }

      gate =
        case attrs["description"] do
          description when is_binary(description) and description != "" ->
            Map.put(gate, :description, description)

          _ ->
            gate
        end

      {:ok, gate}
    else
      false -> {:error, {:invalid_gate, name, attrs}}
    end
  end

  defp build_gate(name, attrs), do: {:error, {:invalid_gate, name, attrs}}

  defp required_gates(gates) do
    names = MapSet.new(gates, & &1.name)

    missing =
      @supported_metrics
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(names, &1))

    case missing do
      [] -> :ok
      names -> {:error, {:baseline_missing_gates, names}}
    end
  end

  defp parse_toml(contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, {%{}, []}}, fn {line, line_number}, {:ok, {data, section}} ->
      trimmed = String.trim(line)

      cond do
        trimmed == "" or String.starts_with?(trimmed, "#") ->
          {:cont, {:ok, {data, section}}}

        Regex.match?(~r/^\[[A-Za-z0-9_.-]+\]$/, trimmed) ->
          section =
            trimmed
            |> String.trim_leading("[")
            |> String.trim_trailing("]")
            |> String.split(".")

          {:cont, {:ok, {data, section}}}

        String.contains?(trimmed, "=") ->
          [raw_key, raw_value] = String.split(trimmed, "=", parts: 2)
          key = String.trim(raw_key)

          with true <- Regex.match?(~r/^[A-Za-z0-9_-]+$/, key),
               {:ok, value} <- parse_value(String.trim(raw_value)),
               {:ok, updated} <- put_nested(data, section ++ [key], value) do
            {:cont, {:ok, {updated, section}}}
          else
            false -> {:halt, {:error, {:baseline_parse_error, line_number, :invalid_key}}}
            {:error, reason} -> {:halt, {:error, {:baseline_parse_error, line_number, reason}}}
          end

        true ->
          {:halt, {:error, {:baseline_parse_error, line_number, :invalid_line}}}
      end
    end)
    |> case do
      {:ok, {data, _section}} -> {:ok, data}
      error -> error
    end
  end

  defp parse_value("\"" <> _rest = value) do
    case Jason.decode(value) do
      {:ok, parsed} when is_binary(parsed) -> {:ok, parsed}
      _ -> {:error, :invalid_string}
    end
  end

  defp parse_value("true"), do: {:ok, true}
  defp parse_value("false"), do: {:ok, false}

  defp parse_value(value) do
    cond do
      Regex.match?(~r/^-?\d+$/, value) ->
        {:ok, String.to_integer(value)}

      Regex.match?(~r/^-?(?:\d+\.\d*|\d*\.\d+)$/, value) ->
        case Float.parse(value) do
          {parsed, ""} -> {:ok, parsed}
          _ -> {:error, :invalid_number}
        end

      true ->
        {:error, :unsupported_value}
    end
  end

  defp put_nested(map, [key], value) do
    if Map.has_key?(map, key) do
      {:error, {:duplicate_key, key}}
    else
      {:ok, Map.put(map, key, value)}
    end
  end

  defp put_nested(map, [key | rest], value) do
    child = Map.get(map, key, %{})

    if is_map(child) do
      case put_nested(child, rest, value) do
        {:ok, updated} -> {:ok, Map.put(map, key, updated)}
        error -> error
      end
    else
      {:error, {:table_conflict, key}}
    end
  end
end
