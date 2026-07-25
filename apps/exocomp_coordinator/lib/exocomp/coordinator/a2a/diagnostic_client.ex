# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.DiagnosticClient do
  @moduledoc """
  Coordinator-side A2A 1.0 boundary for node diagnostic tasks.

  Only `exocomp.system.diagnose` and `exocomp.service.diagnose` can be sent.
  There is no generic message API, so remediation and executor traffic cannot
  cross this boundary.
  """

  alias Exocomp.A2A.Task
  alias Exocomp.Coordinator.A2A.{ClientError, Codec, HTTPTransport}
  alias Exocomp.Coordinator.Registry

  @diagnostic_skills ["exocomp.system.diagnose", "exocomp.service.diagnose"]
  @default_timeout_ms 5_000

  @spec send(String.t(), String.t(), map(), keyword()) ::
          {:ok, Task.t()} | {:error, ClientError.t()}
  def send(node_id, skill_id, params, opts \\ [])
      when is_binary(node_id) and is_binary(skill_id) and is_map(params) do
    operation = :send

    with :ok <- diagnostic_skill(skill_id, operation, node_id),
         {:ok, node} <- registry_node(node_id, operation, opts),
         {:ok, version} <- negotiate_version(node, operation),
         {:ok, body} <- encode_body(skill_id, params, opts, operation, node_id),
         {:ok, response} <- request(node, operation, :post, "/message:send", body, version, opts) do
      decode_success(response, [200, 202], operation, node_id, version)
    end
  end

  @spec get_task(String.t(), String.t(), keyword()) ::
          {:ok, Task.t()} | {:error, ClientError.t()}
  def get_task(node_id, task_id, opts \\ []) when is_binary(node_id) and is_binary(task_id) do
    operation = :get_task

    with {:ok, node} <- registry_node(node_id, operation, opts),
         {:ok, version} <- negotiate_version(node, operation),
         {:ok, response} <-
           request(node, operation, :get, "/tasks/#{path_segment(task_id)}", "", version, opts) do
      decode_success(response, [200], operation, node_id, version)
    end
  end

  @spec cancel(String.t(), String.t(), keyword()) ::
          {:ok, Task.t()} | {:error, ClientError.t()}
  def cancel(node_id, task_id, opts \\ []) when is_binary(node_id) and is_binary(task_id) do
    operation = :cancel

    with {:ok, node} <- registry_node(node_id, operation, opts),
         {:ok, version} <- negotiate_version(node, operation),
         {:ok, response} <-
           request(
             node,
             operation,
             :post,
             "/tasks/#{path_segment(task_id)}:cancel",
             "",
             version,
             opts
           ) do
      decode_success(response, [200], operation, node_id, version)
    end
  end

  defp diagnostic_skill(skill_id, _operation, _node_id) when skill_id in @diagnostic_skills,
    do: :ok

  defp diagnostic_skill(skill_id, operation, node_id) do
    error(:configuration, :diagnostic_skill_required, operation, node_id, details: skill_id)
  end

  defp registry_node(node_id, operation, opts) do
    registry = Keyword.get(opts, :registry, Registry)

    case Registry.get(node_id, registry) do
      {:ok, %{addresses: [address | _]} = node} -> {:ok, Map.put(node, :address, address)}
      {:ok, _node} -> error(:transport, :unreachable, operation, node_id)
      :error -> error(:configuration, :unknown_node, operation, node_id)
    end
  catch
    :exit, reason -> error(:transport, :registry_unavailable, operation, node_id, details: reason)
  end

  defp negotiate_version(node, operation) do
    local = Exocomp.Protocol.version()
    advertised = Map.get(node, :supported_a2a_versions) || Map.get(node, :a2a_versions)

    if is_nil(advertised) or local in List.wrap(advertised) do
      {:ok, local}
    else
      error(:protocol, :unsupported_version, operation, node.id, details: advertised)
    end
  end

  defp encode_body(skill_id, params, opts, operation, node_id) do
    message_id = Keyword.get_lazy(opts, :message_id, &new_id/0)
    context_id = Keyword.get(opts, :context_id)

    skill_id
    |> Codec.encode_diagnostic(params, message_id, context_id)
    |> Jason.encode()
    |> case do
      {:ok, body} -> {:ok, body}
      {:error, reason} -> error(:protocol, :invalid_request, operation, node_id, details: reason)
    end
  end

  defp request(node, operation, method, path, body, version, opts) do
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    transport = Keyword.get(opts, :transport, HTTPTransport)
    transport_opts = Keyword.get(opts, :transport_opts, [])

    request = %{
      method: method,
      path: path,
      headers: [{"accept", "application/json"}, {"a2a-version", version}],
      body: body,
      timeout_ms: timeout_ms,
      node_id: node.id,
      address: node.address,
      hostname: node.hostname,
      port: node.port,
      certificate_identity: node.certificate_identity,
      tls: Keyword.get(opts, :tls, Application.get_env(:exocomp_coordinator, :a2a_tls, []))
    }

    case transport.request(request, transport_opts) do
      {:ok, status, headers, response_body}
      when is_integer(status) and is_list(headers) and is_binary(response_body) ->
        {:ok, {status, normalize_headers(headers), response_body}}

      {:error, :timeout} ->
        error(:transport, :timeout, operation, node.id)

      {:error, reason} ->
        error(:transport, :request_failed, operation, node.id, details: reason)

      other ->
        error(:transport, :malformed_response, operation, node.id, details: other)
    end
  rescue
    exception ->
      error(:transport, :request_failed, operation, node.id,
        details: Exception.message(exception)
      )
  catch
    kind, reason ->
      error(:transport, :request_failed, operation, node.id, details: {kind, reason})
  end

  defp decode_success({status, headers, body}, expected, operation, node_id, version) do
    with :ok <- response_version(headers, version, operation, node_id),
         {:ok, decoded} <- decode_json(body, operation, node_id) do
      if status in expected do
        case Codec.decode_task(decoded) do
          {:ok, task} ->
            {:ok, task}

          {:error, reason} ->
            error(:protocol, :malformed_response, operation, node_id, details: reason)
        end
      else
        protocol_error(decoded, status, operation, node_id)
      end
    end
  end

  defp response_version(headers, expected, operation, node_id) do
    case Map.get(headers, "a2a-version") do
      nil -> :ok
      ^expected -> :ok
      actual -> error(:protocol, :version_mismatch, operation, node_id, details: actual)
    end
  end

  defp decode_json(body, operation, node_id) do
    case Jason.decode(body) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, reason} ->
        error(:protocol, :malformed_response, operation, node_id, details: reason)
    end
  end

  defp protocol_error(%{"error" => error_body}, status, operation, node_id) do
    reason =
      case Map.get(error_body, "code") do
        -32001 -> :task_not_found
        -32002 -> :task_not_cancelable
        -32004 -> :unsupported_operation
        _ -> :remote_error
      end

    error(:protocol, reason, operation, node_id, status: status, details: error_body)
  end

  defp protocol_error(body, status, operation, node_id),
    do: error(:protocol, :unexpected_status, operation, node_id, status: status, details: body)

  defp normalize_headers(headers) do
    Map.new(headers, fn {key, value} ->
      {key |> to_string() |> String.downcase(), to_string(value)}
    end)
  end

  defp path_segment(value), do: URI.encode(value, &URI.char_unreserved?/1)
  defp new_id, do: :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

  defp error(kind, reason, operation, node_id, fields \\ []) do
    {:error,
     %ClientError{
       kind: kind,
       reason: reason,
       operation: operation,
       node_id: node_id,
       status: Keyword.get(fields, :status),
       details: Keyword.get(fields, :details)
     }}
  end
end
