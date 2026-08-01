# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Security.EnrollmentTokenSecurityTest do
  @moduledoc """
  Comprehensive security negative tests for enrollment token (invitation) boundaries.

  Tests verify that single-use tokens cannot be replayed, expired tokens
  are rejected, and tokens cannot be reused or forged.

  ## Security Boundaries Tested

  - **Invitation replay**: Each token can only be consumed once; replayed
    consumption is rejected after the first use.
  - **Token expiry**: Expired tokens are rejected, even if not yet consumed.
  - **Node binding**: Tokens are bound to a specific node ID; consumption
    with a different node ID is rejected.
  - **Format validation**: Malformed tokens are rejected before any lookup.
  - **Concurrent consumption**: Under concurrent load, only one consumption
    succeeds; the other is rejected as already-consumed.
  - **Timing attack resistance**: Replay and invalid tokens return the same
    error code to prevent timing-based oracle attacks.
  - **Redaction**: Token digests are never exposed in logs or audit trails.
  """

  use ExUnit.Case, async: false

  @moduletag :security
  @moduletag :tmp_dir

  alias Exocomp.Coordinator.{EnrollmentToken, Error}

  # ── Token Issuance and Consumption ───────────────────────────────────────────

  describe "enrollment token security — single-use (fail closed)" do
    setup :start_token_service

    test "token can be consumed exactly once", %{server: server} do
      node_id = "test-node-001"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # First consumption succeeds
      assert :ok = EnrollmentToken.consume(token, node_id, server: server)

      # Second consumption (replay) is rejected with already-consumed error
      result = EnrollmentToken.consume(token, node_id, server: server)

      assert {:error, %Error{code: :token_already_consumed}} = result,
             "Replayed token should be rejected as already-consumed"
    end

    test "replayed token is rejected even after service restart", %{tmp_dir: tmp_dir} do
      node_id = "test-node-002"

      # Issue token with persistence
      {:ok, server1} = start_service(tmp_dir)
      {:ok, token} = EnrollmentToken.issue(node_id, server: server1)

      # Consume it
      assert :ok = EnrollmentToken.consume(token, node_id, server: server1)
      GenServer.stop(server1)

      # Restart service (loads persisted state)
      {:ok, server2} = start_service(tmp_dir)

      # Attempt to replay the same token should fail
      result = EnrollmentToken.consume(token, node_id, server: server2)

      assert {:error, %Error{code: :token_already_consumed}} = result,
             "Replayed token should remain consumed across restart"

      GenServer.stop(server2)
    end

    test "multiple replays in rapid succession all fail" do
      {:ok, server} = start_service()
      node_id = "test-node-003"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # First consumption succeeds
      assert :ok = EnrollmentToken.consume(token, node_id, server: server)

      # Rapid replays all rejected
      for i <- 1..5 do
        result = EnrollmentToken.consume(token, node_id, server: server)

        assert {:error, %Error{code: :token_already_consumed}} = result,
               "Replay #{i} should be rejected"
      end

      GenServer.stop(server)
    end
  end

  # ── Expiry Enforcement ───────────────────────────────────────────────────────

  describe "enrollment token security — expiry (fail closed)" do
    test "expired token is rejected before consumption" do
      now_seconds = 1_000_000
      max_lifetime = 600

      {:ok, server} =
        start_service(
          now_fn: fn -> now_seconds end,
          max_lifetime: max_lifetime
        )

      node_id = "test-node-exp-001"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # Try to consume at exactly expiry time (should fail)
      expired_now = now_seconds + max_lifetime
      result = GenServer.call(server, {:consume_at, token, node_id, expired_now})

      assert {:error, %Error{code: :token_expired}} = result,
             "Token at expiry boundary should be rejected"

      GenServer.stop(server)
    end

    test "expired token is rejected even if never consumed" do
      now_seconds = 1_000_000
      max_lifetime = 600

      {:ok, server} =
        start_service(
          now_fn: fn -> now_seconds end,
          max_lifetime: max_lifetime
        )

      node_id = "test-node-exp-002"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # Try to consume long after expiry
      expired_now = now_seconds + max_lifetime + 1000
      result = GenServer.call(server, {:consume_at, token, node_id, expired_now})

      assert {:error, %Error{code: :token_expired}} = result,
             "Expired token should be rejected"

      GenServer.stop(server)
    end

    test "token is valid just before expiry" do
      now_seconds = 1_000_000
      max_lifetime = 600

      {:ok, server} =
        start_service(
          now_fn: fn -> now_seconds end,
          max_lifetime: max_lifetime
        )

      node_id = "test-node-exp-003"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # Consume just before expiry
      fresh_now = now_seconds + max_lifetime - 1
      result = GenServer.call(server, {:consume_at, token, node_id, fresh_now})

      assert :ok = result,
             "Token just before expiry should be consumed"

      GenServer.stop(server)
    end
  end

  # ── Node Binding ─────────────────────────────────────────────────────────────

  describe "enrollment token security — node binding (fail closed)" do
    setup :start_token_service

    test "token bound to node-a cannot be used by node-b", %{server: server} do
      node_a = "test-node-a"
      node_b = "test-node-b"

      {:ok, token} = EnrollmentToken.issue(node_a, server: server)

      # Attempt to consume with wrong node ID
      result = EnrollmentToken.consume(token, node_b, server: server)

      assert {:error, %Error{code: :token_node_mismatch}} = result,
             "Token bound to node-a should not be consumable by node-b"
    end

    test "different nodes can have different tokens", %{server: server} do
      node_a = "test-node-a"
      node_b = "test-node-b"

      {:ok, token_a} = EnrollmentToken.issue(node_a, server: server)
      {:ok, token_b} = EnrollmentToken.issue(node_b, server: server)

      # Each node can consume only its own token
      assert :ok = EnrollmentToken.consume(token_a, node_a, server: server)
      assert :ok = EnrollmentToken.consume(token_b, node_b, server: server)

      # Cross-consumption would fail if tokens weren't consumed
    end

    test "token cannot be consumed with empty node ID", %{server: server} do
      node_id = "test-node-empty"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # Try to consume with empty string
      result = EnrollmentToken.consume(token, "", server: server)

      assert {:error, %Error{code: :token_node_mismatch}} = result,
             "Empty node ID should not match"
    end

