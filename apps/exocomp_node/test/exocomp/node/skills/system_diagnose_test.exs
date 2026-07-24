defmodule Exocomp.Node.Skills.SystemDiagnoseTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.SystemDiagnose

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp fake_observation(source, measurements) do
    %{
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      source: source,
      collector_version: 1,
      duration_us: 100,
      measurements: measurements
    }
  end

  defp fake_cpu do
    fake_observation(Exocomp.Node.Collectors.CPU, %{
      cpu_count: %{value: 4, unit: "cores"},
      cpu_model: %{value: "Test CPU", unit: "string"}
    })
  end

  defp fake_memory do
    fake_observation(Exocomp.Node.Collectors.Memory, %{
      mem_total_bytes: %{value: 8_000_000_000, unit: "bytes"},
      mem_free_bytes: %{value: 2_000_000_000, unit: "bytes"}
    })
  end

  defp fake_disk do
    fake_observation(Exocomp.Node.Collectors.Disk, %{
      root_total_bytes: %{value: 100_000_000_000, unit: "bytes"},
      root_free_bytes: %{value: 50_000_000_000, unit: "bytes"}
    })
  end

  defp fake_uptime do
    fake_observation(Exocomp.Node.Collectors.Uptime, %{
      uptime_seconds: %{value: 12345.6, unit: "seconds"}
    })
  end

  defp install_fake_collectors do
    collectors = %{
      cpu: fn -> fake_cpu() end,
      memory: fn -> fake_memory() end,
      disk: fn -> fake_disk() end,
      uptime: fn -> fake_uptime() end
    }

    Application.put_env(:exocomp_node, :system_diagnose_collectors, collectors)
    on_exit(fn -> Application.delete_env(:exocomp_node, :system_diagnose_collectors) end)
  end

  # ---------------------------------------------------------------------------
  # Test: success path — all four collectors return observations
  # ---------------------------------------------------------------------------

  test "success path returns artifact with all four measurements" do
    install_fake_collectors()

    assert {:ok, %Artifact{} = artifact} = SystemDiagnose.execute(%{}, %{})

    assert [%DataPart{data: data}] = artifact.parts
    assert data["schema_version"] == "1"
    assert data["skill"] == "exocomp.system.diagnose"

    obs = data["observations"]
    assert is_map(obs["cpu"])
    assert is_map(obs["memory"])
    assert is_map(obs["disk"])
    assert is_map(obs["uptime"])
  end

  # ---------------------------------------------------------------------------
  # Test: partial failure — one collector raises an exception
  # ---------------------------------------------------------------------------

  test "partial collector failure returns artifact with structured error for that collector" do
    # The cpu collector raises; others succeed.
    collectors = %{
      cpu: fn -> raise RuntimeError, "cpu failed" end,
      memory: fn -> fake_memory() end,
      disk: fn -> fake_disk() end,
      uptime: fn -> fake_uptime() end
    }

    Application.put_env(:exocomp_node, :system_diagnose_collectors, collectors)
    on_exit(fn -> Application.delete_env(:exocomp_node, :system_diagnose_collectors) end)

    # Partial failures must not crash the caller — the skill returns {:ok, artifact}
    # with a structured error in the "cpu" observation.
    assert {:ok, %Artifact{parts: [%DataPart{data: data}]}} =
             SystemDiagnose.execute(%{}, %{})

    obs = data["observations"]

    # The failed collector is represented as a structured error map.
    assert is_map(obs["cpu"])
    assert Map.has_key?(obs["cpu"], "error")

    # The other collectors succeeded normally.
    assert is_map(obs["memory"])
    assert is_map(obs["disk"])
    assert is_map(obs["uptime"])
    refute Map.has_key?(obs["memory"], "error")
    refute Map.has_key?(obs["disk"], "error")
    refute Map.has_key?(obs["uptime"], "error")
  end

  # ---------------------------------------------------------------------------
  # Test: timeout — collectors hang beyond the configured deadline
  # ---------------------------------------------------------------------------

  test "timeout returns {:error, :timeout}" do
    # Set a very short timeout.
    Application.put_env(:exocomp_node, :system_diagnose_timeout_ms, 50)

    collectors = %{
      cpu: fn -> Process.sleep(5_000) end,
      memory: fn -> Process.sleep(5_000) end,
      disk: fn -> Process.sleep(5_000) end,
      uptime: fn -> Process.sleep(5_000) end
    }

    Application.put_env(:exocomp_node, :system_diagnose_collectors, collectors)

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :system_diagnose_timeout_ms)
      Application.delete_env(:exocomp_node, :system_diagnose_collectors)
    end)

    assert {:error, :timeout} = SystemDiagnose.execute(%{}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: artifact structure
  # ---------------------------------------------------------------------------

  test "returned artifact has a non-empty artifactId" do
    install_fake_collectors()

    assert {:ok, %Artifact{artifactId: id}} = SystemDiagnose.execute(%{}, %{})
    assert is_binary(id) and id != ""
  end

  test "returned artifact has exactly one DataPart" do
    install_fake_collectors()

    assert {:ok, %Artifact{parts: [%DataPart{}]}} = SystemDiagnose.execute(%{}, %{})
  end
end
