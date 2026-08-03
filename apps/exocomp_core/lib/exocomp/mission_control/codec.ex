# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Codec do
  @moduledoc "Shared status-event codec entry points for both protocol peers."

  alias Exocomp.MissionControl.StatusEvent

  @spec encode_status_event(StatusEvent.t()) :: map()
  def encode_status_event(event), do: StatusEvent.encode(event)

  @spec decode_status_event(term(), keyword()) :: {:ok, StatusEvent.t()} | {:error, term()}
  def decode_status_event(raw, opts \\ []), do: StatusEvent.decode(raw, opts)

  @spec encode_status_events([StatusEvent.t()]) :: [map()]
  def encode_status_events(events) when is_list(events),
    do: Enum.map(events, &StatusEvent.encode/1)

  @spec decode_status_events([map()], keyword()) ::
          {:ok, [StatusEvent.t()]} | {:error, term()}
  def decode_status_events(events, opts \\ [])

  def decode_status_events(events, opts) when is_list(events) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case decode_status_event(event, opts) do
        {:ok, event} -> {:cont, {:ok, [event | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, events} -> {:ok, Enum.reverse(events)}
      error -> error
    end
  end

  def decode_status_events(_events, _opts), do: {:error, :invalid_events_list}
end
