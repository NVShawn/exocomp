# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.ArtifactIdentity do
  @moduledoc """
  Captures and cross-checks the exact shipped inputs used by an M5 run.
  """

  @identity_fields ~w(
    schema_version product version architecture source_commit
    elixir_version otp_version erts_version
  )

  @enforce_keys [
    :artifact_version,
    :architecture,
    :source_commit,
    :elixir_version,
    :otp_version,
    :erts_version,
    :node,
    :coordinator,
    :llama_server_path,
    :llama_server_sha256,
    :llama_launcher_sha256,
    :model_path,
    :model_sha256
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  @doc """
  Loads node and coordinator `build-identity.json` files, checks they describe
  one build, verifies the model checksum, and hashes the shipped llama runtime.
  """
  @spec capture(Path.t(), Path.t(), Path.t(), Path.t(), String.t()) ::
          {:ok, t()} | {:error, term()}
  def capture(node_release, coordinator_release, llama_server, model_path, expected_model_sha256)
      when is_binary(node_release) and is_binary(coordinator_release) and
             is_binary(llama_server) and is_binary(model_path) and
             is_binary(expected_model_sha256) do
    with :ok <- absolute_file(:llama_server, llama_server),
         :ok <- absolute_file(:model_path, model_path),
         {:ok, node} <- read_release_identity(node_release, "exocomp_node"),
         {:ok, coordinator} <-
           read_release_identity(coordinator_release, "exocomp_coordinator"),
         :ok <- matching_releases(node, coordinator),
         {:ok, actual_model_sha256} <- sha256(model_path),
         :ok <- checksum_matches(expected_model_sha256, actual_model_sha256),
         {:ok, runtime_path} <- llama_runtime_path(llama_server),
         {:ok, llama_server_sha256} <- sha256(runtime_path),
         {:ok, llama_launcher_sha256} <- sha256(llama_server) do
      {:ok,
       %__MODULE__{
         artifact_version: node["version"],
         architecture: node["architecture"],
         source_commit: node["source_commit"],
         elixir_version: node["elixir_version"],
         otp_version: node["otp_version"],
         erts_version: node["erts_version"],
         node: node,
         coordinator: coordinator,
         llama_server_path: runtime_path,
         llama_server_sha256: llama_server_sha256,
         llama_launcher_sha256: llama_launcher_sha256,
         model_path: model_path,
         model_sha256: actual_model_sha256
       }}
    end
  end

  @doc "Returns a JSON-ready representation with stable string keys."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = identity) do
    identity
    |> Map.from_struct()
    |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)
  end

  @doc "Streams a file through SHA-256 and returns lowercase hexadecimal."
  @spec sha256(Path.t()) :: {:ok, String.t()} | {:error, term()}
  def sha256(path) when is_binary(path) do
    with {:ok, io} <- File.open(path, [:read, :binary]) do
      try do
        digest =
          io
          |> IO.binstream(1_048_576)
          |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
          |> :crypto.hash_final()
          |> Base.encode16(case: :lower)

        {:ok, digest}
      after
        File.close(io)
      end
    end
  end

  defp absolute_file(field, path) do
    cond do
      Path.type(path) != :absolute -> {:error, {:path_not_absolute, field, path}}
      not File.regular?(path) -> {:error, {:file_not_found, field, path}}
      true -> :ok
    end
  end

  defp read_release_identity(release, expected_product) do
    path = Path.join(release, "build-identity.json")

    with true <- File.dir?(release),
         {:ok, contents} <- File.read(path),
         {:ok, identity} when is_map(identity) <- Jason.decode(contents),
         :ok <- required_identity_fields(identity),
         :ok <- expected_product(identity, expected_product),
         {:ok, identity_sha256} <- sha256(path) do
      compact =
        identity
        |> Map.drop(["payload_file_inventory"])
        |> Map.put("build_identity_sha256", identity_sha256)

      {:ok, compact}
    else
      false -> {:error, {:release_directory_not_found, release}}
      {:error, :enoent} -> {:error, {:build_identity_not_found, release}}
      {:error, %Jason.DecodeError{} = reason} -> {:error, {:invalid_build_identity, path, reason}}
      {:error, reason} -> {:error, reason}
      _ -> {:error, {:invalid_build_identity, path, :expected_object}}
    end
  end

  defp required_identity_fields(identity) do
    missing = Enum.reject(@identity_fields, &Map.has_key?(identity, &1))

    case missing do
      [] -> validate_identity(identity)
      fields -> {:error, {:build_identity_missing_fields, identity["product"], fields}}
    end
  end

  defp validate_identity(identity) do
    valid? =
      identity["schema_version"] == 1 and
        is_binary(identity["product"]) and identity["product"] != "" and
        is_binary(identity["version"]) and identity["version"] != "" and
        identity["architecture"] in ["amd64", "arm64"] and
        is_binary(identity["source_commit"]) and
        Regex.match?(~r/^[0-9a-f]{40,64}$/, identity["source_commit"]) and
        Enum.all?(~w(elixir_version otp_version erts_version), fn field ->
          is_binary(identity[field]) and identity[field] != ""
        end)

    if valid? do
      :ok
    else
      {:error, {:invalid_build_identity_fields, identity["product"]}}
    end
  end

  defp expected_product(%{"product" => product}, product), do: :ok

  defp expected_product(%{"product" => actual}, expected),
    do: {:error, {:unexpected_release_product, expected, actual}}

  defp matching_releases(node, coordinator) do
    compared = ~w(version architecture source_commit elixir_version otp_version erts_version)

    mismatches =
      Enum.reject(compared, fn field ->
        node[field] == coordinator[field]
      end)

    case mismatches do
      [] -> :ok
      fields -> {:error, {:release_identity_mismatch, fields}}
    end
  end

  defp checksum_matches(expected, actual) do
    normalized = String.downcase(expected)

    cond do
      not Regex.match?(~r/^[0-9a-f]{64}$/, normalized) ->
        {:error, {:invalid_model_sha256, expected}}

      normalized == actual ->
        :ok

      true ->
        {:error, {:model_sha256_mismatch, normalized, actual}}
    end
  end

  defp llama_runtime_path(launcher) do
    sibling = Path.join(Path.dirname(launcher), "llama-server.bin")

    cond do
      File.regular?(sibling) -> {:ok, sibling}
      File.regular?(launcher) -> {:ok, launcher}
      true -> {:error, {:file_not_found, :llama_server, launcher}}
    end
  end
end
