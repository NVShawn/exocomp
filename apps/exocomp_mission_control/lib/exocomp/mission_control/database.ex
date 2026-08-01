# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Database do
  @moduledoc """
  Small, dependency-neutral boundary for database readiness checks.

  Keeping the query and migration functions injectable makes the readiness
  endpoint useful before a database is available and keeps its tests entirely
  offline. The production defaults use the configured Ecto repository when
  one is present.
  """

  @type check_result :: :ok | :pending | {:error, term()}

  @doc "Checks that the configured repository accepts a trivial query."
  @spec connection_check(keyword()) :: check_result()
  def connection_check(opts \\ []) do
    query_fn = Keyword.get(opts, :query_fn, &default_query/0)

    case safely(query_fn) do
      {:ok, _result} -> :ok
      :ok -> :ok
      {:error, _reason} -> {:error, :database_unavailable}
      _other -> {:error, :database_unavailable}
    end
  end

  @doc "Checks whether the configured migration set has unapplied migrations."
  @spec migration_check(keyword()) :: check_result()
  def migration_check(opts \\ []) do
    migration_fn = Keyword.get(opts, :migration_fn, &default_migrations/0)

    case safely(migration_fn) do
      :ok -> :ok
      {:ok, :ok} -> :ok
      {:ok, false} -> :ok
      {:ok, true} -> :pending
      :pending -> :pending
      {:pending, _reason} -> :pending
      {:error, _reason} -> {:error, :migration_check_failed}
      _other -> {:error, :migration_check_failed}
    end
  end

  defp default_query do
    case Application.get_env(:exocomp_mission_control, :repo) do
      nil ->
        if Mix.env() == :test, do: :ok, else: {:error, :database_not_configured}

      repo ->
        apply(repo, :query, ["SELECT 1", []])
    end
  end

  defp default_migrations do
    case Application.get_env(:exocomp_mission_control, :repo) do
      nil ->
        if Mix.env() == :test, do: :ok, else: {:error, :database_not_configured}

      repo ->
        path =
          Application.get_env(
            :exocomp_mission_control,
            :migration_path,
            Path.join(Application.app_dir(:exocomp_mission_control), "priv/repo/migrations")
          )

        if Code.ensure_loaded?(Ecto.Migrator) do
          migrations = apply(Module.concat(Ecto, Migrator), :migrations, [repo, path])

          if Enum.any?(migrations, fn {status, _version, _name} -> status == :down end) do
            :pending
          else
            :ok
          end
        else
          {:error, :migration_support_unavailable}
        end
    end
  end

  defp safely(function) do
    function.()
  rescue
    _error -> {:error, :check_failed}
  catch
    _kind, _reason -> {:error, :check_failed}
  end
end
