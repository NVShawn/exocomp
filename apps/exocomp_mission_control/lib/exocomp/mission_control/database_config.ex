# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DatabaseConfig do
  @moduledoc "Builds Mission Control database settings from runtime environment."

  @type env_getter :: (String.t() -> String.t() | nil)

  @doc """
  Returns a local development or test repository configuration.

  `DATABASE_URL` takes precedence when present. Otherwise the standard `PG*`
  variables are used. The fallback intentionally contains no password, so a
  local PostgreSQL installation can use peer or other operator-managed auth.
  """
  @spec local_repo_config(atom() | String.t(), env_getter()) :: keyword()
  def local_repo_config(environment, get_env \\ &System.get_env/1)
      when is_atom(environment) or is_binary(environment) do
    case non_blank(get_env.("DATABASE_URL")) do
      nil ->
        [
          database: "exocomp_mission_control_#{environment}",
          hostname: get_env.("PGHOST") || "localhost",
          port: parse_port(get_env.("PGPORT")),
          username: get_env.("PGUSER") || "postgres"
        ]
        |> maybe_put_password(get_env.("PGPASSWORD"))

      database_url ->
        [url: database_url]
    end
  end

  @doc """
  Returns the production repository configuration.

  Production credentials must be supplied through `DATABASE_URL` by the
  deployment secret store. The URL is returned to Ecto but is never included
  in an error message.
  """
  @spec production_repo_config!(env_getter()) :: keyword()
  def production_repo_config!(get_env \\ &System.get_env/1) do
    case non_blank(get_env.("DATABASE_URL")) do
      nil ->
        raise RuntimeError,
              "Mission Control production database is not configured; " <>
                "set DATABASE_URL from the deployment secret store before starting."

      database_url ->
        [url: database_url]
    end
  end

  defp non_blank(value) when is_binary(value) do
    if String.trim(value) == "", do: nil, else: value
  end

  defp non_blank(_value), do: nil

  defp parse_port(nil), do: 5432

  defp parse_port(port) when is_binary(port) do
    case Integer.parse(port) do
      {port, ""} when port in 1..65_535 -> port
      _ -> 5432
    end
  end

  defp parse_port(_port), do: 5432

  defp maybe_put_password(config, password) do
    case non_blank(password) do
      nil -> config
      password -> Keyword.put(config, :password, password)
    end
  end
end
