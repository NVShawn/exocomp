defmodule Exocomp.Coordinator.A2A.HTTPTransport do
  @moduledoc """
  `:httpc` implementation of the diagnostic A2A transport boundary.

  The coordinator client certificate, private key, and trust root are supplied
  as `:certfile`, `:keyfile`, and `:cacertfile` in the request's TLS options.
  """

  @behaviour Exocomp.Coordinator.A2A.Transport

  @impl true
  def request(request, _opts) do
    with :ok <- validate_tls(request.tls) do
      url = url(request.address, request.port, request.path)

      headers =
        Enum.map(request.headers, fn {key, value} -> {to_charlist(key), to_charlist(value)} end)

      http_options = [
        timeout: request.timeout_ms,
        connect_timeout: request.timeout_ms,
        ssl: ssl_options(request)
      ]

      http_request = http_request(request.method, url, headers, request.body)

      request.method
      |> :httpc.request(http_request, http_options, body_format: :binary)
      |> normalize_response()
    end
  catch
    :exit, reason -> {:error, reason}
  end

  defp validate_tls(tls) do
    missing = Enum.reject([:cacertfile, :certfile, :keyfile], &Keyword.has_key?(tls, &1))
    if missing == [], do: :ok, else: {:error, {:missing_tls_options, missing}}
  end

  defp ssl_options(request) do
    identity = to_charlist(request.certificate_identity)

    request.tls
    |> Keyword.take([:cacertfile, :certfile, :keyfile, :password, :versions, :ciphers])
    |> Keyword.merge(
      verify: :verify_peer,
      server_name_indication: identity,
      customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
    )
  end

  defp http_request(:get, url, headers, _body), do: {to_charlist(url), headers}

  defp http_request(:post, url, headers, body),
    do: {to_charlist(url), headers, ~c"application/json", body}

  defp normalize_response({:ok, {{_version, status, _reason}, headers, body}}) do
    normalized_headers =
      Enum.map(headers, fn {key, value} ->
        {key |> to_string() |> String.downcase(), to_string(value)}
      end)

    {:ok, status, normalized_headers, body}
  end

  defp normalize_response({:error, reason}) when reason in [:timeout, :connect_timeout],
    do: {:error, :timeout}

  defp normalize_response({:error, reason}), do: {:error, reason}

  defp url(address, port, path) do
    host = if String.contains?(address, ":"), do: "[#{address}]", else: address
    "https://#{host}:#{port}#{path}"
  end
end
