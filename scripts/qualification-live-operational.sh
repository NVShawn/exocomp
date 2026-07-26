#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Operational qualification helper for dedicated release-candidate guests.
# The caller must first run qualification-live-preflight.sh successfully.

set -euo pipefail
umask 077

version="${QUALIFICATION_VERSION:?QUALIFICATION_VERSION is required}"
architecture="${QUALIFICATION_ARCH:?QUALIFICATION_ARCH is required}"
qualification_root="${QUALIFICATION_ROOT:?QUALIFICATION_ROOT is required}"
evidence_dir="${QUALIFICATION_EVIDENCE:?QUALIFICATION_EVIDENCE is required}"
source_dir="${qualification_root}/src-gates"
node_id="qualification-${architecture}"
public_root="/tmp/exocomp-root-ca-${version}-${architecture}.pem"
public_chain="/tmp/exocomp-coordinator-ca-chain-${version}-${architecture}.pem"

mkdir -p "${evidence_dir}"
exec > >(tee -a "${evidence_dir}/transcript.txt") 2>&1

pass() {
    printf '[PASS] %s\n' "$*"
}

require_output() {
    local pattern="$1"
    local file="$2"
    grep -Fq "${pattern}" "${file}" || {
        printf '[FAIL] expected %q in %s\n' "${pattern}" "${file}" >&2
        return 1
    }
}

coordinator_rpc() {
    local expression="$1"
    bash -c '
      set -a
      . /opt/exocomp/coordinator/config/release-cookie.env
      set +a
      exec /opt/exocomp/coordinator/current/bin/exocomp_coordinator rpc "$1"
    ' bash "${expression}"
}

node_rpc() {
    local expression="$1"
    bash -c '
      set -a
      . /opt/exocomp/node/config/release-cookie.env
      set +a
      exec /opt/exocomp/node/current/bin/exocomp_node rpc "$1"
    ' bash "${expression}"
}

wait_for_coordinator() {
    local attempt
    for attempt in $(seq 1 30); do
        if coordinator_rpc 'IO.puts("rpc_ready=true")' >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    printf '[FAIL] coordinator RPC did not become ready after %s attempts\n' \
        "${attempt}" >&2
    return 1
}

restore_inventory() {
    coordinator_rpc '
      inventory =
        Jason.encode!(%{
          "version" => 1,
          "nodes" => [
            %{
              "id" => "'"${node_id}"'",
              "hostname" => "127.0.0.1",
              "port" => 4433,
              "certificate_identity" => "'"${node_id}"'",
              "capabilities" => ["diagnostics", "recovery"],
              "labels" => %{"qualification" => "'"${version}"'"}
            }
          ]
        })
      :ok = Exocomp.Coordinator.Inventory.replace_json(inventory)
      IO.puts("inventory=restored")
    '
}

