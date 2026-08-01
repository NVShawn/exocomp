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
      {:phoenix, "~> 1.7.18"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:bandit, "~> 1.0"},
      {:ecto_sql, "~> 3.14"},
      {:postgrex, "~> 0.22"},
      {:jason, "~> 1.4"}
    ]
  end
end
