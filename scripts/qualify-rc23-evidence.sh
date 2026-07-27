#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Collect rc.23 evidence from both qualification guests and sign its index.

set -euo pipefail

VERSION="0.1.0-rc.23"
SOURCE_COMMIT="902bee1a52bf037fdaab50bd0c71ba82fa51a8d6"
AMD64_IP="192.168.122.136"
ARM64_IP="192.168.122.171"
RC_DIR="/var/lib/exocomp-qualification/rc23"
REPO_EVIDENCE_DIR="docs/release-evidence/v${VERSION}"
SSH_OPTS="-F /dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
RSYNC_RSH="ssh ${SSH_OPTS}"
EVIDENCE_SIGNING_KEY="$(git config --get user.signingkey)"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

test "$(git rev-parse "v${VERSION}^{}")" = "${SOURCE_COMMIT}"
git verify-tag "v${VERSION}"

echo "=== $(ts) Checking qualification status ==="
for target in "amd64:${AMD64_IP}" "arm64:${ARM64_IP}"; do
    architecture="${target%%:*}"
    address="${target#*:}"
    status="$(
        ssh ${SSH_OPTS} "root@${address}" \
            "cat ${RC_DIR}/qualification-status.txt 2>/dev/null || true"
    )"
    echo "${architecture} status: ${status:-not complete}"
    if ! grep -q '^QUALIFICATION_STATUS=pass$' <<< "${status}"; then
        ssh ${SSH_OPTS} "root@${address}" \
            "tail -40 ${RC_DIR}/orchestration.log 2>/dev/null || true"
        echo "[FAIL] ${architecture} qualification did not complete" >&2
        exit 1
    fi
    ssh ${SSH_OPTS} "root@${address}" \
        "minisign -Vm \
            ${RC_DIR}/evidence/raw/${architecture}/artifacts/manifest.sha256 \
            -p /var/lib/exocomp-qualification/qualification.pub \
            -x ${RC_DIR}/evidence/raw/${architecture}/artifacts/bundle.minisig"
done

test ! -e "${REPO_EVIDENCE_DIR}"
mkdir -p \
    "${REPO_EVIDENCE_DIR}/raw/amd64" \
    "${REPO_EVIDENCE_DIR}/raw/arm64"

echo "=== $(ts) Syncing raw evidence ==="
rsync -a --checksum -e "${RSYNC_RSH}" \
    "root@${AMD64_IP}:${RC_DIR}/evidence/raw/amd64/" \
    "${REPO_EVIDENCE_DIR}/raw/amd64/"
rsync -a --checksum -e "${RSYNC_RSH}" \
    "root@${ARM64_IP}:${RC_DIR}/evidence/raw/arm64/" \
    "${REPO_EVIDENCE_DIR}/raw/arm64/"

for target in \
    "amd64:${AMD64_IP}:exocomp-amd64-qualification" \
    "arm64:${ARM64_IP}:exocomp-arm64-qualification"; do
    architecture="${target%%:*}"
    remainder="${target#*:}"
    address="${remainder%%:*}"
    domain="${remainder#*:}"
    rsync -a --checksum -e "${RSYNC_RSH}" \
        "root@${address}:${RC_DIR}/orchestration.log" \
        "${REPO_EVIDENCE_DIR}/raw/${architecture}/orchestration.log"
    rsync -a --checksum -e "${RSYNC_RSH}" \
        "root@${address}:${RC_DIR}/qualification-status.txt" \
        "${REPO_EVIDENCE_DIR}/raw/${architecture}/qualification-status.txt"
    ssh ${SSH_OPTS} "root@${address}" \
        'uname -a; systemd-detect-virt; systemctl is-system-running; lscpu' \
        > "${REPO_EVIDENCE_DIR}/raw/${architecture}/guest-runtime.txt"
    {
        virsh dominfo "${domain}"
        virsh dumpxml "${domain}"
    } > "${REPO_EVIDENCE_DIR}/raw/${architecture}/hypervisor.txt"
