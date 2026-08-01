# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Collectors.CephTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.Ceph

  @fsid "01234567-89ab-cdef-0123-456789abcdef"

  defp fixture(name) do
    path = Path.expand("../../../../test/fixtures/ceph/#{name}", __DIR__)
    File.read!(path)
  end

  defp state_output(state \\ "active", substate \\ "running", enablement \\ "enabled") do
    """
    UnitFileState=#{enablement}
    LoadState=loaded
    ActiveState=#{state}
    SubState=#{substate}
    """
  end

  defp fixture_runner(listing, overrides \\ %{}) do
    fn
      "systemctl", ["list-units" | _], _opts ->
        {listing, 0}

      "systemctl", ["show", _pager, _property, unit], _opts ->
        {Map.get(overrides, unit, state_output()), 0}

      _command, _args, _opts ->
        {"", 127}
    end
  end

  test "recognizes all traditional daemon kinds and returns systemd state" do
    listing = fixture("traditional.list")

    overrides = %{
      "ceph-osd@12.service" => state_output("failed", "failed", "disabled"),
      "ceph-mds@fs_a.service" => state_output("inactive", "dead", "static")
    }

    observation = Ceph.collect(cmd_runner: fixture_runner(listing, overrides))
    daemons = observation.measurements.daemons.value

    assert observation.measurements.membership.value == :member
    assert Enum.map(daemons, & &1.kind) == [:gateway, :mds, :mgr, :mon, :osd]

    assert %{kind: :mon, id: "alpha", fsid: nil, active_state: "active"} =
             Enum.find(daemons, &(&1.kind == :mon))

    assert %{kind: :osd, id: "12", enablement: "disabled", substate: "failed"} =
             Enum.find(daemons, &(&1.kind == :osd))

    assert %{
             kind: :gateway,
             id: "realm.zone.gateway_a",
             unit: "ceph-radosgw@realm.zone.gateway_a.service"
           } =
             Enum.find(daemons, &(&1.kind == :gateway))
  end

  test "recognizes all cephadm daemon kinds and reports the FSID" do
    listing = fixture("cephadm.list")
    observation = Ceph.collect(cmd_runner: fixture_runner(listing))
    daemons = observation.measurements.daemons.value

    assert length(daemons) == 5
    assert Enum.all?(daemons, &(&1.fsid == @fsid))
    assert Enum.map(daemons, & &1.kind) == [:gateway, :mds, :mgr, :mon, :osd]
    assert Enum.find(daemons, &(&1.kind == :osd)).id == "7"
  end

  test "combines traditional and cephadm units deterministically" do
    observation =
      Ceph.collect(cmd_runner: fixture_runner(fixture("mixed.list")))

    daemons = observation.measurements.daemons.value

    assert length(daemons) == 4

    assert Enum.map(daemons, & &1.unit) == [
             "ceph-#{@fsid}@mgr.node-a.service",
             "ceph-#{@fsid}@osd.7.service",
             "ceph-mon@alpha.service",
             "ceph-osd@12.service"
           ]
  end

  test "an empty successful listing is an explicit non-member result" do
    observation = Ceph.collect(cmd_runner: fixture_runner(fixture("none.list")))

    assert observation.measurements.membership.value == :not_member
    assert observation.measurements.daemons.value == []
    assert observation.measurements.errors.value == []
  end

  test "malformed names are ignored and never become command arguments" do
    test_pid = self()

    runner = fn command, args, opts ->
      send(test_pid, {:command, command, args, opts})
      fixture_runner(fixture("malformed.list")).(command, args, opts)
    end

    observation = Ceph.collect(cmd_runner: runner)
    daemons = observation.measurements.daemons.value

    assert Enum.map(daemons, & &1.unit) == [
             "ceph-#{@fsid}@mon.node-a.service",
             "ceph-mon@alpha.service"
           ]

    assert_receive {:command, "systemctl", ["list-units" | _], _opts}

    units =
      Stream.repeatedly(fn ->
        receive do
          {:command, "systemctl", ["show", _, _, unit], _} -> unit
        after
          0 -> nil
        end
      end)
      |> Enum.take_while(&(&1 != nil))

    for unit <- units do
      refute String.contains?(unit, ";")
      refute String.contains?(unit, "/")
      assert Ceph.parse_unit_name(unit) != :ignore
    end
  end

  test "a list query timeout is bounded and reported" do
    slow_runner = fn _command, _args, _opts ->
      Process.sleep(100)
      {fixture("none.list"), 0}
    end

    observation = Ceph.collect(timeout_ms: 10, cmd_runner: slow_runner)

    assert observation.measurements.membership.error == :timeout
    assert observation.measurements.daemons.error == :timeout
  end

  test "truncated listing output is rejected before parsing" do
    listing = String.duplicate("ceph-mon@alpha.service loaded active running\n", 10)

    observation =
      Ceph.collect(max_output_bytes: 32, cmd_runner: fixture_runner(listing))

    assert observation.measurements.membership.error == :output_limit
    assert observation.measurements.daemons.error == :output_limit
  end

  test "invalid UTF-8 from systemd is rejected without raising" do
    runner = fixture_runner(<<255, 254, 0>>)
    observation = Ceph.collect(cmd_runner: runner)

    assert observation.measurements.membership.error == :malformed
    assert observation.measurements.daemons.error == :malformed
  end

  test "truncated unit state is retained as a bounded per-unit error" do
    unit = "ceph-mon@alpha.service"

    runner =
      fixture_runner("#{unit} loaded active running\n", %{unit => String.duplicate("x", 100)})

    observation = Ceph.collect(max_output_bytes: 64, cmd_runner: runner)

    assert [%{unit: ^unit, error: :output_limit}] = observation.measurements.errors.value
    assert observation.measurements.daemons.value == []
  end

  test "systemctl argv is fixed and has no shell command" do
    test_pid = self()
    listing = "ceph-mon@alpha.service loaded active running\n"

    runner = fn command, args, opts ->
      send(test_pid, {:argv, command, args, opts})
      fixture_runner(listing).(command, args, opts)
    end

    _observation = Ceph.collect(cmd_runner: runner)

    assert_receive {:argv, "systemctl",
                    [
                      "list-units",
                      "--all",
                      "--type=service",
                      "--no-legend",
                      "--no-pager",
                      "--plain",
                      "ceph*.service"
                    ], _}

    assert_receive {:argv, "systemctl",
                    [
                      "show",
                      "--no-pager",
                      "--property=UnitFileState,LoadState,ActiveState,SubState",
                      ^unit
                    ], _}
  end

  test "unit parser rejects shell metacharacters and non-shipped forms" do
    assert Ceph.parse_unit_name("ceph-mon@node;touch.service") == :ignore
    assert Ceph.parse_unit_name("ceph-mon@node/../../x.service") == :ignore
    assert Ceph.parse_unit_name("ceph-#{@fsid}@osd.not-an-id.service") == :ignore
    assert Ceph.parse_unit_name("ceph-#{@fsid}@monitor.node.service") == :ignore
    assert Ceph.parse_unit_name("ceph-mon@node.service.evil") == :ignore
  end
end
