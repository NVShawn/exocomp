defmodule Exocomp.Node.Skills.ServiceDiagnose do
  @moduledoc """
  Skill handler for `exocomp.service.diagnose`.

  Validates the incoming service list against the configured allow-list,
  then delegates to `Exocomp.Node.Collectors.Systemd` for collection.

  ## Configuration

  - `:allowed_services` (Application config, `:exocomp_node`) —
    list of permitted service unit names, e.g. `["sshd.service"]`.
    Defaults to `[]`. Requests for services outside this list are rejected.
  - `:service_diagnose_timeout_ms` (Application config, `:exocomp_node`) —
    total collection timeout in milliseconds (default 10_000).
  - `:service_diagnose_systemd_collector` (Application config, `:exocomp_node`) —
    1-arity function `fn allowed_services -> observation end` injected for tests.

  ## Params

    %{"services" => ["sshd.service", "nginx.service"]}

  ## Errors

  - `{:error, :invalid_params}` — empty service list, or any requested
    service not in the configured allow-list.
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @default_timeout_ms 10_000

  @impl true
  def execute(%{"services" => services} = _params, _context) when is_list(services) do
    with :ok <- validate_services(services) do
      collect_and_build(services)
    end
  end

  def execute(_params, _context) do
    {:error, :invalid_params}
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  defp validate_services([]) do
    {:error, :invalid_params}
  end

  defp validate_services(services) do
    allowed = Application.get_env(:exocomp_node, :allowed_services, [])

    case Enum.reject(services, &(&1 in allowed)) do
      [] -> :ok
      _disallowed -> {:error, :invalid_params}
    end
  end

  # ---------------------------------------------------------------------------
  # Collection
  # ---------------------------------------------------------------------------

  defp collect_and_build(services) do
    timeout_ms =
      Application.get_env(:exocomp_node, :service_diagnose_timeout_ms, @default_timeout_ms)

    collector =
      Application.get_env(
        :exocomp_node,
        :service_diagnose_systemd_collector,
        &default_collect/1
      )

    task = Task.async(fn -> collector.(services) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, observation} ->
        build_artifact(observation)

      nil ->
        {:error, :timeout}
    end
  end

  defp default_collect(services) do
    Exocomp.Node.Collectors.Systemd.collect(allowed_services: services)
  end

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(observation) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.service.diagnose",
      "observations" => %{
        "services" => observation_to_serializable(observation)
      }
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "service-diagnose",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp observation_to_serializable(obs) when is_map(obs) do
    Map.new(obs, fn {k, v} -> {to_string(k), v} end)
  end

  defp observation_to_serializable(other), do: %{"error" => inspect(other)}

  defp generate_artifact_id do
    "service-diagnose-#{System.unique_integer([:positive, :monotonic])}"
  end
end