done

echo "=== $(ts) Auditing collected evidence ==="
for architecture in amd64 arm64; do
    evidence_root="${REPO_EVIDENCE_DIR}/raw/${architecture}"

    grep -Fq "${SOURCE_COMMIT}" \
        "${evidence_root}/candidate-tag-verification.txt"
    grep -Fq 'Good "git" signature' \
        "${evidence_root}/candidate-tag-verification.txt"
    grep -Fq "commit=${SOURCE_COMMIT}" \
        "${evidence_root}/host-and-candidate.txt"
    grep -Fxq 'QUALIFICATION_STATUS=pass' \
        "${evidence_root}/qualification-status.txt"

    for gate in \
        fmt-check \
        lint \
        release-check \
        test-release-packaging \
        test-installer \
        test-bundle \
        test \
        test-release-matrix \
        test-m5-qualification; do
        test -s "${evidence_root}/repo-gates/${gate}.txt"
    done

    test "$(
        grep -Fc '[PASS] Reproducible:' \
            "${evidence_root}/artifacts/build-reproducibility.txt"
    )" -eq 2
    test "$(
        cut -d' ' -f1 \
            "${evidence_root}/artifacts/bundle-reproducibility.sha256" |
            sort -u |
        wc -l
    )" -eq 1
    if [ "${architecture}" = arm64 ]; then
        grep -Fq 'GGML_OPENMP:BOOL=OFF' \
            "${evidence_root}/artifacts/runtime-inputs.txt"
        grep -Fq -- '-sleep 5' \
            "${evidence_root}/orchestration-readiness-override.diff"
        grep -Fq -- '+sleep 30' \
            "${evidence_root}/orchestration-readiness-override.diff"
        grep -Fq -- '-sleep 5' \
            "${evidence_root}/orchestration-lifecycle-readiness-override.diff"
        grep -Fq -- '+sleep 30' \
            "${evidence_root}/orchestration-lifecycle-readiness-override.diff"
    else
        grep -Fq '/llama-b10107-no-openmp/' \
            "${evidence_root}/artifacts/runtime-inputs.txt"
    fi
    if grep -Fq 'libgomp' "${evidence_root}/artifacts/runtime-inputs.txt"; then
        echo "[FAIL] ${architecture} runtime input retains libgomp" >&2
        exit 1
    fi

    grep -Fq '[PASS] live preflight complete' \
        "${evidence_root}/prelive/live/transcript.txt"
    grep -Fq '[PASS] operational live qualification complete' \
        "${evidence_root}/operational/transcript.txt"
    grep -Fq '[PASS] lifecycle qualification complete' \
        "${evidence_root}/lifecycle/transcript.txt"

    python3 - "${evidence_root}" "${architecture}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
architecture = sys.argv[2]
expected_commit = "902bee1a52bf037fdaab50bd0c71ba82fa51a8d6"
manifest = json.loads(
    (root / "artifacts" / "manifest.json").read_text(encoding="utf-8")
)
assert manifest["source"]["commit"] == expected_commit, root / "artifacts" / "manifest.json"
assert manifest["bundle"]["version"] == "0.1.0-rc.23", root / "artifacts" / "manifest.json"
assert manifest["bundle"]["architecture"] == architecture, root / "artifacts" / "manifest.json"

provenance = json.loads(
    (root / "artifacts" / "provenance.json").read_text(encoding="utf-8")
)
assert (
    provenance["predicate"]["invocation"]["configSource"]["digest"]["sha1"]
    == expected_commit
), root / "artifacts" / "provenance.json"

sbom = json.loads((root / "artifacts" / "sbom.spdx.json").read_text(encoding="utf-8"))
assert sbom.get("spdxVersion", "").startswith("SPDX-"), root / "artifacts" / "sbom.spdx.json"
assert expected_commit in json.dumps(sbom), root / "artifacts" / "sbom.spdx.json"

