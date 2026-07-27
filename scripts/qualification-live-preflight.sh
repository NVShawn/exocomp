#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Destructive qualification helper for the dedicated release-candidate guests.
# It operates only on Exocomp-owned paths and the qualification fixture.

set -euo pipefail

version="${QUALIFICATION_VERSION:?QUALIFICATION_VERSION is required}"
architecture="${QUALIFICATION_ARCH:?QUALIFICATION_ARCH is required}"
qualification_root="${QUALIFICATION_ROOT:?QUALIFICATION_ROOT is required}"
dist_dir="${QUALIFICATION_DIST:-${qualification_root}/prelive-dist}"
evidence_dir="${QUALIFICATION_EVIDENCE:-${qualification_root}/evidence/raw/${architecture}/prelive/live}"
bundle_name="exocomp-complete-${version}-linux-${architecture}"
bundle_dir="${dist_dir}/${bundle_name}"
source_dir="${qualification_root}/src-gates"
public_key="/var/lib/exocomp-qualification/qualification.pub"
node_id="qualification-${architecture}"
offline_root="/tmp/exocomp-offline-root-${version}-${architecture}"
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

printf 'candidate=%s architecture=%s commit=%s\n' \
    "${version}" "${architecture}" "$(git -C "${source_dir}" rev-parse HEAD)"

rm -rf "${bundle_dir}"
mkdir -p "${bundle_dir}"
tar -xzf "${dist_dir}/${bundle_name}.tar.gz" -C "${bundle_dir}" --strip-components=1

unshare --net bash "${source_dir}/scripts/verify-bundle.sh" \
    --bundle-dir "${bundle_dir}" \
    --public-key "${public_key}" \
    --strict |
    tee "${evidence_dir}/offline-verification.txt"
pass "strict verification succeeds with no network namespace"

systemctl stop exocomp-node.service exocomp-coordinator.service 2>/dev/null || true
bash "${bundle_dir}/scripts/uninstall.sh" \
    --component node --purge system-cache --non-interactive 2>/dev/null || true
bash "${bundle_dir}/scripts/uninstall.sh" \
    --component coordinator --purge system-cache --non-interactive 2>/dev/null || true
rm -rf /opt/exocomp /var/lib/exocomp-node /var/lib/exocomp-coordinator "${offline_root}"
rm -f /etc/systemd/system/exocomp-node.service
rm -f /etc/systemd/system/exocomp-coordinator.service
rm -f /etc/sudoers.d/exocomp-node /etc/sudoers.d/exocomp-coordinator
systemctl daemon-reload

unshare --net bash "${bundle_dir}/scripts/install.sh" \
    --component coordinator \
    --bundle "${bundle_dir}/releases/exocomp-coordinator-${version}-linux-${architecture}.tar.gz" \
    --no-start \
    --non-interactive |
    tee "${evidence_dir}/coordinator-install.txt"
pass "coordinator installs without network access"

passphrase_file="/run/exocomp-qualification-root-passphrase"
install -o exocomp-coordinator -g exocomp-coordinator -m 0600 \
    <(printf 'qualification-only-root-passphrase-%s' "${architecture}") \
    "${passphrase_file}"
rm -rf "${offline_root}"

