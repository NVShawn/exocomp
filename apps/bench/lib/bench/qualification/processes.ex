# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.Processes do
  @moduledoc """
  Starts and identifies the shipped processes sampled by an M5 run.

  Short mode owns direct release processes. Full mode preserves the initial
  state of installed systemd units and stops only units it started.
  """

  alias Bench.{ArtifactIdentity, Qualification.Config}

  @units ["exocomp-coordinator.service", "exocomp-node.service"]
  @ready_timeout_ms 30_000

  @enforce_keys [
    :node_pid,
    :coordinator_pid,
    :llama_pid,
    :llama_url,
    :ports,
    :services_started,
    :temporary_paths
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  @doc "Starts the real release processes appropriate for the configured mode."
  @spec start(Config.t(), ArtifactIdentity.t()) :: {:ok, t()} | {:error, term()}
  def start(%Config{mode: :short} = config, %ArtifactIdentity{} = identity) do
    start_short(config, identity)
  end

  def start(%Config{mode: :full} = config, %ArtifactIdentity{} = identity) do
    start_full(config, identity)
  end

  @doc "Restores owned process and service state. Safe to call repeatedly."
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{} = processes) do
    Enum.each(processes.ports, &terminate_owned_process/1)

    processes.services_started
    |> Enum.reverse()
    |> Enum.each(fn unit ->
      case systemctl(["stop", unit]) do
        {:ok, _output} ->
          :ok

        {:error, reason} ->
          IO.puts(:stderr, "M5 cleanup warning: could not stop #{unit}: #{inspect(reason)}")
      end
    end)

    Enum.each(processes.temporary_paths, &File.rm/1)
    :ok
  end

  defp start_short(config, identity) do
    marker_root =
      Path.join(
        System.tmp_dir!(),
        "exocomp-m5-#{System.unique_integer([:positive, :monotonic])}"
      )

    coordinator_marker = marker_root <> "-coordinator.ready"
    node_marker = marker_root <> "-node.ready"

    temporary_paths = [node_marker, coordinator_marker, node_marker <> ".dets"]

    result =
      case start_direct_release(
             config.coordinator_release,
             "exocomp_coordinator",
             coordinator_marker
           ) do
        {:ok, coordinator_port, coordinator_pid} ->
          continue_short_after_coordinator(
            config,
            identity,
            coordinator_port,
            coordinator_pid,
            node_marker,
            temporary_paths
          )

        {:error, reason, ports} ->
          short_start_error(reason, ports, temporary_paths)

        {:error, reason} ->
          short_start_error(reason, [], temporary_paths)
      end

    result
  end

  defp start_full(config, identity) do
    case start_service("exocomp-coordinator.service") do
      {:ok, coordinator_pid, coordinator_started} ->
        started =
          if coordinator_started, do: ["exocomp-coordinator.service"], else: []

        continue_full_after_coordinator(config, identity, coordinator_pid, started)

      {:error, reason, started} ->
        full_start_error(reason, started, [])
    end
  end

  defp continue_short_after_coordinator(
         config,
         identity,
         coordinator_port,
         coordinator_pid,
         node_marker,
         temporary_paths
       ) do
    case executable_within(coordinator_pid, config.coordinator_release, :coordinator) do
      :ok ->
        case start_direct_release(config.node_release, "exocomp_node", node_marker) do
          {:ok, node_port, node_pid} ->
            continue_short_after_node(
              config,
              identity,
              coordinator_port,
              coordinator_pid,
              node_port,
              node_pid,
              temporary_paths
            )

          {:error, reason, ports} ->
            short_start_error(reason, ports ++ [coordinator_port], temporary_paths)

          {:error, reason} ->
            short_start_error(reason, [coordinator_port], temporary_paths)
        end

      {:error, reason} ->
        short_start_error(reason, [coordinator_port], temporary_paths)
    end
  end

  defp continue_short_after_node(
         config,
         identity,
         coordinator_port,
         coordinator_pid,
         node_port,
         node_pid,
         temporary_paths
       ) do
    case executable_within(node_pid, config.node_release, :node) do
      :ok ->
        case start_llama(config, identity) do
          {:ok, llama_port, llama_pid} ->
            {:ok,
             %__MODULE__{
               node_pid: node_pid,
               coordinator_pid: coordinator_pid,
               llama_pid: llama_pid,
               llama_url: "http://127.0.0.1:#{config.llama_port}",
               ports: [llama_port, node_port, coordinator_port],
               services_started: [],
               temporary_paths: temporary_paths
             }}

          {:error, reason, ports} ->
            short_start_error(
              reason,
              ports ++ [node_port, coordinator_port],
              temporary_paths
            )

          {:error, reason} ->
            short_start_error(reason, [node_port, coordinator_port], temporary_paths)
        end

      {:error, reason} ->
        short_start_error(reason, [node_port, coordinator_port], temporary_paths)
    end
  end

  defp short_start_error(reason, ports, temporary_paths) do
    Enum.each(ports, &terminate_owned_process/1)
    Enum.each(temporary_paths, &File.rm/1)
    {:error, reason}
  end

  defp continue_full_after_coordinator(config, identity, coordinator_pid, started) do
    case executable_within(coordinator_pid, config.coordinator_release, :coordinator) do
      :ok ->
        case start_service("exocomp-node.service") do
          {:ok, node_pid, node_started} ->
            started =
              if node_started, do: started ++ ["exocomp-node.service"], else: started

            continue_full_after_node(
              config,
              identity,
              coordinator_pid,
              node_pid,
              started
            )

          {:error, reason, newly_started} ->
            full_start_error(reason, started ++ newly_started, [])
        end

      {:error, reason} ->
        full_start_error(reason, started, [])
    end
  end

  defp continue_full_after_node(
         config,
         identity,
         coordinator_pid,
         node_pid,
         started
       ) do
    case executable_within(node_pid, config.node_release, :node) do
      :ok ->
        case start_llama(config, identity) do
          {:ok, llama_port, llama_pid} ->
            {:ok,
             %__MODULE__{
               node_pid: node_pid,
               coordinator_pid: coordinator_pid,
               llama_pid: llama_pid,
               llama_url: "http://127.0.0.1:#{config.llama_port}",
               ports: [llama_port],
               services_started: started,
               temporary_paths: []
             }}

          {:error, reason, ports} ->
            full_start_error(reason, started, ports)

          {:error, reason} ->
            full_start_error(reason, started, [])
        end

      {:error, reason} ->
        full_start_error(reason, started, [])
    end
  end

  defp full_start_error(reason, started_units, ports) do
    Enum.each(ports, &terminate_owned_process/1)

    started_units
    |> Enum.reverse()
    |> Enum.each(&systemctl(["stop", &1]))

    {:error, reason}
  end

  defp start_direct_release(release, product, marker) do
    executable = Path.join([release, "bin", product])

    if File.regular?(executable) do
      code = release_eval(product)

      case open_port(executable, ["eval", code], [{"BENCH_READY_FILE", marker}]) do
        {:ok, port, pid} ->
          case await_file(marker, port, @ready_timeout_ms) do
            :ok -> {:ok, port, pid}
            {:error, reason} -> {:error, {:release_start_failed, product, reason}, [port]}
          end

        {:error, reason} ->
          {:error, {:release_start_failed, product, reason}}
      end
    else
      {:error, {:release_executable_not_found, executable}}
    end
  end

  defp release_eval("exocomp_coordinator") do
    """
    Application.put_env(:exocomp_coordinator, :require_pki, false)
    case Application.ensure_all_started(:exocomp_coordinator) do
      {:ok, _} ->
        File.write!(System.fetch_env!("BENCH_READY_FILE"), "ready")
        Process.sleep(:infinity)
      {:error, reason} ->
        IO.puts(:stderr, "coordinator start failed: \#{inspect(reason)}")
        System.halt(1)
    end
    """
  end

  defp release_eval("exocomp_node") do
    """
    Application.put_env(
      :exocomp_node,
      :replay_ledger_path,
      System.fetch_env!("BENCH_READY_FILE") <> ".dets"
    )
    case Application.ensure_all_started(:exocomp_node) do
      {:ok, _} ->
        File.write!(System.fetch_env!("BENCH_READY_FILE"), "ready")
        Process.sleep(:infinity)
      {:error, reason} ->
        IO.puts(:stderr, "node start failed: \#{inspect(reason)}")
        System.halt(1)
    end
    """
  end

  defp start_llama(config, identity) do
    with :ok <- port_available(config.llama_port),
         {:ok, port, pid} <-
           open_port(
             config.llama_server,
             [
               "--model",
               config.model_path,
               "--host",
               "127.0.0.1",
               "--port",
               Integer.to_string(config.llama_port)
             ],
             [{"LD_LIBRARY_PATH", config.llama_lib_dir}]
           ),
         :ok <- await_executable(pid, identity.llama_server_path, port, 5_000) do
      {:ok, port, pid}
    else
      {:error, reason, port} ->
        {:error, {:llama_start_failed, reason}, [port]}

      {:error, reason} ->
        {:error, {:llama_start_failed, reason}}
    end
  end

  defp start_service(unit) when unit in @units do
    initially_active = service_active?(unit)

    with :ok <- maybe_start_service(unit, initially_active),
         :ok <- await_service(unit, 60_000),
         {:ok, pid} <- service_pid(unit) do
      {:ok, pid, not initially_active}
    else
      {:error, reason} ->
        started = if initially_active, do: [], else: [unit]
        {:error, {:systemd_service_failed, unit, reason}, started}
    end
  end

  defp maybe_start_service(_unit, true), do: :ok

  defp maybe_start_service(unit, false) do
    case systemctl(["start", unit]) do
      {:ok, _output} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp service_active?(unit) do
    match?({:ok, _}, systemctl(["is-active", "--quiet", unit]))
  end

  defp await_service(unit, timeout_ms) do
    await_until(
      fn -> service_active?(unit) end,
      timeout_ms,
      {:service_readiness_timeout, unit}
    )
  end

  defp service_pid(unit) do
    case systemctl(["show", "--property", "MainPID", "--value", unit]) do
      {:ok, output} ->
        case Integer.parse(String.trim(output)) do
          {pid, ""} when pid > 0 -> {:ok, pid}
          _ -> {:error, {:invalid_main_pid, output}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp systemctl(args) do
    case System.cmd("systemctl", args, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, status} -> {:error, {:exit_status, status, String.trim(output)}}
    end
  rescue
    error -> {:error, {:systemctl_unavailable, Exception.message(error)}}
  end

  defp open_port(executable, args, environment) do
    caller = self()
    token = make_ref()

    {owner, monitor} =
      spawn_monitor(fn ->
        own_port(caller, token, executable, args, environment)
      end)

    receive do
      {^token, {:ok, pid}} ->
        Process.demonitor(monitor, [:flush])
        {:ok, owner, pid}

      {^token, {:error, reason}} ->
        Process.demonitor(monitor, [:flush])
        {:error, reason}

      {:DOWN, ^monitor, :process, ^owner, reason} ->
        {:error, {:port_owner_exited, reason}}
    after
      5_000 ->
        Process.exit(owner, :kill)
        Process.demonitor(monitor, [:flush])
        {:error, :port_owner_start_timeout}
    end
  end

  defp own_port(caller, token, executable, args, environment) do
    port =
      Port.open(
        {:spawn_executable, String.to_charlist(executable)},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          :use_stdio,
          args: Enum.map(args, &String.to_charlist/1),
          env:
            Enum.map(environment, fn {name, value} ->
              {String.to_charlist(name), String.to_charlist(value)}
            end)
        ]
      )

    case Port.info(port, :os_pid) do
      {:os_pid, pid} ->
        send(caller, {token, {:ok, pid}})
        port_owner_loop(port)

      _ ->
        Port.close(port)
        send(caller, {token, {:error, :os_pid_unavailable}})
    end
  rescue
    error -> send(caller, {token, {:error, {:port_open_failed, Exception.message(error)}}})
  end

  defp port_owner_loop(port) do
    receive do
      {^port, {:data, _output}} ->
        port_owner_loop(port)

      {^port, {:exit_status, _status}} ->
        :ok

      {:terminate, caller} ->
        terminate_external_port(port)
        send(caller, {:terminated, self()})
    end
  end

  defp await_file(path, owner, timeout_ms) do
    await_until(
      fn ->
        cond do
          File.regular?(path) -> true
          not Process.alive?(owner) -> {:error, :process_exited}
          true -> false
        end
      end,
      timeout_ms,
      :readiness_timeout
    )
  end

  defp await_executable(pid, expected, owner, timeout_ms) do
    case await_until(
           fn ->
             cond do
               not Process.alive?(owner) ->
                 {:error, :process_exited}

               true ->
                 case process_executable(pid) do
                   {:ok, actual} -> canonical_equal?(actual, expected)
                   _ -> false
                 end
             end
           end,
           timeout_ms,
           {:executable_identity_timeout, expected}
         ) do
      :ok -> :ok
      {:error, reason} -> {:error, reason, owner}
    end
  end

  defp executable_within(pid, release, component) do
    with {:ok, executable} <- process_executable(pid),
         {:ok, release_path} <- canonical_path(release) do
      prefix = String.trim_trailing(release_path, "/") <> "/"

      if String.starts_with?(executable, prefix) do
        :ok
      else
        {:error, {:artifact_process_mismatch, component, executable, release_path}}
      end
    end
  end

  defp process_executable(pid) do
    canonical_path("/proc/#{pid}/exe")
  end

  defp canonical_equal?(left, right) do
    with {:ok, canonical_left} <- canonical_path(left),
         {:ok, canonical_right} <- canonical_path(right) do
      canonical_left == canonical_right
    else
      _ -> false
    end
  end

  defp canonical_path(path) do
    case System.cmd("readlink", ["-f", path], stderr_to_stdout: true) do
      {output, 0} ->
        canonical = String.trim(output)
        if canonical == "", do: {:error, {:canonical_path, path}}, else: {:ok, canonical}

      {output, status} ->
        {:error, {:canonical_path, path, status, String.trim(output)}}
    end
  rescue
    error -> {:error, {:canonical_path, path, Exception.message(error)}}
  end

  defp port_available(port_number) do
    case :gen_tcp.connect(~c"127.0.0.1", port_number, [:binary, active: false], 100) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        {:error, {:llama_port_in_use, port_number}}

      {:error, _reason} ->
        :ok
    end
  end

  defp await_until(check, timeout_ms, timeout_reason) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_await_until(check, deadline, timeout_reason)
  end

  defp do_await_until(check, deadline, timeout_reason) do
    case check.() do
      true ->
        :ok

      {:error, reason} ->
        {:error, reason}

      false ->
        remaining = deadline - System.monotonic_time(:millisecond)

        if remaining > 0 do
          Process.sleep(min(100, remaining))
          do_await_until(check, deadline, timeout_reason)
        else
          {:error, timeout_reason}
        end
    end
  end

  defp terminate_owned_process(owner) when is_pid(owner) do
    if Process.alive?(owner) do
      monitor = Process.monitor(owner)
      send(owner, {:terminate, self()})

      receive do
        {:terminated, ^owner} ->
          receive do
            {:DOWN, ^monitor, :process, ^owner, _reason} -> :ok
          after
            1_000 -> Process.demonitor(monitor, [:flush])
          end

        {:DOWN, ^monitor, :process, ^owner, _reason} ->
          :ok
      after
        7_000 ->
          Process.exit(owner, :kill)

          receive do
            {:DOWN, ^monitor, :process, ^owner, _reason} -> :ok
          after
            1_000 -> Process.demonitor(monitor, [:flush])
          end
      end
    end

    :ok
  end

  defp terminate_external_port(port) when is_port(port) do
    case Port.info(port, :os_pid) do
      {:os_pid, pid} ->
        if Port.info(port) do
          _ = signal_process(pid, "TERM")

          if await_port_exit(port, 5_000) == :timeout and Port.info(port) do
            _ = signal_process(pid, "KILL")
            _ = await_port_exit(port, 1_000)
          end
        end

      _ ->
        :ok
    end

    if Port.info(port), do: Port.close(port)
    :ok
  rescue
    _ -> :ok
  end

  # The pinned builder and minimized release guests provide POSIX sh but do not
  # necessarily install the procps `kill` executable. Invoke the shell builtin
  # with the validated integer PID as a positional parameter.
  defp signal_process(pid, signal) when is_integer(pid) and signal in ["TERM", "KILL"] do
    System.cmd(
      "sh",
      ["-c", "kill -#{signal} \"$1\"", "m5-kill", Integer.to_string(pid)],
      stderr_to_stdout: true
    )
  end

  defp await_port_exit(port, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_await_port_exit(port, deadline)
  end

  defp do_await_port_exit(port, deadline) do
    remaining = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, _output}} ->
        do_await_port_exit(port, deadline)

      {^port, {:exit_status, _status}} ->
        :ok
    after
      remaining -> :timeout
    end
  end
end
