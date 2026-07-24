defmodule Exocomp.Node.Skills.SystemDiagnose do
  @moduledoc """
  Skill handler for `exocomp.system.diagnose`.

  Concurrently collects CPU, Memory, Disk, and Uptime observations, then
  packages them into an A2A Artifact. Partial collector failures are
  included as structured error maps rather than propagated as exceptions.

  ## Configuration

  - `:system_diagnose_timeout_ms` (Application config, `:exocomp_node`) —
    total collection timeout in milliseconds (default 10_000).
  - `:system_diagnose_collectors` (Application config, `:exocomp_node`) —
    map of collector overrides for testing:
    `%{cpu: fn -> ... end, memory: fn -> ... end, disk: fn -> ... end, uptime: fn -> ... end}`
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @default_timeout_ms 10_000

  @collector_names [:cpu, :memory, :disk, :uptime]

  @impl true
  def execute(_params, _context) do
    timeout_ms =
      Application.get_env(:exocomp_node, :system_diagnose_timeout_ms, @default_timeout_ms)

    collectors = Application.get_env(:exocomp_node, :system_diagnose_collectors, %{})

    fns = %{
      cpu: Map.get(collectors, :cpu, &default_cpu/0),
      memory: Map.get(collectors, :memory, &default_memory/0),
      disk: Map.get(collectors, :disk, &default_disk/0),
      uptime: Map.get(collectors, :uptime, &default_uptime/0)
    }

    # Wrap each collector in a rescue so that exceptions become {:error, reason}
    # values instead of EXIT signals that would kill the calling process.
    tasks =
      Map.new(@collector_names, fn name ->
        fun = Map.fetch!(fns, name)

        task =
          Task.async(fn ->
            try do
              {:ok, fun.()}
            rescue
              e -> {:error, Exception.message(e)}
            catch
              kind, reason -> {:error, {kind, reason}}
            end
          end)

        {name, task}
      end)

    task_list = Enum.map(@collector_names, fn name -> tasks[name] end)

    # Task.yield_many returns [{task, result_or_nil}] without crashing the caller.
    yields = Task.yield_many(task_list, timeout: timeout_ms)

    # Shut down tasks that did not complete within the timeout.
    Enum.each(yields, fn {task, result} ->
      if result == nil, do: Task.shutdown(task, :brutal_kill)
    end)

    # Check for any nil result (timed-out task).
    has_timeout = Enum.any?(yields, fn {_task, result} -> result == nil end)

    if has_timeout do
      {:error, :timeout}
    else
      indexed = Enum.zip(@collector_names, yields)

      observations =
        Map.new(indexed, fn {name, {_task, yield_result}} ->
          value =
            case yield_result do
              {:ok, {:ok, obs}} -> obs
              {:ok, {:error, reason}} -> {:error, reason}
              {:exit, reason} -> {:error, reason}
            end

          {name, value}
        end)

      build_artifact(observations)
    end
  end

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(observations) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.system.diagnose",
      "observations" => %{
        "cpu" => observation_to_serializable(observations[:cpu]),
        "memory" => observation_to_serializable(observations[:memory]),
        "disk" => observation_to_serializable(observations[:disk]),
        "uptime" => observation_to_serializable(observations[:uptime])
      }
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "system-diagnose",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  # Convert an observation or error into a JSON-serializable map.
  defp observation_to_serializable({:error, reason}) do
    %{"error" => inspect(reason)}
  end

  defp observation_to_serializable(obs) when is_map(obs) do
    Map.new(obs, fn {k, v} ->
      {to_string(k), serialize_value(v)}
    end)
  end

  defp observation_to_serializable(other) do
    %{"error" => inspect(other)}
  end

  defp serialize_value(%{measurements: measurements} = obs) when is_map(measurements) do
    %{
      "observed_at" => obs[:observed_at] || obs["observed_at"],
      "source" => inspect(obs[:source] || obs["source"]),
      "collector_version" => obs[:collector_version] || obs["collector_version"],
      "duration_us" => obs[:duration_us] || obs["duration_us"],
      "measurements" => Map.new(measurements, fn {k, v} -> {to_string(k), v} end)
    }
  end

  defp serialize_value(%{value: _value} = m), do: m
  defp serialize_value(%{error: _} = e), do: e
  defp serialize_value(v), do: v

  # ---------------------------------------------------------------------------
  # Default collector functions
  # ---------------------------------------------------------------------------

  defp default_cpu, do: Exocomp.Node.Collectors.CPU.collect()
  defp default_memory, do: Exocomp.Node.Collectors.Memory.collect()
  defp default_disk, do: Exocomp.Node.Collectors.Disk.collect()
  defp default_uptime, do: Exocomp.Node.Collectors.Uptime.collect()

  defp generate_artifact_id do
    "system-diagnose-#{System.unique_integer([:positive, :monotonic])}"
  end
end
