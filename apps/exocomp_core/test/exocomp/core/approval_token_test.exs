# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Core.ApprovalTokenTest do
  use ExUnit.Case, async: true

  alias Exocomp.Core.ApprovalToken

  test "canonical encoding uses fixed key order and supports atom or string keys" do
    atom_payload = payload()
    string_payload = Map.new(atom_payload, fn {key, value} -> {Atom.to_string(key), value} end)

    assert ApprovalToken.canonical_encode(atom_payload) ==
             ApprovalToken.canonical_encode(string_payload)

    assert Jason.decode!(ApprovalToken.canonical_encode(atom_payload)) == string_payload
  end

  test "parameter and evidence hashing is recursively deterministic" do
    first = %{"z" => 1, "nested" => %{"b" => 2, "a" => 1}}
    second = %{"nested" => %{"a" => 1, "b" => 2}, "z" => 1}

    assert ApprovalToken.hash_params(first) == ApprovalToken.hash_params(second)
    assert ApprovalToken.hash_evidence(first) == ApprovalToken.hash_params(first)

    assert ApprovalToken.sha256_hex("abc") ==
             "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  end

  defp payload do
    %{
      schema_version: "1",
      nonce: "nonce",
      node_id: "node-1",
      task_id: "task-1",
      correlation_id: "corr-1",
      action_id: "restart",
      parameter_hash: "params",
      evidence_hash: "evidence",
      issued_at: "2026-01-01T00:00:00Z",
      expires_at: "2026-01-01T00:01:00Z",
      operator: "operator"
    }
  end
end
