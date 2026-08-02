# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ProfileAction do
  @moduledoc "Typed A2A entry point for shipped profile actions."

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.ProfileActionCatalog

  @allowed_keys MapSet.new(["profile_id", "profile_version", "action_id", "target_unit"])

  @impl true
  def execute(params, context) when is_map(params) do
    with :ok <- validate_params(params),
         {:ok, request} <- build_request(params),
         {:ok, result} <- ProfileActionCatalog.execute(request, execution_opts()) do
      {:ok, artifact(result, context)}
    end
  end

  def execute(_params, _context), do: {:error, :invalid_params}

  defp validate_params(params) do
    keys = params |> Map.keys() |> MapSet.new()

    if MapSet.equal?(keys, @allowed_keys), do: :ok, else: {:error, :invalid_params}
  end

  defp build_request(params) do
    with {:ok, profile_id} <- nonempty(params, "profile_id"),
         {:ok, profile_version} <- positive_integer(params, "profile_version"),
         {:ok, action_id} <- nonempty(params, "action_id"),
         {:ok, target_unit} <- nonempty(params, "target_unit") do
      {:ok,
       %{
         profile_id: profile_id,
         profile_version: profile_version,
         action_id: action_id,
         target_unit: target_unit
       }}
    end
  end

  defp nonempty(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {:invalid_field, key}}
    end
  end

  defp positive_integer(params, key) do
    case Map.get(params, key) do
      value when is_integer(value) and value > 0 ->
        {:ok, value}

      value when is_binary(value) ->
        case Integer.parse(value) do
          {parsed, ""} when parsed > 0 -> {:ok, parsed}
          _ -> {:error, {:invalid_field, key}}
        end

      _ ->
        {:error, {:invalid_field, key}}
    end
  end

  defp execution_opts do
    case Application.get_env(:exocomp_node, :profile_action_lock_server) do
      nil -> []
      server -> [lock_server: server]
    end
  end

  defp artifact(result, context) do
    %Artifact{
      artifactId: "profile-action-#{System.unique_integer([:positive, :monotonic])}",
      name: "profile-action",
      parts: [
        %DataPart{
          data: %{
            "schema_version" => "1",
            "skill" => "exocomp.profile.action",
            "action_id" => "restart_failed_daemon",
            "target_unit" => result.target_unit,
            "status" => result.status,
            "correlation_id" => context_value(context, :correlation_id)
          }
        }
      ]
    }
  end

  defp context_value(context, key) when is_map(context),
    do: Map.get(context, key) || Map.get(context, Atom.to_string(key))

  defp context_value(_context, _key), do: nil
end
