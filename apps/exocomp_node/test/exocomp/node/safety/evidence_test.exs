defmodule Exocomp.Node.Safety.EvidenceTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.Evidence

  @valid_hash String.duplicate("a", 64)

  @valid_attrs %{
    "schema_version" => "1",
    "evidence_id" => "ev-001",
    "collector" => "systemd.service.status",
    "collector_version" => "1.0.0",
    "target_id" => "nginx.service",
    "observed_at" => "2026-07-23T21:00:00Z",
    "values" => %{"active_state" => "failed", "sub_state" => "dead"},
    "integrity_hash" => @valid_hash
  }

  # ── schema_version/0 ──────────────────────────────────────────────────

  test "schema_version/0 returns '1'" do
    assert Evidence.schema_version() == "1"
  end

  # ── parse/1 — valid input ─────────────────────────────────────────────

  test "parse/1 returns {:ok, Evidence} for a valid map" do
    assert {:ok, %Evidence{} = ev} = Evidence.parse(@valid_attrs)
    assert ev.schema_version == "1"
    assert ev.evidence_id == "ev-001"
    assert ev.collector == "systemd.service.status"
    assert ev.collector_version == "1.0.0"
    assert ev.target_id == "nginx.service"
    assert ev.values == %{"active_state" => "failed", "sub_state" => "dead"}
    assert ev.integrity_hash == @valid_hash
    assert %DateTime{} = ev.observed_at
  end

  # ── parse/1 — schema version ──────────────────────────────────────────

  test "parse/1 rejects missing schema_version" do
    attrs = Map.delete(@valid_attrs, "schema_version")
    assert {:error, :missing_schema_version} = Evidence.parse(attrs)
  end

  test "parse/1 rejects unknown schema_version '2'" do
    attrs = Map.put(@valid_attrs, "schema_version", "2")
    assert {:error, {:unknown_schema_version, "2"}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects schema_version nil" do
    attrs = Map.put(@valid_attrs, "schema_version", nil)
    assert {:error, :missing_schema_version} = Evidence.parse(attrs)
  end

  # ── parse/1 — unknown fields ──────────────────────────────────────────

  test "parse/1 rejects an extra/unknown field" do
    attrs = Map.put(@valid_attrs, "injection_attempt", "malicious")
    assert {:error, {:unknown_fields, ["injection_attempt"]}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects multiple unknown fields" do
    attrs =
      @valid_attrs
      |> Map.put("foo", "bar")
      |> Map.put("baz", "qux")

    assert {:error, {:unknown_fields, unknown}} = Evidence.parse(attrs)
    assert Enum.sort(unknown) == ["baz", "foo"]
  end

  # ── parse/1 — required field validation ──────────────────────────────

  @required_fields ~w[evidence_id collector collector_version target_id observed_at values integrity_hash]

  for field <- @required_fields do
    test "parse/1 rejects missing field '#{field}'" do
      attrs = Map.delete(@valid_attrs, unquote(field))
      assert {:error, _reason} = Evidence.parse(attrs)
    end
  end

  test "parse/1 rejects empty evidence_id" do
    attrs = Map.put(@valid_attrs, "evidence_id", "")
    assert {:error, {:empty_field, "evidence_id"}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects non-string evidence_id" do
    attrs = Map.put(@valid_attrs, "evidence_id", 42)
    assert {:error, {:invalid_field, "evidence_id", 42}} = Evidence.parse(attrs)
  end

  # ── parse/1 — observed_at ─────────────────────────────────────────────

  test "parse/1 accepts ISO 8601 UTC datetime" do
    assert {:ok, %Evidence{observed_at: %DateTime{}}} = Evidence.parse(@valid_attrs)
  end

  test "parse/1 accepts datetime with offset" do
    attrs = Map.put(@valid_attrs, "observed_at", "2026-07-23T21:00:00+05:30")
    assert {:ok, %Evidence{observed_at: %DateTime{}}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects malformed datetime" do
    attrs = Map.put(@valid_attrs, "observed_at", "not-a-date")
    assert {:error, {:invalid_datetime, "observed_at", _}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects non-string observed_at" do
    attrs = Map.put(@valid_attrs, "observed_at", 1_234_567_890)
    assert {:error, {:invalid_datetime, "observed_at", 1_234_567_890}} = Evidence.parse(attrs)
  end

  # ── parse/1 — values map ──────────────────────────────────────────────

  test "parse/1 accepts empty values map" do
    attrs = Map.put(@valid_attrs, "values", %{})
    assert {:ok, %Evidence{values: %{}}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects values with non-string value" do
    attrs = Map.put(@valid_attrs, "values", %{"key" => 42})
    assert {:error, {:invalid_values, :non_string_value}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects values that is not a map" do
    attrs = Map.put(@valid_attrs, "values", "not_a_map")
    assert {:error, {:invalid_field, "values", :not_a_map}} = Evidence.parse(attrs)
  end

  # ── parse/1 — integrity_hash ──────────────────────────────────────────

  test "parse/1 accepts exactly 64 lowercase hex chars" do
    assert {:ok, %Evidence{integrity_hash: h}} = Evidence.parse(@valid_attrs)
    assert byte_size(h) == 64
  end

  test "parse/1 rejects hash that is too short" do
    attrs = Map.put(@valid_attrs, "integrity_hash", String.duplicate("a", 63))
    assert {:error, {:invalid_integrity_hash, :must_be_64_hex_chars}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects hash that is too long" do
    attrs = Map.put(@valid_attrs, "integrity_hash", String.duplicate("a", 65))
    assert {:error, {:invalid_integrity_hash, :must_be_64_hex_chars}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects hash with uppercase hex chars" do
    attrs = Map.put(@valid_attrs, "integrity_hash", String.duplicate("A", 64))
    assert {:error, {:invalid_integrity_hash, :must_be_64_hex_chars}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects hash with non-hex chars" do
    attrs = Map.put(@valid_attrs, "integrity_hash", String.duplicate("z", 64))
    assert {:error, {:invalid_integrity_hash, :must_be_64_hex_chars}} = Evidence.parse(attrs)
  end

  test "parse/1 rejects non-string integrity_hash" do
    attrs = Map.put(@valid_attrs, "integrity_hash", 42)
    assert {:error, {:invalid_integrity_hash, 42}} = Evidence.parse(attrs)
  end

  # ── parse/1 — non-map input ────────────────────────────────────────────

  test "parse/1 rejects nil" do
    assert {:error, :invalid_evidence_input} = Evidence.parse(nil)
  end

  test "parse/1 rejects a list" do
    assert {:error, :invalid_evidence_input} = Evidence.parse([])
  end
end