license_lines = [
    line for line in
    (root / "artifacts" / "licenses.sha256").read_text(encoding="utf-8").splitlines()
    if line.strip()
]
assert len(license_lines) >= 3, root / "artifacts" / "licenses.sha256"

for directory, expected_mode in (("bench-short", "short"), ("bench", "full")):
    summary_path = root / directory / "summary.json"
    samples_path = root / directory / "samples.jsonl"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    assert summary["config"]["mode"] == expected_mode, summary_path
    gates = summary.get("gate_results", [])
    assert gates, summary_path
    assert samples_path.stat().st_size > 0, samples_path

    failed = [gate for gate in gates if gate.get("status") != "pass"]
    assert not failed, summary_path
    if architecture == "arm64":
        assert summary["config"]["inference_timeout_ms"] == 600_000, summary_path
PY
    echo "[PASS] ${architecture} collected evidence is complete"
done

# Full M5 sample streams exceed Git hosting's per-file limit uncompressed.
# Preserve them losslessly while keeping every observation in the signed index.
find "${REPO_EVIDENCE_DIR}/raw" -name samples.jsonl -type f \
    -exec xz -T0 -6 '{}' \;

ssh ${SSH_OPTS} "root@${AMD64_IP}" \
    "cat /var/lib/exocomp-qualification/allowed-signers" \
    > "${REPO_EVIDENCE_DIR}/allowed-signers"
ssh ${SSH_OPTS} "root@${AMD64_IP}" \
    "cat /var/lib/exocomp-qualification/qualification.pub" \
    > "${REPO_EVIDENCE_DIR}/bundle-qualification.pub"

cat > "${REPO_EVIDENCE_DIR}/qualification-results.json" <<EOF
{
  "schema_version": 1,
  "candidate": {
    "tag": "v${VERSION}",
    "commit": "${SOURCE_COMMIT}",
    "tag_signature_verified": true
  },
  "decision": "pass",
  "publication_ready": true,
  "qualification_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hosts": {
    "amd64": {
      "guest_architecture": "x86_64",
      "systemd": true,
      "virtualization": "kvm",
      "cpu_execution": "host-passthrough"
    },
    "arm64": {
      "guest_architecture": "aarch64",
      "systemd": true,
      "virtualization": "qemu-full-system",
      "cpu_execution": "emulated-cortex-a57"
    }
  },
  "criteria": {
    "M6-CRIT-1": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-2": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-3": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-4": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-5": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-6": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-7": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-8": {"amd64": "pass", "arm64": "pass"},
    "M6-CRIT-9": {"amd64": "pass", "arm64": "pass"}
  },
  "scenario_results": {
    "offline_artifact_verification_and_install": "pass",
    "pki_initialization_enrollment_renewal": "pass",
    "multi_node_diagnostics": "pass",
    "failed_service_recovery": "pass",
    "m5_shipped_artifact_full": "pass",
    "m5_shipped_artifact_short_amd64": "pass",
    "m5_shipped_artifact_short_arm64": "pass",
    "systemd_hardening": "pass",
    "upgrade_automatic_rollback": "pass",
    "backup_restore": "pass",
    "default_and_purge_uninstall": "pass"
  }
}
EOF
python3 -m json.tool \
    "${REPO_EVIDENCE_DIR}/qualification-results.json" \
    >/dev/null

cat > "${REPO_EVIDENCE_DIR}/README.md" <<EOF
# M6 release qualification: v${VERSION}

## Decision

**PASS — publication-ready.**

Both clean systemd guests passed all M6-CRIT criteria and documented live
scenarios using only artifacts built from the exact signed tag.

## Qualification identity

