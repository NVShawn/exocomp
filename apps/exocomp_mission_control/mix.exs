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
      elixir: "1.20.2",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :logger],
      mod: {Exocomp.MissionControl.Application, []}
    ]
  end

  defp deps do
    [
      {:exocomp_core, in_umbrella: true},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.7"},
      {:bandit, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:oauth2, "~> 2.1"},
      {:httpoison, "~> 2.0"},
      {:jose, "~> 1.11"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      {:gettext, "~> 0.24"}
    ]
  end
end
