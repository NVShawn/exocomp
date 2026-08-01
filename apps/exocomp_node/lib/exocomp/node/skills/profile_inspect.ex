# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ProfileInspect do
  @moduledoc """
  Skill handler for `exocomp.profile.inspect`.

  Version 1 currently exposes the fixed, read-only Ceph node discovery path.
  The handler deliberately does not accept a command, executable, unit list,
  path, or systemd selector from the request. A request may identify the
  shipped profile as `ceph` (or omit the selector for this single-branch
  implementation), but all discovery inputs remain compile-time constants in
  the collector.
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @skill_id "exocomp.profile.inspect"
  @profile_id "ceph"
  @profile_version 1
  @default_timeout_ms 10_000
  @allowed_params MapSet.new(["profile", "profile_id", "version", "profile_version"])

  @impl true
  def execute(params, _context) when is_map(params) do
    with :ok <- validate_params(params),
         {:ok, observation} <- collect_observation() do
      {:ok, build_artifact(observation)}
    end
  end

  def execute(_params, _context), do: {:error, :invalid_params}

  defp validate_params(params) do
    requested_keys = params |> Map.keys() |> MapSet.new()

    with true <- MapSet.subset?(requested_keys, @allowed_params),
         :ok <- validate_profile_id(params),
         :ok <- validate_profile_version(params) do
      :ok
    else
      false -> {:error, :invalid_params}
      error -> error
    end
  end

  defp validate_profile_id(params) do
    ids =
      [Map.get(params, "profile"), Map.get(params, "profile_id")]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    case ids do
      [] -> :ok
      [@profile_id] -> :ok
      _other -> {:error, :unsupported_profile}
    end
  end

  defp validate_profile_version(params) do
    versions =
      [Map.get(params, "version"), Map.get(params, "profile_version")]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    case versions do
      [] -> :ok
      [@profile_version] -> :ok
      _other -> {:error, :unsupported_profile_version}
    end
  end

  defp collect_observation do
    collector =
      Application.get_env(
        :exocomp_node,
        :profile_inspect_ceph_collector,
        Application.get_env(:exocomp_node, :profile_inspect_collector, &default_collect/0)
      )

    timeout_ms =
      case Application.get_env(:exocomp_node, :profile_inspect_timeout_ms, @default_timeout_ms) do
        value when is_integer(value) and value > 0 -> value
        _other -> @default_timeout_ms
      end

    task = Task.async(fn -> safe_collect(collector) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, observation}} -> {:ok, observation}
      {:ok, {:error, reason}} -> {:error, reason}
      {:ok, _other} -> {:error, :collector_failed}
      {:exit, _reason} -> {:error, :collector_failed}
      nil -> {:error, :timeout}
    end
  end

  defp safe_collect(collector) when is_function(collector, 0) do
    {:ok, collector.()}
  rescue
    _exception -> {:error, :collector_failed}
  catch
    _kind, _reason -> {:error, :collector_failed}
  end

  defp safe_collect(_collector), do: {:error, :collector_failed}

  defp default_collect do
    Exocomp.Node.Collectors.Ceph.collect()
  end

  defp build_artifact(observation) do
    serialized = observation_to_serializable(observation)

    artifact = %Artifact{
      artifactId: "profile-inspect-#{System.unique_integer([:positive, :monotonic])}",
      name: "profile-inspect",
      parts: [
        %DataPart{
          data: %{
            "schema_version" => "1",
            "skill" => @skill_id,
            "profile_id" => @profile_id,
            "profile_version" => @profile_version,
            "observations" => %{"ceph" => serialized}
          }
        }
      ]
    }

    artifact
  end

  defp observation_to_serializable(observation) when is_map(observation) do
    Map.new(observation, fn {key, value} -> {to_string(key), serialize_value(value)} end)
  end

  defp observation_to_serializable(other), do: %{"error" => inspect(other)}

  defp serialize_value(%{measurements: measurements} = observation) when is_map(measurements) do
    %{
      "observed_at" => observation[:observed_at] || observation["observed_at"],
      "source" => inspect(observation[:source] || observation["source"]),
      "collector_version" => observation[:collector_version] || observation["collector_version"],
      "duration_us" => observation[:duration_us] || observation["duration_us"],
      "measurements" =>
        Map.new(measurements, fn {key, value} -> {to_string(key), serialize_value(value)} end)
    }
  end

  defp serialize_value(%{value: value} = measurement) do
    %{
      "value" => serialize_value(value),
      "unit" => measurement[:unit] || measurement["unit"]
    }
  end

  defp serialize_value(%{error: error} = partial_error) do
    %{
      "error" => to_string(error),
      "reason" => partial_error[:reason] || partial_error["reason"]
    }
  end

  defp serialize_value(value) when is_list(value), do: Enum.map(value, &serialize_value/1)

  defp serialize_value(value) when is_map(value) do
    Map.new(value, fn {key, nested_value} -> {to_string(key), serialize_value(nested_value)} end)
  end

  defp serialize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp serialize_value(value), do: value
end
