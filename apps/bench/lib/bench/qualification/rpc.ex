# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.RPC do
  @moduledoc false

  @begin "EXOCOMP_BENCH_JSON_BEGIN"
  @finish "EXOCOMP_BENCH_JSON_END"

  @doc "Wraps an Elixir expression so release RPC emits one framed JSON value."
  @spec frame_expression(String.t()) :: String.t()
  def frame_expression(expression) when is_binary(expression) do
    """
    value = (#{expression})
    IO.write(#{inspect(@begin)})
    IO.write(Jason.encode!(value))
    IO.write(#{inspect(@finish)})
    :ok
    """
  end

  @doc "Extracts and decodes the framed JSON value from release CLI output."
  @spec decode_output(String.t()) :: {:ok, term()} | {:error, term()}
  def decode_output(output) when is_binary(output) do
    pattern = ~r/#{Regex.escape(@begin)}(.*?)#{Regex.escape(@finish)}/s

    case Regex.run(pattern, output) do
      [_, json] -> Jason.decode(json)
      _other -> {:error, {:rpc_output_unframed, String.slice(output, 0, 500)}}
    end
  end

  @doc "Reads exactly one protected release-cookie assignment."
  @spec read_cookie(Path.t()) :: {:ok, String.t()} | {:error, term()}
  def read_cookie(path) do
    with {:ok, contents} <- File.read(path),
         [value] <- cookie_values(contents),
         true <- value != "" and not String.contains?(value, ["\n", "\r", <<0>>]) do
      {:ok, value}
    else
      false -> {:error, {:invalid_release_cookie, path}}
      values when is_list(values) -> {:error, {:invalid_release_cookie, path}}
      {:error, reason} -> {:error, {:release_cookie_read_failed, path, reason}}
    end
  end

  defp cookie_values(contents) do
    for line <- String.split(contents, "\n", trim: true),
        String.starts_with?(line, "RELEASE_COOKIE="),
        do: String.replace_prefix(line, "RELEASE_COOKIE=", "")
  end
end
