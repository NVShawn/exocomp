# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.WebSocket do
  @moduledoc """
  Minimal RFC 6455 client transport used by the coordinator's Mission Control
  connection.

  The coordinator has no inbound Mission Control listener.  Keeping the
  client on top of `:ssl` makes that boundary explicit and avoids adding a
  general-purpose HTTP client whose defaults could weaken the mTLS policy.
  """

  import Bitwise

  @magic "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  @default_path "/api/v1/clusters/connect"
  @max_frame_size 16 * 1_024 * 1_024

  defstruct [:socket, :host, :port, :path, buffer: <<>>]

  @type t :: %__MODULE__{
          socket: :ssl.sslsocket(),
          host: String.t(),
          port: pos_integer(),
          path: String.t(),
          buffer: binary()
        }

  @type message :: {:text, binary()} | {:binary, binary()} | {:close, binary()}

  @doc "Connects to a `wss://` endpoint with TLS 1.3 and a client certificate."
  @spec connect(keyword()) :: {:ok, t()} | {:error, term()}
  def connect(opts) when is_list(opts) do
    with {:ok, uri} <- endpoint_uri(opts),
         {:ok, tls_options} <- tls_options(opts, uri.host),
         {:ok, socket} <- open_tls(uri, tls_options, opts) do
      case websocket_handshake(socket, uri, opts) do
        {:ok, key} ->
          {:ok,
           %__MODULE__{
             socket: socket,
             host: uri.host,
             port: uri.port,
             path: request_path(uri),
             buffer: key.leftover
           }}

        {:error, reason} ->
          :ssl.close(socket)
          {:error, reason}
      end
    end
  end

  @doc "Builds the non-negotiable TLS options used by the outbound client."
  @spec tls_options(keyword()) :: {:ok, keyword()} | {:error, term()}
  def tls_options(opts) when is_list(opts) do
    case endpoint_uri(opts) do
      {:ok, uri} -> tls_options(opts, uri.host)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Closes a client connection and releases its TLS socket."
  @spec close(t()) :: :ok
  def close(%__MODULE__{socket: socket}) do
    _ = :ssl.close(socket)
    :ok
  end

  @doc "Sends a text WebSocket frame. Maps are encoded as JSON for callers."
  @spec send_text(t(), binary() | map()) :: {:ok, t()} | {:error, term()}
  def send_text(%__MODULE__{} = state, payload) do
    payload = if is_map(payload), do: Jason.encode!(payload), else: payload
    send_frame(state, 0x1, payload)
  end

  @doc "Sends a binary WebSocket frame."
  @spec send_binary(t(), iodata()) :: {:ok, t()} | {:error, term()}
  def send_binary(%__MODULE__{} = state, payload),
    do: send_frame(state, 0x2, IO.iodata_to_binary(payload))

  @doc "Receives one complete WebSocket message, replying to ping frames."
  @spec recv(t(), timeout()) :: {:ok, message(), t()} | {:error, term()}
  def recv(%__MODULE__{} = state, timeout \\ 15_000) do
    case decode_frame(state.buffer) do
      {:ok, opcode, payload, rest} ->
        handle_frame(opcode, payload, %{state | buffer: rest}, timeout)

      :more ->
        recv_more(state, timeout)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp recv_more(%__MODULE__{socket: socket, buffer: buffer} = state, timeout) do
    case :ssl.recv(socket, 0, timeout) do
      {:ok, data} -> recv(%{state | buffer: buffer <> data}, timeout)
      {:error, reason} -> {:error, reason}
      :closed -> {:error, :closed}
    end
  end

  defp handle_frame(0x1, payload, state, _timeout), do: {:ok, {:text, payload}, state}
  defp handle_frame(0x2, payload, state, _timeout), do: {:ok, {:binary, payload}, state}
  defp handle_frame(0x8, payload, state, _timeout), do: {:ok, {:close, payload}, state}

  defp handle_frame(0x9, payload, state, timeout) do
    with {:ok, state} <- send_frame(state, 0xA, payload), do: recv(state, timeout)
  end

  defp handle_frame(0xA, _payload, state, timeout), do: recv(state, timeout)
  defp handle_frame(_opcode, _payload, _state, _timeout), do: {:error, :unsupported_frame}

  defp endpoint_uri(opts) do
    endpoint =
      Enum.find_value([:endpoint, :url, :mission_control_url], &Keyword.get(opts, &1))

    case endpoint && URI.parse(endpoint) do
      %URI{scheme: "wss", host: host, port: port} = uri when is_binary(host) and host != "" ->
        port = port || 443

        if is_integer(port) and port in 1..65_535 do
          {:ok, %{uri | port: port}}
        else
          {:error, :invalid_endpoint_port}
        end

      %URI{scheme: scheme} when is_binary(scheme) ->
        {:error, {:unsupported_endpoint_scheme, scheme}}

      _other ->
        {:error, :invalid_endpoint}
    end
  end

  defp tls_options(opts, host) do
    with {:ok, ca_cert} <- required_option(opts, [:ca_cert, :cacertfile, :ca_cert_path]),
         {:ok, client_cert} <-
           required_option(opts, [:client_cert, :certfile, :client_cert_path]),
         {:ok, client_key} <- required_option(opts, [:client_key, :keyfile, :client_key_path]) do
      {:ok,
       [
         verify: :verify_peer,
         cacertfile: to_charlist(ca_cert),
         certfile: to_charlist(client_cert),
         keyfile: to_charlist(client_key),
         server_name_indication: to_charlist(Keyword.get(opts, :server_name, host)),
         customize_hostname_check: [
           match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
         ],
         versions: [:"tlsv1.3"]
       ]}
    end
  end

  defp required_option(opts, names) do
    case Enum.find_value(names, &Keyword.get(opts, &1)) do
      value when is_binary(value) and value != "" -> {:ok, value}
      value when is_list(value) and value != [] -> {:ok, value}
      _other -> {:error, {:missing_tls_option, hd(names)}}
    end
  end

  defp open_tls(uri, tls_options, opts) do
    timeout = Keyword.get(opts, :connect_timeout_ms, 5_000)

    connect_host = Keyword.get(opts, :connect_host, uri.host)
    :ssl.connect(to_charlist(connect_host), uri.port, tls_options, timeout)
  catch
    :exit, reason -> {:error, reason}
  end

  defp websocket_handshake(socket, uri, opts) do
    key = Base.encode64(:crypto.strong_rand_bytes(16))
    host_header = host_header(uri.host, uri.port)

    request = [
      "GET ",
      request_path(uri),
      " HTTP/1.1\r\n",
      "Host: ",
      host_header,
      "\r\n",
      "Upgrade: websocket\r\n",
      "Connection: Upgrade\r\n",
      "Sec-WebSocket-Key: ",
      key,
      "\r\n",
      "Sec-WebSocket-Version: 13\r\n",
      optional_protocol_header(opts),
      "\r\n"
    ]

    with :ok <- :ssl.send(socket, request),
         {:ok, response, leftover} <-
           read_headers(socket, <<>>, Keyword.get(opts, :timeout_ms, 15_000)),
         :ok <- validate_handshake(response, key) do
      {:ok, %{leftover: leftover}}
    end
  end

  defp optional_protocol_header(opts) do
    case Keyword.get(opts, :subprotocol) do
      protocol when is_binary(protocol) and protocol != "" ->
        "Sec-WebSocket-Protocol: " <> protocol <> "\r\n"

      _other ->
        ""
    end
  end

  defp read_headers(socket, buffer, timeout) do
    case :binary.match(buffer, "\r\n\r\n") do
      {offset, 4} ->
        <<headers::binary-size(offset), _delimiter::binary-size(4), leftover::binary>> = buffer
        {:ok, headers, leftover}

      :nomatch ->
        case :ssl.recv(socket, 0, timeout) do
          {:ok, data} -> read_headers(socket, buffer <> data, timeout)
          {:error, reason} -> {:error, reason}
          :closed -> {:error, :closed}
        end
    end
  end

  defp validate_handshake(response, key) do
    case String.split(response, "\r\n", trim: true) do
      [status_line | header_lines] ->
        with {:ok, 101} <- status_code(status_line),
             headers <- parse_headers(header_lines),
             expected <- Base.encode64(:crypto.hash(:sha, key <> @magic)),
             ^expected <- Map.get(headers, "sec-websocket-accept") do
          :ok
        else
          {:ok, status} -> {:error, {:unexpected_upgrade_status, status}}
          nil -> {:error, :missing_websocket_accept}
          _other -> {:error, :invalid_websocket_accept}
        end

      _other ->
        {:error, :malformed_upgrade_response}
    end
  end

  defp status_code("HTTP/1.1 " <> rest), do: parse_status(rest)
  defp status_code("HTTP/1.0 " <> rest), do: parse_status(rest)
  defp status_code(_line), do: {:error, :malformed_upgrade_response}

  defp parse_status(rest) do
    case Integer.parse(String.slice(rest, 0, 3)) do
      {status, _} -> {:ok, status}
      :error -> {:error, :malformed_upgrade_response}
    end
  end

  defp parse_headers(lines) do
    Enum.reduce(lines, %{}, fn line, headers ->
      case String.split(line, ":", parts: 2) do
        [key, value] -> Map.put(headers, String.downcase(String.trim(key)), String.trim(value))
        _other -> headers
      end
    end)
  end

  defp send_frame(%__MODULE__{socket: socket} = state, opcode, payload)
       when is_binary(payload) and byte_size(payload) <= @max_frame_size do
    mask = :crypto.strong_rand_bytes(4)
    masked_payload = mask_payload(payload, mask)

    case :ssl.send(socket, frame_header(opcode, byte_size(payload), mask) <> masked_payload) do
      :ok -> {:ok, state}
      {:error, reason} -> {:error, reason}
    end
  end

  defp send_frame(_state, _opcode, _payload), do: {:error, :frame_too_large}

  defp frame_header(opcode, length, mask) when length <= 125,
    do: <<1::1, 0::3, opcode::4, 1::1, length::7, mask::binary>>

  defp frame_header(opcode, length, mask) when length <= 65_535,
    do: <<1::1, 0::3, opcode::4, 1::1, 126::7, length::16, mask::binary>>

  defp frame_header(opcode, length, mask),
    do: <<1::1, 0::3, opcode::4, 1::1, 127::7, length::64, mask::binary>>

  defp mask_payload(payload, mask), do: mask_payload(payload, mask, 0, <<>>)

  defp mask_payload(<<>>, _mask, _index, acc), do: acc

  defp mask_payload(<<byte, rest::binary>>, mask, index, acc) do
    mask_byte = :binary.at(mask, rem(index, 4))
    mask_payload(rest, mask, index + 1, <<acc::binary, bxor(byte, mask_byte)>>)
  end

  defp decode_frame(
         <<_fin::1, _rsv::3, _opcode::4, _masked::1, length::7, _rest::binary>> = frame
       )
       when length in 0..125 do
    decode_frame_with_length(frame, length, 2)
  end

  defp decode_frame(
         <<_fin::1, _rsv::3, _opcode::4, _masked::1, 126::7, length::16, _rest::binary>> = frame
       ),
       do: decode_frame_with_length(frame, length, 4)

  defp decode_frame(
         <<_fin::1, _rsv::3, _opcode::4, _masked::1, 127::7, length::64, _rest::binary>> = frame
       )
       when length <= @max_frame_size,
       do: decode_frame_with_length(frame, length, 10)

  defp decode_frame(
         <<_fin::1, _rsv::3, _opcode::4, _masked::1, 127::7, _length::64, _rest::binary>>
       ),
       do: {:error, :frame_too_large}

  defp decode_frame(_frame), do: :more

  defp decode_frame_with_length(
         <<_fin::1, _rsv::3, opcode::4, masked::1, _length_marker::7, rest::binary>>,
         length,
         length_bytes
       ) do
    <<_extended_length::binary-size(length_bytes - 2), payload_data::binary>> = rest

    if masked == 1 do
      if byte_size(payload_data) < length + 4 do
        :more
      else
        <<mask::binary-size(4), payload::binary-size(length), leftover::binary>> = payload_data
        {:ok, opcode, mask_payload(payload, mask), leftover}
      end
    else
      if byte_size(payload_data) < length do
        :more
      else
        <<payload::binary-size(length), leftover::binary>> = payload_data
        {:ok, opcode, payload, leftover}
      end
    end
  rescue
    _exception -> :more
  end

  defp request_path(%URI{path: path, query: query}) do
    path = if is_binary(path) and path != "", do: path, else: @default_path
    if is_binary(query), do: path <> "?" <> query, else: path
  end

  defp host_header(host, port) when port == 443, do: bracket_host(host)
  defp host_header(host, port), do: bracket_host(host) <> ":" <> Integer.to_string(port)

  defp bracket_host(host) do
    if String.contains?(host, ":"), do: "[" <> host <> "]", else: host
  end
end
