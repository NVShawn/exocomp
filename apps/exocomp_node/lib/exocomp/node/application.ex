defmodule Exocomp.Node.Application do
  @moduledoc false

  use Application

  require Logger

  # Capture the Mix env at compile time so the release binary behaves correctly
  # without Mix being available at runtime.
  @env Mix.env()

  @impl true
  def start(_type, _args) do
    children = build_children()
    Supervisor.start_link(children, strategy: :one_for_one, name: Exocomp.Node.Supervisor)
  end

  # Only add the Listener to the supervision tree in production.  In test and
  # dev modes, tests start the Listener directly via `start_supervised!/1`.
  defp build_children do
    if @env == :prod do
      case System.get_env("EXOCOMP_CONFIG_FILE") do
        nil ->
          Logger.error(
            "[Node.Application] EXOCOMP_CONFIG_FILE is not set; " <>
              "the listener will not start. " <>
              "Set the environment variable and restart the release."
          )

          []

        config_path ->
          [{Exocomp.Node.Listener, config_path: config_path}]
      end
    else
      []
    end
  end
end
