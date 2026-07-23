defmodule Exocomp.Node.LlamaServerTest do
  use ExUnit.Case, async: false

  alias Exocomp.Node.LlamaServer

  defmodule TestSupervisor do
    use Supervisor

    def start_link(child), do: Supervisor.start_link(__MODULE__, child)

    @impl true
    def init(child), do: Supervisor.init([child], strategy: :one_for_one)
  end

  test "starts under a one-for-one supervisor and remains starting before readiness" do
    supervisor =
      start_supervised!(
        {TestSupervisor,
         {LlamaServer,
          llama_server_path: fixture_path("llama-server-stub"),
          llama_model_path: "/tmp/model.gguf",
          llama_host: "0.0.0.0",
          llama_port: 18_080,
          llama_ready_timeout_ms: 1_000}}
      )

    assert is_pid(supervisor)
    assert LlamaServer.status() == :starting
    assert LlamaServer.base_url() == {:error, :not_ready}

    state = :sys.get_state(LlamaServer)
    assert state.host == "127.0.0.1"
    assert Process.alive?(Process.whereis(LlamaServer))
  end

  test "a nonexistent executable degrades without crashing its supervisor" do
    supervisor =
      start_supervised!(
        {TestSupervisor,
         {LlamaServer,
          llama_server_path: "/definitely/not/a/llama-server",
          llama_port: 18_081,
          llama_ready_timeout_ms: 10}}
      )

    assert eventually(fn -> LlamaServer.status() == :degraded end)
    assert Process.alive?(supervisor)
    assert Process.alive?(Process.whereis(LlamaServer))
    assert :sys.get_state(LlamaServer).restart_count >= 1
  end

  test "reports stopped when no server is running" do
    assert LlamaServer.status() == :stopped
    assert LlamaServer.base_url() == {:error, :not_ready}
  end

  defp fixture_path(name), do: Path.expand("../../fixtures/#{name}", __DIR__)

  defp eventually(fun, attempts \\ 50)
  defp eventually(_fun, 0), do: false

  defp eventually(fun, attempts) do
    if fun.() do
      true
    else
      Process.sleep(10)
      eventually(fun, attempts - 1)
    end
  end
end
