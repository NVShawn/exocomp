# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MixProject do
  use Mix.Project

  def project do
    [
      app: :exocomp_coordinator,
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
      extra_applications: [:crypto, :inets, :logger, :public_key, :ssl],
      mod: {Exocomp.Coordinator.Application, []}
    ]
  end

  defp deps do
    [
      {:exocomp_core, in_umbrella: true},
      {:exocomp_node, in_umbrella: true, only: :test},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.0"},
      {:plug, "~> 1.17"},
      {:x509, "~> 0.9.2"}
    ]
  end
end
