# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "1.18.3",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :logger, :inets, :public_key],
      mod: {Bench.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"}
    ]
  end

  defp releases do
    [
      bench_harness: [
        applications: [bench: :permanent],
        include_erts: true,
        include_executables_for: [:unix]
      ]
    ]
  end
end
