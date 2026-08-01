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
<<<<<<< HEAD
      deps: deps()
=======
      deps: []
>>>>>>> epic-EXOCOMP-132--task-EXOCOMP-158
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
      {:jason, "~> 1.4"}
    ]
  end
end
