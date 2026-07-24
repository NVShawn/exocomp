defmodule Exocomp.Coordinator.PKI.State do
  @moduledoc """
  Publishes the coordinator's validated, non-secret PKI runtime metadata.

  This process is started only after `Exocomp.Coordinator.PKI.Bootstrap`
  validates the complete online state and offline root backup. It retains
  paths and the public root fingerprint, never key material or root-key
  protection input.
  """

  use GenServer

  @type status :: %{
          healthy: true,
          online_state: Path.t(),
          offline_backup: Path.t(),
          root_fingerprint: String.t()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec status(GenServer.server()) :: status()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @impl true
  def init(opts) do
    metadata = Keyword.fetch!(opts, :metadata)

    state =
      metadata
      |> Map.take([:online_state, :offline_backup, :root_fingerprint])
      |> Map.put(:healthy, true)

    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state, state}
end
