defmodule Exocomp.Node.Safety.ProposalTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.Proposal

  @valid_attrs %{
    "schema_version" => "1",
    "action_id" => "systemd.service.restart",
    "target_id" => "nginx.service",
    "parameters" => %{"reason" => "OOM killed"},
    "evidence_refs" => ["ev-001", "ev-002"],
    "rationale" => "The service OOM-killed twice in the last hour."
  }

  # ── schema_version/0 ──────────────────────────────────────────────────

  test "schema_version/0 returns '1'" do
    assert Proposal.schema_version() == "1"
  end

  # ── parse/1 — valid input ─────────────────────────────────────────────

  test "parse/1 returns {:ok, Proposal} for a valid map" do
    assert {:ok, %Proposal{} = p} = Proposal.parse(@valid_attrs)
    assert p.schema_version == "1"
    assert p.action_id == "systemd.service.restart"
    assert p.target_id == "nginx.service"
    assert p.parameters == %{"reason" => "OOM killed"}
    assert p.evidence_refs == ["ev-001", "ev-002"]
    assert p.rationale == "The service OOM-killed twice in the last hour."
  end

  test "parse/1 accepts empty parameters map" do
    attrs = Map.put(@valid_attrs, "parameters", %{})
    assert {:ok, %Proposal{parameters: %{}}} = Proposal.parse(attrs)
  end

  test "parse/1 accepts empty evidence_refs list" do
    attrs = Map.put(@valid_attrs, "evidence_refs", [])
    assert {:ok, %Proposal{evidence_refs: []}} = Proposal.parse(attrs)
  end

  test "parse/1 accepts empty rationale string" do
    attrs = Map.put(@valid_attrs, "rationale", "")
    assert {:ok, %Proposal{rationale: ""}} = Proposal.parse(attrs)
  end

  # ── parse/1 — schema version ──────────────────────────────────────────

  test "parse/1 rejects missing schema_version" do
    attrs = Map.delete(@valid_attrs, "schema_version")
    assert {:error, :missing_schema_version} = Proposal.parse(attrs)
  end

  test "parse/1 rejects unknown schema_version '0'" do
    attrs = Map.put(@valid_attrs, "schema_version", "0")
    assert {:error, {:unknown_schema_version, "0"}} = Proposal.parse(attrs)
  end

  test "parse/1 rejects schema_version '2'" do
    attrs = Map.put(@valid_attrs, "schema_version", "2")
    assert {:error, {:unknown_schema_version, "2"}} = Proposal.parse(attrs)
  end

  # ── parse/1 — unknown fields ──────────────────────────────────────────

  test "parse/1 rejects any unknown field" do
    attrs = Map.put(@valid_attrs, "injected_field", "x")
    assert {:error, {:unknown_fields, ["injected_field"]}} = Proposal.parse(attrs)
  end

  test "parse/1 rejects multiple unknown fields" do
    attrs =
      @valid_attrs
      |> Map.put("cmd", "rm -rf /")
      |> Map.put("shell", "bash")

    assert {:error, {:unknown_fields, fields}} = Proposal.parse(attrs)
    assert Enum.sort(fields) == ["cmd", "shell"]
  end

  # ── parse/1 — action_id validation ───────────────────────────────────

  test "parse/1 rejects missing action_id" do
    attrs = Map.delete(@valid_attrs, "action_id")
    assert {:error, {:missing_field, "action_id"}} = Proposal.parse(attrs)
  end

  describe "parse/1 action_id character allowlist" do
    @valid_action_ids [
      "systemd.service.restart",
      "system.logs.vacuum",
      "a",
      "A-B_C.D",
      String.duplicate("a", 128)
    ]

    for id <- @valid_action_ids do
      test "accepts '#{id}'" do
        attrs = Map.put(@valid_attrs, "action_id", unquote(id))
        assert {:ok, %Proposal{}} = Proposal.parse(attrs)
      end
    end

    @invalid_action_ids [
      "",
      "has spaces",
      "shell; rm -rf /",
      "../../etc/passwd",
      "action\x00null",
      "cmd|pipe",
      String.duplicate("a", 129)
    ]

    for id <- @invalid_action_ids do
      test "rejects '#{id}'" do
        attrs = Map.put(@valid_attrs, "action_id", unquote(id))
        assert {:error, _} = Proposal.parse(attrs)
      end
    end
  end

  # ── parse/1 — parameters validation ──────────────────────────────────

  test "parse/1 rejects parameters with non-string value" do
    attrs = Map.put(@valid_attrs, "parameters", %{"key" => 42})

    assert {:error, {:invalid_parameters, :values_must_be_flat_string_map}} =
             Proposal.parse(attrs)
  end

  test "parse/1 rejects parameters that is not a map" do
    attrs = Map.put(@valid_attrs, "parameters", "not_a_map")
    assert {:error, {:invalid_field, "parameters", :not_a_map}} = Proposal.parse(attrs)
  end

  test "parse/1 rejects missing parameters" do
    attrs = Map.delete(@valid_attrs, "parameters")
    assert {:error, {:missing_field, "parameters"}} = Proposal.parse(attrs)
  end

  # ── parse/1 — evidence_refs validation ───────────────────────────────

  test "parse/1 rejects evidence_refs with empty string element" do
    attrs = Map.put(@valid_attrs, "evidence_refs", ["ev-001", ""])

    assert {:error, {:invalid_evidence_refs, :must_be_list_of_nonempty_strings}} =
             Proposal.parse(attrs)
  end

  test "parse/1 rejects evidence_refs with non-string element" do
    attrs = Map.put(@valid_attrs, "evidence_refs", [42])

    assert {:error, {:invalid_evidence_refs, :must_be_list_of_nonempty_strings}} =
             Proposal.parse(attrs)
  end

  test "parse/1 rejects missing evidence_refs" do
    attrs = Map.delete(@valid_attrs, "evidence_refs")
    assert {:error, {:missing_field, "evidence_refs"}} = Proposal.parse(attrs)
  end

  # ── parse/1 — non-map input ────────────────────────────────────────────

  test "parse/1 rejects nil" do
    assert {:error, :invalid_proposal_input} = Proposal.parse(nil)
  end

  test "parse/1 rejects a string" do
    assert {:error, :invalid_proposal_input} = Proposal.parse("not a map")
  end
end
