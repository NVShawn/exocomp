Code.require_file("support/fake_llama_server.ex", __DIR__)

# :httpc (used by ProposalClient) references :public_key in its default SSL
# option setup even for plain HTTP connections, starting in OTP 27+.
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

ExUnit.start()
