# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.DesiredServiceTest do
  use ExUnit.Case, async: true

  alias Exocomp.DesiredService
  alias Exocomp.DesiredService.SourceExpectation

  @node "node-a"
  @unit "api.service"

  defp manual(opts \\ []), do: SourceExpectation.new(:manual, @node, @unit, opts)
  defp automatic(opts \\ []), do: SourceExpectation.new(:automatic, @node, @unit, opts)

  defp profile(opts) do
    SourceExpectation.new(:cluster_profile, @node, @unit, opts)
  end

  defp resolve(sources), do: DesiredService.resolve_one(sources)

  test "each source resolves to one effective expectation" do
    cases = [
      {manual(), [:manual], :manual_allow_list, nil},
      {automatic(), [:automatic], nil, nil},
      {profile(profile_context: "profile-a"), [:cluster_profile], :shipped_profile, "profile-a"}
    ]

    Enum.each(cases, fn {source, expected_sources, expected_authority, expected_context} ->
      result = resolve([source])

      assert result.node == @node
      assert result.unit == @unit
      assert result.sources == expected_sources
      assert result.required_probes == []
      assert result.expected_state == :running
      assert result.profile_context == expected_context
      assert result.recovery_authority_source == expected_authority
    end)
  end

  test "all source combinations merge with sorted provenance and authority" do
    source_map = %{
      manual: manual(required_probes: ["systemd"]),
      automatic: automatic(required_probes: ["systemd", "health"]),
      cluster_profile: profile(required_probes: ["profile"], profile_context: "profile-a")
    }

    cases = [
      {[:manual], [:manual], ["systemd"], :manual_allow_list, nil},
      {[:automatic], [:automatic], ["health", "systemd"], nil, nil},
      {[:cluster_profile], [:cluster_profile], ["profile"], :shipped_profile, "profile-a"},
      {[:manual, :automatic], [:automatic, :manual], ["health", "systemd"], :manual_allow_list,
       nil},
      {[:automatic, :cluster_profile], [:automatic, :cluster_profile],
       ["health", "profile", "systemd"], :shipped_profile, "profile-a"},
      {[:manual, :cluster_profile], [:cluster_profile, :manual], ["profile", "systemd"],
       :manual_allow_list, "profile-a"},
      {[:manual, :automatic, :cluster_profile], [:automatic, :cluster_profile, :manual],
       ["health", "profile", "systemd"], :manual_allow_list, "profile-a"}
    ]

    Enum.each(cases, fn {
                          source_names,
                          expected_sources,
                          expected_probes,
                          expected_authority,
                          expected_context
                        } ->
      sources = Enum.map(source_names, &Map.fetch!(source_map, &1))
      result = resolve(Enum.reverse(sources))

      assert result.sources == expected_sources
      assert result.required_probes == expected_probes
      assert result.profile_context == expected_context
      assert result.recovery_authority_source == expected_authority
    end)
  end

  test "automatic discovery never grants recovery authority, even with duplicate input" do
    result = resolve([automatic(), automatic(expected_state: :failed)])

    assert result.recovery_authority_source == nil
    assert result.sources == [:automatic]
  end

  test "duplicate services collapse and duplicate probes are removed" do
    duplicate = manual(required_probes: ["health", "systemd", "health"])
    other_unit = SourceExpectation.new(:automatic, @node, "worker.service", probes: ["health"])

    assert [api, worker] = DesiredService.resolve([other_unit, duplicate, duplicate])
    assert api.unit == @unit
    assert api.sources == [:manual]
    assert api.required_probes == ["health", "systemd"]
    assert worker.unit == "worker.service"
  end

  test "output services are sorted by node and unit regardless of input order" do
    sources = [
      SourceExpectation.new(:automatic, "node-b", "z.service", probes: ["z"]),
      SourceExpectation.new(:manual, "node-a", "z.service", probes: ["z"]),
      SourceExpectation.new(:cluster_profile, "node-a", "a.service", probes: ["a"]),
      SourceExpectation.new(:automatic, "node-a", "z.service", probes: ["z"])
    ]

    assert [first, second, third] = DesiredService.resolve(Enum.reverse(sources))

    assert [{first.node, first.unit}, {second.node, second.unit}, {third.node, third.unit}] ==
             [{"node-a", "a.service"}, {"node-a", "z.service"}, {"node-b", "z.service"}]
  end

  test "conflicting expected states use source precedence, independent of input order" do
    sources = [
      automatic(expected_state: :automatic_state),
      profile(expected_state: :profile_state, profile_context: "profile-a"),
      manual(expected_state: :manual_state)
    ]

    assert resolve(sources).expected_state == :manual_state
    assert resolve(Enum.reverse(sources)).expected_state == :manual_state
  end
end
