defmodule Exocomp.Node.ListenerTest do
  # async: false because tests bind TCP ports.
  use ExUnit.Case, async: false

  alias Exocomp.Node.Listener

  # Resolve the fixtures directory at compile time.
  # File: apps/exocomp_node/test/exocomp/node/listener_test.exs
  # fixtures/ is two directories up from exocomp/node/
  @fixtures_dir Path.expand("../../fixtures", __DIR__)
  @certs_dir Path.join(@fixtures_dir, "certs")

  # The port range used by listener tests.  Each test is assigned a unique
  # port from this range to avoid PORT_IN_USE races between sequential tests
  # and any lingering TIME_WAIT connections.
  #
  # We start at 18433 to avoid colliding with the config_valid.json port (4433).
  @base_port 18_433

  # A monotonically-increasing counter for port allocation per test.
  # ExUnit runs these tests sequentially (async: false), so a simple
  # counter works.
  def alloc_port(offset), do: @base_port + offset

  # ── Helpers ───────────────────────────────────────────────────────────────────

  # Copy a key to a temp file with the given mode.
  defp tmp_key_with_mode(source, mode) do
    tmp = Path.join(System.tmp_dir!(), "listener_test_key_#{:rand.uniform(9_999_999)}.key")
    File.cp!(source, tmp)
    File.chmod!(tmp, mode)
    tmp
  end

  # Write a temporary JSON config file with absolute cert paths.
  defp write_temp_config(opts) do
    config = %{
      "version" => 1,
      "node_id" => Keyword.get(opts, :node_id, "exocomp-test-node"),
      "tls" => %{
        "ca_cert" => Keyword.get(opts, :ca, Path.join(@certs_dir, "ca.crt")),
        "node_cert" => Keyword.get(opts, :cert, Path.join(@certs_dir, "node.crt")),
        "node_key" => Keyword.get(opts, :key, Path.join(@certs_dir, "node.key"))
      },
      "listen" => %{
        "host" => "127.0.0.1",
        "port" => Keyword.fetch!(opts, :port)
      }
    }

    path =
      Path.join(System.tmp_dir!(), "listener_test_cfg_#{:rand.uniform(9_999_999)}.json")

    File.write!(path, Jason.encode!(config))
    path
  end

  # Try a plain TCP connect to verify the port is open (does not perform TLS).
  defp port_open?(port) do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [], 2_000) do
      {:ok, sock} ->
        :gen_tcp.close(sock)
        true

      {:error, _} ->
        false
    end
  end

  # ── 1. Valid config + valid identity ─────────────────────────────────────────

  test "valid config and identity: starts, port is open" do
    port = alloc_port(0)
    key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o600)
    on_exit(fn -> File.rm(key) end)

    cfg_path = write_temp_config(port: port, key: key)
    on_exit(fn -> File.rm(cfg_path) end)

    pid = start_supervised!({Listener, config_path: cfg_path})
    assert is_pid(pid)

    # Allow the server a moment to bind.
    Process.sleep(50)
    assert port_open?(port), "Expected port #{port} to be open after Listener start"
  end

  # ── 2. Missing config file ────────────────────────────────────────────────────

  test "missing config file: process fails to start" do
    assert_raise(RuntimeError, fn ->
      start_supervised!({Listener, config_path: "/nonexistent/no_such_config.json"})
    end)
  end

  # ── 3. Malformed config ───────────────────────────────────────────────────────

  test "malformed config JSON: process fails to start" do
    path = Path.join(@fixtures_dir, "config_malformed.json")

    assert_raise(RuntimeError, fn ->
      start_supervised!({Listener, config_path: path})
    end)
  end

  # ── 4. Unknown config version ─────────────────────────────────────────────────

  test "unknown config version: process fails to start" do
    path = Path.join(@fixtures_dir, "config_unknown_version.json")

    assert_raise(RuntimeError, fn ->
      start_supervised!({Listener, config_path: path})
    end)
  end

  # ── 5. Key with bad permissions ───────────────────────────────────────────────

  test "key file with 0o644 permissions: process fails to start" do
    port = alloc_port(1)
    key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o644)
    on_exit(fn -> File.rm(key) end)

    cfg_path = write_temp_config(port: port, key: key)
    on_exit(fn -> File.rm(cfg_path) end)

    assert_raise(RuntimeError, fn ->
      start_supervised!({Listener, config_path: cfg_path})
    end)
  end

  # ── 6. Invalid cert chain (rogue CA) ─────────────────────────────────────────

  test "cert signed by rogue CA: process fails to start" do
    port = alloc_port(2)
    # Use the rogue key (matched to the rogue cert) at 0o600.
    rogue_key = tmp_key_with_mode(Path.join(@certs_dir, "rogue.key"), 0o600)
    on_exit(fn -> File.rm(rogue_key) end)

    cfg_path =
      write_temp_config(
        port: port,
        cert: Path.join(@certs_dir, "rogue.crt"),
        key: rogue_key,
        ca: Path.join(@certs_dir, "ca.crt")
      )

    on_exit(fn -> File.rm(cfg_path) end)

    assert_raise(RuntimeError, fn ->
      start_supervised!({Listener, config_path: cfg_path})
    end)
  end

  # ── 7. Wrong SAN ─────────────────────────────────────────────────────────────

  test "cert SAN does not match node_id: process fails to start" do
    port = alloc_port(3)
    wrong_key = tmp_key_with_mode(Path.join(@certs_dir, "wrong_san.key"), 0o600)
    on_exit(fn -> File.rm(wrong_key) end)

    cfg_path =
      write_temp_config(
        port: port,
        cert: Path.join(@certs_dir, "wrong_san.crt"),
        key: wrong_key,
        ca: Path.join(@certs_dir, "ca.crt"),
        node_id: "exocomp-test-node"
      )

    on_exit(fn -> File.rm(cfg_path) end)

    assert_raise(RuntimeError, fn ->
      start_supervised!({Listener, config_path: cfg_path})
    end)
  end

  # ── 8. Reload: valid → valid ──────────────────────────────────────────────────

  test "reload with same valid config succeeds and port remains open" do
    port = alloc_port(4)
    key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o600)
    on_exit(fn -> File.rm(key) end)

    cfg_path = write_temp_config(port: port, key: key)
    on_exit(fn -> File.rm(cfg_path) end)

    pid = start_supervised!({Listener, config_path: cfg_path})
    Process.sleep(50)
    assert port_open?(port)

    assert :ok = GenServer.call(pid, :reload)
    Process.sleep(50)
    assert port_open?(port), "Port should still be open after successful reload"
  end

  # ── 9. Reload with bad config: returns error, listener goes down ───────────────

  test "reload with missing config file returns error and listener stops" do
    port = alloc_port(5)
    key = tmp_key_with_mode(Path.join(@certs_dir, "node.key"), 0o600)
    on_exit(fn -> File.rm(key) end)

    # Start with a valid config that we will then delete to simulate a bad reload.
    cfg_path = write_temp_config(port: port, key: key)

    pid = start_supervised!({Listener, config_path: cfg_path})
    Process.sleep(50)
    assert port_open?(port)

    # Monitor the listener so we can wait for it to exit after the reload failure.
    ref = Process.monitor(pid)

    # Delete the config file so the reload fails.
    File.rm!(cfg_path)

    result = GenServer.call(pid, :reload)
    assert {:error, _reason} = result

    # Listener should stop after a failed reload.
    assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 2_000
  end
end
