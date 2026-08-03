# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.MixProject do
  use Mix.Project

  def project do
    [
      app: :exocomp_mission_control,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      start_apps_before_run: [:logger],
      elixirc_paths: elixirc_paths(Mix.env()),
      ecto_repos: [Exocomp.MissionControl.Repo],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Exocomp.MissionControl.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug_cowboy, "~> 2.7"},
      {:ecto_sql, "~> 3.14"},
      {:postgrex, "~> 0.22"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:oauth2, "~> 2.1"},
      {:httpoison, "~> 2.0"},
      {:jose, "~> 1.11"},
      {:x509, "~> 0.9.2"},
      {:exocomp_core, in_umbrella: true},
      {:plug, "~> 1.14"},
      {:bandit, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.seed": ["run", "priv/repo/seeds.exs"]
    ]
  end
end
