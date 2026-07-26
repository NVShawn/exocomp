# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.HostSamplerTest do
  use ExUnit.Case, async: false

  alias Bench.HostSampler

  @child_eventually_timeout_ms 30_000
  @delayed_readiness_ms 5_100

  setup do
    root =
      Path.join(System.tmp_dir!(), "host-sampler-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    %{root: root}
  end

  test "preserves target attribution and emits missing samples", %{root: root} do
    {:ok, sampler} =
      HostSampler.start_link(
        node: nil,
        coordinator: 99_999_999,
        llama: "not-a-pid",
        proc_root: root,
        interval: 60_000
      )

    samples = HostSampler.flush(sampler)
    assert MapSet.new(Enum.map(samples, & &1.source)) == MapSet.new([:node, :coordinator, :llama])
    assert length(samples) == 21
    assert Enum.all?(samples, &is_nil(&1.value))
    assert Enum.all?(samples, &(&1.tags == [:missing]))
    assert :ok = HostSampler.stop(sampler)
  end

  test "reads process metrics and calculates CPU usage between samples", %{root: root} do
    write_process(root, "123", cpu_ticks: 100, rss_kb: 10, pss_kb: 8)

    {:ok, sampler} =
      HostSampler.start_link(
        node: 123,
        proc_root: root,
        interval: 60_000,
        clock_ticks: 100
      )

    first = HostSampler.flush(sampler)
    assert sample(first, :node, "cpu.percent").tags == [:warming_up]
    assert sample(first, :node, "memory.rss.bytes").value == 10 * 1_024
    assert sample(first, :node, "memory.pss.bytes").value == 8 * 1_024
    assert sample(first, :node, "file_descriptors.open").value == 2
    assert sample(first, :node, "disk.io.bytes").value == 30
    assert sample(first, :node, "page_faults").value == 7

    Process.sleep(20)
    write_stat(root, "123", 120)

    second = HostSampler.flush(sampler)
    assert sample(second, :node, "cpu.percent").value > 0
    assert :ok = HostSampler.stop(sampler)
  end

  test "RSS reflects a later allocation and status is used when smaps is unavailable", %{
    root: root
  } do
    write_process(root, "456", cpu_ticks: 1, rss_kb: 4, pss_kb: 3)

    {:ok, sampler} =
      HostSampler.start_link(node: 456, proc_root: root, interval: 60_000)

    first = HostSampler.flush(sampler)
    assert sample(first, :node, "memory.rss.bytes").value == 4 * 1_024

    File.rm!(Path.join([root, "456", "smaps_rollup"]))
    File.write!(Path.join([root, "456", "status"]), "Name:\ttest\nVmRSS:\t64 kB\n")

    second = HostSampler.flush(sampler)
    assert sample(second, :node, "memory.rss.bytes").value == 64 * 1_024
    assert sample(second, :node, "memory.pss.bytes").tags == [:unavailable]
    assert :ok = HostSampler.stop(sampler)
  end

  test "reads optional cgroup v2 network accounting", %{root: root} do
    cgroup_root = Path.join(root, "cgroup")
    write_process(root, "789", cpu_ticks: 1, rss_kb: 4, pss_kb: 3)
    File.write!(Path.join([root, "789", "cgroup"]), "0::/bench/node\n")
    File.mkdir_p!(Path.join(cgroup_root, "bench/node"))

    File.write!(
      Path.join(cgroup_root, "bench/node/network.stat"),
      "rx_bytes 120\ntx_bytes 80\n"
    )

    {:ok, sampler} =
      HostSampler.start_link(
        node: 789,
        proc_root: root,
        cgroup_root: cgroup_root,
        interval: 60_000
      )

    samples = HostSampler.flush(sampler)
    assert sample(samples, :node, "network.io.bytes").value == 200
    assert :ok = HostSampler.stop(sampler)
  end

  @tag :linux
  @tag timeout: 120_000
  test "CPU and RSS increase under live synthetic load" do
    child =
      Port.open(
        {:spawn_executable, System.find_executable("elixir")},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          :use_stdio,
          {:line, 1_024},
          args: [
            "-e",
            """
            Process.sleep(#{@delayed_readiness_ms})
            IO.puts("ready")
            IO.read(:line)
            allocation = :binary.copy(<<1>>, 64 * 1_024 * 1_024)
            IO.puts("allocated \#{byte_size(allocation)}")
            burn = fn burn -> burn.(burn) end
            spawn(fn -> burn.(burn) end)
            Process.sleep(:infinity)
            """
          ]
        ]
      )

    on_exit(fn ->
      if Port.info(child), do: Port.close(child)
    end)

    assert :ok = await_port_line(child, "ready", @child_eventually_timeout_ms)
    {:os_pid, os_pid} = Port.info(child, :os_pid)

    {:ok, sampler} =
      HostSampler.start_link(node: os_pid, interval: 60_000)

    baseline = HostSampler.flush(sampler)
    baseline_rss = sample(baseline, :node, "memory.rss.bytes").value

    Port.command(child, "allocate\n")
    assert :ok = await_port_line(child, "allocated 67108864", @child_eventually_timeout_ms)

    assert {:ok, _loaded} =
             eventually_value(
               fn ->
                 samples = HostSampler.flush(sampler)
                 cpu = sample(samples, :node, "cpu.percent").value
                 rss = sample(samples, :node, "memory.rss.bytes").value

                 if is_number(cpu) and cpu > 0 and is_integer(rss) and rss > baseline_rss do
                   {:ok, samples}
                 else
                   :retry
                 end
               end,
               @child_eventually_timeout_ms
             )

    assert :ok = HostSampler.stop(sampler)
  end

  @tag :linux
  test "waiting for child readiness is bounded when readiness never occurs" do
    child =
      Port.open(
        {:spawn_executable, System.find_executable("elixir")},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          :use_stdio,
          {:line, 1_024},
          args: ["-e", "Process.sleep(:infinity)"]
        ]
      )

    on_exit(fn ->
      if Port.info(child), do: Port.close(child)
    end)

    assert {:error, :timeout} = await_port_line(child, "ready", 20)
  end

  defp sample(samples, source, name) do
    Enum.find(samples, &(&1.source == source and &1.metric_name == name))
  end

  defp await_port_line(port, expected, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    await_port_line_until(port, expected, deadline)
  end

  defp await_port_line_until(port, expected, deadline) do
    remaining = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, {:eol, ^expected}}} ->
        :ok

      {^port, {:data, _other}} ->
        await_port_line_until(port, expected, deadline)

      {^port, {:exit_status, status}} ->
        {:error, {:exit_status, status}}
    after
      remaining -> {:error, :timeout}
    end
  end

  defp eventually_value(observation, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    eventually_value_until(observation, deadline)
  end

  defp eventually_value_until(observation, deadline) do
    case observation.() do
      {:ok, _value} = success ->
        success

      :retry ->
        remaining = deadline - System.monotonic_time(:millisecond)

        if remaining > 0 do
          Process.sleep(min(20, remaining))
          eventually_value_until(observation, deadline)
        else
          {:error, :timeout}
        end
    end
  end

  defp write_process(root, pid, opts) do
    directory = Path.join(root, pid)
    File.mkdir_p!(Path.join(directory, "fd"))
    File.touch!(Path.join([directory, "fd", "0"]))
    File.touch!(Path.join([directory, "fd", "1"]))
    write_stat(root, pid, Keyword.fetch!(opts, :cpu_ticks))

    File.write!(
      Path.join(directory, "smaps_rollup"),
      "Rss:                #{Keyword.fetch!(opts, :rss_kb)} kB\n" <>
        "Pss:                 #{Keyword.fetch!(opts, :pss_kb)} kB\n"
    )

    File.write!(Path.join(directory, "io"), "read_bytes: 10\nwrite_bytes: 20\n")
  end

  defp write_stat(root, pid, cpu_ticks) do
    # Fields after comm begin with field 3. minflt=2, majflt=5, utime+stime=cpu_ticks.
    fields = ["R", "1", "1", "1", "1", "1", "1", "2", "0", "5", "0", "#{cpu_ticks}", "0"]

    File.write!(
      Path.join([root, pid, "stat"]),
      "#{pid} (test worker) #{Enum.join(fields, " ")}\n"
    )
  end
end
