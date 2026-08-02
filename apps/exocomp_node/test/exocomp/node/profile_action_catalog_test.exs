# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.ProfileActionCatalogTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.{ExecutorLock, ProfileActionCatalog}
  alias Exocomp.Node.Skills.ProfileAction

  @request %{
    profile_id: "ceph",
    profile_version: 1,
    action_id: "restart_failed_daemon",
    target_unit: "ceph-osd@42.service"
  }

  @profile_action_params %{
    "profile_id" => "ceph",
    "profile_version" => 1,
    "action_id" => "restart_failed_daemon",
    "target_unit" => "ceph-osd@42.service"
  }

  test "encodes the exact five-field helper wire request" do
    assert {:ok, line} = ProfileActionCatalog.request_line(@request)

    assert line == "1\tceph\t1\trestart_failed_daemon\tceph-osd@42.service\n"
    assert byte_size(line) == 51
  end

  test "node catalog owns the installed helper path and sends wire bytes on stdin" do
    parent = self()
    lock = start_lock()

    runner = fn path, argv, opts ->
      send(parent, {:helper_call, path, argv, opts[:input]})
      {:ok, "ok\n", 0}
    end

    assert {:ok, %{status: "accepted", target_unit: "ceph-osd@42.service"}} =
             ProfileActionCatalog.execute(@request, lock_server: lock, runner: runner)

    assert_receive {:helper_call, "/usr/bin/sudo",
                    ["/opt/exocomp/node/bin/profile-action-helper"], wire}

    assert wire == "1\tceph\t1\trestart_failed_daemon\tceph-osd@42.service\n"
  end

  test "rejects unsupported profiles and malformed target units before execution" do
    runner = fn _path, _argv, _opts -> flunk("helper must not be called") end
    lock = start_lock()

    assert {:error, :unsupported_profile_action} =
             ProfileActionCatalog.execute(%{@request | profile_id: "local"},
               lock_server: lock,
               runner: runner
             )

    assert {:error, :invalid_target_unit} =
             ProfileActionCatalog.request_line(%{
               @request
               | target_unit: "ceph-osd@$(id).service"
             })
  end

  test "serializes one attempt per target" do
    parent = self()
    lock = start_lock()

    runner = fn _path, _argv, _opts ->
      send(parent, :entered)

      receive do
        :release -> {:ok, "ok", 0}
      end
    end

    first =
      Task.async(fn ->
        ProfileActionCatalog.execute(@request, lock_server: lock, runner: runner)
      end)

    assert_receive :entered

    assert {:error, :concurrent_execution} =
             ProfileActionCatalog.execute(@request,
               lock_server: lock,
               runner: fn _, _, _ -> {:ok, "bad", 0} end
             )

    send(first.pid, :release)
    assert {:ok, _} = Task.await(first)
  end

  test "A2A profile action delegates only the typed catalog request" do
    parent = self()
    lock = start_lock()
    previous_runner = Application.get_env(:exocomp_node, :profile_action_runner)
    previous_lock = Application.get_env(:exocomp_node, :profile_action_lock_server)

    Application.put_env(:exocomp_node, :profile_action_runner, fn path, argv, opts ->
      send(parent, {:a2a_helper_call, path, argv, opts[:input]})
      {:ok, "ok", 0}
    end)

    Application.put_env(:exocomp_node, :profile_action_lock_server, lock)

    on_exit(fn ->
      if previous_runner do
        Application.put_env(:exocomp_node, :profile_action_runner, previous_runner)
      else
        Application.delete_env(:exocomp_node, :profile_action_runner)
      end

      if previous_lock do
        Application.put_env(:exocomp_node, :profile_action_lock_server, previous_lock)
      else
        Application.delete_env(:exocomp_node, :profile_action_lock_server)
      end
    end)

    assert {:ok,
            %Artifact{
              name: "profile-action",
              parts: [%DataPart{data: %{"action_id" => "restart_failed_daemon"}}]
            }} = ProfileAction.execute(@profile_action_params, %{correlation_id: "corr-1"})

    assert_receive {:a2a_helper_call, "/usr/bin/sudo",
                    ["/opt/exocomp/node/bin/profile-action-helper"], wire}

    assert wire == "1\tceph\t1\trestart_failed_daemon\tceph-osd@42.service\n"

    assert {:error, :invalid_params} =
             ProfileAction.execute(Map.put(@profile_action_params, "unexpected", true), %{})
  end

  defp start_lock do
    name = String.to_atom("profile_action_lock_#{System.unique_integer([:positive])}")
    start_supervised!({ExecutorLock, name: name})
    name
  end
end