sudo -u exocomp-coordinator \
    env EXOCOMP_ROOT_KEY_PASSPHRASE_FILE="${passphrase_file}" \
    bash -c '
      cd /opt/exocomp/coordinator
      set -a
      . ./config/release-cookie.env
      set +a
      exec ./current/bin/exocomp_coordinator eval "$1"
    ' bash "
      passphrase =
        System.fetch_env!(\"EXOCOMP_ROOT_KEY_PASSPHRASE_FILE\")
        |> File.read!()
        |> String.trim()

      case Exocomp.Coordinator.PKI.Bootstrap.initialize(
             online_state: \"/var/lib/exocomp-coordinator/pki\",
             offline_backup: \"${offline_root}\",
             root_key_protection: {:passphrase, passphrase}
           ) do
        {:ok, metadata} ->
          IO.puts(\"disposition=#{metadata.disposition}\")
          IO.puts(\"root_fingerprint=#{metadata.root_fingerprint}\")

        {:error, error} ->
          IO.puts(:stderr, \"pki_error=#{error.code}\")
          System.halt(1)
      end
    " |
    tee "${evidence_dir}/pki-initialization.txt"
rm -f "${passphrase_file}"
require_output "disposition=initialized" "${evidence_dir}/pki-initialization.txt"
pass "production PKI initializes from the shipped coordinator"
sha256sum "${offline_root}/root_ca.pem" > "${evidence_dir}/offline-root-public.sha256"
install -m 0644 /var/lib/exocomp-coordinator/pki/root_ca.pem "${public_root}"
install -m 0644 /var/lib/exocomp-coordinator/pki/root_ca.pem "${public_chain}"
cat /var/lib/exocomp-coordinator/pki/intermediate_ca.pem >> "${public_chain}"
rm -rf "${offline_root}"
pass "offline root was removed before production startup"

if ! grep -Fq "127.0.0.1 exocomp-coordinator" /etc/hosts; then
    printf '127.0.0.1 exocomp-coordinator\n' >> /etc/hosts
fi

systemctl enable --now exocomp-coordinator.service
sleep 5

coordinator_rpc() {
    local expression="$1"
    bash -c '
      set -a
      . /opt/exocomp/coordinator/config/release-cookie.env
      set +a
      exec /opt/exocomp/coordinator/current/bin/exocomp_coordinator rpc "$1"
    ' bash "${expression}"
}

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
  %{status: :healthy} = Exocomp.Coordinator.Health.check()
  IO.puts("coordinator_ready=true")
' | tee "${evidence_dir}/coordinator-ready.txt"

token_file="/run/exocomp-qualification-enrollment-token"
coordinator_rpc '
  case Exocomp.Coordinator.EnrollmentToken.issue("'"${node_id}"'") do
    {:ok, token} -> IO.write(token)
    {:error, error} ->
      raise "token_issue_error=#{error.code}"
  end
' > "${token_file}"
chmod 0600 "${token_file}"
printf 'token_issued=true token_length=%s token_value=[REDACTED]\n' \
    "$(wc -c < "${token_file}")" |
    tee "${evidence_dir}/enrollment-token-redacted.txt"

unshare --net bash "${bundle_dir}/scripts/install.sh" \
    --component node \
    --bundle "${bundle_dir}/releases/exocomp-node-${version}-linux-${architecture}.tar.gz" \
    --allow-list exocomp-fixture.service \
    --no-start \
    --non-interactive |
    tee "${evidence_dir}/node-install.txt"
pass "node installs without network access"

sudo -u exocomp-node \
    env ENROLLMENT_TOKEN="$(<"${token_file}")" \
    bash -c '
      cd /opt/exocomp/node
      set -a
      . ./config/release-cookie.env
      set +a
      exec ./current/bin/exocomp_node eval "$1"
    ' bash "
      {:ok, _} = Application.ensure_all_started(:ssl)
      {:ok, _} = Application.ensure_all_started(:inets)
      ca_path = \"${public_root}\"
      ca_pem = File.read!(ca_path)

      case Exocomp.Node.EnrollmentClient.enroll(
             node_id: \"${node_id}\",
             token: System.fetch_env!(\"ENROLLMENT_TOKEN\"),
             endpoint: \"https://exocomp-coordinator:4443/v1/enroll\",
             credential_dir: \"/var/lib/exocomp-node/credentials\",
             ca_file: \"${public_chain}\",
             ca_pem: ca_pem
           ) do
        {:ok, paths} ->
          IO.puts(\"enrollment=ok\")
          IO.puts(\"generation=\" <> Path.basename(paths.generation))

        {:error, reason} ->
          IO.puts(:stderr, \"enrollment_error=\" <> inspect(reason))
          System.halt(1)
      end
    " |
    tee "${evidence_dir}/enrollment.txt"
rm -f "${token_file}"
require_output "enrollment=ok" "${evidence_dir}/enrollment.txt"

python3 - "${node_id}" <<'PY'
import json
import pathlib
import sys

node_id = sys.argv[1]
path = pathlib.Path("/opt/exocomp/node/config/node.json")
config = json.loads(path.read_text())
config["node_id"] = node_id
config["node"]["id"] = node_id
config["node"]["label"] = "qualification"
config["tls"]["ca_cert"] = "/var/lib/exocomp-coordinator/pki/root_ca.pem"
config["tls"]["node_cert"] = "/var/lib/exocomp-node/credentials/current/chain.pem"
config["tls"]["node_key"] = "/var/lib/exocomp-node/credentials/current/key.pem"
config["coordinator"]["host"] = "exocomp-coordinator"
config["coordinator"]["port"] = 4443
config["coordinator"]["tls"]["ca_cert"] = config["tls"]["ca_cert"]
config["coordinator"]["tls"]["cert"] = config["tls"]["node_cert"]
config["coordinator"]["tls"]["key"] = config["tls"]["node_key"]
path.write_text(json.dumps(config, indent=2) + "\n")
PY
chown exocomp-node:exocomp-node /opt/exocomp/node/config/node.json
chmod 0640 /opt/exocomp/node/config/node.json

# The node account needs read-only access to the public root certificate.
install -d -o exocomp-node -g exocomp-node -m 0700 /opt/exocomp/node/config/pki
install -o exocomp-node -g exocomp-node -m 0644 \
    /var/lib/exocomp-coordinator/pki/root_ca.pem \
    /opt/exocomp/node/config/pki/ca.crt
python3 - <<'PY'
import json
import pathlib

path = pathlib.Path("/opt/exocomp/node/config/node.json")
config = json.loads(path.read_text())
config["tls"]["ca_cert"] = "/opt/exocomp/node/config/pki/ca.crt"
config["coordinator"]["tls"]["ca_cert"] = config["tls"]["ca_cert"]
path.write_text(json.dumps(config, indent=2) + "\n")
PY
chown exocomp-node:exocomp-node /opt/exocomp/node/config/node.json

systemctl enable --now exocomp-node.service
sleep 5
systemctl is-active --quiet exocomp-node.service
pass "enrolled node starts from the shipped release"

systemctl status exocomp-coordinator.service exocomp-node.service --no-pager \
    > "${evidence_dir}/service-status.txt"
systemd-analyze security exocomp-coordinator.service exocomp-node.service --no-pager \
    > "${evidence_dir}/systemd-security.txt"

printf '[PASS] live preflight complete\n'
