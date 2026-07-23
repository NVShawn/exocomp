defmodule Exocomp.Node.Collectors.SystemdTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.Systemd

  # ---------------------------------------------------------------------------
  # Stub runner helpers
  #
  # The collector dispatches via: apply(mod, fun, [cmd, args, cmd_opts] ++ extra_args)
  # so public helpers must receive (cmd, args, opts, <extra_args...>).
  # ---------------------------------------------------------------------------

  # Fixed-response runner.
  # MFA extra_args = [output, exit_code] → called as stub_runner(cmd, args, opts, output, exit_code)
  def stub_runner(_cmd, _args, _opts, output, exit_code), do: {output, exit_code}

  defp make_runner(output, exit_code \\ 0) do
    {__MODULE__, :stub_runner, [output, exit_code]}
  end

  # Proxy runner: delegates to an anonymous function f/3 that receives (cmd, args, opts).
  # MFA extra_args = [f] → called as call_fn(cmd, args, opts, f)
  def call_fn(cmd, args, opts, f), do: f.(cmd, args, opts)

  # ---------------------------------------------------------------------------
  # Fixtures
  # ---------------------------------------------------------------------------

  defp valid_systemctl_output(state \\ "active") do
    """
    ActiveState=#{state}
    SubState=running
    LoadState=loaded
    UnitFileState=enabled
    ExecMainPID=12345
    ExecMainStatus=0
    """
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "collect/1 with no allowed services" do
    test "returns empty measurements and correct envelope" do
      obs = Systemd.collect(allowed_services: [], cmd_runner: make_runner("", 0))

      assert obs.measurements == %{}
      assert obs.source == Exocomp.Node.Collectors.Systemd
      assert obs.collector_version >= 1
      assert is_binary(obs.observed_at)
    end
  end

  describe "collect/1 with valid service output" do
    test "returns observation envelope" do
      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: make_runner(valid_systemctl_output())
        )

      assert is_binary(obs.observed_at)
      assert obs.source == Exocomp.Node.Collectors.Systemd
    end

    test "measurement keys are prefixed with service name (dots/hyphens as underscores)" do
      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: make_runner(valid_systemctl_output())
        )

      m = obs.measurements

      assert Map.has_key?(m, :sshd_service_activestate)
      assert Map.has_key?(m, :sshd_service_substate)
      assert Map.has_key?(m, :sshd_service_loadstate)
      assert Map.has_key?(m, :sshd_service_unitfilestate)
      assert Map.has_key?(m, :sshd_service_execmainpid)
      assert Map.has_key?(m, :sshd_service_execmainstatus)
    end

    test "values are strings with unit 'string'" do
      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: make_runner(valid_systemctl_output())
        )

      m = obs.measurements

      assert m.sshd_service_activestate.value == "active"
      assert m.sshd_service_activestate.unit == "string"
      assert m.sshd_service_substate.value == "running"
      assert m.sshd_service_loadstate.value == "loaded"
      assert m.sshd_service_unitfilestate.value == "enabled"
    end
  end

  describe "collect/1 with a service in various states" do
    for state <- ~w[inactive failed activating deactivating] do
      test "captures state '#{state}' correctly" do
        obs =
          Systemd.collect(
            allowed_services: ["nginx.service"],
            cmd_runner: make_runner(valid_systemctl_output(unquote(state)))
          )

        assert obs.measurements.nginx_service_activestate.value == unquote(state)
      end
    end
  end

  describe "collect/1 with service name containing hyphens" do
    test "hyphens in service name become underscores in measurement keys" do
      obs =
        Systemd.collect(
          allowed_services: ["my-cool-service.service"],
          cmd_runner: make_runner(valid_systemctl_output())
        )

      assert Map.has_key?(obs.measurements, :my_cool_service_service_activestate)
    end
  end

  describe "collect/1 multiple services — partial independence" do
    test "error on second service does not corrupt first service measurements" do
      call_counter = :counters.new(1, [])

      runner = fn _cmd, _args, _opts ->
        n = :counters.get(call_counter, 1)
        :counters.add(call_counter, 1, 1)

        if n == 0 do
          {valid_systemctl_output(), 0}
        else
          {"", 1}
        end
      end

      obs =
        Systemd.collect(
          allowed_services: ["sshd.service", "nginx.service"],
          cmd_runner: {__MODULE__, :call_fn, [runner]}
        )

      # sshd succeeded
      assert obs.measurements.sshd_service_activestate.value == "active"

      # nginx failed (non-zero exit code)
      assert obs.measurements.nginx_service_activestate.error == :unavailable
    end
  end

  describe "collect/1 when systemctl times out" do
    test "all property measurements for that service return :timeout error" do
      slow_runner = fn _cmd, _args, _opts ->
        Process.sleep(30_000)
        {"", 0}
      end

      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          timeout_ms: 50,
          cmd_runner: {__MODULE__, :call_fn, [slow_runner]}
        )

      assert obs.measurements.sshd_service_activestate.error == :timeout
      assert obs.measurements.sshd_service_substate.error == :timeout
      assert obs.measurements.sshd_service_execmainpid.error == :timeout
    end
  end

  describe "collect/1 when systemctl exits non-zero" do
    test "all property measurements return :unavailable error" do
      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: make_runner("Failed to connect to bus: No such file or directory", 1)
        )

      for {_k, v} <- obs.measurements do
        assert v.error == :unavailable
      end
    end
  end

  describe "collect/1 with empty output" do
    test "measurements return :unavailable error" do
      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: make_runner("   \n  \n")
        )

      assert obs.measurements.sshd_service_activestate.error == :unavailable
    end
  end

  describe "collect/1 with oversized output" do
    test "measurements return :output_limit error" do
      # > 65 536 bytes
      big_output = String.duplicate("ActiveState=active\n", 4000)

      obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: make_runner(big_output)
        )

      assert obs.measurements.sshd_service_activestate.error == :output_limit
    end
  end

  describe "security: allow-list enforcement" do
    test "cmd_runner is never called when allowed_services is empty" do
      test_pid = self()

      tracking_runner = fn _cmd, _args, _opts ->
        send(test_pid, :cmd_runner_called)
        {"", 0}
      end

      _obs =
        Systemd.collect(
          allowed_services: [],
          cmd_runner: {__MODULE__, :call_fn, [tracking_runner]}
        )

      refute_receive :cmd_runner_called, 100
    end

    test "the argv list passed to the runner contains only the allowed service name — no shell" do
      test_pid = self()

      capturing_runner = fn _cmd, args, _opts ->
        send(test_pid, {:captured_args, args})
        {valid_systemctl_output(), 0}
      end

      _obs =
        Systemd.collect(
          allowed_services: ["sshd.service"],
          cmd_runner: {__MODULE__, :call_fn, [capturing_runner]}
        )

      assert_receive {:captured_args, args}, 1000

      # The service name appears as a plain argument — not interpolated into a shell string.
      assert List.last(args) == "sshd.service"

      # No shell injection vectors in any argv element.
      for arg <- args do
        refute String.contains?(arg, ";"),
               "shell metachar ';' found in argv: #{inspect(arg)}"

        refute String.contains?(arg, "|"),
               "shell metachar '|' found in argv: #{inspect(arg)}"

        refute String.contains?(arg, "`"),
               "shell metachar '`' found in argv: #{inspect(arg)}"

        refute arg == "-c", "shell '-c' flag found in argv"
        refute arg == "sh", "'sh' found as argv element"
        refute arg == "bash", "'bash' found as argv element"
      end
    end
  end
end
