defmodule Exocomp.Coordinator.RegistryTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{Inventory, Registry}

  setup do
    json =
      :json.encode(%{
        "version" => 1,
        "nodes" => [
          %{
            "id" => "node-a",
            "hostname" => "node-a.example.test",
            "port" => 8443,
            "certificate_identity" => "spiffe://node/node-a",
            "capabilities" => [],
            "labels" => %{}
          }
        ]
      })

    :ok = Inventory.replace_json(IO.iodata_to_binary(json))
    :ok
  end

  test "gets and updates bounded live node state" do
    assert {:ok, %{id: "node-a", reachability: :unknown}} = Registry.get("node-a")
    assert :ok = Registry.update("node-a", %{reachability: :healthy, consecutive_failures: 0})
    assert {:ok, %{reachability: :healthy}} = Registry.get("node-a")
    assert {:error, :invalid_state} = Registry.update("node-a", %{reachability: :missing})
    assert {:error, :not_found} = Registry.update("missing", %{reachability: :healthy})
    assert :error = Registry.get("missing")
  end

  test "reconstructs configured nodes after registry restart" do
    previous = Process.whereis(Registry)
    reference = Process.monitor(previous)
    Process.exit(previous, :kill)
    assert_receive {:DOWN, ^reference, :process, ^previous, :killed}

    restarted = wait_for_restart(previous)
    assert is_pid(restarted)
    assert {:ok, %{id: "node-a", reachability: :unknown}} = wait_for_node()
  end

  defp wait_for_restart(previous, attempts \\ 50)

  defp wait_for_restart(_previous, 0), do: nil

  defp wait_for_restart(previous, attempts) do
    case Process.whereis(Registry) do
      pid when is_pid(pid) and pid != previous ->
        pid

      _other ->
        Process.sleep(10)
        wait_for_restart(previous, attempts - 1)
    end
  end

  defp wait_for_node(attempts \\ 50)
  defp wait_for_node(0), do: Registry.get("node-a")

  defp wait_for_node(attempts) do
    case Registry.get("node-a") do
      {:ok, _entry} = found ->
        found

      :error ->
        Process.sleep(10)
        wait_for_node(attempts - 1)
    end
  end
end
