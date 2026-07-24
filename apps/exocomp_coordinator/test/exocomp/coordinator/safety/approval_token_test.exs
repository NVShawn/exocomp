defmodule Exocomp.Coordinator.Safety.ApprovalTokenTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.Safety.ApprovalToken

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp valid_token(overrides \\ %{}) do
    base = %ApprovalToken{
      schema_version: "1",
      nonce: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
      task_id: "task-001",
      correlation_id: "corr-abc",
      node_id: "node-42",
      action_id: "restart_service",
      parameter_hash: "a" <> String.duplicate("0", 63),
      evidence_hash: "b" <> String.duplicate("0", 63),
      issued_at: "2024-01-01T00:00:00Z",
      expires_at: "2024-01-01T00:05:00Z",
      operator: "ops@example.com"
    }

    Map.merge(base, overrides)
  end

  # All 11 required fields in keyword form (used to test missing-key errors).
  defp all_fields do
    [
      schema_version: "1",
      nonce: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
      task_id: "task-001",
      correlation_id: "corr-abc",
      node_id: "node-42",
      action_id: "restart_service",
      parameter_hash: "a" <> String.duplicate("0", 63),
      evidence_hash: "b" <> String.duplicate("0", 63),
      issued_at: "2024-01-01T00:00:00Z",
      expires_at: "2024-01-01T00:05:00Z",
      operator: "ops@example.com"
    ]
  end

  # ---------------------------------------------------------------------------
  # schema_version/0 accessor
  # ---------------------------------------------------------------------------

  test "schema_version/0 returns the current version string" do
    assert ApprovalToken.schema_version() == "1"
  end

  # ---------------------------------------------------------------------------
  # @enforce_keys — all 11 fields are required
  # Using struct!/2 so enforcement happens at runtime inside the anonymous fn.
  # ---------------------------------------------------------------------------

  test "raises ArgumentError when schema_version is missing" do
    fields = Keyword.delete(all_fields(), :schema_version)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when nonce is missing" do
    fields = Keyword.delete(all_fields(), :nonce)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when task_id is missing" do
    fields = Keyword.delete(all_fields(), :task_id)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when correlation_id is missing" do
    fields = Keyword.delete(all_fields(), :correlation_id)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when node_id is missing" do
    fields = Keyword.delete(all_fields(), :node_id)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when action_id is missing" do
    fields = Keyword.delete(all_fields(), :action_id)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when parameter_hash is missing" do
    fields = Keyword.delete(all_fields(), :parameter_hash)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when evidence_hash is missing" do
    fields = Keyword.delete(all_fields(), :evidence_hash)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when issued_at is missing" do
    fields = Keyword.delete(all_fields(), :issued_at)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when expires_at is missing" do
    fields = Keyword.delete(all_fields(), :expires_at)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  test "raises ArgumentError when operator is missing" do
    fields = Keyword.delete(all_fields(), :operator)
    assert_raise ArgumentError, fn -> Kernel.struct!(ApprovalToken, fields) end
  end

  # ---------------------------------------------------------------------------
  # validate_schema_version/1
  # ---------------------------------------------------------------------------

  test "validate_schema_version/1 returns {:ok, token} for the current version" do
    token = valid_token()
    assert {:ok, ^token} = ApprovalToken.validate_schema_version(token)
  end

  test "validate_schema_version/1 returns {:error, :unknown_schema_version} for wrong version" do
    token = valid_token(%{schema_version: "2"})
    assert {:error, :unknown_schema_version} = ApprovalToken.validate_schema_version(token)
  end

  test "validate_schema_version/1 returns {:error, :unknown_schema_version} for empty string" do
    token = valid_token(%{schema_version: ""})
    assert {:error, :unknown_schema_version} = ApprovalToken.validate_schema_version(token)
  end

  test "validate_schema_version/1 returns {:error, :unknown_schema_version} for integer version" do
    token = valid_token(%{schema_version: 1})
    assert {:error, :unknown_schema_version} = ApprovalToken.validate_schema_version(token)
  end

  # ---------------------------------------------------------------------------
  # canonical_encode/1 — determinism
  # ---------------------------------------------------------------------------

  test "canonical_encode/1 returns a binary" do
    result = ApprovalToken.canonical_encode(valid_token())
    assert is_binary(result)
  end

  test "canonical_encode/1 is byte-for-byte identical for identical inputs" do
    token = valid_token()
    first = ApprovalToken.canonical_encode(token)
    second = ApprovalToken.canonical_encode(token)
    assert first == second
  end

  test "canonical_encode/1 produces valid JSON" do
    result = ApprovalToken.canonical_encode(valid_token())
    assert {:ok, _} = Jason.decode(result)
  end

  test "canonical_encode/1 encodes all 11 fields" do
    result = ApprovalToken.canonical_encode(valid_token())
    {:ok, decoded} = Jason.decode(result)

    assert Map.has_key?(decoded, "schema_version")
    assert Map.has_key?(decoded, "nonce")
    assert Map.has_key?(decoded, "task_id")
    assert Map.has_key?(decoded, "correlation_id")
    assert Map.has_key?(decoded, "node_id")
    assert Map.has_key?(decoded, "action_id")
    assert Map.has_key?(decoded, "parameter_hash")
    assert Map.has_key?(decoded, "evidence_hash")
    assert Map.has_key?(decoded, "issued_at")
    assert Map.has_key?(decoded, "expires_at")
    assert Map.has_key?(decoded, "operator")
  end

  test "canonical_encode/1 keys appear in lexicographic order in the raw JSON bytes" do
    result = ApprovalToken.canonical_encode(valid_token())

    # The 11 keys in expected lexicographic order
    expected_key_order = [
      "action_id",
      "correlation_id",
      "evidence_hash",
      "expires_at",
      "issued_at",
      "node_id",
      "nonce",
      "operator",
      "parameter_hash",
      "schema_version",
      "task_id"
    ]

    # Find the byte-offset of each key in the raw JSON string
    positions =
      Enum.map(expected_key_order, fn key ->
        {pos, _len} = :binary.match(result, [~s("#{key}")])
        {pos, key}
      end)

    actual_order =
      positions
      |> Enum.sort()
      |> Enum.map(fn {_pos, key} -> key end)

    assert actual_order == expected_key_order
  end

  # ---------------------------------------------------------------------------
  # canonical_encode/1 — field sensitivity (any single-field change produces
  # different bytes)
  # ---------------------------------------------------------------------------

  test "canonical_encode/1 differs when schema_version changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{schema_version: "2"}))
    refute base == other
  end

  test "canonical_encode/1 differs when nonce changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{nonce: "different-nonce"}))
    refute base == other
  end

  test "canonical_encode/1 differs when task_id changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{task_id: "task-999"}))
    refute base == other
  end

  test "canonical_encode/1 differs when correlation_id changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{correlation_id: "corr-xyz"}))
    refute base == other
  end

  test "canonical_encode/1 differs when node_id changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{node_id: "node-99"}))
    refute base == other
  end

  test "canonical_encode/1 differs when action_id changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{action_id: "clear_disk"}))
    refute base == other
  end

  test "canonical_encode/1 differs when parameter_hash changes" do
    base = ApprovalToken.canonical_encode(valid_token())

    other =
      ApprovalToken.canonical_encode(
        valid_token(%{parameter_hash: "c" <> String.duplicate("0", 63)})
      )

    refute base == other
  end

  test "canonical_encode/1 differs when evidence_hash changes" do
    base = ApprovalToken.canonical_encode(valid_token())

    other =
      ApprovalToken.canonical_encode(
        valid_token(%{evidence_hash: "d" <> String.duplicate("0", 63)})
      )

    refute base == other
  end

  test "canonical_encode/1 differs when issued_at changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{issued_at: "2024-06-01T00:00:00Z"}))
    refute base == other
  end

  test "canonical_encode/1 differs when expires_at changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{expires_at: "2024-01-01T01:00:00Z"}))
    refute base == other
  end

  test "canonical_encode/1 differs when operator changes" do
    base = ApprovalToken.canonical_encode(valid_token())
    other = ApprovalToken.canonical_encode(valid_token(%{operator: "other@example.com"}))
    refute base == other
  end

  # ---------------------------------------------------------------------------
  # sha256_hex/1
  # ---------------------------------------------------------------------------

  test "sha256_hex/1 returns a 64-character lowercase hex string" do
    result = ApprovalToken.sha256_hex("hello")
    assert byte_size(result) == 64
    assert result == String.downcase(result)
  end

  test "sha256_hex/1 matches known SHA-256 value" do
    # echo -n "hello" | sha256sum
    # => 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
    assert ApprovalToken.sha256_hex("hello") ==
             "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
  end

  test "sha256_hex/1 returns different values for different inputs" do
    refute ApprovalToken.sha256_hex("hello") == ApprovalToken.sha256_hex("world")
  end

  # ---------------------------------------------------------------------------
  # hash_params/1 — order independence
  # ---------------------------------------------------------------------------

  test "hash_params/1 returns a 64-character hex string" do
    result = ApprovalToken.hash_params(%{"key" => "value"})
    assert byte_size(result) == 64
  end

  test "hash_params/1 produces identical output regardless of map insertion order" do
    map_a = %{"b" => 2, "a" => 1, "c" => 3}
    map_b = %{"c" => 3, "a" => 1, "b" => 2}
    assert ApprovalToken.hash_params(map_a) == ApprovalToken.hash_params(map_b)
  end

  test "hash_params/1 returns different values for different content" do
    refute ApprovalToken.hash_params(%{"key" => "value1"}) ==
             ApprovalToken.hash_params(%{"key" => "value2"})
  end

  test "hash_params/1 handles empty map" do
    result = ApprovalToken.hash_params(%{})
    assert is_binary(result)
    assert byte_size(result) == 64
  end

  test "hash_params/1 handles nested maps with order independence" do
    map_a = %{"outer" => %{"z" => 26, "a" => 1}}
    map_b = %{"outer" => %{"a" => 1, "z" => 26}}
    assert ApprovalToken.hash_params(map_a) == ApprovalToken.hash_params(map_b)
  end

  # ---------------------------------------------------------------------------
  # hash_evidence/1 — order independence (mirrors hash_params)
  # ---------------------------------------------------------------------------

  test "hash_evidence/1 returns a 64-character hex string" do
    result = ApprovalToken.hash_evidence(%{"disk_free_gb" => 12.5})
    assert byte_size(result) == 64
  end

  test "hash_evidence/1 produces identical output regardless of map insertion order" do
    ev_a = %{"cpu_percent" => 90, "disk_free_gb" => 12.5, "load_avg" => 2.3}
    ev_b = %{"load_avg" => 2.3, "disk_free_gb" => 12.5, "cpu_percent" => 90}
    assert ApprovalToken.hash_evidence(ev_a) == ApprovalToken.hash_evidence(ev_b)
  end

  test "hash_evidence/1 returns different values for different content" do
    refute ApprovalToken.hash_evidence(%{"disk_free_gb" => 12.5}) ==
             ApprovalToken.hash_evidence(%{"disk_free_gb" => 99.0})
  end

  test "hash_evidence/1 output equals hash_params/1 for the same map" do
    map = %{"k" => "v"}
    assert ApprovalToken.hash_evidence(map) == ApprovalToken.hash_params(map)
  end
end
