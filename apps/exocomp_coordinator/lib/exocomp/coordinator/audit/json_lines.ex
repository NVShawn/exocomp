defmodule Exocomp.Coordinator.Audit.JSONLines do
  @moduledoc """
  Durable JSON-lines audit sink with one bounded rotation file.
  """

  @behaviour Exocomp.Coordinator.Audit.Sink

  @default_max_bytes 10 * 1_024 * 1_024

  @impl true
  def init(opts) do
    path = Keyword.fetch!(opts, :path)
    max_bytes = Keyword.get(opts, :max_bytes, @default_max_bytes)

    # Audit logs contain node IDs, enrollment patterns, and error codes that
    # should be owner-readable only. Set mode 0600 on every file we open or
    # create. A chmod failure is treated as a sink-init failure so the
    # coordinator can signal audit degradation rather than write to an
    # insecure file.
    with :ok <- validate_max_bytes(max_bytes),
         :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, io} <- File.open(path, [:append, :binary]),
         :ok <- File.chmod(path, 0o600),
         {:ok, stat} <- File.stat(path) do
      {:ok, %{path: path, io: io, bytes: stat.size, max_bytes: max_bytes}}
    end
  end

  @impl true
  def write(state, event) do
    line = [:json.encode(event), ?\n]
    size = IO.iodata_length(line)

    cond do
      size > state.max_bytes ->
        {:error, :event_too_large}

      state.bytes + size > state.max_bytes ->
        with {:ok, rotated} <- rotate(state) do
          append(rotated, line, size)
        end

      true ->
        append(state, line, size)
    end
  end

  @impl true
  def close(%{io: io}) do
    File.close(io)
  end

  def close(_state), do: :ok

  defp append(state, line, size) do
    with :ok <- IO.binwrite(state.io, line),
         :ok <- :file.sync(state.io) do
      {:ok, %{state | bytes: state.bytes + size}}
    end
  end

  defp rotate(state) do
    :ok = File.close(state.io)
    rotated_path = state.path <> ".1"

    with :ok <- remove_if_present(rotated_path),
         :ok <- File.rename(state.path, rotated_path),
         {:ok, io} <- File.open(state.path, [:write, :binary]) do
      # Apply the same 0600 restriction to the freshly-created rotation file.
      # Close the new handle on failure to avoid leaking a file descriptor.
      case File.chmod(state.path, 0o600) do
        :ok ->
          {:ok, %{state | io: io, bytes: 0}}

        error ->
          File.close(io)
          error
      end
    end
  end

  defp remove_if_present(path) do
    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      error -> error
    end
  end

  defp validate_max_bytes(value) when is_integer(value) and value > 0, do: :ok
  defp validate_max_bytes(_value), do: {:error, :invalid_max_bytes}
end
