#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Destructive lifecycle qualification for dedicated release-candidate guests.
# Run only after the live operational and performance scenarios have completed.

set -euo pipefail
umask 077

version="${QUALIFICATION_VERSION:?QUALIFICATION_VERSION is required}"
architecture="${QUALIFICATION_ARCH:?QUALIFICATION_ARCH is required}"
qualification_root="${QUALIFICATION_ROOT:?QUALIFICATION_ROOT is required}"
dist_dir="${QUALIFICATION_DIST:?QUALIFICATION_DIST is required}"
evidence_dir="${QUALIFICATION_EVIDENCE:?QUALIFICATION_EVIDENCE is required}"
bundle_name="exocomp-complete-${version}-linux-${architecture}"
bundle_dir="${dist_dir}/${bundle_name}"
node_archive="${bundle_dir}/releases/exocomp-node-${version}-linux-${architecture}.tar.gz"
coordinator_archive="${bundle_dir}/releases/exocomp-coordinator-${version}-linux-${architecture}.tar.gz"
backup_dir="${qualification_root}/lifecycle-backups/${architecture}"
previous_version="${version}-qualification-previous"
unrelated_path="/srv/exocomp-qualification-unrelated-${version}-${architecture}"

mkdir -p "${evidence_dir}" "${backup_dir}"
exec > >(tee -a "${evidence_dir}/transcript.txt") 2>&1

pass() {
    printf '[PASS] %s\n' "$*"
}

installed_rpc() {
    local component="$1"
    local expression="$2"
    bash -c '
      set -a
      . "/opt/exocomp/$1/config/release-cookie.env"
      set +a
      exec "/opt/exocomp/$1/current/bin/exocomp_$1" rpc "$2"
    ' bash "${component}" "${expression}"
}

record_protected_hashes() {
    local destination="$1"
    (
        cd /
        sha256sum \
            opt/exocomp/node/config/node.json \
            opt/exocomp/node/config/release-cookie.env \
            var/lib/exocomp-node/credentials/current/chain.pem \
            var/lib/exocomp-node/credentials/current/key.pem \
            var/lib/exocomp-node/qualification-preserved-state \
            opt/exocomp/coordinator/config/coordinator.json \
            opt/exocomp/coordinator/config/release-cookie.env \
            var/lib/exocomp-coordinator/pki/root_ca.pem \
            var/lib/exocomp-coordinator/pki/intermediate_ca.pem \
            var/lib/exocomp-coordinator/pki/intermediate_ca_key.pem \
            var/lib/exocomp-coordinator/pki/coordinator.pem \
            var/lib/exocomp-coordinator/pki/coordinator_chain.pem \
            var/lib/exocomp-coordinator/pki/coordinator_key.pem \
            var/lib/exocomp-coordinator/qualification-preserved-state \
            "${unrelated_path#/}"
    ) > "${destination}"
}

test -d "${bundle_dir}"
test -f "${node_archive}"
test -f "${coordinator_archive}"
systemctl is-active --quiet exocomp-node.service
systemctl is-active --quiet exocomp-coordinator.service

printf 'candidate=%s architecture=%s commit=%s\n' \
    "${version}" "${architecture}" \
    "$(git -C "${qualification_root}/src-gates" rev-parse HEAD)"

install -d -m 0755 "$(dirname "${unrelated_path}")"
printf 'unrelated-resource-preserved\n' > "${unrelated_path}"
printf 'node-protected-state-preserved\n' \
    > /var/lib/exocomp-node/qualification-preserved-state
printf 'coordinator-protected-state-preserved\n' \
    > /var/lib/exocomp-coordinator/qualification-preserved-state
chown exocomp-node:exocomp-node \
    /var/lib/exocomp-node/qualification-preserved-state
chown exocomp-coordinator:exocomp-coordinator \
    /var/lib/exocomp-coordinator/qualification-preserved-state
chmod 0600 \
    /var/lib/exocomp-node/qualification-preserved-state \
    /var/lib/exocomp-coordinator/qualification-preserved-state

# Exercise the installed protected-state utility, including its adjacent
# checksum verification, against production PKI material.
systemctl stop exocomp-node.service exocomp-coordinator.service
record_protected_hashes "${evidence_dir}/protected-state-before.sha256"
backup_archive="${backup_dir}/coordinator-state.tar.gz"
rm -f "${backup_archive}" "${backup_archive}.sha256"
/opt/exocomp/coordinator/current/bin/exocomp-state-backup create \
    --component coordinator \
    --output "${backup_archive}" |
    tee "${evidence_dir}/backup-create.txt"
(
    cd "${backup_dir}"
    sha256sum -c "$(basename "${backup_archive}.sha256")"
) | tee "${evidence_dir}/backup-checksum.txt"

root_hash="$(sha256sum /var/lib/exocomp-coordinator/pki/root_ca.pem)"
rm -f \
    /var/lib/exocomp-coordinator/pki/root_ca.pem \
    /var/lib/exocomp-coordinator/qualification-preserved-state
/opt/exocomp/coordinator/current/bin/exocomp-state-backup restore \
    --component coordinator \
    --archive "${backup_archive}" \
    --force |
    tee "${evidence_dir}/backup-restore.txt"
test "${root_hash}" = \
    "$(sha256sum /var/lib/exocomp-coordinator/pki/root_ca.pem)"
test -f /var/lib/exocomp-coordinator/qualification-preserved-state
pass "installed backup utility restores protected coordinator PKI and state"

