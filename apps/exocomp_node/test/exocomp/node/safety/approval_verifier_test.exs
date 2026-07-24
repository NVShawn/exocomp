defmodule Exocomp.Node.Safety.ApprovalVerifierTest do
  use ExUnit.Case, async: false

  alias Exocomp.Core.ApprovalToken
  alias Exocomp.Node.Safety.ApprovalVerifier

  @now ~U[2026-07-24 16:00:00Z]

  setup %{tmp_dir: tmp_dir} do
    original = Application.get_env(:exocomp_node, :approval_public_key_path)
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    key_path = Path.join(tmp_dir, "coordinator-approval-public.key")
    File.write!(key_path, public_key)
    Application.put_env(:exocomp_node, :approval_public_key_path, key_path)

    on_exit(fn ->
      if original do
        Application.put_env(:exocomp_node, :approval_public_key_path, original)
      else
        Application.delete_env(:exocomp_node, :approval_public_key_path)
      end
    end)

    %{public_key: public_key, private_key: private_key, key_path: key_path}
  end

  @tag :tmp_dir
  test "valid token with correct key and bindings passes", %{private_key: private_key} do
    token = signed_token(payload(), private_key)
    assert {:ok, ^token} = ApprovalVerifier.verify(token, context())
  end

  @tag :tmp_dir
  test "accepts an unpadded base64url signature", %{private_key: private_key} do
    token = signed_token(payload(), private_key)
    encoded = Base.url_encode64(token.signature, padding: false)
    wire_token = %{"payload" => stringify_keys(token.payload), "signature" => encoded}

    assert {:ok, ^wire_token} = ApprovalVerifier.verify(wire_token, context())
  end

  @tag :tmp_dir
  test "rejects a bit-flipped signature", %{private_key: private_key} do
    token = signed_token(payload(), private_key)
    <<first, rest::binary>> = token.signature
    tampered = %{token | signature: <<Bitwise.bxor(first, 1), rest::binary>>}

    assert {:error, :invalid_signature} = ApprovalVerifier.verify(tampered, context())
  end

  @tag :tmp_dir
  test "rejects a different public key", %{private_key: private_key, key_path: key_path} do
    {wrong_public_key, _} = :crypto.generate_key(:eddsa, :ed25519)
    File.write!(key_path, wrong_public_key)

    assert {:error, :invalid_signature} =
             signed_token(payload(), private_key) |> ApprovalVerifier.verify(context())
  end

  @tag :tmp_dir
  test "missing or malformed public key fails closed without details", %{
    private_key: private_key,
    key_path: key_path
  } do
    token = signed_token(payload(), private_key)
    File.rm!(key_path)
    assert {:error, :public_key_unavailable} = ApprovalVerifier.verify(token, context())

    File.write!(key_path, "not-a-public-key")
    assert {:error, :public_key_unavailable} = ApprovalVerifier.verify(token, context())
  end

  @tag :tmp_dir
  test "every payload binding names its field when tampered and re-signed", %{
    private_key: private_key
  } do
    tampering = %{
      schema_version: "2",
      nonce: "",
      node_id: "another-node",
      task_id: "another-task",
      correlation_id: "another-correlation",
      action_id: "system.logs.vacuum",
      parameter_hash: String.duplicate("f", 64),
      evidence_hash: "",
      issued_at: "not-a-time",
      expires_at: "not-a-time",
      operator: ""
    }

    Enum.each(tampering, fn {field, value} ->
      token = payload() |> Map.put(field, value) |> signed_token(private_key)

      assert {:error, {:binding_mismatch, ^field, _expected, ^value}} =
               ApprovalVerifier.verify(token, context())
    end)
  end

  @tag :tmp_dir
  test "expired token is rejected strictly", %{private_key: private_key} do
    token =
      payload()
      |> Map.put(:expires_at, DateTime.to_iso8601(@now))
      |> signed_token(private_key)

    assert {:error, :expired} = ApprovalVerifier.verify(token, context())
  end

  @tag :tmp_dir
  test "future-issued token is rejected", %{private_key: private_key} do
    token =
      payload()
      |> Map.put(:issued_at, @now |> DateTime.add(1, :second) |> DateTime.to_iso8601())
      |> signed_token(private_key)

    assert {:error, :not_yet_valid} = ApprovalVerifier.verify(token, context())
  end

  @tag :tmp_dir
  test "wrong node, action, and actual parameters are rejected", %{private_key: private_key} do
    token = signed_token(payload(), private_key)

    assert {:error, {:binding_mismatch, :node_id, "wrong", "node-1"}} =
             ApprovalVerifier.verify(token, %{context() | node_id: "wrong"})

    assert {:error,
            {:binding_mismatch, :action_id, "system.logs.vacuum", "systemd.service.restart"}} =
             ApprovalVerifier.verify(token, %{context() | action: :"system.logs.vacuum"})

    assert {:error, {:binding_mismatch, :parameter_hash, _, _}} =
             ApprovalVerifier.verify(token, %{
               context()
               | parameters: %{"unit" => "other.service"}
             })
  end

  defp payload do
    %{
      schema_version: "1",
      nonce: Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false),
      node_id: "node-1",
      task_id: "task-1",
      correlation_id: "corr-1",
      action_id: "systemd.service.restart",
      parameter_hash: ApprovalToken.hash_params(%{"unit" => "example.service"}),
      evidence_hash: ApprovalToken.hash_evidence(%{"active" => true}),
      issued_at: @now |> DateTime.add(-1, :second) |> DateTime.to_iso8601(),
      expires_at: @now |> DateTime.add(60, :second) |> DateTime.to_iso8601(),
      operator: "operator@example.com"
    }
  end

  defp context do
    %{
      node_id: "node-1",
      task_id: "task-1",
      correlation_id: "corr-1",
      action: :"systemd.service.restart",
      parameters: %{"unit" => "example.service"},
      now: @now
    }
  end

  defp signed_token(payload, private_key) do
    signature =
      :crypto.sign(:eddsa, :none, ApprovalToken.canonical_encode(payload), [
        private_key,
        :ed25519
      ])

    %{payload: payload, signature: signature}
  end

  defp stringify_keys(map), do: Map.new(map, fn {key, value} -> {Atom.to_string(key), value} end)
end
