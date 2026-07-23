defmodule Exocomp.Node.MixProject do
  use Mix.Project

  def project do
    [
      app: :exocomp_node,
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
      extra_applications: [:logger, :inets],
      mod: {Exocomp.Node.Application, []}
    ]
  end

  defp deps do
    [
      {:exocomp_core, in_umbrella: true},
      {:jason, "~> 1.4"}
    ]
  end
end
