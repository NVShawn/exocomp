# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.DesiredService.SourceExpectation do
  @moduledoc """
  One typed contribution to an `Exocomp.DesiredService` expectation.

  Use `manual/3`, `automatic/3`, or `cluster_profile/3` through
  `Exocomp.DesiredService` to make the source intent apparent at call sites.
  """

  @enforce_keys [:source, :node, :unit]
  defstruct [
    :source,
    :node,
    :unit,
    required_probes: [],
    expected_state: :running,
    profile_context: nil
  ]

  @type source :: :manual | :automatic | :cluster_profile
  @type t :: %__MODULE__{
          source: source(),
          node: String.t(),
          unit: String.t(),
          required_probes: [atom() | String.t()],
          expected_state: term(),
          profile_context: term() | nil
        }

  @doc "Build a source contribution with the common desired-state fields."
  @spec new(source(), String.t(), String.t(), keyword()) :: t()
  def new(source, node, unit, opts \\ [])

  def new(:profile, node, unit, opts),
    do: new(:cluster_profile, node, unit, opts)

  def new(source, node, unit, opts)
      when source in [:manual, :automatic, :cluster_profile] and
             is_binary(node) and is_binary(unit) and is_list(opts) do
    %__MODULE__{
      source: source,
      node: node,
      unit: unit,
      required_probes: Keyword.get(opts, :required_probes, Keyword.get(opts, :probes, [])),
      expected_state: Keyword.get(opts, :expected_state, :running),
      profile_context: Keyword.get(opts, :profile_context)
    }
  end

  def new(source, _node, _unit, _opts) do
    raise ArgumentError, "invalid desired-service source: #{inspect(source)}"
  end
end
