# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.CredentialInstallerTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.CredentialInstaller

  @certs Path.expand("../../fixtures/certs", __DIR__)

  setup do
    directory =
      Path.join(
        System.tmp_dir!(),
        "credential-installer-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(directory) end)

    {:ok,
     directory: directory,
     chain: File.read!(Path.join(@certs, "node.crt")),
     key: File.read!(Path.join(@certs, "node.key")),
     ca: File.read!(Path.join(@certs, "ca.crt"))}
  end

  test "installs a validated generation with stable paths and strict modes", context do
    assert {:ok, paths} =
             CredentialInstaller.install(context.chain, context.key, context.directory,
               node_id: "exocomp-test-node",
               ca_pem: context.ca
             )

    assert File.read!(paths.chain) == context.chain
    assert File.read!(paths.key) == context.key
    assert File.stat!(paths.key).mode |> Bitwise.band(0o777) == 0o600
    assert File.stat!(paths.generation).mode |> Bitwise.band(0o777) == 0o700
    assert File.lstat!(Path.join(context.directory, "current")).type == :symlink
  end

  test "a failed replacement leaves the prior generation active", context do
    assert {:ok, first} =
             CredentialInstaller.install(context.chain, context.key, context.directory,
               node_id: "exocomp-test-node",
               ca_pem: context.ca
             )

    old_target = File.read_link!(Path.join(context.directory, "current"))
    rogue_key = File.read!(Path.join(@certs, "rogue.key"))

    assert {:error, :key_mismatch} =
             CredentialInstaller.install(context.chain, rogue_key, context.directory,
               node_id: "exocomp-test-node",
               ca_pem: context.ca
             )

    assert File.read_link!(Path.join(context.directory, "current")) == old_target
    assert File.read!(first.chain) == context.chain
  end

  test "rejects a certificate for a different node", context do
    assert {:error, :node_id_mismatch} =
             CredentialInstaller.install(context.chain, context.key, context.directory,
               node_id: "another-node",
               ca_pem: context.ca
             )

    refute File.exists?(Path.join(context.directory, "current"))
  end

  test "refuses a symlink as the credential directory", context do
    target = context.directory <> "-target"
    File.mkdir_p!(target)
    File.ln_s!(target, context.directory)

    assert {:error, :unsafe_credential_directory} =
             CredentialInstaller.install(context.chain, context.key, context.directory,
               node_id: "exocomp-test-node",
               ca_pem: context.ca
             )

    assert File.lstat!(context.directory).type == :symlink
    refute File.exists?(Path.join(target, "current"))
    File.rm_rf(target)
  end
end
