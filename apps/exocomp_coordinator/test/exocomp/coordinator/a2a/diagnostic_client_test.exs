defmodule Exocomp.Coordinator.A2A.DiagnosticClientTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{DataPart, Task, TextPart}
  alias Exocomp.Coordinator.A2A.{ClientError, DiagnosticClient}
  alias Exocomp.Coordinator.Inventory.Node
  alias Exocomp.Coordinator.Registry

  defmodule FakeTransport do
    @behaviour Exocomp.Coordinator.A2A.Transport

    @impl true
    def request(request, opts) do
      send(Keyword.fetch!(opts, :owner), {:transport_request, request})

      case Keyword.fetch!(opts, :response) do
        response when is_function(response, 1) -> response.(request)
        response -> response
      end
    end
  end

  setup do
    registry = start_supervised!({Registry, name: unique_name()})

    node = %Node{
      id: "node-a",
      hostname: "node-a.example.test",
      port: 8443,
      certificate_identity: "node-a.identity.test",
      capabilities: ["exocomp.system.diagnose", "exocomp.service.diagnose"]
    }

    :ok = Registry.rebuild([node], registry)
    :ok = Registry.update("node-a", %{addresses: ["192.0.2.10"]}, registry)

    %{registry: registry}
  end

  test "send creates a diagnostic task using registry identity and A2A 1.0", %{
    registry: registry
  } do
    response = json_response(202, task_json("task-1", "submitted"))

    assert {:ok, %Task{id: "task-1", status: %{state: :submitted}}} =
             DiagnosticClient.send(
               "node-a",
               "exocomp.system.diagnose",
               %{"detail" => "full"},
               client_opts(registry, response,
                 message_id: "message-1",
                 context_id: "goal-1",
                 timeout_ms: 321
               )
             )

    assert_receive {:transport_request, request}
    assert request.address == "192.0.2.10"
    assert request.hostname == "node-a.example.test"
    assert request.certificate_identity == "node-a.identity.test"
    assert request.port == 8443
    assert request.timeout_ms == 321
    assert {"a2a-version", "1.0"} in request.headers
    assert request.path == "/message:send"

    assert %{
             "contextId" => "goal-1",
             "messageId" => "message-1",
             "parts" => [
               %{
                 "data" => %{
                   "detail" => "full",
                   "skill" => "exocomp.system.diagnose"
                 }
               }
             ]
           } = Jason.decode!(request.body)
  end

  test "send rejects remediation before transport is called", %{registry: registry} do
    assert {:error,
            %ClientError{
              kind: :configuration,
              reason: :diagnostic_skill_required,
              operation: :send
            }} =
             DiagnosticClient.send(
               "node-a",
               "exocomp.remediation.propose",
               %{},
               client_opts(registry, json_response(202, task_json("never", "submitted")))
             )

    refute_receive {:transport_request, _request}
  end

  test "get_task decodes terminal results and typed artifact parts", %{registry: registry} do
    artifact = %{
      "artifactId" => "artifact-1",
      "name" => "diagnosis",
      "parts" => [
        %{"type" => "text", "text" => "healthy"},
        %{"type" => "data", "data" => %{"load" => 0.2}}
      ]
    }

    response = json_response(200, task_json("task-2", "completed", [artifact]))

    assert {:ok,
            %Task{
              id: "task-2",
              status: %{state: :completed},
              artifacts: [
                %{
                  artifactId: "artifact-1",
                  parts: [%TextPart{text: "healthy"}, %DataPart{data: %{"load" => 0.2}}]
                }
              ]
            }} = DiagnosticClient.get_task("node-a", "task-2", client_opts(registry, response))

    assert_receive {:transport_request, %{method: :get, path: "/tasks/task-2"}}
  end

  test "normalizes a per-request timeout", %{registry: registry} do
    assert {:error,
            %ClientError{
              kind: :transport,
              reason: :timeout,
              operation: :get_task,
              node_id: "node-a"
            }} =
             DiagnosticClient.get_task(
               "node-a",
               "task-timeout",
               client_opts(registry, {:error, :timeout}, timeout_ms: 17)
             )

    assert_receive {:transport_request, %{timeout_ms: 17}}
  end

  test "normalizes malformed JSON and malformed task responses", %{registry: registry} do
    assert {:error, %ClientError{kind: :protocol, reason: :malformed_response}} =
             DiagnosticClient.get_task(
               "node-a",
               "bad-json",
               client_opts(registry, {:ok, 200, [], "{"})
             )

    assert {:error,
            %ClientError{
              kind: :protocol,
              reason: :malformed_response,
              details: {:malformed_task, %{"unexpected" => true}}
            }} =
             DiagnosticClient.get_task(
               "node-a",
               "bad-task",
               client_opts(registry, json_response(200, %{"unexpected" => true}))
             )
  end

  test "cancel returns the canceled task", %{registry: registry} do
    response = json_response(200, task_json("task-3", "canceled"))

    assert {:ok, %Task{id: "task-3", status: %{state: :canceled}}} =
             DiagnosticClient.cancel("node-a", "task-3", client_opts(registry, response))

    assert_receive {:transport_request, %{method: :post, path: "/tasks/task-3:cancel"}}
  end

  test "cancel normalizes unsupported and not-cancelable protocol responses", %{
    registry: registry
  } do
    unsupported =
      json_response(400, %{
        "error" => %{"code" => -32004, "message" => "Unsupported operation"}
      })

    assert {:error,
            %ClientError{
              kind: :protocol,
              reason: :unsupported_operation,
              operation: :cancel,
              status: 400
            }} =
             DiagnosticClient.cancel(
               "node-a",
               "task-4",
               client_opts(registry, unsupported)
             )

    not_cancelable =
      json_response(400, %{
        "error" => %{"code" => -32002, "message" => "Task not cancelable"}
      })

    assert {:error, %ClientError{reason: :task_not_cancelable, status: 400}} =
             DiagnosticClient.cancel(
               "node-a",
               "task-5",
               client_opts(registry, not_cancelable)
             )
  end

  test "version negotiation fails before transport when a node advertises no common version", %{
    registry: registry
  } do
    :ok = Registry.update("node-a", %{supported_a2a_versions: ["2.0"]}, registry)

    assert {:error,
            %ClientError{
              kind: :protocol,
              reason: :unsupported_version,
              operation: :get_task
            }} =
             DiagnosticClient.get_task(
               "node-a",
               "task-6",
               client_opts(registry, json_response(200, task_json("task-6", "working")))
             )

    refute_receive {:transport_request, _request}
  end

  test "response version mismatch is a normalized protocol error", %{registry: registry} do
    response = {:ok, 200, [{"A2A-Version", "2.0"}], Jason.encode!(task_json("task-7", "working"))}

    assert {:error,
            %ClientError{
              kind: :protocol,
              reason: :version_mismatch,
              details: "2.0"
            }} =
             DiagnosticClient.get_task("node-a", "task-7", client_opts(registry, response))
  end

  test "unknown and unverified nodes fail without transport", %{registry: registry} do
    assert {:error, %ClientError{kind: :configuration, reason: :unknown_node}} =
             DiagnosticClient.get_task(
               "missing",
               "task",
               client_opts(registry, json_response(200, task_json("task", "working")))
             )

    :ok = Registry.update("node-a", %{addresses: []}, registry)

    assert {:error, %ClientError{kind: :transport, reason: :unreachable}} =
             DiagnosticClient.get_task(
               "node-a",
               "task",
               client_opts(registry, json_response(200, task_json("task", "working")))
             )

    refute_receive {:transport_request, _request}
  end

  defp client_opts(registry, response, extra \\ []) do
    [
      registry: registry,
      transport: FakeTransport,
      transport_opts: [owner: self(), response: response]
    ]
    |> Keyword.merge(extra)
  end

  defp json_response(status, body), do: {:ok, status, [], Jason.encode!(body)}

  defp task_json(id, state, artifacts \\ []) do
    %{
      "id" => id,
      "status" => %{"state" => state, "timestamp" => "2026-07-24T00:00:00Z"},
      "history" => [],
      "artifacts" => artifacts
    }
  end

  defp unique_name, do: :"diagnostic_client_registry_#{System.unique_integer([:positive])}"
end
