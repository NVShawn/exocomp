# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Collectors.HttpProbe do
  @moduledoc """
  HTTP prober for loopback addresses only.

  Executes HTTP GET requests to loopback URLs and collects response metadata
  (status code, response time, body size). Rejects non-loopback URLs at
  runtime as a safety check.

  ## Output limits and timeout

  Response bodies are limited to `max_response_bytes`. The HTTP request is
  given `timeout_ms` to complete; if it times out, a timeout error is
  returned.

  ## Return format

  Returns one of:
  - `{:ok, status_code, response_time_ms, body_size}` — successful probe
  - `{:error, reason}` — connection failed, timeout, or other error
  """

  @doc """
  Probe an HTTP endpoint.

  Only loopback addresses (127.0.0.0/8, ::1, localhost) are accepted.

  Options:
  - `:timeout_ms` — HTTP request timeout in milliseconds (default 5_000).
  - `:max_response_bytes` — maximum response body size in bytes (default 65_536).

  Returns `{:ok, status_code, response_time_ms, body_size}` or `{:error, reason}`.
  """
  @spec probe(String.t(), keyword()) :: {:ok, integer(), integer(), integer()} | {:error, term()}
  def probe(url, opts \\ []) when is_binary(url) and is_list(opts) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)
    max_response_bytes = Keyword.get(opts, :max_response_bytes, 65_536)

    # Validate loopback at runtime for defense-in-depth
    case is_loopback_url(url) do
      true ->
        do_probe(url, timeout_ms, max_response_bytes)

      false ->
        {:error, "non-loopback URL"}
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP probing
  # ---------------------------------------------------------------------------

  defp do_probe(url, timeout_ms, max_response_bytes) do
    started = System.monotonic_time(:millisecond)

    # Ensure inets is started for httpc
    :inets.start()

    # Parse the URL to handle inet/inet6
    case URI.parse(url) do
      %URI{host: host, scheme: scheme} when is_binary(host) and scheme in ["http", "https"] ->
        url_str = to_charlist(url)
        http_opts = [timeout: timeout_ms]

        # Select socket options for inet or inet6
        request_opts = [socket_opts: [socket_family(host)]]

        # Make the HTTP request using httpc from Erlang's inets
        case :httpc.request(:get, {url_str, []}, http_opts, request_opts) do
          {:ok, {{_version, status_code, _reason}, _headers, body}} ->
            elapsed = System.monotonic_time(:millisecond) - started
            body_size = byte_size(body)

            if body_size > max_response_bytes do
              {:error, "response exceeded #{max_response_bytes} bytes"}
            else
              {:ok, status_code, elapsed, body_size}
            end

          {:error, reason} ->
            {:error, reason}
        end

      _invalid_uri ->
        {:error, "invalid URI"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp is_loopback_url(url) do
    case URI.parse(url) do
      %URI{host: host, scheme: scheme}
      when scheme in ["http", "https"] and is_binary(host) ->
        String.starts_with?(host, "127.") or host == "localhost" or host == "::1"

      _other ->
        false
    end
  end

  # Determine socket family for the given hostname
  defp socket_family("::1"), do: :inet6
  # localhost typically resolves to 127.0.0.1
  defp socket_family("localhost"), do: :inet

  defp socket_family(host) do
    if String.starts_with?(host, "127.") do
      :inet
    else
      :inet6
    end
  end
end