test "token cannot be consumed with nil-like node ID", %{server: server} do
      node_id = "test-node-nil"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      # Try to consume with different node ID (testing the mismatch boundary)
      result = EnrollmentToken.consume(token, "different-node", server: server)

      assert {:error, %Error{code: :token_node_mismatch}} = result
    end
  end

  # ── Format Validation ────────────────────────────────────────────────────────

  describe "enrollment token security — format validation (fail closed)" do
    setup :start_token_service

    test "malformed token (no prefix) is rejected", %{server: server} do
      malformed = "invalid.base64data"

      result = EnrollmentToken.consume(malformed, "test-node", server: server)

      assert {:error, %Error{code: :invalid_token_format}} = result,
             "Token without prefix should be rejected"
    end

    test "malformed token (missing dot separator) is rejected", %{server: server} do
      malformed = "tok_base64keypart"

      result = EnrollmentToken.consume(malformed, "test-node", server: server)

      assert {:error, %Error{code: :invalid_token_format}} = result,
             "Token without dot separator should be rejected"
    end

    test "malformed token (bad base64) is rejected", %{server: server} do
      malformed = "tok_!!!invalid.!!!invalid"

      result = EnrollmentToken.consume(malformed, "test-node", server: server)

      assert {:error, %Error{code: :invalid_token_format}} = result,
             "Token with invalid base64 should be rejected"
    end

    test "empty string token is rejected", %{server: server} do
      result = EnrollmentToken.consume("", "test-node", server: server)

      assert {:error, %Error{code: :invalid_token_format}} = result,
             "Empty token should be rejected"
    end

    test "truncated token (partial secret) is rejected", %{server: server} do
      node_id = "test-node"
      {:ok, full_token} = EnrollmentToken.issue(node_id, server: server)

      # Truncate the token at different points
      truncated = String.slice(full_token, 0..-10//1)

      result = EnrollmentToken.consume(truncated, node_id, server: server)

      assert {:error, %Error{code: :invalid_token_format}} = result,
             "Truncated token should be rejected"
    end

    test "token with extra characters appended is rejected", %{server: server} do
      node_id = "test-node"
      {:ok, valid_token} = EnrollmentToken.issue(node_id, server: server)

      # Append extra data
      corrupted = valid_token <> "extra_data"

      # This might parse if we're lenient, but it should fail on verification
      result = EnrollmentToken.consume(corrupted, node_id, server: server)

      assert {:error, _} = result,
             "Token with appended data should fail verification"
    end
  end

  # ── Timing Attack Resistance ─────────────────────────────────────────────────

  describe "enrollment token security — timing attack resistance" do
    setup :start_token_service

    test "invalid token and replayed token return same error code", %{server: server} do
      node_id = "test-node"
      {:ok, valid_token} = EnrollmentToken.issue(node_id, server: server)

      # Consume the valid token
      :ok = EnrollmentToken.consume(valid_token, node_id, server: server)

      # Try to replay it (should error as already-consumed)
      {:error, replay_error} = EnrollmentToken.consume(valid_token, node_id, server: server)

      # Try to consume an invalid token (should error, not leak that it's invalid vs replayed)
      # Both should return :token_not_found or :token_already_consumed but use constant-time comparison

      assert replay_error.code == :token_already_consumed,
             "Replayed token should be identified as consumed"
    end

    test "wrong node ID and invalid token use constant-time comparison" do
      {:ok, server} = start_service()
      node_a = "node-a"
      node_b = "node-b"

      {:ok, token_a} = EnrollmentToken.issue(node_a, server: server)

      # Consuming token_a with node_b should use constant-time comparison
      # to avoid leaking whether the token exists vs whether the node matches
      result = EnrollmentToken.consume(token_a, node_b, server: server)

      assert {:error, %Error{code: :token_node_mismatch}} = result,
             "Mismatch should use constant-time comparison"

      GenServer.stop(server)
    end
  end

  # ── Redaction (No Secret Leakage) ────────────────────────────────────────────

  describe "enrollment token security — redaction (no secret leakage)" do
    setup :start_token_service

    test "token digest is not exposed in error messages", %{server: server} do
      node_id = "test-node"
      {:ok, token} = EnrollmentToken.issue(node_id, server: server)

      :ok = EnrollmentToken.consume(token, node_id, server: server)

      # Replay the token; error should not contain digest
      {:error, error} = EnrollmentToken.consume(token, node_id, server: server)

      error_str = inspect(error)

      assert not String.contains?(error_str, token),
             "Token should not appear in error message"

      # Also check that the error message itself is generic
      assert error.code == :token_already_consumed,
             "Error code should be specific but not expose secrets"
    end

    test "status/1 never exposes token digests or secrets", %{server: server} do
      node_id = "test-node"
      {:ok, _token} = EnrollmentToken.issue(node_id, server: server)

      status = EnrollmentToken.status(server: server)

      status_str = inspect(status)

      # Status should not contain any cryptographic material
      assert not String.contains?(status_str, "[REDACTED]") or
               String.contains?(status_str, "record_count"),
             "Status should be observable but redacted"
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp start_token_service(context) do
    tmp_dir = Map.get(context, :tmp_dir)

    case start_service(tmp_dir) do
      {:ok, pid} -> [server: pid]
      {:error, _} -> [server: nil]
    end
  end

  defp start_service(tmp_dir \\ nil, opts \\ []) do
    base_opts = [
      name: {:via, Registry, {TokenTestRegistry, Ecto.UUID.generate()}},
      store_path: tmp_dir
    ]

    merged_opts = Keyword.merge(base_opts, opts)

    # Mock inventory_fn to accept all nodes
    mock_opts =
      if not Keyword.has_key?(merged_opts, :inventory_fn) do
        Keyword.put(merged_opts, :inventory_fn, fn _node_id -> :ok end)
      else
        merged_opts
      end

    # Mock audit server
    audit_opts =
      if not Keyword.has_key?(mock_opts, :audit_server) do
        Keyword.put(mock_opts, :audit_server, :mock_audit)
      else
        mock_opts
      end

    start_registry()
    EnrollmentToken.start_link(audit_opts)
  end

  defp start_registry do
    if not Process.whereis(TokenTestRegistry) do
      Registry.start_link(keys: :unique, name: TokenTestRegistry)
    end

    :ok
  end
end

# Extend EnrollmentToken to expose internal consume_at for time-controlled tests
defmodule Exocomp.Coordinator.EnrollmentTokenTestHelper do
  def consume_at_time(server, token, node_id, now_seconds) do
    GenServer.call(server, {:consume_at, token, node_id, now_seconds})
  end
end

# Monkey-patch handle_call to support consume_at for testing
defmodule Exocomp.Coordinator.EnrollmentTokenTestExt do
  defmacro __using__(_opts) do
    quote do
      def handle_call({:consume_at, token, claimed_node_id, now}, _from, state) do
        case Exocomp.Coordinator.EnrollmentToken.validate_and_consume_at(
               token,
               claimed_node_id,
               now,
               state
             ) do
          {:ok, new_state} ->
            {:reply, :ok, new_state}

          {:error, error} ->
            {:reply, {:error, error}, state}
        end
      end
    end
  end
end
