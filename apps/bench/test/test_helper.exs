# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
Code.require_file("support/fake_llama_server.ex", __DIR__)

# :httpc (used by Bench.Workload.LlamaInference) references :public_key in its
# default SSL option setup even for plain HTTP connections, starting in OTP 27+.
# Ensure public_key is in the code path and started before any tests run.
# In the full Docker build environment this is satisfied automatically; in the
# stripped-down local toolchain we add it explicitly.
otp_lib = to_string(:code.root_dir()) <> "/lib"

case File.ls(otp_lib) do
  {:ok, dirs} ->
    dirs
    |> Enum.filter(&String.starts_with?(&1, "public_key"))
    |> Enum.each(fn dir ->
      ebin = ~c"#{otp_lib}/#{dir}/ebin"
      :code.add_patha(ebin)
    end)

    dirs
    |> Enum.filter(&String.starts_with?(&1, "asn1"))
    |> Enum.each(fn dir ->
      ebin = ~c"#{otp_lib}/#{dir}/ebin"
      :code.add_patha(ebin)
    end)

  _error ->
    :ok
end

Application.ensure_all_started(:public_key)

# Warm up the OS CA cert cache to force-load :pubkey_cert_records and all other
# transitive :public_key modules before any test starts. Under full-system arm64
# QEMU emulation, lazy code loading via code_server is slow enough (>2 s) that
# the first call to :httpc.ssl_verify_host_options/1 — which triggers
# :pubkey_os_cacerts.get/0 → :pubkey_cert_records.decode_cert/1 via
# code_server.call — can exceed the per-test timeout and cause spurious failures.
# This warmup is a no-op on native hosts where the modules are already loaded.
try do
  :pubkey_os_cacerts.get()
rescue
  _ -> :ok
end

ExUnit.start()
