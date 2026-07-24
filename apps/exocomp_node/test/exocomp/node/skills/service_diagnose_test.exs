defmodule Exocomp.Node.Skills.ServiceDiagnoseTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.ServiceDiagnose

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp fake_systemd_collector(services) do
    measurements =
      Enum.flat_map(services, fn svc ->
        prefix = svc |> String.replace(".", "_") |> String.replace("-", "_")

        [
          {:"#{prefix}_activestate", %{value: "active", unit: "string"}},
          {:"#{prefix}_substate", %{value: "running", unit: "string"}}
        ]
      end)
      |> Map.new()

    %{
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      source: Exocomp.Node.Collectors.Systemd,
      collector_version: 1,
      duration_us: 200,
      measurements: measurements
    }
  end

  defp install_fake_collector do
    Application.put_env(
      :exocomp_node,
      :service_diagnose_systemd_collector,
      &fake_systemd_collector/1
    )

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :service_diagnose_systemd_collector)
    end)
  end

  defp set_allowed(services) do
    Application.put_env(:exocomp_node, :allowed_services, services)
    on_exit(fn -> Application.delete_env(:exocomp_node, :allowed_services) end)
  end

  # ---------------------------------------------------------------------------
  # Test: success path — valid services, all in allow-list
  # ---------------------------------------------------------------------------

  test "success path returns artifact with service state" do
    set_allowed(["sshd.service", "nginx.service"])
    install_fake_collector()

    params = %{"services" => ["sshd.service"]}
    assert {:ok, %Artifact{} = artifact} = ServiceDiagnose.execute(params, %{})

    assert [%DataPart{data: data}] = artifact.parts
    assert data["schema_version"] == "1"
    assert data["skill"] == "exocomp.service.diagnose"
    assert is_map(data["observations"]["services"])
  end

  # ---------------------------------------------------------------------------
  # Test: empty service list → {:error, :invalid_params}
  # ---------------------------------------------------------------------------

  test "empty service list returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} = ServiceDiagnose.execute(%{"services" => []}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: service not in allowed list → {:error, :invalid_params}
  # ---------------------------------------------------------------------------

  test "service not in allowed list returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} =
             ServiceDiagnose.execute(%{"services" => ["mysql.service"]}, %{})
  end

  test "mix of allowed and disallowed services returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} =
             ServiceDiagnose.execute(%{"services" => ["sshd.service", "mysql.service"]}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: missing params key
  # ---------------------------------------------------------------------------

  test "missing 'services' key in params returns {:error, :invalid_params}" do
    assert {:error, :invalid_params} = ServiceDiagnose.execute(%{}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: artifact structure
  # ---------------------------------------------------------------------------

  test "returned artifact has a non-empty artifactId" do
    set_allowed(["sshd.service"])
    install_fake_collector()

    assert {:ok, %Artifact{artifactId: id}} =
             ServiceDiagnose.execute(%{"services" => ["sshd.service"]}, %{})

    assert is_binary(id) and id != ""
  end

  # ---------------------------------------------------------------------------
  # Test: multiple services all in allow-list
  # ---------------------------------------------------------------------------

  test "multiple services all in allow-list succeed" do
    set_allowed(["sshd.service", "nginx.service"])
    install_fake_collector()

    params = %{"services" => ["sshd.service", "nginx.service"]}
    assert {:ok, _artifact} = ServiceDiagnose.execute(params, %{})
  end
end
