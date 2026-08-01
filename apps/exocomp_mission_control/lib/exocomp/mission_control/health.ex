# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Health do
  @moduledoc "Redacted liveness and readiness evaluation for Mission Control."

  alias Exocomp.MissionControl.{Database, Supervision}

  @check_names [:database, :migrations, :supervision]

  @type state :: :ok | :pending | :failed
  @type report :: %{
          status: :ok | :not_ready,
          ready?: boolean(),
          checks: %{database: state(), migrations: state(), supervision: state()}
        }

  @doc "Liveness is intentionally independent of the database and cluster fleet."
  @spec liveness() :: %{status: :ok}
  def liveness, do: %{status: :ok}

  @doc "Evaluates local database, migration, and supervision readiness checks."
  @spec evaluate(keyword()) :: report()
  def evaluate(opts \\ []) do
    checks = %{
      database: normalize_check(run_check(opts, :database, &Database.connection_check/1, opts)),
      migrations:
        normalize_check(run_check(opts, :migrations, &Database.migration_check/1, opts)),
      supervision:
        normalize_check(
          run_check(opts, :supervision, &Supervision.check/1, Supervision.configured_processes())
        )
    }

    ready? = Enum.all?(@check_names, &(Map.fetch!(checks, &1) == :ok))

    %{status: if(ready?, do: :ok, else: :not_ready), ready?: ready?, checks: checks}
  end

  @doc "Alias used by callers that treat readiness as a status operation."
  @spec status(keyword()) :: report()
  def status(opts \\ []), do: evaluate(opts)

  @doc "Returns only the readiness decision."
  @spec ready?(keyword()) :: boolean()
  def ready?(opts \\ []), do: evaluate(opts).ready?

  defp run_check(opts, key, default, argument) do
    case Keyword.get(opts, key) do
      function when is_function(function, 0) ->
        safely(function)

      function when is_function(function, 1) ->
        safely(fn -> function.(argument) end)

      nil ->
        check_key = String.to_atom("#{key}_check")

        case Keyword.get(
               opts,
               check_key,
               Application.get_env(:exocomp_mission_control, check_key)
             ) do
          function when is_function(function, 0) -> safely(function)
          function when is_function(function, 1) -> safely(fn -> function.(argument) end)
          nil -> safely(fn -> default.(argument) end)
        end
    end
  end

  defp normalize_check(:ok), do: :ok
  defp normalize_check(true), do: :ok
  defp normalize_check(:pending), do: :pending
  defp normalize_check({:pending, _reason}), do: :pending
  defp normalize_check({:ok, _value}), do: :ok
  defp normalize_check(_failure), do: :failed

  defp safely(function) do
    function.()
  rescue
    _error -> {:error, :check_failed}
  catch
    _kind, _reason -> {:error, :check_failed}
  end
end