systemctl start exocomp-coordinator.service
systemctl start exocomp-node.service
sleep 5
installed_rpc coordinator '
  %{status: :healthy} = Exocomp.Coordinator.Health.check()
  IO.puts("coordinator_after_restore=healthy")
' | tee "${evidence_dir}/health-after-restore.txt"
systemctl is-active --quiet exocomp-node.service

# Activate the exact candidate payload under an artificial prior-version
# identity. Then reinstall the candidate with a forced application-health
# failure and require the installer to restore that known-good prior link.
bash "${bundle_dir}/scripts/install.sh" \
    --component node \
    --bundle "${node_archive}" \
    --version "${previous_version}" \
    --allow-list exocomp-fixture.service \
    --non-interactive |
    tee "${evidence_dir}/upgrade-prior-install.txt"
test "$(readlink /opt/exocomp/node/current)" = \
    "releases/${previous_version}"
systemctl is-active --quiet exocomp-node.service

set +e
EXOCOMP_HEALTHCHECK_COMMAND=/bin/false \
EXOCOMP_HEALTHCHECK_ATTEMPTS=1 \
EXOCOMP_HEALTHCHECK_INTERVAL=0 \
    bash "${bundle_dir}/scripts/install.sh" \
        --component node \
        --bundle "${node_archive}" \
        --version "${version}" \
        --allow-list exocomp-fixture.service \
        --non-interactive \
        > "${evidence_dir}/automatic-rollback.txt" 2>&1
rollback_rc=$?
set -e
printf 'installer_exit=%s\n' "${rollback_rc}" \
    >> "${evidence_dir}/automatic-rollback.txt"
test "${rollback_rc}" -ne 0
grep -Fq "prior current version restored" \
    "${evidence_dir}/automatic-rollback.txt"
test "$(readlink /opt/exocomp/node/current)" = \
    "releases/${previous_version}"
systemctl is-active --quiet exocomp-node.service
installed_rpc node '
  listener = Process.whereis(Exocomp.Node.Listener)
  true = is_pid(listener) and Process.alive?(listener)
  IO.puts("rolled_back_node=healthy")
' | tee "${evidence_dir}/health-after-rollback.txt"
pass "failed candidate health gate automatically restores the prior release"

record_protected_hashes "${evidence_dir}/protected-state-after-rollback.sha256"
cmp \
    "${evidence_dir}/protected-state-before.sha256" \
    "${evidence_dir}/protected-state-after-rollback.sha256"
pass "upgrade and rollback preserve credentials, PKI, config, and durable state"

# Default removal must remove owned executables/integration while preserving
# all protected state and unrelated resources.
bash "${bundle_dir}/scripts/uninstall.sh" \
    --component node \
    --non-interactive |
    tee "${evidence_dir}/uninstall-node-default.txt"
test ! -e /etc/systemd/system/exocomp-node.service
test ! -e /etc/sudoers.d/exocomp-node
test ! -e /opt/exocomp/node/current
test -f /opt/exocomp/node/config/node.json
test -f /var/lib/exocomp-node/credentials/current/key.pem

bash "${bundle_dir}/scripts/uninstall.sh" \
    --component coordinator \
    --non-interactive |
    tee "${evidence_dir}/uninstall-coordinator-default.txt"
test ! -e /etc/systemd/system/exocomp-coordinator.service
test ! -e /opt/exocomp/coordinator/current
test -f /opt/exocomp/coordinator/config/coordinator.json
test -f /var/lib/exocomp-coordinator/pki/root_ca.pem
record_protected_hashes "${evidence_dir}/protected-state-after-default-uninstall.sha256"
cmp \
    "${evidence_dir}/protected-state-before.sha256" \
    "${evidence_dir}/protected-state-after-default-uninstall.sha256"
pass "default uninstall preserves protected and unrelated state"

# Reinstall without starting, then exercise the only supported purge category.
# It may remove release caches but still cannot touch protected data.
bash "${bundle_dir}/scripts/install.sh" \
    --component node \
    --bundle "${node_archive}" \
    --version "${version}" \
    --allow-list exocomp-fixture.service \
    --no-start \
    --non-interactive |
    tee "${evidence_dir}/reinstall-node-for-purge.txt"
bash "${bundle_dir}/scripts/install.sh" \
    --component coordinator \
    --bundle "${coordinator_archive}" \
    --version "${version}" \
    --no-start \
    --non-interactive |
    tee "${evidence_dir}/reinstall-coordinator-for-purge.txt"

bash "${bundle_dir}/scripts/uninstall.sh" \
    --component node \
    --purge system-cache \
    --non-interactive |
    tee "${evidence_dir}/uninstall-node-purge.txt"
bash "${bundle_dir}/scripts/uninstall.sh" \
    --component coordinator \
    --purge system-cache \
    --non-interactive |
    tee "${evidence_dir}/uninstall-coordinator-purge.txt"
test -z "$(find /opt/exocomp/node/releases -mindepth 1 -print -quit)"
test -z "$(find /opt/exocomp/coordinator/releases -mindepth 1 -print -quit)"
record_protected_hashes "${evidence_dir}/protected-state-after-purge-uninstall.sha256"
cmp \
    "${evidence_dir}/protected-state-before.sha256" \
    "${evidence_dir}/protected-state-after-purge-uninstall.sha256"
pass "system-cache purge removes releases and preserves all protected state"

printf '[PASS] lifecycle qualification complete\n'