- **Tag:** \`v${VERSION}\`
- **Commit:** \`${SOURCE_COMMIT}\`
- **Architectures:** Linux amd64 (KVM) and Linux arm64 (full-system QEMU)
- **Qualification date:** $(date -u +%Y-%m-%d)

The candidate preserves protected-state ownership during both backup/restore
and upgrade. Automatic rollback terminates the rejected BEAM directly with
SIGTERM, restores the prior link in a defined order, and waits for the restored
application health probe. It replaces rejected candidates v0.1.0-rc.3 through
v0.1.0-rc.22; none of their results are reused here.

The arm64 orchestration transcript records longer startup waits and a
600-second per-inference deadline for full-system CPU emulation. Both
orchestration values are included in the signed evidence. They do not alter
functional success requirements or M5 CPU/RAM ceilings. Release builds and
complete bundles were each built twice and compared before live qualification.

## M6 criteria

| Criterion | amd64 | arm64 | Evidence |
|---|---:|---:|---|
| M6-CRIT-1 | PASS | PASS | Governance, licenses, SBOM, and provenance gates |
| M6-CRIT-2 | PASS | PASS | Two byte-identical release builds and release matrix |
| M6-CRIT-3 | PASS | PASS | Strict no-network verification and offline installation |
| M6-CRIT-4 | PASS | PASS | Live systemd hardening, ownership, and exact privilege policy |
| M6-CRIT-5 | PASS | PASS | Shipped-artifact backup, restore, upgrade, and automatic rollback |
| M6-CRIT-6 | PASS | PASS | Default and system-cache purge uninstall preserve protected state |
| M6-CRIT-7 | PASS | PASS | Shipped guide commands for PKI, enrollment, renewal, approval, cleanup, and diagnostics |
| M6-CRIT-8 | PASS | PASS | Reproducible signed bundle and tamper-detecting metadata |
| M6-CRIT-9 | PASS | PASS | Indexed evidence and host identities recorded for both guests; authoritative full M5 passed |

## Evidence layout

- \`raw/{amd64,arm64}/repo-gates/\`: required Make gates.
- \`raw/{amd64,arm64}/artifacts/\`: reproducibility, checksums, signatures,
  licenses, SBOM, provenance, and runtime input identities.
- \`raw/{amd64,arm64}/prelive/live/\`: no-network verification, install,
  production PKI initialization, enrollment, and systemd startup.
- \`raw/{amd64,arm64}/operational/\`: renewal, multi-node diagnostics,
  approval/replay behavior, failed-service recovery, and hardening.
- \`raw/{amd64,arm64}/bench-short/\` and \`bench/\`: passing shipped M5 short
  and full-gate results. Sample streams are losslessly stored as
  \`samples.jsonl.xz\`.
- \`raw/{amd64,arm64}/lifecycle/\`: backup/restore, rollback, default
  uninstall, purge uninstall, and protected-state preservation.

## Evidence integrity

\`\`\`sh
sha256sum -c evidence-index.sha256
ssh-keygen -Y verify \\
  -f allowed-signers \\
  -I shedwards@nvidia.com \\
  -n exocomp-release-qualification \\
  -s evidence-index.sha256.sig \\
  < evidence-index.sha256
\`\`\`
EOF

echo "=== $(ts) Creating signed evidence index ==="
(
    cd "${REPO_EVIDENCE_DIR}"
    find . -type f \
        ! -name evidence-index.sha256 \
        ! -name evidence-index.sha256.sig \
        -print0 |
        sort -z |
        xargs -0 sha256sum \
        > evidence-index.sha256
    ssh-keygen -Y sign \
        -f "${EVIDENCE_SIGNING_KEY}" \
        -n exocomp-release-qualification \
        evidence-index.sha256
    ssh-keygen -Y verify \
        -f allowed-signers \
        -I shedwards@nvidia.com \
        -n exocomp-release-qualification \
        -s evidence-index.sha256.sig \
        < evidence-index.sha256
)

echo "[PASS] Evidence index signed and verified"
