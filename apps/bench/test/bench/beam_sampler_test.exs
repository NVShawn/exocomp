defmodule Bench.BeamSamplerTest do
  use ExUnit.Case, async: false

  alias Bench.BeamSampler

  test "starts, flushes expected runtime metrics, and stops cleanly" do
    {:ok, sampler} = BeamSampler.start_link(interval: 60_000)
    samples = BeamSampler.flush(sampler)
    names = MapSet.new(samples, & &1.metric_name)

    assert "scheduler.utilization" in names
    assert "process.count" in names
    assert "run_queue.length" in names
    assert "memory.total.bytes" in names
    assert Enum.all?(samples, &(&1.source == :beam))

    monitor = Process.monitor(sampler)
    assert :ok = BeamSampler.stop(sampler)
    assert_receive {:DOWN, ^monitor, :process, ^sampler, :normal}
  end

  test "scheduler utilization is a ratio between zero and one" do
    {:ok, sampler} = BeamSampler.start_link(interval: 60_000)

    utilization =
      sampler
      |> BeamSampler.flush()
      |> sample!("scheduler.utilization")
      |> Map.fetch!(:value)

    assert is_float(utilization)
    assert utilization >= 0.0
    assert utilization <= 1.0
    assert :ok = BeamSampler.stop(sampler)
  end

  test "reports growth in a registered process mailbox" do
    name = unique_name("mailbox")

    mailbox =
      spawn(fn ->
        receive do
          :release -> :ok
        end
      end)

    Process.register(mailbox, name)

    on_exit(fn ->
      if Process.alive?(mailbox), do: send(mailbox, :release)
    end)

    {:ok, sampler} = BeamSampler.start_link(interval: 60_000, processes: [name])
    baseline = BeamSampler.flush(sampler) |> sample!("mailbox.#{name}.depth")

    send(mailbox, :one)
    send(mailbox, :two)
    send(mailbox, :three)

    loaded = BeamSampler.flush(sampler) |> sample!("mailbox.#{name}.depth")

    assert loaded.value == baseline.value + 3
    assert :ok = BeamSampler.stop(sampler)
  end

  test "reports the size of an accessible task registry" do
    registry = unique_name("registry")
    start_supervised!({Registry, keys: :unique, name: registry})
    assert {:ok, _owner} = Registry.register(registry, :task, nil)

    {:ok, sampler} = BeamSampler.start_link(interval: 60_000, task_registry: registry)

    registry_size =
      sampler
      |> BeamSampler.flush()
      |> sample!("task_registry.size")
      |> Map.fetch!(:value)

    assert registry_size == 1
    assert :ok = BeamSampler.stop(sampler)
  end

  test "polls repeatedly at the configured interval" do
    {:ok, sampler} = BeamSampler.start_link(interval: 5)
    Process.sleep(30)

    process_samples =
      sampler
      |> BeamSampler.flush()
      |> Enum.filter(&(&1.metric_name == "process.count"))

    assert length(process_samples) >= 2
    assert :ok = BeamSampler.stop(sampler)
  end

  test "rejects a non-positive sampling interval" do
    assert {:error, {:invalid_interval, 0}} = BeamSampler.start_link(interval: 0)
  end

  defp sample!(samples, name), do: Enum.find(samples, &(&1.metric_name == name))

  defp unique_name(prefix) do
    String.to_atom("#{prefix}_#{System.unique_integer([:positive])}")
  end
end
