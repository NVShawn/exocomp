# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.AuditLog do
  @moduledoc """
  Synchronous durable JSON-lines sink for recovery state transitions.

  Every append is flushed before it returns. Recovery therefore fails closed
  before execution when the audit boundary is unavailable.
  """

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec append(Exocomp.Recovery.AuditEvent.t(), GenServer.server()) ::
          :ok | {:error, term()}
  def append(event, server \\ __MODULE__), do: GenServer.call(server, {:append, event})

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :path, Application.fetch_env!(:exocomp_node, :recovery_audit_path))
    File.mkdir_p!(Path.dirname(path))

    case :file.open(String.to_charlist(path), [:append, :binary, :raw]) do
      {:ok, io} -> {:ok, %{io: io}}
      {:error, reason} -> {:stop, {:audit_unavailable, reason}}
    end
  end

  @impl true
  def handle_call({:append, event}, _from, state) do
    result =
      with {:ok, json} <- Jason.encode(json_safe(event)),
           :ok <- :file.write(state.io, [json, "\n"]),
           :ok <- :file.sync(state.io) do
        :ok
      end

    {:reply, result, state}
  rescue
    error -> {:reply, {:error, {:encode_failed, Exception.message(error)}}, state}
  end

  @impl true
  def terminate(_reason, state), do: :file.close(state.io)

  defp json_safe(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp json_safe(%_{} = struct), do: struct |> Map.from_struct() |> json_safe()

  defp json_safe(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), json_safe(value)} end)
  end

  defp json_safe(list) when is_list(list), do: Enum.map(list, &json_safe/1)
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value), do: value
end
