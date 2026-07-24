defmodule Exocomp.Node.Application do
  @moduledoc false

  use Application

  require Logger

  # Capture the Mix env at compile time so the release binary behaves correctly
  # without Mix being available at runtime.
  @env Mix.env()

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: Exocomp.Node.Supervisor)
  end

  defp children do
    llama_server_children() ++ listener_children()
  end

  defp llama_server_children do
    case Application.get_env(:exocomp_node, :llama_server_path) do
      path when is_binary(path) and path != "" -> [Exocomp.Node.LlamaServer]
      _other -> []
    end
  end

  defp listener_children when @env != :prod, do: []

  defp listener_children do
    case System.get_env("EXOCOMP_CONFIG_FILE") do
      nil ->
        Logger.error(
          "[Node.Application] EXOCOMP_CONFIG_FILE is not set; " <>
            "the listener will not start. Set the environment variable and restart the release."
        )

        []

      config_path ->
        [{Exocomp.Node.Listener, config_path: config_path}]
    end
  end
end
