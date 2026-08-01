# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceObserveTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.ServiceObserve

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

  defp fake_http_prober(url, _timeout_ms, _max_response_bytes) do
    cond do
      String.contains?(url, "http://127.0.0.1") or String.contains?(url, "localhost") ->
        {:ok, 200, 45, 1024}

      true ->
        {:error, "non-loopback URL"}
    end
  end

  defp install_fake_collectors do
    Application.put_env(
      :exocomp_node,
      :service_observe_systemd_collector,
      &fake_systemd_collector/1
    )

    Application.put_env(
      :exocomp_node,
      :service_observe_http_prober,
      &fake_http_prober/3
    )

    on_exit(fn ->
      Application.delete_env(:exocomp_node, :service_observe_systemd_collector)
      Application.delete_env(:exocomp_node, :service_observe_http_prober)
    end)
  end

  defp set_allowed(services) do
    Application.put_env(:exocomp_node, :allowed_services, services)
    on_exit(fn -> Application.delete_env(:exocomp_node, :allowed_services) end)
  end

  # ---------------------------------------------------------------------------
  # Test: success path — valid services, no probes
  # ---------------------------------------------------------------------------

  test "success path returns artifact with service state" do
    set_allowed(["sshd.service", "nginx.service"])
    install_fake_collectors()

    params = %{"services" => ["sshd.service"]}
    assert {:ok, %Artifact{} = artifact} = ServiceObserve.execute(params, %{})

    assert [%DataPart{data: data}] = artifact.parts
    assert data["schema_version"] == "1"
    assert data["skill"] == "exocomp.service.observe"
    assert is_map(data["systemd"])
    assert is_list(data["probes"])
    assert data["probes"] == []
  end

  # ---------------------------------------------------------------------------
  # Test: success path with HTTP probes
  # ---------------------------------------------------------------------------

  test "success path with loopback HTTP probes" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    params = %{
      "services" => ["sshd.service"],
      "probes" => [
        %{"url" => "http://127.0.0.1:8080/health"}
      ]
    }

    assert {:ok, %Artifact{} = artifact} = ServiceObserve.execute(params, %{})
    assert [%DataPart{data: data}] = artifact.parts
    assert length(data["probes"]) == 1

    [probe] = data["probes"]
    assert probe["status"] == 200
    assert is_integer(probe["response_time_ms"])
    assert is_integer(probe["body_size"])
  end

  # ---------------------------------------------------------------------------
  # Test: localhost HTTP probe
  # ---------------------------------------------------------------------------

  test "localhost probe is allowed" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    params = %{
      "services" => ["sshd.service"],
      "probes" => [
        %{"url" => "http://localhost:9000/status"}
      ]
    }

    assert {:ok, _artifact} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: IPv6 loopback probe
  # ---------------------------------------------------------------------------

  test "IPv6 loopback probe is allowed" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    params = %{
      "services" => ["sshd.service"],
      "probes" => [
        %{"url" => "http://[::1]:8000/health"}
      ]
    }

    assert {:ok, _artifact} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: rejection of non-loopback URLs
  # ---------------------------------------------------------------------------

  test "non-loopback URL is rejected" do
    set_allowed(["sshd.service"])

    params = %{
      "services" => ["sshd.service"],
      "probes" => [
        %{"url" => "http://192.168.1.1:8080/health"}
      ]
    }

    assert {:error, :invalid_params} = ServiceObserve.execute(params, %{})
  end

  test "external HTTPS URL is rejected" do
    set_allowed(["sshd.service"])

    params = %{
      "services" => ["sshd.service"],
      "probes" => [
        %{"url" => "https://example.com/health"}
      ]
    }

    assert {:error, :invalid_params} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: empty service list → {:error, :invalid_params}
  # ---------------------------------------------------------------------------

  test "empty service list returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} = ServiceObserve.execute(%{"services" => []}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: service not in allowed list → {:error, :invalid_params}
  # ---------------------------------------------------------------------------

  test "service not in allowed list returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} =
             ServiceObserve.execute(%{"services" => ["mysql.service"]}, %{})
  end

  test "mix of allowed and disallowed services returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} =
             ServiceObserve.execute(%{"services" => ["sshd.service", "mysql.service"]}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: missing services key
  # ---------------------------------------------------------------------------

  test "missing 'services' key in params returns {:error, :invalid_params}" do
    assert {:error, :invalid_params} = ServiceObserve.execute(%{}, %{})
  end

  test "services key with non-list value returns {:error, :invalid_params}" do
    set_allowed(["sshd.service"])

    assert {:error, :invalid_params} =
             ServiceObserve.execute(%{"services" => "sshd.service"}, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: probes with missing or invalid fields
  # ---------------------------------------------------------------------------

  test "probe without URL field is rejected" do
    set_allowed(["sshd.service"])

    params = %{
      "services" => ["sshd.service"],
      "probes" => [%{}]
    }

    assert {:error, :invalid_params} = ServiceObserve.execute(params, %{})
  end

  test "probe with non-string URL is rejected" do
    set_allowed(["sshd.service"])

    params = %{
      "services" => ["sshd.service"],
      "probes" => [%{"url" => 123}]
    }

    assert {:error, :invalid_params} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: limit enforcement
  # ---------------------------------------------------------------------------

  test "service count exceeding limit is rejected" do
    set_allowed(Enum.map(1..60, fn i -> "service#{i}.service" end))

    params = %{"services" => Enum.map(1..60, fn i -> "service#{i}.service" end)}

    assert {:error, :invalid_params} = ServiceObserve.execute(params, %{})
  end

  test "probe count exceeding limit is rejected" do
    set_allowed(["sshd.service"])

    probes =
      Enum.map(1..15, fn i ->
        %{"url" => "http://127.0.0.1:#{9000 + i}/health"}
      end)

    params = %{
      "services" => ["sshd.service"],
      "probes" => probes
    }

    assert {:error, :invalid_params} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: multiple services all in allow-list
  # ---------------------------------------------------------------------------

  test "multiple services all in allow-list succeed" do
    set_allowed(["sshd.service", "nginx.service"])
    install_fake_collectors()

    params = %{"services" => ["sshd.service", "nginx.service"]}
    assert {:ok, _artifact} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: multiple probes
  # ---------------------------------------------------------------------------

  test "multiple loopback probes succeed" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    params = %{
      "services" => ["sshd.service"],
      "probes" => [
        %{"url" => "http://127.0.0.1:8080/health"},
        %{"url" => "http://localhost:9000/status"}
      ]
    }

    assert {:ok, %Artifact{} = artifact} = ServiceObserve.execute(params, %{})
    [%DataPart{data: data}] = artifact.parts
    assert length(data["probes"]) == 2
  end

  # ---------------------------------------------------------------------------
  # Test: artifact structure
  # ---------------------------------------------------------------------------

  test "returned artifact has required fields" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    assert {:ok, %Artifact{artifactId: id}} =
             ServiceObserve.execute(%{"services" => ["sshd.service"]}, %{})

    assert is_binary(id) and id != ""
  end

  test "artifact data contains observation metadata" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    assert {:ok, %Artifact{} = artifact} =
             ServiceObserve.execute(%{"services" => ["sshd.service"]}, %{})

    [%DataPart{data: data}] = artifact.parts
    assert data["schema_version"] == "1"
    assert data["skill"] == "exocomp.service.observe"
    assert is_binary(data["observation_id"])
    assert is_binary(data["started_at"])
    assert is_integer(data["elapsed_us"])
    assert data["elapsed_us"] >= 0
  end

  # ---------------------------------------------------------------------------
  # Test: nil probes in params is allowed (treated as empty list)
  # ---------------------------------------------------------------------------

  test "nil probes field is treated as empty list" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    params = %{
      "services" => ["sshd.service"],
      "probes" => nil
    }

    assert {:ok, %Artifact{}} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: omitted probes field is allowed
  # ---------------------------------------------------------------------------

  test "omitted probes field defaults to empty list" do
    set_allowed(["sshd.service"])
    install_fake_collectors()

    params = %{"services" => ["sshd.service"]}

    assert {:ok, %Artifact{}} = ServiceObserve.execute(params, %{})
  end

  # ---------------------------------------------------------------------------
  # Test: edge case - single service, single probe
  # ---------------------------------------------------------------------------

  test "single service and single probe succeed" do
    set_allowed(["nginx.service"])
    install_fake_collectors()

    params = %{
      "services" => ["nginx.service"],
      "probes" => [%{"url" => "http://127.0.0.1:80/"}]
    }

    assert {:ok, %Artifact{}} = ServiceObserve.execute(params, %{})
  end
end
