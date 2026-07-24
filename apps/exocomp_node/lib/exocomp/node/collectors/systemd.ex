defmodule Exocomp.Node.Collectors.Systemd do
  @moduledoc """
  Collector for systemd service state via `systemctl show`.

  ## Security model

  Only services on the explicit `allowed_services` list are queried. No
  caller input — not from a model, A2A request body, or configuration — ever
  becomes part of the argv list before passing through the allow-list check.

  `systemctl` is invoked with a fixed argv list:

  ```
  systemctl show --no-pager --property=<FIXED_PROPS> <allowed_service>
  ```

  **No shell is involved.** `System.cmd/3` is called directly with the
  executable and an argv list. `sh -c`, `bash -c`, and string interpolation
  into a shell command are explicitly forbidden in this module.

  ## Output limits and timeout

  Output is capped at `@max_output_bytes`. The subprocess is given
  `@timeout_ms` to complete; if it hangs the task is killed and a
  `:timeout` partial error is returned for that service.

  ## Collector version history

  - 1: Initial release — per-service ActiveState, SubState, LoadState,
       UnitFileState, ExecMainPID, ExecMainStatus.
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__

  # Fixed property list — never interpolated from external input.
  @properties ~w[
    ActiveState
    SubState
    LoadState
    UnitFileState
    ExecMainPID
    ExecMainStatus
  ]

  @property_flag "--property=#{Enum.join(@properties, ",")}"

  @timeout_ms 5_000
  @max_output_bytes 65_536

  @doc """
  Collect systemd service states for all entries in `allowed_services`.

  Returns one group of measurements per service (prefixed by service name
  with dots and hyphens replaced by underscores).

  Options:
  - `:allowed_services` — list of service unit names to query, e.g.
    `["sshd.service", "nginx.service"]`. Only these names are ever used.
    Defaults to `[]` (no services queried).
  - `:timeout_ms` — override the per-service subprocess timeout in
    milliseconds. Defaults to #{@timeout_ms}.
  - `:cmd_runner` — MFA `{mod, fun, extra_args}` for running external
    commands, injected for testing. The function receives
    `(cmd, args, cmd_opts)` and returns `{output, exit_code}`.
    Defaults to `System.cmd/3`.
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) do
    started_at = System.monotonic_time(:microsecond)
    allowed_services = Keyword.get(opts, :allowed_services, [])
    timeout_ms = Keyword.get(opts, :timeout_ms, @timeout_ms)
    cmd_runner = Keyword.get(opts, :cmd_runner, {__MODULE__, :default_cmd_runner, []})

    measurements =
      allowed_services
      |> Enum.flat_map(fn service ->
        collect_service(service, timeout_ms, cmd_runner)
      end)
      |> Map.new()

    Types.build(@source, @collector_version, started_at, measurements)
  end

  @doc false
  def default_cmd_runner(cmd, args, cmd_opts) do
    System.cmd(cmd, args, cmd_opts)
  end

  # ---------------------------------------------------------------------------
  # Per-service collection
  # ---------------------------------------------------------------------------

  # Returns a list of {atom_key, measurement} pairs for one service.
  defp collect_service(service, timeout_ms, cmd_runner) do
    key_prefix = service_to_key(service)

    result =
      run_systemctl(service, timeout_ms, cmd_runner)

    case result do
      {:ok, props} ->
        Enum.map(@properties, fn prop ->
          atom_key = :"#{key_prefix}_#{String.downcase(prop)}"

          measurement =
            case Map.fetch(props, prop) do
              {:ok, value} -> Types.ok(value, "string")
              :error -> Types.err(:unavailable, "#{prop} not in systemctl output for #{service}")
            end

          {atom_key, measurement}
        end)

      {:error, kind, reason} ->
        Enum.map(@properties, fn prop ->
          atom_key = :"#{key_prefix}_#{String.downcase(prop)}"
          {atom_key, Types.err(kind, reason)}
        end)
    end
  end

  # ---------------------------------------------------------------------------
  # systemctl invocation
  # ---------------------------------------------------------------------------

  defp run_systemctl(service, timeout_ms, {mod, fun, extra_args}) do
    # argv list — no shell, no interpolation of external input into a shell string
    cmd = "systemctl"
    args = ["show", "--no-pager", @property_flag, service]
    cmd_opts = [stderr_to_stdout: true]

    task =
      Task.async(fn ->
        apply(mod, fun, [cmd, args, cmd_opts] ++ extra_args)
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        cond do
          byte_size(output) > @max_output_bytes ->
            {:error, :output_limit,
             "systemctl output for #{service} exceeded #{@max_output_bytes} bytes"}

          true ->
            parse_systemctl_output(output, service)
        end

      {:ok, {_output, exit_code}} ->
        {:error, :unavailable, "systemctl exited #{exit_code} for #{service}"}

      nil ->
        {:error, :timeout, "systemctl timed out after #{timeout_ms}ms for #{service}"}
    end
  end

  # ---------------------------------------------------------------------------
  # Output parsing
  # ---------------------------------------------------------------------------

  defp parse_systemctl_output(output, service) do
    if String.trim(output) == "" do
      {:error, :unavailable, "systemctl returned empty output for #{service}"}
    else
      props =
        output
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn line, acc ->
          case String.split(line, "=", parts: 2) do
            [key, value] -> Map.put(acc, String.trim(key), String.trim(value))
            _ -> acc
          end
        end)

      {:ok, props}
    end
  end

  # ---------------------------------------------------------------------------
  # Key helpers
  # ---------------------------------------------------------------------------

  # Converts a service unit name to a safe atom key prefix.
  # "sshd.service" -> "sshd_service"
  # "my-cool.service" -> "my_cool_service"
  defp service_to_key(service) do
    service
    |> String.replace(".", "_")
    |> String.replace("-", "_")
    |> String.replace(~r/[^a-zA-Z0-9_]/, "")
  end
end
