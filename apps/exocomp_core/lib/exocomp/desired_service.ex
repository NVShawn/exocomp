# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.DesiredService do
  @moduledoc """
  A deterministic desired-state expectation for one node and systemd unit.

  `resolve/1` is the boundary between the three desired-state sources and
  consumers that need one effective expectation. It performs no I/O and does
  not inspect the current state of a node. Every contribution is explicit
  about its source, while the effective result keeps the complete source set
  and the merged probe set for auditability.

  Manual contributions represent the operator's service allow-list. Automatic
  contributions represent discovery only and can never authorize recovery.
  Cluster-profile contributions represent a shipped profile and may provide
  profile context and profile recovery authority.

  When sources disagree about expected state, the explicit source precedence is
  manual, cluster profile, then automatic. This keeps a local operator
  allow-list authoritative over a profile, and a profile authoritative over an
  observation. Ties within one source are resolved by the canonical term
  ordering of the state, so input order never changes the result.
  """

  alias Exocomp.DesiredService.SourceExpectation

  @enforce_keys [
    :node,
    :unit,
    :sources,
    :required_probes,
    :expected_state,
    :profile_context,
    :recovery_authority_source
  ]
  defstruct [
    :node,
    :unit,
    :sources,
    :required_probes,
    :expected_state,
    :profile_context,
    :recovery_authority_source
  ]

  @typedoc "A source contributing a desired service expectation."
  @type source :: :manual | :automatic | :cluster_profile

  @typedoc "A probe identifier required before the expectation is actionable."
  @type probe :: atom() | String.t()

  @typedoc "The desired state of the systemd unit."
  @type expected_state :: term()

  @typedoc "Opaque context retained from a cluster profile."
  @type profile_context :: term() | nil

  @typedoc "The source that can authorize recovery for the effective service."
  @type recovery_authority_source :: :manual_allow_list | :shipped_profile | nil

  @type t :: %__MODULE__{
          node: String.t(),
          unit: String.t(),
          sources: [source()],
          required_probes: [probe()],
          expected_state: expected_state(),
          profile_context: profile_context(),
          recovery_authority_source: recovery_authority_source()
        }

  @source_precedence [:manual, :cluster_profile, :automatic]
  @authority_precedence [:manual_allow_list, :shipped_profile]

  @doc "Build a manual allow-list contribution."
  @spec manual(String.t(), String.t(), keyword()) :: SourceExpectation.t()
  def manual(node, unit, opts \\ []),
    do: SourceExpectation.new(:manual, node, unit, opts)

  @doc "Build an automatic discovery contribution."
  @spec automatic(String.t(), String.t(), keyword()) :: SourceExpectation.t()
  def automatic(node, unit, opts \\ []),
    do: SourceExpectation.new(:automatic, node, unit, opts)

  @doc "Build a shipped cluster-profile contribution."
  @spec cluster_profile(String.t(), String.t(), keyword()) :: SourceExpectation.t()
  def cluster_profile(node, unit, opts \\ []),
    do: SourceExpectation.new(:cluster_profile, node, unit, opts)

  @doc "Alias for `cluster_profile/3` for callers using the shorter source name."
  @spec profile(String.t(), String.t(), keyword()) :: SourceExpectation.t()
  def profile(node, unit, opts \\ []), do: cluster_profile(node, unit, opts)

  @doc """
  Resolve source contributions into one effective expectation per node/unit.

  The returned list is sorted by `{node, unit}`. Within each result, sources
  and required probes are unique and sorted. Duplicate contributions for the
  same node/unit therefore cannot produce duplicate effective services.
  """
  @spec resolve([SourceExpectation.t()]) :: [t()]
  def resolve(contributions) when is_list(contributions) do
    contributions
    |> Enum.group_by(&{&1.node, &1.unit})
    |> Enum.sort_by(fn {{node, unit}, _entries} -> {node, unit} end)
    |> Enum.map(fn {{node, unit}, entries} -> merge_group(node, unit, entries) end)
  end

  @doc """
  Resolve contributions expected to describe one node/unit.

  This convenience function is useful to callers that already partitioned
  their input. It raises `ArgumentError` for an empty or multi-service input,
  preventing accidental selection of an arbitrary result.
  """
  @spec resolve_one([SourceExpectation.t()]) :: t()
  def resolve_one(contributions) when is_list(contributions) do
    case resolve(contributions) do
      [result] -> result
      [] -> raise ArgumentError, "expected at least one desired-service contribution"
      _results -> raise ArgumentError, "expected contributions for one node and unit"
    end
  end

  defp merge_group(node, unit, entries) do
    %__MODULE__{
      node: node,
      unit: unit,
      sources: entries |> Enum.map(& &1.source) |> unique_sorted(),
      required_probes: entries |> Enum.flat_map(& &1.required_probes) |> unique_sorted(),
      expected_state: effective_expected_state(entries),
      profile_context: effective_profile_context(entries),
      recovery_authority_source: effective_authority(entries)
    }
  end

  defp effective_expected_state(entries) do
    entries
    |> Enum.sort_by(fn entry ->
      {source_rank(entry.source), canonical_term(entry.expected_state)}
    end)
    |> List.first()
    |> Map.fetch!(:expected_state)
  end

  defp effective_profile_context(entries) do
    entries
    |> Enum.filter(&(&1.source == :cluster_profile))
    |> Enum.map(& &1.profile_context)
    |> Enum.reject(&is_nil/1)
    |> unique_sorted()
    |> List.first()
  end

  defp effective_authority(entries) do
    entries
    |> Enum.map(&authority_for/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.find(&(&1 == :manual_allow_list))
    |> case do
      nil ->
        Enum.find(@authority_precedence, &authority_present?(&1, entries))

      authority ->
        authority
    end
  end

  defp authority_present?(authority, entries) do
    Enum.any?(entries, &(authority_for(&1) == authority))
  end

  # Authority is derived from the source rather than copied from untrusted
  # contribution data. In particular, automatic discovery always returns nil.
  defp authority_for(%SourceExpectation{source: :manual}), do: :manual_allow_list
  defp authority_for(%SourceExpectation{source: :cluster_profile}), do: :shipped_profile
  defp authority_for(%SourceExpectation{source: :automatic}), do: nil

  defp source_rank(source), do: Enum.find_index(@source_precedence, &(&1 == source))

  defp unique_sorted(values) do
    values
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp canonical_term(term), do: :erlang.term_to_binary(term)
end
