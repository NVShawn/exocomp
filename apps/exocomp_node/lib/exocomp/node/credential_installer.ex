# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.CredentialInstaller do
  @moduledoc """
  Validates and installs a node certificate chain and private key as one
  atomically activated credential generation.

  Callers use `current/chain.pem` and `current/key.pem`. A new generation is
  completely written and validated before a single rename switches `current`;
  a failed install therefore leaves the previous generation active.
  """

  import Bitwise

  @chain_file "chain.pem"
  @key_file "key.pem"

  @type paths :: %{chain: Path.t(), key: Path.t(), generation: Path.t()}

  @spec install(binary(), binary(), Path.t(), keyword()) ::
          {:ok, paths()} | {:error, term()}
  def install(chain_pem, key_pem, directory, opts \\ [])

  def install(chain_pem, key_pem, directory, opts)
      when is_binary(chain_pem) and is_binary(key_pem) and is_binary(directory) and
             is_list(opts) do
    with :ok <- validate_material(chain_pem, key_pem, opts),
         :ok <- ensure_directory(directory),
         {:ok, stage, generation} <- paths(directory),
         :ok <- File.mkdir(stage),
         :ok <- File.chmod(stage, 0o700),
         :ok <- write_file(Path.join(stage, @chain_file), chain_pem, 0o600),
         :ok <- write_file(Path.join(stage, @key_file), key_pem, 0o600),
         :ok <- File.rename(stage, generation),
         :ok <- activate(directory, generation) do
      {:ok,
       %{
         chain: Path.join([directory, "current", @chain_file]),
         key: Path.join([directory, "current", @key_file]),
         generation: generation
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def install(_chain, _key, _directory, _opts), do: {:error, :invalid_arguments}

  @doc "Returns the stable paths applications should use for the active generation."
  @spec current(Path.t()) :: %{chain: Path.t(), key: Path.t()}
  def current(directory) do
    %{
      chain: Path.join([directory, "current", @chain_file]),
      key: Path.join([directory, "current", @key_file])
    }
  end

  defp validate_material(chain_pem, key_pem, opts) do
    with {:ok, certs} <- certificates(chain_pem),
         {:ok, key} <- private_key(key_pem),
         :ok <- key_matches(hd(certs), key),
         :ok <- validate_node_id(hd(certs), Keyword.get(opts, :node_id)),
         :ok <- validate_chain(certs, Keyword.get(opts, :ca_pem)) do
      :ok
    end
  rescue
    _exception -> {:error, :invalid_credentials}
  end

  defp certificates(pem) do
    entries = :public_key.pem_decode(pem)
    cert_entries = Enum.filter(entries, &match?({:Certificate, _, :not_encrypted}, &1))

    if cert_entries != [] and length(entries) == length(cert_entries) do
      {:ok, Enum.map(cert_entries, fn {:Certificate, der, _} -> der end)}
    else
      {:error, :invalid_certificate_chain}
    end
  end

  defp private_key(pem) do
    case X509.PrivateKey.from_pem(pem) do
      {:ok, key} -> {:ok, key}
      _other -> {:error, :invalid_private_key}
    end
  end

  defp key_matches(leaf_der, key) do
    leaf = X509.Certificate.from_der!(leaf_der)

    if X509.Certificate.public_key(leaf) == X509.PublicKey.derive(key),
      do: :ok,
      else: {:error, :key_mismatch}
  end

  defp validate_node_id(_leaf, nil), do: :ok

  defp validate_node_id(leaf_der, node_id) when is_binary(node_id) do
    leaf = X509.Certificate.from_der!(leaf_der)

    case X509.Certificate.extension(leaf, :subject_alt_name) do
      {:Extension, _oid, _critical, names} ->
        if {:dNSName, String.to_charlist(node_id)} in names,
          do: :ok,
          else: {:error, :node_id_mismatch}

      _other ->
        {:error, :node_id_mismatch}
    end
  end

  defp validate_chain(_certs, nil), do: :ok

  defp validate_chain(certs, ca_pem) when is_binary(ca_pem) do
    with {:ok, [root_der]} <- certificates(ca_pem),
         {:ok, _} <- :public_key.pkix_path_validation(root_der, Enum.reverse(certs), []) do
      :ok
    else
      _other -> {:error, :invalid_certificate_chain}
    end
  end

  defp ensure_directory(directory) do
    case File.lstat(directory) do
      {:ok, %{type: :directory}} ->
        secure_directory(directory)

      {:error, :enoent} ->
        with :ok <- File.mkdir_p(directory),
             :ok <- secure_directory(directory) do
          :ok
        else
          _other -> {:error, :unsafe_credential_directory}
        end

      _other ->
        {:error, :unsafe_credential_directory}
    end
  end

  defp secure_directory(directory) do
    with :ok <- File.chmod(directory, 0o700),
         {:ok, stat} <- File.lstat(directory),
         true <- stat.type == :directory and (stat.mode &&& 0o077) == 0 do
      :ok
    else
      _other -> {:error, :unsafe_credential_directory}
    end
  end

  defp paths(directory) do
    suffix =
      12
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    {:ok, Path.join(directory, ".staging-#{suffix}"),
     Path.join(directory, "generation-#{suffix}")}
  end

  defp write_file(path, contents, mode) do
    case File.open(path, [:write, :binary, :exclusive]) do
      {:ok, io} ->
        result =
          with :ok <- IO.binwrite(io, contents),
               :ok <- :file.sync(io),
               :ok <- File.chmod(path, mode) do
            :ok
          end

        File.close(io)
        result

      {:error, reason} ->
        {:error, {:credential_write_failed, reason}}
    end
  end

  defp activate(directory, generation) do
    name = Path.basename(generation)
    temporary = Path.join(directory, ".current-#{System.unique_integer([:positive])}")
    current = Path.join(directory, "current")

    with :ok <- File.ln_s(name, temporary),
         :ok <- File.rename(temporary, current) do
      :ok
    else
      {:error, reason} ->
        File.rm(temporary)
        {:error, {:credential_activation_failed, reason}}
    end
  end
end
