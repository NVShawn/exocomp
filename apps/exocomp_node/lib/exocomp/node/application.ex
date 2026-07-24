defmodule Exocomp.Node.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: Exocomp.Node.Supervisor)
  end

  defp children do
    llama_server_children =
      case Application.get_env(:exocomp_node, :llama_server_path) do
        path when is_binary(path) and path != "" -> [Exocomp.Node.LlamaServer]
        _other -> []
      end

    [Exocomp.Node.TaskRegistry | llama_server_children]
  end
end
