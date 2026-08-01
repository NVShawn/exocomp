# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
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
    releases = [
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

    # Mission Control is introduced by the Milestone 7 application task. Keep
    # the release contract in the root project now, but do not make the
    # pre-Mission-Control checkout uncompilable while that application is
    # still being integrated.
    if File.dir?("apps/exocomp_mission_control") do
      Keyword.put(releases, :mission_control,
        applications: [
          exocomp_core: :permanent,
          exocomp_mission_control: :permanent
        ],
        include_erts: true,
        include_executables_for: [:unix]
      )
    else
      releases
    end
  end
end
