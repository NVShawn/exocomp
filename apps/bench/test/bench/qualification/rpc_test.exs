# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.RPCTest do
  use ExUnit.Case, async: true

  alias Bench.Qualification.RPC

  test "decodes framed JSON while ignoring release CLI noise" do
    output = "warning\nEXOCOMP_BENCH_JSON_BEGIN{\"samples\":[1]}EXOCOMP_BENCH_JSON_END\n:ok\n"
    assert {:ok, %{"samples" => [1]}} = RPC.decode_output(output)
    assert {:error, {:rpc_output_unframed, _}} = RPC.decode_output("no frame")
  end

  test "frames an expression with deterministic markers" do
    framed = RPC.frame_expression("%{\"ok\" => true}")
    assert framed =~ "EXOCOMP_BENCH_JSON_BEGIN"
    assert framed =~ "EXOCOMP_BENCH_JSON_END"
    assert framed =~ "Jason.encode!"
  end

  test "accepts one cookie assignment and rejects ambiguous files" do
    root = Path.join(System.tmp_dir!(), "bench-rpc-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    path = Path.join(root, "release-cookie.env")

    File.write!(path, "RELEASE_COOKIE=secret-value\n")
    assert {:ok, "secret-value"} = RPC.read_cookie(path)

    File.write!(path, "RELEASE_COOKIE=one\nRELEASE_COOKIE=two\n")
    assert {:error, {:invalid_release_cookie, ^path}} = RPC.read_cookie(path)
  end
end
