defmodule Exocomp.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      elixir: "1.20.2",
      start_permanent: Mix.env() == :prod,
      deps: [],
      releases: releases()
    ]
  end

  defp releases do
    [
      exocomp_node: [
        applications: [
          exocomp_core: :permanent,
          exocomp_node: :permanent
        ],
        include_erts: true,
        include_executables_for: [:unix]
      ],
      exocomp_coordinator: [
        applications: [
          exocomp_core: :permanent,
          exocomp_coordinator: :permanent
        ],
        include_erts: true,
        include_executables_for: [:unix]
      ]
    ]
  end
end