issue_token() {
    local destination="$1"
    coordinator_rpc "
      case Exocomp.Coordinator.EnrollmentToken.issue(\"${node_id}\") do
        {:ok, token} -> IO.write(token)
        {:error, error} ->
          raise \"token_issue_error=#{error.code}\"
      end
    " > "${destination}"
    chmod 0600 "${destination}"
}

systemctl is-active --quiet exocomp-coordinator.service
systemctl is-active --quiet exocomp-node.service
wait_for_coordinator
restore_inventory > "${evidence_dir}/inventory-initial.txt"
test -s "${public_root}"
test -s "${public_chain}"
printf 'candidate=%s architecture=%s commit=%s\n' \
    "${version}" "${architecture}" "$(git -C "${source_dir}" rev-parse HEAD)"

# Exercise token binding, one-use semantics, and TLS trust using only modules
# and certificates shipped in the installed node release.
token_one="/run/exocomp-qualification-negative-token-one"
token_two="/run/exocomp-qualification-negative-token-two"
issue_token "${token_one}"
issue_token "${token_two}"

sudo -u exocomp-node \
    env ENROLLMENT_TOKEN_ONE="$(<"${token_one}")" \
    ENROLLMENT_TOKEN_TWO="$(<"${token_two}")" \
    bash -c '
      cd /opt/exocomp/node
      set -a
      . ./config/release-cookie.env
      set +a
      exec ./current/bin/exocomp_node eval "$1"
    ' bash "
      {:ok, _} = Application.ensure_all_started(:ssl)
      {:ok, _} = Application.ensure_all_started(:inets)
      node_id = \"${node_id}\"
      endpoint = \"https://exocomp-coordinator:4443/v1/enroll\"
      root_pem = File.read!(\"${public_root}\")
      common = [
        endpoint: endpoint,
        ca_file: \"${public_chain}\",
        ca_pem: root_pem
      ]

      rogue_key = X509.PrivateKey.new_ec(:secp256r1)
      rogue_cert =
        X509.Certificate.self_signed(
          rogue_key,
          \"/O=Exocomp Qualification/CN=Untrusted Qualification Root\",
          template: :root_ca
        )
      rogue_path = \"/tmp/exocomp-untrusted-${architecture}.pem\"
      File.write!(rogue_path, X509.Certificate.to_pem(rogue_cert))

      # Run this first so :httpc cannot reuse a TLS session established by a
      # preceding request that used the trusted qualification root.
      untrusted =
        Exocomp.Node.EnrollmentClient.enroll(
          node_id: node_id,
          token: System.fetch_env!(\"ENROLLMENT_TOKEN_TWO\"),
          endpoint: endpoint,
          credential_dir: \"/tmp/exocomp-negative-untrusted-${architecture}\",
          ca_file: rogue_path,
          ca_pem: X509.Certificate.to_pem(rogue_cert)
        )

      unless match?({:error, {:failed_connect, _}}, untrusted) do
        IO.puts(:stderr, \"untrusted_result=\" <> inspect(untrusted))
        System.halt(1)
      end
      IO.puts(\"untrusted_root=denied\")

      wrong =
        Exocomp.Node.EnrollmentClient.enroll(
          common ++
            [
              node_id: node_id <> \"-wrong\",
              token: System.fetch_env!(\"ENROLLMENT_TOKEN_ONE\"),
              credential_dir: \"/tmp/exocomp-negative-wrong-${architecture}\"
            ]
        )

      unless wrong == {:error, {:http_error, 401}} do
        IO.puts(:stderr, \"wrong_node_result=\" <> inspect(wrong))
        System.halt(1)
      end
      IO.puts(\"wrong_node_token=denied\")

      {:ok, _paths} =
        Exocomp.Node.EnrollmentClient.enroll(
          common ++
            [
              node_id: node_id,
              token: System.fetch_env!(\"ENROLLMENT_TOKEN_ONE\"),
              credential_dir: \"/tmp/exocomp-negative-valid-${architecture}\"
            ]
        )
      IO.puts(\"single_use_first_request=accepted\")

      replay =
        Exocomp.Node.EnrollmentClient.enroll(
          common ++
            [
              node_id: node_id,
              token: System.fetch_env!(\"ENROLLMENT_TOKEN_ONE\"),
              credential_dir: \"/tmp/exocomp-negative-replay-${architecture}\"
            ]
        )

      unless replay == {:error, {:http_error, 401}} do
        IO.puts(:stderr, \"replay_result=\" <> inspect(replay))
        System.halt(1)
      end
      IO.puts(\"single_use_replay=denied\")
    " | tee "${evidence_dir}/enrollment-negatives.txt"
rm -f "${token_one}" "${token_two}"
rm -rf \
    "/tmp/exocomp-negative-wrong-${architecture}" \
    "/tmp/exocomp-negative-valid-${architecture}" \
    "/tmp/exocomp-negative-replay-${architecture}" \
    "/tmp/exocomp-negative-untrusted-${architecture}" \
    "/tmp/exocomp-untrusted-${architecture}.pem"
require_output "wrong_node_token=denied" "${evidence_dir}/enrollment-negatives.txt"
require_output "single_use_replay=denied" "${evidence_dir}/enrollment-negatives.txt"
require_output "untrusted_root=denied" "${evidence_dir}/enrollment-negatives.txt"
pass "enrollment rejects wrong-node, replayed, and untrusted requests"

renew_node() {
    local label="$1"
    sudo -u exocomp-node \
        env RENEWAL_LABEL="${label}" \
        bash -c '
          cd /opt/exocomp/node
          set -a
          . ./config/release-cookie.env
          set +a
          exec ./current/bin/exocomp_node eval "$1"
        ' bash "
          {:ok, _} = Application.ensure_all_started(:ssl)
          {:ok, _} = Application.ensure_all_started(:inets)
          node_id = \"${node_id}\"
          endpoint = ~c\"https://exocomp-coordinator:4443/v1/renew\"
          credential_dir = \"/var/lib/exocomp-node/credentials\"
          current = Exocomp.Node.CredentialInstaller.current(credential_dir)
          old_chain = File.read!(current.chain)

          {_key, new_key_pem, csr_pem} =
            Exocomp.Node.EnrollmentClient.identity_request(node_id)
          {:ok, body} = Jason.encode(%{\"csr\" => csr_pem})
          mtls_options = [
            timeout: 15_000,
            ssl: [
              verify: :verify_peer,
              cacertfile: ~c\"${public_chain}\",
              certfile: String.to_charlist(current.chain),
              keyfile: String.to_charlist(current.key),
              server_name_indication: ~c\"exocomp-coordinator\",
              customize_hostname_check: [
                match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
              ],
              versions: [:\"tlsv1.3\", :\"tlsv1.2\"]
            ]
          ]

          {:ok, {{_version, 200, _reason}, _headers, response_body}} =
            :httpc.request(
              :post,
              {endpoint, [{~c\"content-type\", ~c\"application/json\"}],
               ~c\"application/json\", body},
              mtls_options,
              body_format: :binary
            )
          {:ok, %{\"chain_pem\" => new_chain}} = Jason.decode(response_body)
          {:ok, paths} =
            Exocomp.Node.CredentialInstaller.install(
              new_chain,
              new_key_pem,
              credential_dir,
              node_id: node_id,
              ca_pem: File.read!(\"${public_root}\")
            )

          old_hash = :crypto.hash(:sha256, old_chain) |> Base.encode16(case: :lower)
          new_hash = :crypto.hash(:sha256, new_chain) |> Base.encode16(case: :lower)
          if old_hash == new_hash, do: System.halt(1)
          IO.puts(\"renewal=\" <> System.fetch_env!(\"RENEWAL_LABEL\") <> \":ok\")
          IO.puts(\"renewed_generation=\" <> Path.basename(paths.generation))
          IO.puts(\"certificate_changed=true\")
        "
}

sudo -u exocomp-node \
    bash -c '
      cd /opt/exocomp/node
      set -a
      . ./config/release-cookie.env
      set +a
      exec ./current/bin/exocomp_node eval "$1"
    ' bash "
      {:ok, _} = Application.ensure_all_started(:ssl)
      {:ok, _} = Application.ensure_all_started(:inets)
      {_key, _key_pem, csr} =
        Exocomp.Node.EnrollmentClient.identity_request(\"${node_id}\")
      {:ok, body} = Jason.encode(%{\"csr\" => csr})
      options = [
        timeout: 15_000,
        ssl: [
          verify: :verify_peer,
          cacertfile: ~c\"${public_chain}\",
          server_name_indication: ~c\"exocomp-coordinator\",
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ],
          versions: [:\"tlsv1.3\", :\"tlsv1.2\"]
        ]
      ]

      {:ok, {{_version, 401, _reason}, _headers, _body}} =
        :httpc.request(
          :post,
          {~c\"https://exocomp-coordinator:4443/v1/renew\",
           [{~c\"content-type\", ~c\"application/json\"}],
           ~c\"application/json\", body},
          options,
          body_format: :binary
        )
      IO.puts(\"renewal_without_client_cert=denied\")
    " | tee "${evidence_dir}/renewal-missing-client.txt"
require_output "renewal_without_client_cert=denied" \
    "${evidence_dir}/renewal-missing-client.txt"

renew_node "before-restart" | tee "${evidence_dir}/renewal-before-restart.txt"
require_output "renewal=before-restart:ok" \
    "${evidence_dir}/renewal-before-restart.txt"
systemctl restart exocomp-node.service
sleep 3
systemctl is-active --quiet exocomp-node.service
pass "mTLS renewal succeeds and missing-client-certificate renewal fails"

(
    cd /
    find var/lib/exocomp-coordinator/pki \
        var/lib/exocomp-coordinator/enrollment-tokens \
        -type f -print0 |
        sort -z |
        xargs -0 sha256sum
) > "${evidence_dir}/coordinator-state-before-restart.sha256"
systemctl restart exocomp-coordinator.service
systemctl restart exocomp-node.service
sleep 5
wait_for_coordinator
coordinator_rpc '
  %{status: :healthy} = Exocomp.Coordinator.Health.check()
  IO.puts("coordinator_after_restart=healthy")
' | tee "${evidence_dir}/restart-health.txt"
systemctl is-active --quiet exocomp-node.service
(
    cd /
    find var/lib/exocomp-coordinator/pki \
        var/lib/exocomp-coordinator/enrollment-tokens \
        -type f -print0 |
        sort -z |
        xargs -0 sha256sum
) > "${evidence_dir}/coordinator-state-after-restart.sha256"
cmp \
    "${evidence_dir}/coordinator-state-before-restart.sha256" \
    "${evidence_dir}/coordinator-state-after-restart.sha256"
renew_node "after-restart" | tee "${evidence_dir}/renewal-after-restart.txt"
require_output "renewal=after-restart:ok" \
    "${evidence_dir}/renewal-after-restart.txt"
systemctl restart exocomp-node.service
sleep 3
systemctl is-active --quiet exocomp-node.service
pass "PKI and enrollment state survive service restarts and repeated renewal"

# Make the audit sink unavailable in-memory. A state-changing operation must
# fail and health must degrade. Restarting the service restores the configured
# sink and healthy state.
restore_inventory | tee "${evidence_dir}/inventory-after-restart.txt"

coordinator_rpc '
  :sys.replace_state(Exocomp.Coordinator.Audit, fn state ->
    %{state | sink_state: nil, sink_opts: [path: "/proc/exocomp-denied/audit.jsonl"]}
  end)

  {:error, %{code: :audit_unavailable}} =
    Exocomp.Coordinator.EnrollmentToken.issue("qualification-'"${architecture}"'")
  %{status: :degraded, audit: %{healthy: false}} =
    Exocomp.Coordinator.Health.check()
  IO.puts("audit_unavailable=state_change_denied")
  IO.puts("audit_unavailable=health_degraded")
' | tee "${evidence_dir}/audit-fail-closed.txt"
systemctl restart exocomp-coordinator.service
sleep 5
wait_for_coordinator
coordinator_rpc '
  %{status: :healthy, audit: %{healthy: true}} =
    Exocomp.Coordinator.Health.check()
  IO.puts("audit_after_restart=healthy")
' | tee -a "${evidence_dir}/audit-fail-closed.txt"
pass "audit failure blocks mutation and degrades health"

# Fan a diagnostic goal out from the installed coordinator to the installed
# node plus an intentionally unreachable inventory member. This exercises the
# production runtime's default outbound A2A TLS configuration and proves a
# successful node artifact is retained beside an explicit partial failure.
unreachable_id="${node_id}-unreachable"
coordinator_rpc "
  inventory =
    Jason.encode!(%{
      \"version\" => 1,
      \"nodes\" => [
        %{
          \"id\" => \"${node_id}\",
          \"hostname\" => \"${node_id}\",
          \"port\" => 4433,
          \"certificate_identity\" => \"${node_id}\",
          \"capabilities\" => [\"diagnostics\"],
          \"labels\" => %{\"qualification\" => \"${version}\"}
        },
        %{
          \"id\" => \"${unreachable_id}\",
          \"hostname\" => \"${unreachable_id}\",
          \"port\" => 4433,
          \"certificate_identity\" => \"${unreachable_id}\",
          \"capabilities\" => [\"diagnostics\"],
          \"labels\" => %{\"qualification\" => \"${version}\"}
        }
      ]
    })

  :ok = Exocomp.Coordinator.Inventory.replace_json(inventory)
  :ok = Exocomp.Coordinator.Registry.update(
    \"${node_id}\",
    %{addresses: [\"127.0.0.1\"]}
  )
  :ok = Exocomp.Coordinator.Registry.update(
    \"${unreachable_id}\",
    %{addresses: [\"192.0.2.1\"]}
  )

  {:ok, accepted} =
    Exocomp.Coordinator.Orchestrator.run(
      \"qualification-multinode-${architecture}-\" <>
        Integer.to_string(System.unique_integer([:positive])),
      \"exocomp.system.diagnose\",
      %{},
      [\"${node_id}\", \"${unreachable_id}\"],
      client_opts: [timeout_ms: 2_000]
    )

  terminal =
    Enum.reduce_while(1..100, accepted, fn _, _ ->
      {:ok, goal} = Exocomp.Coordinator.GoalStore.get(accepted.id)

      if Exocomp.Coordinator.DiagnosticGoal.terminal?(goal) do
        {:halt, goal}
      else
        Process.sleep(200)
        {:cont, goal}
      end
    end)

  :completed = terminal.state
  :succeeded = terminal.node_outcomes[\"${node_id}\"].state
  :unreachable = terminal.node_outcomes[\"${unreachable_id}\"].state
  true = length(terminal.node_outcomes[\"${node_id}\"].artifacts) >= 1
  IO.puts(\"multi_node_goal=completed\")
  IO.puts(\"reachable_node=succeeded\")
  IO.puts(\"unreachable_node=explicit\")
  IO.puts(\"partial_artifact_preserved=true\")
  IO.puts(\"correlation_id=#{terminal.id}\")
" | tee "${evidence_dir}/multi-node-diagnostics.txt"
require_output "multi_node_goal=completed" \
    "${evidence_dir}/multi-node-diagnostics.txt"
require_output "partial_artifact_preserved=true" \
    "${evidence_dir}/multi-node-diagnostics.txt"
pass "multi-node diagnostics preserve reachable and explicit partial outcomes"
restore_inventory > "${evidence_dir}/inventory-after-multinode.txt"

# Install the repository's documented systemd qualification fixture. First
# exercise an active-service restart through a real coordinator-signed,
# task-bound approval, then hold the fixture failed and run the automatic
# recovery state machine. Both paths invoke the shipped restricted executor as
# the unprivileged node account.
make -C "${source_dir}" fixture-install
mkdir -p /etc/systemd/system/exocomp-fixture.service.d
printf '[Service]\nRestart=no\n' \
    > /etc/systemd/system/exocomp-fixture.service.d/qualification.conf
systemctl daemon-reload
systemctl restart exocomp-fixture.service
sleep 2
systemctl is-active --quiet exocomp-fixture.service

approval_public_raw="/opt/exocomp/node/config/approval-signing.pub"
sed -n \
    '/BEGIN EXOCOMP ED25519 PUBLIC KEY/,/END EXOCOMP ED25519 PUBLIC KEY/{
      /BEGIN/d
      /END/d
      p
    }' \
    /var/lib/exocomp-coordinator/pki/approval_signing.pub |
    base64 --decode |
    install -o exocomp-node -g exocomp-node -m 0444 /dev/stdin \
        "${approval_public_raw}"

approval_task="qualification-approved-restart-${architecture}"
approval_context="${evidence_dir}/approval-context.json"
approval_token="/run/exocomp-qualification-approval-token"
approval_audit="/var/lib/exocomp-node/approval-qualification-audit.log"

systemctl show exocomp-fixture.service --property=InvocationID \
    > "${evidence_dir}/approval-invocation-before.txt"
node_rpc '
  alias Exocomp.Core.ApprovalToken
  alias Exocomp.Node.Recovery.ApprovalRequired
  alias Exocomp.Recovery.Evidence

  Application.put_env(
    :exocomp_node,
    :approval_public_key_path,
    "'"${approval_public_raw}"'"
  )

  node_id = "'"${node_id}"'"
  service = "exocomp-fixture.service"
  task_id = "'"${approval_task}"'"
  audit_path = "'"${approval_audit}"'"

  collect = fn ->
    value = fn property ->
      {output, 0} =
        System.cmd(
          "/usr/bin/systemctl",
          ["show", service, "--property=#{property}", "--value"]
        )

      String.trim(output)
    end

    Evidence.new(node_id, service, %{
      "active_state" => value.("ActiveState"),
      "sub_state" => value.("SubState"),
      "unit_name" => service
    })
  end

  File.rm(audit_path)

  audit = fn event ->
    File.write!(audit_path, inspect(event, limit: :infinity) <> "\n", [:append])
    :ok
  end

  initial = collect.()

  {:ok, flow} =
    ApprovalRequired.request(
      initial,
      task_id: task_id,
      node_id: node_id,
      allow_list: [service],
      audit_fun: audit,
      refresh_fun: fn _, _ -> {:ok, collect.()} end,
      verify_fun: fn _, _ -> {:ok, collect.()} end
    )

  :persistent_term.put({:qualification_approval, task_id}, flow)

  canonical_evidence = %{
    "active_state" => initial.data["active_state"],
    "sub_state" => initial.data["sub_state"],
    "unit_name" => initial.data["unit_name"]
  }

  IO.puts(
    Jason.encode!(%{
      "action_id" => "restart_service",
      "correlation_id" => flow.machine.correlation_id,
      "evidence_hash" => ApprovalToken.hash_evidence(canonical_evidence),
      "node_id" => node_id,
      "operator" => "qualification-operator",
      "parameter_hash" => ApprovalToken.hash_params(%{"service" => service}),
      "task_id" => task_id
    })
  )
' > "${approval_context}"
chmod 0644 "${approval_context}"

approval_context_b64="$(base64 -w 0 "${approval_context}")"
coordinator_rpc '
  alias Exocomp.Core.ApprovalToken

  context =
    "'"${approval_context_b64}"'"
    |> Base.decode64!()
    |> Jason.decode!()

  now = DateTime.utc_now()

  payload =
    context
    |> Map.merge(%{
      "schema_version" => "1",
      "nonce" =>
        :crypto.strong_rand_bytes(32)
        |> Base.url_encode64(padding: false),
      "issued_at" =>
        now |> DateTime.add(-1, :second) |> DateTime.to_iso8601(),
      "expires_at" =>
        now |> DateTime.add(300, :second) |> DateTime.to_iso8601()
    })

  encoded_private =
    "/var/lib/exocomp-coordinator/pki/approval_signing.key"
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.at(1)

  private_key = Base.decode64!(encoded_private)

  signature =
    :crypto.sign(
      :eddsa,
      :none,
      ApprovalToken.canonical_encode(payload),
      [private_key, :ed25519]
    )

  IO.puts(
    Jason.encode!(%{
      "payload" => payload,
      "signature" => Base.url_encode64(signature, padding: false)
    })
  )
' > "${approval_token}"
install -o exocomp-node -g exocomp-node -m 0400 \
    "${approval_token}" "${approval_token}.node"
rm -f "${approval_token}"

node_rpc '
  alias Exocomp.Node.Recovery.ApprovalRequired

  task_id = "'"${approval_task}"'"
  flow = :persistent_term.get({:qualification_approval, task_id})
  token = File.read!("'"${approval_token}.node"'") |> Jason.decode!()

  {:ok, completed} =
    ApprovalRequired.approve(flow, token, "qualification-operator")

  :completed = completed.machine.state
  :completed = completed.task.status.state

  {:error, :duplicate_approval, replay_pending} =
    ApprovalRequired.approve(flow, token, "qualification-operator")

  :awaiting_approval = replay_pending.machine.state
  IO.puts("active_service_approval=completed")
  IO.puts("approval_execution=one_restricted_restart")
  IO.puts("approval_replay=denied")
' | tee "${evidence_dir}/active-service-approval.txt"
rm -f "${approval_token}.node"
systemctl show exocomp-fixture.service --property=InvocationID \
    > "${evidence_dir}/approval-invocation-after.txt"
! cmp -s \
    "${evidence_dir}/approval-invocation-before.txt" \
    "${evidence_dir}/approval-invocation-after.txt"
systemctl is-active --quiet exocomp-fixture.service
require_output "approval_replay=denied" \
    "${evidence_dir}/active-service-approval.txt"
pass "active-service restart requires a valid bound approval and rejects replay"

printf 'failed\n' > /run/exocomp-fixture/mode
for _attempt in $(seq 1 20); do
    if systemctl is-failed --quiet exocomp-fixture.service; then
        break
    fi
    sleep 1
done
systemctl is-failed --quiet exocomp-fixture.service
mkdir -p /run/exocomp-fixture
printf 'active\n' > /run/exocomp-fixture/mode
systemctl show exocomp-fixture.service \
    --property=ActiveState,SubState,Result,InvocationID \
    > "${evidence_dir}/fixture-before-recovery.txt"

node_rpc '
  alias Exocomp.Node.Recovery.FailedService
  alias Exocomp.Recovery.Evidence

  collect = fn ->
    value = fn property ->
      {output, 0} =
        System.cmd(
          "/usr/bin/systemctl",
          ["show", "exocomp-fixture.service", "--property=#{property}", "--value"]
        )
      String.trim(output)
    end

    health =
      case :httpc.request(~c"http://127.0.0.1:8877/health") do
        {:ok, {{_version, 200, _reason}, _headers, _body}} -> "healthy"
        _other -> "unhealthy"
      end

    Evidence.new(
      "qualification-node",
      "exocomp-fixture.service",
      %{
        "active_state" => value.("ActiveState"),
        "sub_state" => value.("SubState"),
        "health" => health,
        "unit_name" => "exocomp-fixture.service"
      }
    )
  end

  initial = collect.()
  audit_path = "/var/lib/exocomp-node/recovery-qualification-audit.log"
  File.rm(audit_path)

  audit = fn event ->
    File.write!(audit_path, inspect(event, limit: :infinity) <> "\n", [:append])
    :ok
  end

  {:ok, result} =
    FailedService.recover(
      initial,
      task_id: "qualification-systemd-recovery",
      allow_list: ["exocomp-fixture.service"],
      audit_fun: audit,
      refresh_fun: fn _, _ -> {:ok, collect.()} end,
      verify_fun: fn _, _ -> {:ok, collect.()} end,
      wait_fun: fn -> Process.sleep(500) end,
      stability_samples: 2,
      verification_attempts: 3
    )

  :completed = result.machine.state
  :completed = result.task.status.state
  6 = File.stream!(audit_path) |> Enum.count()
  IO.puts("recovery_state=completed")
  IO.puts("recovery_audit_events=6")
  IO.puts("recovery_execution=one_restricted_restart")
' | tee "${evidence_dir}/failed-service-recovery.txt"
systemctl is-active --quiet exocomp-fixture.service
curl -fsS http://127.0.0.1:8877/health \
    > "${evidence_dir}/fixture-health-after-recovery.json"
systemctl show exocomp-fixture.service \
    --property=ActiveState,SubState,Result,InvocationID \
    > "${evidence_dir}/fixture-after-recovery.txt"
cp /var/lib/exocomp-node/recovery-qualification-audit.log \
    "${evidence_dir}/recovery-audit.log"
require_output "recovery_execution=one_restricted_restart" \
    "${evidence_dir}/failed-service-recovery.txt"
pass "failed fixture recovers exactly once through shipped restricted executor"

# Validate the only cleanup action against the exact installed sudoers entry.
# Then demonstrate that caller-selected service commands, shells, user-data
# cleanup sources, and unknown actions are denied without side effects.
node_rpc '
  alias Exocomp.Node.{ActionCatalog, Executor, VacuumBounds}

  [:restart_service, :vacuum_logs] = ActionCatalog.action_ids()
  {:error, :not_allowed} =
    ActionCatalog.lookup(
      :restart_service,
      "not-allow-listed.service",
      ["exocomp-fixture.service"]
    )
  {:error, :unknown_action} =
    ActionCatalog.lookup(:delete_user_data, "/home/operator", [])
  {:error, :user_data_path} =
    VacuumBounds.validate_source("/home/operator")
  {:error, :unknown_path} =
    VacuumBounds.validate_source("/var/log")
  {:ok, result} =
    Executor.execute(:vacuum_logs, nil, ["exocomp-fixture.service"])
  0 = result.exit_code
  IO.puts("bounded_journal_cleanup=completed")
  IO.puts("user_data_cleanup=denied")
  IO.puts("unknown_action=denied")
' | tee "${evidence_dir}/bounded-cleanup-and-unsafe-modes.txt"

sudo -n -l -U exocomp-node > "${evidence_dir}/node-sudo-list.txt"
set +e
sudo -u exocomp-node sudo -n /usr/bin/systemctl restart ssh.service \
    >> "${evidence_dir}/bounded-cleanup-and-unsafe-modes.txt" 2>&1
unsafe_service_rc=$?
sudo -u exocomp-node sudo -n /bin/sh -c true \
    >> "${evidence_dir}/bounded-cleanup-and-unsafe-modes.txt" 2>&1
unsafe_shell_rc=$?
set -e
test "${unsafe_service_rc}" -ne 0
test "${unsafe_shell_rc}" -ne 0
printf 'unlisted_service_sudo=denied\nshell_sudo=denied\n' |
    tee -a "${evidence_dir}/bounded-cleanup-and-unsafe-modes.txt"
require_output "bounded_journal_cleanup=completed" \
    "${evidence_dir}/bounded-cleanup-and-unsafe-modes.txt"
require_output "shell_sudo=denied" \
    "${evidence_dir}/bounded-cleanup-and-unsafe-modes.txt"
pass "bounded cleanup succeeds while unsafe action modes fail closed"

systemd-analyze security \
    exocomp-coordinator.service exocomp-node.service --no-pager \
    > "${evidence_dir}/systemd-security.txt"
systemctl cat exocomp-coordinator.service exocomp-node.service \
    > "${evidence_dir}/systemd-units.txt"
visudo -cf /etc/sudoers.d/exocomp-node \
    > "${evidence_dir}/node-sudoers-validation.txt" 2>&1
{
    stat -c '%a %U:%G %n' \
        /etc/systemd/system/exocomp-coordinator.service \
        /etc/systemd/system/exocomp-node.service \
        /etc/sudoers.d/exocomp-node \
        /opt/exocomp/coordinator/config/release-cookie.env \
        /opt/exocomp/node/config/release-cookie.env \
        /var/lib/exocomp-coordinator/pki/intermediate_ca_key.pem \
        /var/lib/exocomp-coordinator/pki/coordinator_key.pem \
        /var/lib/exocomp-node/credentials/current/key.pem
    printf 'world-writable-files='
    find /opt/exocomp /var/lib/exocomp-coordinator /var/lib/exocomp-node \
        -xdev -type f -perm -0002 -print | wc -l
} > "${evidence_dir}/ownership-and-modes.txt"
require_output "world-writable-files=0" "${evidence_dir}/ownership-and-modes.txt"
pass "systemd hardening, exact sudoers, ownership, and key modes inspected"

make -C "${source_dir}" fixture-cleanup
test ! -e /etc/systemd/system/exocomp-fixture.service
test ! -e /usr/local/bin/exocomp-fixture
test ! -e /run/exocomp-fixture
pass "documented systemd fixture cleanup removes all fixture-owned paths"

printf '[PASS] operational live qualification complete\n'
