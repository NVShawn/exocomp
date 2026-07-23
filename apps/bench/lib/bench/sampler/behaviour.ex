defmodule Bench.Sampler.Behaviour do
  @moduledoc """
  Behaviour that all `Bench.Sampler` implementations must satisfy.

  A sampler is started before a workload begins and stopped after the
  workload completes.  During its active window it emits `Bench.Sample`
  structs at a configured interval, writing them to the output stream.

  Built-in implementations:

  - `Bench.Sampler.Beam`  – BEAM scheduler, memory, and process metrics
    (added in EXOCOMP-55).
  - `Bench.Sampler.Host`  – OS CPU, RSS/PSS, file descriptors, and I/O
    (added in EXOCOMP-56).
  """

  alias Bench.Sample

  @doc """
  Called once before sampling begins.  Returns an opaque state term that is
  threaded through subsequent callbacks.
  """
  @callback init(opts :: keyword()) :: {:ok, state :: term()} | {:error, reason :: term()}

  @doc """
  Collects a single sample and returns it along with the updated state.
  """
  @callback collect(state :: term()) ::
              {:ok, Sample.t(), new_state :: term()} | {:error, reason :: term()}

  @doc """
  Called once after sampling ends.  Should release any OS resources acquired
  during `init/1`.
  """
  @callback terminate(state :: term()) :: :ok
end
