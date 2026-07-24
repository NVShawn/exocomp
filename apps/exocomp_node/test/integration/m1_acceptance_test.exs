defmodule Exocomp.Integration.M1AcceptanceTest do
  @moduledoc """
  M1 milestone acceptance integration tests.

  These tests start a live Bandit mTLS HTTPS listener with fixture certificates
  and exercise every M1-CRIT-* acceptance criterion through real SSL connections
  and A2A 1.0 protocol exchanges.

  ## M1-CRIT coverage

  | Criterion | Coverage                                                        |
  |-----------|------------------------------------------------------------------|
  | M1-CRIT-1 | Verified by `make build`, `make test`, `make lint`, `make fmt-check` quality gates. |
  | M1-CRIT-2 | Verified by `scripts/smoke-releases.sh` (run inside `make test`). |
  | M1-CRIT-3 | `test/3*` — authenticated client retrieves Agent Card + diagnostic artifact. |
  | M1-CRIT-4 | Unit tests in `test/exocomp/node/collectors/` (cpu, memory, disk, uptime, systemd). |
  | M1-CRIT-5 | `test/5*` — llama.cpp unavailability fails the task; node stays up. |
  | M1-CRIT-6 | `test/6*` — unauthenticated connections are rejected; bad-key/bad-chain prevents start. |
  | M1-CRIT-7 | `test/7*` — host state snapshot taken before/after node exercise. |

  ## Running

      MIX_ENV=test mix test apps/exocomp_node/test/integration/m1_acceptance_test.exs

  These tests do NOT require systemd or root access.  They run inside the
  standard CI builder container alongside `make test`.  Tags: `:m1_acceptance`.
  """

  use ExUnit.Case, async: false

  @moduletag :m1_acceptance

  alias Exocomp.Node.Listener

  # File: apps/exocomp_node/test/integration/m1_acceptance_test.exs
  # fixtures/ is one directory up from integration/ (at test/fixtures/).
  @fixtures_dir Path.expand("../fixtures", __DIR__)
  @certs_dir Path.join(@fixtures_dir, "certs")
  @ca_cert Path.join(@certs_dir, "ca.crt")
  @node_cert Path.join(@certs_dir, "node.crt")
  @node_key_src Path.join(@certs_dir, "node.key")

  # Port range: start above listener_test.exs (18433..18438) and
  # proposal_client_test.exs (19999) to avoid collisions.
  @base_port 19_200

  # ── Setup helpers ─────────────────────────────────────────────────────────────

  # Copy the fixture key to a temp path with 0o600 permissions.
  defp tmp_key do
    path =
      Path.join(
        System.tmp_dir!(),
        "m1_acceptance_key_#{System.unique_integer([:positive])}.key"
      )

    File.cp!(@node_key_src, path)
    File.chmod!(path, 0o600)
    on_exit(fn -> File.rm(path) end)
    path
  end

  # Write a temporary JSON config file pointing at the fixture certs.
  defp write_config(port) do
    key = tmp_key()

    cfg = %{
      "version" => 1,
      "node_id" => "exocomp-test-node",
      "tls" => %{
        "ca_cert" => @ca_cert,
        "node_cert" => @node_cert,
        "node_key" => key
      },
      "listen" => %{"host" => "127.0.0.1", "port" => port}
    }

    path =
      Path.join(
        System.tmp_dir!(),
        "m1_acceptance_cfg_#{System.unique_integer([:positive])}.json"
      )

    File.write!(path, Jason.encode!(cfg))
    on_exit(fn -> File.rm(path) end)
    path
  end

  # Start the Listener on `port` and wait for it to accept connections.
  defp start_listener!(port) do
    cfg_path = write_config(port)
    _pid = start_supervised!({Listener, config_path: cfg_path})

    # Poll until the port is reachable (max 2 s).
    assert wait_for_port(port, 2_000),
           "Listener did not open port #{port} within 2000 ms"
  end

  # Install fake collectors so exocomp.system.diagnose works in tests that
  # don't have real /proc data.
  defp install_fake_collectors do
    fake = fn source ->
      %{
        observed_at: DateTime.to_iso8601(DateTime.utc_now()),
        source: source,
        collector_version: 1,
        duration_us: 50,
        measurements: %{m1_test_value: %{value: 1, unit: "units"}}
      }
    end

    Application.put_env(:exocomp_node, :system_diagnose_collectors, %{
      cpu: fn -> fake.(Exocomp.Node.Collectors.CPU) end,
      memory: fn -> fake.(Exocomp.Node.Collectors.Memory) end,
      disk: fn -> fake.(Exocomp.Node.Collectors.Disk) end,
      uptime: fn -> fake.(Exocomp.Node.Collectors.Uptime) end
    })

    on_exit(fn -> Application.delete_env(:exocomp_node, :system_diagnose_collectors) end)
  end

  # ── HTTP-over-mTLS client ─────────────────────────────────────────────────────

  # SSL options shared by all client connections (verify server cert).
  defp client_ssl_opts do
    [
      :binary,
      active: false,
      verify: :verify_peer,
      cacertfile: String.to_charlist(@ca_cert),
      versions: [:"tlsv1.3"],
      server_name_indication: ~c"exocomp-test-node"
    ]
  end

  # mTLS opts: also send the test node cert as the client cert.
  defp mtls_ssl_opts do
    client_ssl_opts() ++
      [
        certfile: String.to_charlist(@node_cert),
        keyfile: String.to_charlist(@node_key_src)
      ]
  end

  # Make a GET request over mTLS.
  defp mtls_get(port, path) do
    mtls_request(port, "GET", path, [], nil)
  end

  # Make a POST request over mTLS.
  defp mtls_post(port, path, json_body) when is_binary(json_body) do
    mtls_request(port, "POST", path, [{"content-type", "application/json"}], json_body)
  end

  # Make an mTLS HTTPS request; return `{:ok, status_code, body}` or `{:error, reason}`.
  defp mtls_request(port, method, path, extra_headers, body) do
    ssl_request(port, method, path, extra_headers, body, mtls_ssl_opts())
  end

  # Try an HTTPS connection WITHOUT a client certificate.
  # Returns `{:rejected, reason}` when the TLS handshake or HTTP layer
  # blocks unauthenticated access.
  defp unauthenticated_request(port, path) do
    case ssl_request(port, "GET", path, [], nil, client_ssl_opts()) do
      {:ok, status, body} -> {:ok, status, body}
      {:error, reason} -> {:rejected, reason}
    end
  end

  # Low-level: open an SSL socket, send an HTTP/1.1 request, read the response.
  defp ssl_request(port, method, path, extra_headers, body, ssl_opts) do
    case :ssl.connect({127, 0, 0, 1}, port, ssl_opts, 5_000) do
      {:ok, sock} ->
        result = send_and_recv(sock, method, path, extra_headers, body)
        :ssl.close(sock)
        result

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_and_recv(sock, method, path, extra_headers, body) do
    default_headers = [
      {"host", "exocomp-test-node"},
      {"a2a-version", "1.0"},
      {"connection", "close"}
    ]

    all_headers = default_headers ++ extra_headers

    header_str =
      Enum.map_join(all_headers, "\r\n", fn {k, v} -> "#{k}: #{v}" end)

    request =
      if body && body != "" do
        "#{method} #{path} HTTP/1.1\r\n" <>
          "#{header_str}\r\n" <>
          "content-length: #{byte_size(body)}\r\n\r\n" <>
          body
      else
        "#{method} #{path} HTTP/1.1\r\n#{header_str}\r\n\r\n"
      end

    case :ssl.send(sock, request) do
      :ok ->
        case recv_full(sock, "") do
          {:ok, data} -> parse_response(data)
          err -> err
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Read from the SSL socket until the connection closes (triggered by
  # `Connection: close` in the request).
  defp recv_full(sock, acc) do
    case :ssl.recv(sock, 0, 5_000) do
      {:ok, chunk} ->
        recv_full(sock, acc <> chunk)

      {:error, :closed} ->
        {:ok, acc}

      # Connection reset — treat any accumulated data as the response.
      {:error, reason} when acc != "" ->
        _ = reason
        {:ok, acc}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse an HTTP/1.1 response into {status_code, body}.
  defp parse_response(data) do
    case String.split(data, "\r\n\r\n", parts: 2) do
      [head, body] ->
        status =
          head
          |> String.split("\r\n")
          |> hd()
          |> parse_status_line()

        {:ok, status, body}

      _ ->
        {:error, :malformed_response}
    end
  end

  defp parse_status_line(line) do
    case String.split(line, " ", parts: 3) do
      [_ver, code | _] -> String.to_integer(code)
      _ -> 0
    end
  end

  # ── Port availability helpers ─────────────────────────────────────────────────

  defp port_open?(port) do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [], 500) do
      {:ok, sock} ->
        :gen_tcp.close(sock)
        true

      {:error, _} ->
        false
    end
  end

  defp wait_for_port(port, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_port(port, deadline)
  end

  defp poll_port(port, deadline) do
    if port_open?(port) do
      true
    else
      remaining = deadline - System.monotonic_time(:millisecond)

      if remaining > 0 do
        Process.sleep(50)
        poll_port(port, deadline)
      else
        false
      end
    end
  end

  # Poll GET /tasks/:id until state == expected_state or timeout.
  defp wait_for_task_state(port, task_id, expected_state, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_task_state(port, task_id, expected_state, deadline)
  end

  defp poll_task_state(port, task_id, expected_state, deadline) do
    case mtls_get(port, "/tasks/#{task_id}") do
      {:ok, 200, body} ->
        case Jason.decode(body) do
          {:ok, %{"status" => %{"state" => ^expected_state}}} ->
            true

          {:ok, _other} ->
            remaining = deadline - System.monotonic_time(:millisecond)

            if remaining > 0 do
              Process.sleep(50)
              poll_task_state(port, task_id, expected_state, deadline)
            else
              false
            end

          _ ->
            false
        end

      _ ->
        false
    end
  end

  # ── Tests ─────────────────────────────────────────────────────────────────────

  # ── M1-CRIT-6: mTLS enforcement — unauthenticated calls rejected ──────────────

  test "M1-CRIT-6a: unauthenticated connection is rejected before request processing" do
    # [PASS/FAIL evidence for M1-CRIT-6]
    #
    # The server is configured with `fail_if_no_peer_cert: true` (TLS layer)
    # and the A2ARouter's authenticate_mtls plug (HTTP layer).  A connection
    # without a client certificate must be blocked at one of these layers.
    port = @base_port + 0
    start_listener!(port)

    result = unauthenticated_request(port, "/.well-known/agent-card.json")

    # Accepted outcomes:
    # 1. TLS handshake fails (server rejects before any HTTP bytes are read).
    # 2. Handshake succeeds but server returns HTTP 401.
    case result do
      {:rejected, _reason} ->
        :ok

      {:ok, 401, _body} ->
        :ok

      {:ok, other_status, _body} ->
        flunk("Expected TLS rejection or HTTP 401, got HTTP #{other_status}")
    end
  end

  # ── M1-CRIT-3: Agent Card discovery ──────────────────────────────────────────

  test "M1-CRIT-3a: authenticated mTLS client retrieves Agent Card with correct skills" do
    # [PASS/FAIL evidence for M1-CRIT-3 — Agent Card]
    port = @base_port + 1
    start_listener!(port)

    assert {:ok, 200, body} = mtls_get(port, "/.well-known/agent-card.json")

    assert {:ok, card} = Jason.decode(body),
           "Agent Card response is not valid JSON"

    # Verify Agent Card schema fields.
    assert is_binary(card["url"]),
           "Agent Card must have a 'url' field"

    assert card["capabilities"]["streaming"] == false,
           "Agent Card must declare streaming: false"

    skill_ids = Enum.map(card["skills"], & &1["id"])

    assert "exocomp.system.diagnose" in skill_ids,
           "Agent Card must list exocomp.system.diagnose"

    assert "exocomp.service.diagnose" in skill_ids,
           "Agent Card must list exocomp.service.diagnose"

    assert "exocomp.remediation.propose" in skill_ids,
           "Agent Card must list exocomp.remediation.propose"
  end

  test "M1-CRIT-3b: authenticated client submits system.diagnose task and receives artifact" do
    # [PASS/FAIL evidence for M1-CRIT-3 — system diagnostic artifact]
    port = @base_port + 2
    start_listener!(port)
    install_fake_collectors()

    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{"type" => "data", "data" => %{"skill" => "exocomp.system.diagnose"}}
        ]
      })

    # Submit the task.
    assert {:ok, 202, resp_body} = mtls_post(port, "/message:send", body),
           "POST /message:send should return 202 Accepted"

    assert {:ok, task} = Jason.decode(resp_body)
    assert is_binary(task["id"]), "Response must contain a task id"

    task_id = task["id"]

    assert task["status"]["state"] == "submitted",
           "Immediately after submission, task state should be 'submitted'"

    # Poll until the task reaches 'completed'.
    assert wait_for_task_state(port, task_id, "completed", 5_000),
           "Task #{task_id} did not reach 'completed' state within 5 s"

    # Verify the completed task contains an artifact.
    assert {:ok, 200, task_body} = mtls_get(port, "/tasks/#{task_id}")
    assert {:ok, completed} = Jason.decode(task_body)
    assert completed["status"]["state"] == "completed"

    assert [
             %{
               "artifactId" => artifact_id,
               "name" => "system-diagnose",
               "parts" => [
                 %{
                   "type" => "data",
                   "data" => %{
                     "schema_version" => "1",
                     "skill" => "exocomp.system.diagnose",
                     "observations" => observations
                   }
                 }
               ]
             }
           ] = completed["artifacts"]

    assert is_binary(artifact_id)
    assert Map.keys(observations) |> Enum.sort() == ["cpu", "disk", "memory", "uptime"]
  end

  test "M1-CRIT-3c: GET /tasks returns the list of tasks including submitted one" do
    # [PASS/FAIL evidence for M1-CRIT-3 — task list endpoint]
    port = @base_port + 3
    start_listener!(port)
    install_fake_collectors()

    submit_body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{"type" => "data", "data" => %{"skill" => "exocomp.system.diagnose"}}
        ]
      })

    assert {:ok, 202, resp} = mtls_post(port, "/message:send", submit_body)
    assert {:ok, %{"id" => task_id}} = Jason.decode(resp)

    assert {:ok, 200, list_body} = mtls_get(port, "/tasks")
    assert {:ok, tasks} = Jason.decode(list_body)
    assert is_list(tasks), "GET /tasks must return a JSON array"
    ids = Enum.map(tasks, & &1["id"])
    assert task_id in ids, "GET /tasks must include the submitted task"
  end

  # ── M1-CRIT-5: llama.cpp failure isolation ───────────────────────────────────

  test "M1-CRIT-5a: inference unavailable → task fails; node agent stays responsive" do
    # [PASS/FAIL evidence for M1-CRIT-5]
    #
    # When no llama-server is running, exocomp.remediation.propose must
    # transition the task to 'failed' without crashing the node process.
    port = @base_port + 4
    start_listener!(port)

    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{
            "type" => "data",
            "data" => %{"skill" => "exocomp.remediation.propose", "cpu" => 99}
          }
        ]
      })

    assert {:ok, 202, resp_body} = mtls_post(port, "/message:send", body)
    assert {:ok, task} = Jason.decode(resp_body)
    task_id = task["id"]

    # The task must eventually fail (not hang indefinitely).
    assert wait_for_task_state(port, task_id, "failed", 10_000),
           "Task #{task_id} did not reach 'failed' state within 10 s. " <>
             "Inference unavailability must not block the node indefinitely."

    # The node must remain responsive after the failure.
    assert {:ok, 200, _} = mtls_get(port, "/.well-known/agent-card.json"),
           "Node must still respond to requests after a failed inference task"
  end

  test "M1-CRIT-5b: proposal failure does not produce an executable action" do
    # [PASS/FAIL evidence for M1-CRIT-5]
    #
    # A failed proposal must not be returned as an artifact that could be
    # misinterpreted as a command.  The task status must be 'failed' (not
    # 'completed' with a partial or fabricated proposal).
    port = @base_port + 5
    start_listener!(port)

    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{
            "type" => "data",
            "data" => %{"skill" => "exocomp.remediation.propose", "cpu" => 99}
          }
        ]
      })

    assert {:ok, 202, resp_body} = mtls_post(port, "/message:send", body)
    assert {:ok, task} = Jason.decode(resp_body)
    task_id = task["id"]

    assert wait_for_task_state(port, task_id, "failed", 10_000),
           "Expected task to reach 'failed' state; a 'completed' state with " <>
             "fabricated output would be a M1-CRIT-5 violation."

    # Confirm the final state is definitively 'failed', not 'completed'.
    assert {:ok, 200, task_body} = mtls_get(port, "/tasks/#{task_id}")
    assert {:ok, %{"status" => %{"state" => "failed"}}} = Jason.decode(task_body)
  end

  # ── Task lifecycle ────────────────────────────────────────────────────────────

  test "task lifecycle: submitted → working → completed transitions are observable" do
    port = @base_port + 6
    start_listener!(port)
    install_fake_collectors()

    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{"type" => "data", "data" => %{"skill" => "exocomp.system.diagnose"}}
        ]
      })

    assert {:ok, 202, resp_body} = mtls_post(port, "/message:send", body)

    assert {:ok, %{"id" => task_id, "status" => %{"state" => initial_state}}} =
             Jason.decode(resp_body)

    assert initial_state in ["submitted", "working"],
           "Initial task state should be 'submitted' or 'working'"

    assert wait_for_task_state(port, task_id, "completed", 5_000),
           "Task did not reach 'completed' state within 5 s"
  end

  test "task cancellation: submitted task can be canceled via POST /tasks/:id:cancel" do
    port = @base_port + 7
    start_listener!(port)

    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{"type" => "data", "data" => %{"skill" => "exocomp.system.diagnose"}}
        ]
      })

    assert {:ok, 202, resp_body} = mtls_post(port, "/message:send", body)
    assert {:ok, %{"id" => task_id}} = Jason.decode(resp_body)

    # The cancel endpoint exists and returns a valid HTTP response.
    # 200 = canceled successfully; 400 = task already reached a terminal state
    # before we could cancel (both are acceptable outcomes in this race).
    assert {:ok, status, _cancel_body} = mtls_post(port, "/tasks/#{task_id}:cancel", "")
    assert status in [200, 400], "Cancel returned unexpected status #{status}"
  end

  test "concurrent requests: multiple simultaneous submissions are all accepted" do
    port = @base_port + 8
    start_listener!(port)
    install_fake_collectors()

    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{"type" => "data", "data" => %{"skill" => "exocomp.system.diagnose"}}
        ]
      })

    # Submit 3 tasks concurrently.
    tasks =
      Task.async_stream(
        1..3,
        fn _i -> mtls_post(port, "/message:send", body) end,
        timeout: 10_000,
        max_concurrency: 3
      )
      |> Enum.to_list()

    # All submissions must succeed.
    for {:ok, result} <- tasks do
      assert {:ok, 202, _resp} = result
    end

    # Node must still be responsive after concurrent load.
    assert {:ok, 200, _} = mtls_get(port, "/.well-known/agent-card.json")
  end

  # ── M1-CRIT-7: host state invariance ─────────────────────────────────────────

  test "M1-CRIT-7: node operation leaves no persistent host state changes" do
    # [PASS/FAIL evidence for M1-CRIT-7]
    #
    # Snapshot key host state paths before starting the node, exercise the
    # node, then verify the same paths are unchanged after shutdown.
    #
    # The node must not write to /etc, /usr, /var/lib, /opt, or any system
    # directory during normal operation.

    system_paths = ["/etc", "/usr", "/var/lib/exocomp", "/opt/exocomp"]

    # Snapshot: record whether each path exists and, if a directory, its entries.
    snapshot = fn paths ->
      Enum.into(paths, %{}, fn path ->
        case File.ls(path) do
          {:ok, files} -> {path, Enum.sort(files)}
          {:error, _} -> {path, :not_present}
        end
      end)
    end

    before_snap = snapshot.(system_paths)

    port = @base_port + 9
    install_fake_collectors()
    start_listener!(port)

    # Exercise the node with a few requests.
    body =
      Jason.encode!(%{
        "role" => "user",
        "parts" => [
          %{"type" => "data", "data" => %{"skill" => "exocomp.system.diagnose"}}
        ]
      })

    assert {:ok, 202, resp_body} = mtls_post(port, "/message:send", body)
    assert {:ok, %{"id" => task_id}} = Jason.decode(resp_body)
    wait_for_task_state(port, task_id, "completed", 5_000)

    # Also exercise Agent Card and task list.
    assert {:ok, 200, _} = mtls_get(port, "/.well-known/agent-card.json")
    assert {:ok, 200, _} = mtls_get(port, "/tasks")

    # Stop the listener before taking the final snapshot so the comparison
    # spans the complete node lifecycle, including graceful shutdown.
    :ok = stop_supervised(Listener)
    after_snap = snapshot.(system_paths)

    # Snapshot must be identical before and after node operation.
    assert before_snap == after_snap,
           "Host state changed during node operation:\n" <>
             "Before: #{inspect(before_snap)}\n" <>
             "After:  #{inspect(after_snap)}"
  end

  test "M1-CRIT-7: invalid A2A requests do not cause host state changes" do
    port = @base_port + 10
    start_listener!(port)

    system_paths = ["/etc", "/usr"]

    snapshot = fn paths ->
      Enum.into(paths, %{}, fn path ->
        case File.ls(path) do
          {:ok, files} -> {path, Enum.sort(files)}
          {:error, _} -> {path, :not_present}
        end
      end)
    end

    before_snap = snapshot.(system_paths)

    # Send malformed JSON.
    assert {:ok, 400, _} = mtls_post(port, "/message:send", "not-valid-json{{{")

    # Request an unknown route.
    assert {:ok, 404, _} = mtls_get(port, "/does-not-exist")

    # Request an unknown task.
    assert {:ok, 404, _} = mtls_get(port, "/tasks/nonexistent-task-id")

    after_snap = snapshot.(system_paths)

    assert before_snap == after_snap,
           "Host state changed after invalid A2A requests:\n" <>
             "Before: #{inspect(before_snap)}\n" <>
             "After:  #{inspect(after_snap)}"
  end

  # ── Graceful shutdown ─────────────────────────────────────────────────────────

  test "graceful shutdown: Listener stops cleanly when its supervised process exits" do
    port = @base_port + 11
    start_listener!(port)

    # Confirm the listener is up.
    assert port_open?(port)

    # Stop the supervised Listener (simulates OTP supervisor shutdown).
    :ok = stop_supervised(Listener)

    # Allow a brief moment for the port to be released.
    Process.sleep(100)

    refute port_open?(port),
           "Port #{port} should be released after Listener stops"
  end

  # ── A2A protocol correctness ──────────────────────────────────────────────────

  test "A2A-Version header: missing version header returns 400 InvalidRequestError" do
    port = @base_port + 12
    start_listener!(port)

    # We need a lower-level request without the A2A-Version header.
    # Build it manually.
    ssl_opts = mtls_ssl_opts()

    case :ssl.connect({127, 0, 0, 1}, port, ssl_opts, 5_000) do
      {:ok, sock} ->
        req =
          "GET /.well-known/agent-card.json HTTP/1.1\r\nhost: exocomp-test-node\r\nconnection: close\r\n\r\n"

        :ssl.send(sock, req)

        {:ok, data} = recv_full(sock, "")
        :ssl.close(sock)

        {:ok, status, _body} = parse_response(data)
        assert status == 400

      {:error, reason} ->
        flunk("Unexpected SSL error: #{inspect(reason)}")
    end
  end

  test "body size limit: oversized request body returns 413" do
    port = @base_port + 13
    start_listener!(port)

    # Send a body > 1 MiB.
    big_body = String.duplicate("x", 1_048_577)
    assert {:ok, 413, _} = mtls_post(port, "/message:send", big_body)
  end
end
