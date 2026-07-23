defmodule Bench.HostSamplerTest do
  use ExUnit.Case, async: false

  alias Bench.HostSampler

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
  test "CPU and RSS increase under live synthetic load" do
    child =
      Port.open(
        {:spawn_executable, System.find_executable("elixir")},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          :use_stdio,
          args: [
            "-e",
            """
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

    assert_receive {^child, {:data, "ready\n"}}, 5_000
    {:os_pid, os_pid} = Port.info(child, :os_pid)

    {:ok, sampler} =
      HostSampler.start_link(node: os_pid, interval: 60_000)

    baseline = HostSampler.flush(sampler)
    baseline_rss = sample(baseline, :node, "memory.rss.bytes").value

    Port.command(child, "allocate\n")
    assert_receive {^child, {:data, "allocated 67108864\n"}}, 5_000
    Process.sleep(200)

    loaded = HostSampler.flush(sampler)

    assert sample(loaded, :node, "cpu.percent").value > 0
    assert sample(loaded, :node, "memory.rss.bytes").value > baseline_rss
    assert :ok = HostSampler.stop(sampler)
  end

  defp sample(samples, source, name) do
    Enum.find(samples, &(&1.source == source and &1.metric_name == name))
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
