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
>>>>>>> 5977f064 (EXOCOMP-150: persist and deliver cluster commands)
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.21"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.17"}
    ]
  end
end
