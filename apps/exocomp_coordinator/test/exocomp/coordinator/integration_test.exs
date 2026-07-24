defmodule Exocomp.Coordinator.IntegrationTest do
  @moduledoc """
  Integration tests for EXOCOMP-77: coordinator PKI initialization and
  enrollment operations.

  These tests exercise the full path from Bootstrap.initialize through the
  supervised enrollment service and verify:

  - Clean initialization followed by supervised tree start
  - Idempotent rerun (already-initialized state)
  - Missing, corrupt, and insecure-permission PKI material causes startup
    failure
  - Token issue/consume through the supervised service (with real PKI state)
  - Restart replay rejection (persistent store survives supervisor stop/start)
  - Audit outage fail-closed behavior
  - Log and output redaction (no private key material in Logger output)
  - No root private key retained in online state directory
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Exocomp.Coordinator.{Application, Audit, EnrollmentToken, PKI.Bootstrap, PKI.State}

  @passphrase "correct horse battery staple integration"

  # ---------------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------------

  defp unique_prefix,
    do: :"i#{System.unique_integer([:positive, :monotonic])}"

  defp pki_base(tmp_dir, label) do
    base = Path.join(tmp_dir, label)
    File.mkdir_p!(base)
    File.chmod!(base, 0o700)
    base
  end

  defp pki_opts(base) do
    [
      online_state: Path.join(base, "online"),
      offline_backup: Path.join(base, "offline"),
      root_key_protection: {:passphrase, @passphrase}
    ]
  end

  defp build_tree_opts(base, prefix, extra \\ []) do
    pki_opts(base) ++
      [
        supervisor_name: prefix,
        name_prefix: prefix,
        enrollment_token_opts: [inventory_fn: fn _ -> :ok end]
      ] ++
      extra
  end

  # Start the coordinator tree and unlink the supervisor from the test process.
  # Unlinking ensures that killing the supervisor in tests does not propagate
  # an exit signal to the test process.
  defp start_tree(opts) do
    case Application.start_supervised_tree(opts) do
      {:ok, pid} ->
        # Unlink so that Process.exit(pid, :kill) does not kill the test process.
        Process.unlink(pid)

        on_exit(fn ->
          if Process.alive?(pid) do
            ref = Process.monitor(pid)
            Process.exit(pid, :kill)

            receive do
              {:DOWN, ^ref, :process, ^pid, _} -> :ok
            after
              500 -> :ok
            end
          end
        end)

        {:ok, pid}

      error ->
        error
    end
  end

  # Synchronously stop a supervisor that was started via start_tree/1.
  # The supervisor must already be unlinked from the test process.
  defp stop_supervisor(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)

    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    after
      1_000 -> :ok
    end

    # Brief pause so the OS deregisters all named processes before the next
    # supervisor start.
    Process.sleep(50)
  end

  # ---------------------------------------------------------------------------
  # 1. Clean initialization followed by supervised tree start
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "clean PKI initialization enables supervised tree to start", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    assert {:ok, pid} = start_tree(build_tree_opts(base, prefix))
    assert Process.alive?(pid)

    pki_state = :"#{prefix}_pki_state"
    assert %{healthy: true, root_fingerprint: fp} = State.status(pki_state)
    assert fp =~ ~r/\A(?:[0-9A-F]{2}:){31}[0-9A-F]{2}\z/
  end

  @tag :tmp_dir
  test "enrollment token service is accessible after clean initialization", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    node_id = "node-integration-clean"

    assert {:ok, _pid} = start_tree(build_tree_opts(base, prefix))

    enrollment = :"#{prefix}_enrollment_token"
    assert {:ok, token} = EnrollmentToken.issue(node_id, server: enrollment)
    assert is_binary(token) and String.starts_with?(token, "tok_")
    assert :ok = EnrollmentToken.consume(token, node_id, server: enrollment)
  end

  # ---------------------------------------------------------------------------
  # 2. Idempotent rerun (already-initialized state)
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "already-initialized PKI state allows supervised tree to start again", %{tmp_dir: tmp_dir} do
    prefix_a = unique_prefix()
    prefix_b = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    node_id = "node-idempotent"

    assert {:ok, pid_a} = start_tree(build_tree_opts(base, prefix_a))
    fingerprint_a = State.status(:"#{prefix_a}_pki_state").root_fingerprint
    stop_supervisor(pid_a)

    # Second startup using the same PKI dirs — disposition is :already_initialized
    assert {:ok, _pid_b} = start_tree(build_tree_opts(base, prefix_b))
    assert State.status(:"#{prefix_b}_pki_state").root_fingerprint == fingerprint_a

    enrollment = :"#{prefix_b}_enrollment_token"
    assert {:ok, token} = EnrollmentToken.issue(node_id, server: enrollment)
    assert :ok = EnrollmentToken.consume(token, node_id, server: enrollment)
  end

  # ---------------------------------------------------------------------------
  # 3. PKI startup failure modes
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "missing online PKI state prevents supervised tree from starting", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    Bootstrap.initialize(pki_opts(base))
    File.rm_rf!(Path.join(base, "online"))

    assert {:error, %{code: :invalid_pki_state}} =
             Application.start_supervised_tree(build_tree_opts(base, prefix))
  end

  @tag :tmp_dir
  test "missing offline backup prevents supervised tree from starting", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    Bootstrap.initialize(pki_opts(base))
    File.rm_rf!(Path.join(base, "offline"))

    assert {:error, %{code: :invalid_pki_state}} =
             Application.start_supervised_tree(build_tree_opts(base, prefix))
  end

  @tag :tmp_dir
  test "corrupt PKI certificate prevents supervised tree from starting", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    Bootstrap.initialize(pki_opts(base))
    cert_path = Path.join([base, "online", "coordinator.pem"])
    File.write!(cert_path, "not a valid certificate")
    File.chmod!(cert_path, 0o644)

    assert {:error, %{code: :invalid_pki_state}} =
             Application.start_supervised_tree(build_tree_opts(base, prefix))
  end

  @tag :tmp_dir
  test "insecure permissions on PKI directory prevent supervised tree from starting", %{
    tmp_dir: tmp_dir
  } do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    Bootstrap.initialize(pki_opts(base))
    File.chmod!(Path.join(base, "online"), 0o755)

    assert {:error, %{code: :invalid_pki_state}} =
             Application.start_supervised_tree(build_tree_opts(base, prefix))
  end

  @tag :tmp_dir
  test "insecure permissions on a private PKI file prevent supervised tree from starting", %{
    tmp_dir: tmp_dir
  } do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    Bootstrap.initialize(pki_opts(base))
    File.chmod!(Path.join([base, "online", "coordinator_key.pem"]), 0o644)

    assert {:error, %{code: :invalid_pki_state}} =
             Application.start_supervised_tree(build_tree_opts(base, prefix))
  end

  # ---------------------------------------------------------------------------
  # 4. Token issue/consume through the supervised service (real PKI state)
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "token issued through supervised service can be consumed exactly once", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    node_id = "node-supervised-consume"

    assert {:ok, _pid} = start_tree(build_tree_opts(base, prefix))

    enrollment = :"#{prefix}_enrollment_token"
    assert {:ok, token} = EnrollmentToken.issue(node_id, server: enrollment)
    assert :ok = EnrollmentToken.consume(token, node_id, server: enrollment)

    assert {:error, %{code: :token_already_consumed}} =
             EnrollmentToken.consume(token, node_id, server: enrollment)
  end

  @tag :tmp_dir
  test "token with wrong node ID is rejected through supervised service", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")

    assert {:ok, _pid} = start_tree(build_tree_opts(base, prefix))

    enrollment = :"#{prefix}_enrollment_token"
    assert {:ok, token} = EnrollmentToken.issue("node-original", server: enrollment)

    assert {:error, %{code: :token_node_mismatch}} =
             EnrollmentToken.consume(token, "node-other", server: enrollment)
  end

  # ---------------------------------------------------------------------------
  # 5. Restart replay rejection (persistent store survives supervisor stop/start)
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "consumed token cannot be replayed after supervisor restart", %{tmp_dir: tmp_dir} do
    prefix_a = unique_prefix()
    prefix_b = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    node_id = "node-restart-replay"
    store_path = Path.join(tmp_dir, "enrollment-tokens-replay")

    opts_a = build_tree_opts(base, prefix_a, store_path: store_path)
    assert {:ok, pid_a} = start_tree(opts_a)
    enrollment_a = :"#{prefix_a}_enrollment_token"

    assert {:ok, token} = EnrollmentToken.issue(node_id, server: enrollment_a)
    assert :ok = EnrollmentToken.consume(token, node_id, server: enrollment_a)

    stop_supervisor(pid_a)

    opts_b = build_tree_opts(base, prefix_b, store_path: store_path)
    assert {:ok, _pid_b} = start_tree(opts_b)
    enrollment_b = :"#{prefix_b}_enrollment_token"

    assert {:error, %{code: :token_already_consumed}} =
             EnrollmentToken.consume(token, node_id, server: enrollment_b)
  end

  @tag :tmp_dir
  test "token issued before restart can be consumed after restart", %{tmp_dir: tmp_dir} do
    prefix_a = unique_prefix()
    prefix_b = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    node_id = "node-persist-token"
    store_path = Path.join(tmp_dir, "enrollment-tokens-persist")

    opts_a = build_tree_opts(base, prefix_a, store_path: store_path)
    assert {:ok, pid_a} = start_tree(opts_a)

    assert {:ok, token} = EnrollmentToken.issue(node_id, server: :"#{prefix_a}_enrollment_token")
    stop_supervisor(pid_a)

    opts_b = build_tree_opts(base, prefix_b, store_path: store_path)
    assert {:ok, _pid_b} = start_tree(opts_b)

    assert :ok = EnrollmentToken.consume(token, node_id, server: :"#{prefix_b}_enrollment_token")
  end

  # ---------------------------------------------------------------------------
  # 6. Audit outage fail-closed
  # ---------------------------------------------------------------------------

  defmodule OfflineSink do
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(_opts), do: {:error, :offline}

    @impl true
    def write(_state, _event), do: {:error, :offline}

    @impl true
    def close(_state), do: :ok
  end

  @tag :tmp_dir
  test "enrollment token issuance fails closed when audit is unavailable", %{tmp_dir: tmp_dir} do
    audit_name = :"audit_offline_#{System.unique_integer([:positive])}"
    enrollment_name = :"et_offline_#{System.unique_integer([:positive])}"
    node_id = "node-audit-outage-issue"
    _base = pki_base(tmp_dir, "pki_audit")

    # Start an Audit server with an offline sink.
    # Use a unique child spec id to avoid collisions in the ExUnit test supervisor.
    start_supervised!(
      Supervisor.child_spec(
        {Audit, [name: audit_name, sink: {OfflineSink, []}]},
        id: audit_name
      )
    )

    assert %{healthy: false} = Audit.status(audit_name)

    start_supervised!(
      Supervisor.child_spec(
        {EnrollmentToken,
         [
           name: enrollment_name,
           inventory_fn: fn _ -> :ok end,
           audit_server: audit_name
         ]},
        id: enrollment_name
      )
    )

    assert {:error, %{code: :audit_unavailable}} =
             EnrollmentToken.issue(node_id, server: enrollment_name)
  end

  @tag :tmp_dir
  test "enrollment token consumption fails closed when audit is unavailable", %{tmp_dir: tmp_dir} do
    audit_ok_name = :"audit_ok_#{System.unique_integer([:positive])}"
    audit_offline_name = :"audit_offline_#{System.unique_integer([:positive])}"
    enrollment_a_name = :"et_ok_#{System.unique_integer([:positive])}"
    enrollment_b_name = :"et_offline_#{System.unique_integer([:positive])}"
    node_id = "node-audit-outage-consume"
    store_path = Path.join(tmp_dir, "tokens-audit-outage")

    # First: issue token with a working audit.
    # Use a unique child spec id so two Audit children can coexist in the same
    # ExUnit test supervisor (the default id is the module name, which would
    # collide for the second start_supervised! call).
    audit_path = Path.join(tmp_dir, "audit.jsonl")

    start_supervised!(
      Supervisor.child_spec(
        {Audit, [name: audit_ok_name, sink: {Audit.JSONLines, path: audit_path}]},
        id: audit_ok_name
      )
    )

    start_supervised!(
      Supervisor.child_spec(
        {EnrollmentToken,
         [
           name: enrollment_a_name,
           inventory_fn: fn _ -> :ok end,
           store_path: store_path,
           audit_server: audit_ok_name
         ]},
        id: enrollment_a_name
      )
    )

    assert {:ok, token} = EnrollmentToken.issue(node_id, server: enrollment_a_name)

    # Second: consume with an offline audit — must fail closed.
    start_supervised!(
      Supervisor.child_spec(
        {Audit, [name: audit_offline_name, sink: {OfflineSink, []}]},
        id: audit_offline_name
      )
    )

    assert %{healthy: false} = Audit.status(audit_offline_name)

    start_supervised!(
      Supervisor.child_spec(
        {EnrollmentToken,
         [
           name: enrollment_b_name,
           inventory_fn: fn _ -> :ok end,
           store_path: store_path,
           audit_server: audit_offline_name
         ]},
        id: enrollment_b_name
      )
    )

    assert {:error, %{code: :audit_unavailable}} =
             EnrollmentToken.consume(token, node_id, server: enrollment_b_name)
  end

  # ---------------------------------------------------------------------------
  # 7. Log/output redaction
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "Bootstrap.initialize does not emit passphrase or private key material to Logger", %{
    tmp_dir: tmp_dir
  } do
    base = pki_base(tmp_dir, "pki")
    passphrase = @passphrase

    log =
      capture_log(fn ->
        assert {:ok, _metadata} = Bootstrap.initialize(pki_opts(base))
      end)

    refute log =~ passphrase
    refute log =~ "PRIVATE KEY"
    refute log =~ "ENCRYPTED"
  end

  @tag :tmp_dir
  test "supervised tree startup does not emit passphrase or private key material to Logger", %{
    tmp_dir: tmp_dir
  } do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    passphrase = @passphrase

    log =
      capture_log(fn ->
        assert {:ok, _pid} = start_tree(build_tree_opts(base, prefix))
      end)

    refute log =~ passphrase
    refute log =~ "PRIVATE KEY"
    refute log =~ "ENCRYPTED"
  end

  @tag :tmp_dir
  test "token operations do not emit token plaintext or passphrase to Logger", %{tmp_dir: tmp_dir} do
    prefix = unique_prefix()
    base = pki_base(tmp_dir, "pki")
    node_id = "node-redaction-test"
    passphrase = @passphrase

    assert {:ok, _pid} = start_tree(build_tree_opts(base, prefix))
    enrollment = :"#{prefix}_enrollment_token"

    token_holder = self()

    log =
      capture_log(fn ->
        {:ok, token} = EnrollmentToken.issue(node_id, server: enrollment)
        send(token_holder, {:token, token})
        :ok = EnrollmentToken.consume(token, node_id, server: enrollment)
      end)

    assert_received {:token, token}
    refute log =~ passphrase
    refute log =~ token
    refute log =~ "PRIVATE KEY"
    refute log =~ "tok_"
  end

  # ---------------------------------------------------------------------------
  # 8. No root private key retained in online state
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "root CA private key is absent from online state directory after initialization", %{
    tmp_dir: tmp_dir
  } do
    base = pki_base(tmp_dir, "pki")
    assert {:ok, metadata} = Bootstrap.initialize(pki_opts(base))

    online_files = File.ls!(metadata.online_state)

    refute "root_ca_key.pem" in online_files,
           "root CA private key must not exist in the online state directory"
  end

  @tag :tmp_dir
  test "online state after initialization contains only expected files", %{tmp_dir: tmp_dir} do
    base = pki_base(tmp_dir, "pki")
    assert {:ok, metadata} = Bootstrap.initialize(pki_opts(base))

    online_files = metadata.online_state |> File.ls!() |> Enum.sort()

    expected = [
      "approval_signing.key",
      "approval_signing.pub",
      "coordinator.pem",
      "coordinator_key.pem",
      "intermediate_ca.pem",
      "intermediate_ca_key.pem",
      "pki.manifest",
      "root_ca.pem"
    ]

    assert online_files == expected,
           "Expected online files #{inspect(expected)}, got #{inspect(online_files)}"
  end

  @tag :tmp_dir
  test "offline backup contains protected root key and no unencrypted private keys", %{
    tmp_dir: tmp_dir
  } do
    base = pki_base(tmp_dir, "pki")
    assert {:ok, metadata} = Bootstrap.initialize(pki_opts(base))

    root_key_path = Path.join(metadata.offline_backup, "root_ca_key.pem")
    assert File.exists?(root_key_path)

    key_pem = File.read!(root_key_path)
    assert key_pem =~ "ENCRYPTED"
    assert {:error, _} = X509.PrivateKey.from_pem(key_pem)
    assert {:ok, _} = X509.PrivateKey.from_pem(key_pem, password: @passphrase)
  end

  @tag :tmp_dir
  test "online and offline directory permissions are 0700", %{tmp_dir: tmp_dir} do
    base = pki_base(tmp_dir, "pki")
    assert {:ok, metadata} = Bootstrap.initialize(pki_opts(base))

    assert {:ok, %{mode: online_mode}} = File.stat(metadata.online_state)
    assert Bitwise.band(online_mode, 0o777) == 0o700

    assert {:ok, %{mode: backup_mode}} = File.stat(metadata.offline_backup)
    assert Bitwise.band(backup_mode, 0o777) == 0o700
  end

  @tag :tmp_dir
  test "private files in online state have mode 0600", %{tmp_dir: tmp_dir} do
    base = pki_base(tmp_dir, "pki")
    assert {:ok, metadata} = Bootstrap.initialize(pki_opts(base))

    private_files = [
      "intermediate_ca_key.pem",
      "coordinator_key.pem",
      "approval_signing.key",
      "pki.manifest"
    ]

    for name <- private_files do
      path = Path.join(metadata.online_state, name)
      assert {:ok, %{mode: mode}} = File.stat(path), "could not stat #{path}"
      assert Bitwise.band(mode, 0o777) == 0o600, "#{name} should be 0600"
    end
  end

  @tag :tmp_dir
  test "root CA key in offline backup has mode 0600", %{tmp_dir: tmp_dir} do
    base = pki_base(tmp_dir, "pki")
    assert {:ok, metadata} = Bootstrap.initialize(pki_opts(base))

    root_key_path = Path.join(metadata.offline_backup, "root_ca_key.pem")
    assert {:ok, %{mode: mode}} = File.stat(root_key_path)
    assert Bitwise.band(mode, 0o777) == 0o600
  end
end
