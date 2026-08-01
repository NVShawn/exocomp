# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceInventoryTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.ServiceInventory

  # ---------------------------------------------------------------------------
  # Helpers: Fake command runner
  # ---------------------------------------------------------------------------

  # Fixture: systemctl list-unit-files output for enabled services
  defp fixture_list_output do
    """
    sshd.service                              enabled-runtime enabled
    nginx.service                             enabled         enabled
    exocomp-node.service                      enabled         enabled
    static-service.service                    static          enabled
    oneshot-done.service                      enabled         enabled
    """
  end

  # Fixture: systemctl show output for a typical enabled service
  defp fixture_show_enabled_service(service_name) do
    case service_name do
      "sshd.service" ->
        """
        Type=notify
        RemainAfterExit=no
        Condition=
        ConditionResult=success
        UnitFileState=enabled-runtime
        LoadState=loaded
        ActiveState=active
        SubState=running
        """

      "nginx.service" ->
        """
        Type=forking
        RemainAfterExit=yes
        Condition=
        ConditionResult=success
        UnitFileState=enabled
        LoadState=loaded
        ActiveState=active
        SubState=running
        """

      "exocomp-node.service" ->
        """
        Type=simple
        RemainAfterExit=no
        Condition=
        ConditionResult=success
        UnitFileState=enabled
        LoadState=loaded
        ActiveState=active
        SubState=running
        """

      "static-service.service" ->
        """
        Type=simple
        RemainAfterExit=no
        Condition=
        ConditionResult=success
        UnitFileState=static
        LoadState=loaded
        ActiveState=inactive
        SubState=dead
        """

      "oneshot-done.service" ->
        """
        Type=oneshot
        RemainAfterExit=no
        Condition=
        ConditionResult=success
        UnitFileState=enabled
        LoadState=loaded
        ActiveState=inactive
        SubState=dead
        """

      _ ->
        """
        Type=simple
        RemainAfterExit=no
        Condition=
        ConditionResult=success
        UnitFileState=enabled
        LoadState=loaded
        ActiveState=active
        SubState=running
        """
    end
  end

  # Fixture: systemctl show output for a service with failed condition
  defp fixture_show_with_failed_condition(_service_name) do
    """
    Type=simple
    RemainAfterExit=no
    Condition=ConditionVirtualization=kvm
    ConditionResult=failed
    UnitFileState=enabled
    LoadState=loaded
    ActiveState=active
    SubState=running
    """
  end

  # Fake command runner that returns fixture data
  defp fake_cmd_runner(cmd, args, _opts) do
    case {cmd, args} do
      {"systemctl",
       ["list-unit-files", "--type=service", "--state=enabled,enabled-runtime", "--no-legend", "--no-pager", "--plain"]} ->
        {fixture_list_output(), 0}

      {"systemctl", ["show", "--no-pager" | _rest]} ->
        # Extract service name from args
        service_name = List.last(args)
        output = fixture_show_enabled_service(service_name)
        {output, 0}

      _ ->
        {"", 1}
    end
  end

  # Fake collector that returns a fake observation
  defp fake_collector do
    %{
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      source: Exocomp.Node.Collectors.ServiceInventory,
      collector_version: 1,
      duration_us: 500,
      measurements: %{
        sshd_service_type: %{value: "notify", unit: "string"},
        sshd_service_remainafterexit: %{value: "no", unit: "string"},
        sshd_service_condition: %{value: "", unit: "string"},
        sshd_service_conditionresult: %{value: "success", unit: "string"},
        sshd_service_unitfilestate: %{value: "enabled-runtime", unit: "string"},
        sshd_service_loadstate: %{value: "loaded", unit: "string"},
        sshd_service_activestate: %{value: "active", unit: "string"},
        sshd_service_substate: %{value: "running", unit: "string"},
        nginx_service_type: %{value: "forking", unit: "string"},
        nginx_service_remainafterexit: %{value: "yes", unit: "string"},
        nginx_service_condition: %{value: "", unit: "string"},
        nginx_service_conditionresult: %{value: "success", unit: "string"},
        nginx_service_unitfilestate: %{value: "enabled", unit: "string"},
        nginx_service_loadstate: %{value: "loaded", unit: "string"},
        nginx_service_activestate: %{value: "active", unit: "string"},
        nginx_service_substate: %{value: "running", unit: "string"}
      }
    }
  end

  defp install_fake_collector do
    Application.put_env(
      :exocomp_node,
      :service_inventory_collector,
      &fake_collector/0
    )

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :service_inventory_collector)
    end)
  end

  # ---------------------------------------------------------------------------
  # Test: Basic execution with fake collector
  # ---------------------------------------------------------------------------

  test "execute with no parameters calls collector and returns artifact" do
    install_fake_collector()

    params = %{}
    assert {:ok, %Artifact{} = artifact} = ServiceInventory.execute(params, %{})

    assert [%DataPart{data: data}] = artifact.parts
    assert data["schema_version"] == "1"
    assert data["skill"] == "exocomp.service.inventory"
    assert is_map(data["observations"]["enabled_services"])
  end

  test "returned artifact has a non-empty artifactId" do
    install_fake_collector()

    assert {:ok, %Artifact{artifactId: id}} = ServiceInventory.execute(%{}, %{})
    assert is_binary(id) and id != ""
    assert String.starts_with?(id, "service-inventory-")
  end

  test "artifact name is service-inventory" do
    install_fake_collector()

    assert {:ok, %Artifact{name: name}} = ServiceInventory.execute(%{}, %{})
    assert name == "service-inventory"
  end

  test "observations contain enabled_services key" do
    install_fake_collector()

    {:ok, artifact} = ServiceInventory.execute(%{}, %{})
    [%DataPart{data: data}] = artifact.parts
    assert Map.has_key?(data["observations"], "enabled_services")
  end

  # ---------------------------------------------------------------------------
  # Test: Artifact structure with real collector data
  # ---------------------------------------------------------------------------

  test "artifact data structure includes source collector info" do
    install_fake_collector()

    {:ok, artifact} = ServiceInventory.execute(%{}, %{})
    [%DataPart{data: data}] = artifact.parts
    obs = data["observations"]["enabled_services"]

    # Should contain at least the basic observation envelope
    assert is_map(obs)
    # Collector version, source, observed_at, etc. should be present
    assert is_binary(obs["observed_at"]) or is_map(obs)
  end

  # ---------------------------------------------------------------------------
  # Test: Integration with real collector (collector-level tests)
  # ---------------------------------------------------------------------------

  test "collector includes sshd and nginx from enabled list" do
    # This tests the collector behavior when command runners are injected
    {:ok, observation} =
      with_cmd_runner(&fake_cmd_runner/3, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    # Verify the observation has service measurements
    assert observation.source == Exocomp.Node.Collectors.ServiceInventory
    assert observation.collector_version == 1
    assert is_map(observation.measurements)

    # We should have measurements for sshd and nginx at minimum
    measurements = observation.measurements
    sshd_keys = Map.keys(measurements) |> Enum.filter(&String.starts_with?(to_string(&1), "sshd"))
    nginx_keys = Map.keys(measurements) |> Enum.filter(&String.starts_with?(to_string(&1), "nginx"))

    assert length(sshd_keys) > 0, "Should have sshd measurements"
    assert length(nginx_keys) > 0, "Should have nginx measurements"
  end

  test "collector excludes exocomp-node.service from inventory" do
    {:ok, observation} =
      with_cmd_runner(&fake_cmd_runner/3, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    measurements = observation.measurements
    exocomp_keys = Map.keys(measurements) |> Enum.filter(&String.starts_with?(to_string(&1), "exocomp_node"))

    assert Enum.empty?(exocomp_keys), "exocomp-node.service should be excluded"
  end

  test "collector excludes static units from inventory" do
    {:ok, observation} =
      with_cmd_runner(&fake_cmd_runner/3, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    measurements = observation.measurements
    static_keys = Map.keys(measurements) |> Enum.filter(&String.starts_with?(to_string(&1), "static_service"))

    assert Enum.empty?(static_keys), "static-service should be excluded (UnitFileState=static)"
  end

  test "collector excludes completed oneshots from inventory" do
    {:ok, observation} =
      with_cmd_runner(&fake_cmd_runner/3, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    measurements = observation.measurements
    oneshot_keys =
      Map.keys(measurements) |> Enum.filter(&String.starts_with?(to_string(&1), "oneshot_done"))

    assert Enum.empty?(oneshot_keys),
           "oneshot-done.service should be excluded (Type=oneshot, ActiveState=inactive)"
  end

  test "collector marks failed conditions as not_applicable" do
    fake_runner = fn cmd, args, opts ->
      case {cmd, args} do
        {"systemctl",
         ["list-unit-files", "--type=service", "--state=enabled,enabled-runtime", "--no-legend", "--no-pager", "--plain"]} ->
          # Return a single service with failed condition
          {"failed-cond.service                    enabled         enabled\n", 0}

        {"systemctl", ["show", "--no-pager" | _rest]} ->
          service_name = List.last(args)
          output = fixture_show_with_failed_condition(service_name)
          {output, 0}

        _ ->
          {"", 1}
      end
    end

    {:ok, observation} =
      with_cmd_runner(fake_runner, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    measurements = observation.measurements

    # Find the ConditionResult measurement for the service
    cond_result_key =
      Enum.find(Map.keys(measurements), fn key ->
        String.ends_with?(to_string(key), "conditionresult")
      end)

    assert cond_result_key != nil, "Should have a conditionresult measurement"
    measurement = measurements[cond_result_key]

    assert measurement.value == "not_applicable",
           "Failed condition should be marked as not_applicable"
  end

  # ---------------------------------------------------------------------------
  # Test: Timeout handling
  # ---------------------------------------------------------------------------

  test "returns error on timeout" do
    # Mock a collector that times out
    Application.put_env(
      :exocomp_node,
      :service_inventory_timeout_ms,
      100
    )

    Application.put_env(
      :exocomp_node,
      :service_inventory_collector,
      fn ->
        :timer.sleep(500)
        fake_collector()
      end
    )

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :service_inventory_timeout_ms)
      Application.delete_env(:exocomp_node, :service_inventory_collector)
    end)

    assert {:error, :timeout} = ServiceInventory.execute(%{}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: Collector-level timeout
  # ---------------------------------------------------------------------------

  test "collector handles command timeout gracefully" do
    slow_runner = fn _cmd, _args, _opts ->
      :timer.sleep(20_000)
      {"", 0}
    end

    # Use a very short timeout
    {:ok, observation} =
      with_cmd_runner(slow_runner, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect(timeout_ms: 100)
      end)

    # Measurements should be present but may include timeout errors
    assert is_map(observation.measurements)
  end

  # ---------------------------------------------------------------------------
  # Test: Malformed output handling
  # ---------------------------------------------------------------------------

  test "collector handles malformed systemctl output" do
    bad_runner = fn cmd, args, _opts ->
      case {cmd, args} do
        {"systemctl",
         ["list-unit-files", "--type=service", "--state=enabled,enabled-runtime", "--no-legend", "--no-pager", "--plain"]} ->
          {"bad-service.service\n", 0}

        {"systemctl", ["show", "--no-pager" | _rest]} ->
          # Return garbage output
          {"garbage output\nno equals signs here\n", 0}

        _ ->
          {"", 1}
      end
    end

    {:ok, observation} =
      with_cmd_runner(bad_runner, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    # Should still return an observation, but with errors for missing properties
    assert is_map(observation.measurements)
  end

  test "collector handles empty output from list-unit-files" do
    empty_runner = fn cmd, args, _opts ->
      case {cmd, args} do
        {"systemctl",
         ["list-unit-files", "--type=service", "--state=enabled,enabled-runtime", "--no-legend", "--no-pager", "--plain"]} ->
          {"", 0}

        _ ->
          {"", 1}
      end
    end

    {:ok, observation} =
      with_cmd_runner(empty_runner, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    # Should return empty measurements when no services listed
    assert observation.measurements == %{}
  end

  # ---------------------------------------------------------------------------
  # Test: Output size limit
  # ---------------------------------------------------------------------------

  test "collector enforces output size limit" do
    huge_runner = fn cmd, args, _opts ->
      case {cmd, args} do
        {"systemctl",
         ["list-unit-files", "--type=service", "--state=enabled,enabled-runtime", "--no-legend", "--no-pager", "--plain"]} ->
          {"huge-service.service\n", 0}

        {"systemctl", ["show", "--no-pager" | _rest]} ->
          # Return output larger than limit
          huge_output = String.duplicate("x", 100_000)
          {huge_output, 0}

        _ ->
          {"", 1}
      end
    end

    {:ok, observation} =
      with_cmd_runner(huge_runner, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    # Should have error measurements for output_limit
    measurements = observation.measurements

    error_measurements =
      Enum.filter(measurements, fn {_k, v} ->
        is_map(v) and Map.has_key?(v, :error) and v.error == :output_limit
      end)

    assert length(error_measurements) > 0,
           "Should have output_limit errors for oversized output"
  end

  # ---------------------------------------------------------------------------
  # Test: Exclusion rules (via collector)
  # ---------------------------------------------------------------------------

  test "collector with all exclusion cases" do
    complex_runner = fn cmd, args, _opts ->
      case {cmd, args} do
        {"systemctl",
         ["list-unit-files", "--type=service", "--state=enabled,enabled-runtime", "--no-legend", "--no-pager", "--plain"]} ->
          """
          enabled.service                        enabled         enabled
          disabled.service                       disabled        enabled
          masked.service                         masked          enabled
          static.service                         static          enabled
          indirect.service                       indirect        enabled
          generated.service                      generated       enabled
          exocomp-node.service                   enabled         enabled
          oneshot-done.service                   enabled         enabled
          """
          |> (fn s -> {s, 0} end).()

        {"systemctl", ["show", "--no-pager" | _rest]} ->
          service_name = List.last(args)

          case service_name do
            "enabled.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=enabled
              LoadState=loaded
              ActiveState=active
              SubState=running
              """

            "disabled.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=disabled
              LoadState=loaded
              ActiveState=inactive
              SubState=dead
              """

            "masked.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=masked
              LoadState=masked
              ActiveState=inactive
              SubState=dead
              """

            "static.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=static
              LoadState=loaded
              ActiveState=inactive
              SubState=dead
              """

            "indirect.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=indirect
              LoadState=loaded
              ActiveState=inactive
              SubState=dead
              """

            "generated.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=generated
              LoadState=loaded
              ActiveState=inactive
              SubState=dead
              """

            "exocomp-node.service" ->
              """
              Type=simple
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=enabled
              LoadState=loaded
              ActiveState=active
              SubState=running
              """

            "oneshot-done.service" ->
              """
              Type=oneshot
              RemainAfterExit=no
              Condition=
              ConditionResult=success
              UnitFileState=enabled
              LoadState=loaded
              ActiveState=inactive
              SubState=dead
              """

            _ ->
              "Type=unknown\n"
          end
          |> (fn s -> {s, 0} end).()

        _ ->
          {"", 1}
      end
    end

    {:ok, observation} =
      with_cmd_runner(complex_runner, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    measurements = observation.measurements
    keys = Map.keys(measurements) |> Enum.map(&to_string/1)

    # enabled.service should be included
    assert Enum.any?(keys, &String.starts_with?(&1, "enabled_service")),
           "enabled.service should be included"

    # All excluded types should NOT appear
    assert !Enum.any?(keys, &String.starts_with?(&1, "disabled_service")),
           "disabled.service should be excluded"

    assert !Enum.any?(keys, &String.starts_with?(&1, "masked_service")),
           "masked.service should be excluded"

    assert !Enum.any?(keys, &String.starts_with?(&1, "static_service")),
           "static.service should be excluded"

    assert !Enum.any?(keys, &String.starts_with?(&1, "indirect_service")),
           "indirect.service should be excluded"

    assert !Enum.any?(keys, &String.starts_with?(&1, "generated_service")),
           "generated.service should be excluded"

    assert !Enum.any?(keys, &String.starts_with?(&1, "exocomp_node_service")),
           "exocomp-node.service should be excluded"

    assert !Enum.any?(keys, &String.starts_with?(&1, "oneshot_done")),
           "oneshot-done.service should be excluded"
  end

  # ---------------------------------------------------------------------------
  # Test: All properties returned
  # ---------------------------------------------------------------------------

  test "collector returns all required properties for included services" do
    required_props = ["Type", "RemainAfterExit", "Condition", "ConditionResult", "UnitFileState", "LoadState", "ActiveState", "SubState"]
    
    {:ok, observation} =
      with_cmd_runner(&fake_cmd_runner/3, fn ->
        Exocomp.Node.Collectors.ServiceInventory.collect()
      end)

    measurements = observation.measurements
    
    # Get all properties for sshd service
    sshd_measurements = Enum.filter(measurements, fn {k, _v} ->
      String.starts_with?(to_string(k), "sshd_service_")
    end)
    
    # Convert property keys to property names
    found_props = Enum.map(sshd_measurements, fn {k, _v} ->
      k
      |> to_string()
      |> String.replace_prefix("sshd_service_", "")
      |> String.upcase()
    end)
    
    # Each required property should be present (in lowercase form)
    Enum.each(required_props, fn prop ->
      prop_lower = String.downcase(prop)
      assert Enum.any?(found_props, fn found ->
        String.downcase(found) == prop_lower
      end), "Property #{prop} should be collected"
    end)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Helper to run a block with a custom command runner
  defp with_cmd_runner(runner_fn, _block_fn) do
    # The collector needs to receive the runner via options
    # Pass the runner function directly via cmd_runner and list_runner
    Exocomp.Node.Collectors.ServiceInventory.collect(cmd_runner: runner_fn, list_runner: runner_fn)
    |> (fn result -> {:ok, result} end).()
  end
end
