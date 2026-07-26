# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.ArtifactIdentityTest do
  use ExUnit.Case, async: true

  alias Bench.ArtifactIdentity

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "artifact-identity-#{System.unique_integer([:positive])}"
      )

    node = Path.join(root, "node")
    coordinator = Path.join(root, "coordinator")
    runtime = Path.join(root, "runtime")
    Enum.each([node, coordinator, runtime], &File.mkdir_p!/1)

    model = Path.join(root, "model.gguf")
    launcher = Path.join(runtime, "llama-server")
    binary = Path.join(runtime, "llama-server.bin")
    File.write!(model, "pinned model")
    File.write!(launcher, "#!/bin/sh\n")
    File.write!(binary, "real llama runtime")

    write_identity(node, "exocomp_node")
    write_identity(coordinator, "exocomp_coordinator")

    on_exit(fn -> File.rm_rf!(root) end)

    %{
      root: root,
      node: node,
      coordinator: coordinator,
      model: model,
      launcher: launcher,
      binary: binary
    }
  end

  test "captures matching release, llama runtime, and verified model identity", context do
    {:ok, model_sha} = ArtifactIdentity.sha256(context.model)
    {:ok, binary_sha} = ArtifactIdentity.sha256(context.binary)
    {:ok, launcher_sha} = ArtifactIdentity.sha256(context.launcher)

    assert {:ok, identity} =
             ArtifactIdentity.capture(
               context.node,
               context.coordinator,
               context.launcher,
               context.model,
               String.upcase(model_sha)
             )

    assert identity.artifact_version == "0.1.0"
    assert identity.llama_server_path == context.binary
    assert identity.llama_server_sha256 == binary_sha
    assert identity.llama_launcher_sha256 == launcher_sha
    assert identity.model_sha256 == model_sha
    assert ArtifactIdentity.to_map(identity)["source_commit"] == String.duplicate("a", 40)
    assert Regex.match?(~r/^[0-9a-f]{64}$/, identity.node["build_identity_sha256"])
    refute Map.has_key?(identity.node, "payload_file_inventory")
  end

  test "rejects release identity mismatches", context do
    write_identity(context.coordinator, "exocomp_coordinator", version: "0.2.0")
    {:ok, model_sha} = ArtifactIdentity.sha256(context.model)

    assert {:error, {:release_identity_mismatch, fields}} =
             ArtifactIdentity.capture(
               context.node,
               context.coordinator,
               context.launcher,
               context.model,
               model_sha
             )

    assert "version" in fields
  end

  test "missing build identity and model checksum mismatch fail before a run", context do
    File.rm!(Path.join(context.node, "build-identity.json"))
    {:ok, model_sha} = ArtifactIdentity.sha256(context.model)

    assert {:error, {:build_identity_not_found, release}} =
             ArtifactIdentity.capture(
               context.node,
               context.coordinator,
               context.launcher,
               context.model,
               model_sha
             )

    assert release == context.node

    write_identity(context.node, "exocomp_node")

    assert {:error, {:model_sha256_mismatch, _, _}} =
             ArtifactIdentity.capture(
               context.node,
               context.coordinator,
               context.launcher,
               context.model,
               String.duplicate("0", 64)
             )
  end

  test "rejects malformed required identity fields", context do
    write_identity(context.node, "exocomp_node", source_commit: "not-a-commit")
    {:ok, model_sha} = ArtifactIdentity.sha256(context.model)

    assert {:error, {:invalid_build_identity_fields, "exocomp_node"}} =
             ArtifactIdentity.capture(
               context.node,
               context.coordinator,
               context.launcher,
               context.model,
               model_sha
             )
  end

  test "requires absolute shipped binary and model paths", context do
    {:ok, model_sha} = ArtifactIdentity.sha256(context.model)

    assert {:error, {:path_not_absolute, :llama_server, "relative/llama-server"}} =
             ArtifactIdentity.capture(
               context.node,
               context.coordinator,
               "relative/llama-server",
               context.model,
               model_sha
             )
  end

  defp write_identity(directory, product, opts \\ []) do
    identity = %{
      "schema_version" => 1,
      "product" => product,
      "version" => Keyword.get(opts, :version, "0.1.0"),
      "architecture" => current_architecture(),
      "source_commit" => Keyword.get(opts, :source_commit, String.duplicate("a", 40)),
      "elixir_version" => "1.20.2",
      "otp_version" => "28.5.0.3",
      "erts_version" => "16.2"
    }

    File.write!(Path.join(directory, "build-identity.json"), Jason.encode!(identity))
  end

  defp current_architecture, do: Bench.HostProfile.detect().architecture
end
