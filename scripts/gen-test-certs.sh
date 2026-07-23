#!/usr/bin/env bash
# scripts/gen-test-certs.sh
#
# Generate TLS test fixture certificates for apps/exocomp_node test suite.
#
# SECURITY NOTE: The private keys produced by this script are committed to the
# repository intentionally. These are development-only fixture secrets with no
# production exposure. Committing them ensures fully reproducible tests without
# requiring developers or CI to re-run this script. Never use these keys
# outside of test environments.
#
# This script is idempotent: running it multiple times produces fresh certs
# that overwrite the previous ones without error.
#
# Usage: sh scripts/gen-test-certs.sh
#        make gen-test-fixtures
#
# Output: apps/exocomp_node/test/fixtures/certs/
#   ca.crt           — self-signed CA certificate
#   node.crt         — leaf cert signed by CA, SAN=DNS:exocomp-test-node
#   node.key         — node private key (mode 0600)
#   wrong_san.crt    — leaf cert with mismatched SAN (DNS:wrong-san-node)
#   wrong_san.key    — wrong_san private key (mode 0600)
#   expired.crt      — cert that expired in the past (for chain validation tests)
#   expired.key      — expired cert private key (mode 0600)
#   rogue.crt        — cert signed by a different (rogue) CA
#   rogue.key        — rogue cert private key (mode 0600)

set -eu

FIXTURES_DIR="apps/exocomp_node/test/fixtures/certs"
mkdir -p "$FIXTURES_DIR"

# Use a temp dir for intermediate files so concurrent runs don't collide.
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ---------------------------------------------------------------------------
# 1. Self-signed CA
# ---------------------------------------------------------------------------
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMPDIR/ca.key" \
  -out "$FIXTURES_DIR/ca.crt" \
  -days 3650 \
  -subj "/CN=ExoComp Test CA/O=ExoComp/C=US" \
  -addext "basicConstraints=critical,CA:true" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  2>/dev/null

# ---------------------------------------------------------------------------
# 2. Node leaf certificate — SAN=DNS:exocomp-test-node (matches node ID)
# ---------------------------------------------------------------------------
openssl req -newkey rsa:2048 -nodes \
  -keyout "$FIXTURES_DIR/node.key" \
  -out "$TMPDIR/node.csr" \
  -subj "/CN=exocomp-test-node/O=ExoComp/C=US" \
  2>/dev/null

openssl x509 -req \
  -in "$TMPDIR/node.csr" \
  -CA "$FIXTURES_DIR/ca.crt" \
  -CAkey "$TMPDIR/ca.key" \
  -CAcreateserial \
  -out "$FIXTURES_DIR/node.crt" \
  -days 3650 \
  -extfile <(printf "subjectAltName=DNS:exocomp-test-node\nbasicConstraints=CA:false\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth,clientAuth") \
  2>/dev/null

# ---------------------------------------------------------------------------
# 3. Wrong SAN certificate — SAN intentionally mismatches node ID
# ---------------------------------------------------------------------------
openssl req -newkey rsa:2048 -nodes \
  -keyout "$FIXTURES_DIR/wrong_san.key" \
  -out "$TMPDIR/wrong_san.csr" \
  -subj "/CN=wrong-san-node/O=ExoComp/C=US" \
  2>/dev/null

openssl x509 -req \
  -in "$TMPDIR/wrong_san.csr" \
  -CA "$FIXTURES_DIR/ca.crt" \
  -CAkey "$TMPDIR/ca.key" \
  -CAcreateserial \
  -out "$FIXTURES_DIR/wrong_san.crt" \
  -days 3650 \
  -extfile <(printf "subjectAltName=DNS:wrong-san-node\nbasicConstraints=CA:false\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth,clientAuth") \
  2>/dev/null

# ---------------------------------------------------------------------------
# 4. Expired certificate — start and end dates in the past
# ---------------------------------------------------------------------------
openssl req -newkey rsa:2048 -nodes \
  -keyout "$FIXTURES_DIR/expired.key" \
  -out "$TMPDIR/expired.csr" \
  -subj "/CN=exocomp-expired-node/O=ExoComp/C=US" \
  2>/dev/null

openssl x509 -req \
  -in "$TMPDIR/expired.csr" \
  -CA "$FIXTURES_DIR/ca.crt" \
  -CAkey "$TMPDIR/ca.key" \
  -CAcreateserial \
  -out "$FIXTURES_DIR/expired.crt" \
  -not_before 20200101000000Z \
  -not_after 20200102000000Z \
  -extfile <(printf "subjectAltName=DNS:exocomp-expired-node\nbasicConstraints=CA:false\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth,clientAuth") \
  2>/dev/null

# ---------------------------------------------------------------------------
# 5. Rogue CA + certificate — trust-root tests
# ---------------------------------------------------------------------------
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMPDIR/rogue_ca.key" \
  -out "$TMPDIR/rogue_ca.crt" \
  -days 3650 \
  -subj "/CN=Rogue CA/O=Rogue/C=US" \
  -addext "basicConstraints=critical,CA:true" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  2>/dev/null

openssl req -newkey rsa:2048 -nodes \
  -keyout "$FIXTURES_DIR/rogue.key" \
  -out "$TMPDIR/rogue.csr" \
  -subj "/CN=exocomp-test-node/O=ExoComp/C=US" \
  2>/dev/null

openssl x509 -req \
  -in "$TMPDIR/rogue.csr" \
  -CA "$TMPDIR/rogue_ca.crt" \
  -CAkey "$TMPDIR/rogue_ca.key" \
  -CAcreateserial \
  -out "$FIXTURES_DIR/rogue.crt" \
  -days 3650 \
  -extfile <(printf "subjectAltName=DNS:exocomp-test-node\nbasicConstraints=CA:false\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth,clientAuth") \
  2>/dev/null

# ---------------------------------------------------------------------------
# Set strict permissions on all private keys
# ---------------------------------------------------------------------------
chmod 0600 \
  "$FIXTURES_DIR/node.key" \
  "$FIXTURES_DIR/wrong_san.key" \
  "$FIXTURES_DIR/expired.key" \
  "$FIXTURES_DIR/rogue.key"

echo "Generated fixture certificates in $FIXTURES_DIR:"
ls -la "$FIXTURES_DIR"

echo ""
echo "Verifying node.crt SAN:"
openssl x509 -noout -ext subjectAltName -in "$FIXTURES_DIR/node.crt"
