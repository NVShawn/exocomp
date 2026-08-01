# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.CommandProcessorTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{CommandProcessor, CommandReceipt, CommandResult}

  @moduletag :tmp_dir

  test "acknowledges receipt separately and executes a duplicate only once", %{tmp_dir: tmp_dir} do
    parent = self()

    processor =
      start_processor(tmp_dir,
        handlers: %{
          "health.check" => fn payload, context ->
            send(parent, {:ran, payload, context})
            Process.sleep(30)
            {:ok, %{healthy: true}}
          end
        }
      )

    command = command("duplicate-before-execution", "health.check", %{node: "node-a"})

    assert {:ok, %CommandReceipt{status: :received, duplicate: false} = receipt} =
             CommandProcessor.accept(command, processor)

    assert {:ok, %CommandReceipt{status: :received, duplicate: true}} =
             CommandProcessor.accept(command, processor)

    assert receipt.command_id == command.command_id
    assert receipt.status == :received
    assert_receive {:ran, %{node: "node-a"}, %{command_id: "duplicate-before-execution"}}
    refute_receive {:ran, _, _}, 100

    assert {:ok, %CommandResult{status: :completed, result: %{healthy: true}}} =
             eventually_result(command.command_id, processor)
  end

  test "a pending command becomes terminal after restart and is not executed again", %{
    tmp_dir: tmp_dir
  } do
    parent = self()
    opts = processor_opts(tmp_dir)

    processor =
      start_processor_opts(
        opts ++
          [
            handlers: %{
              "slow.command" => fn _payload, _context ->
                send(parent, :handler_started)
                Process.sleep(5_000)
                {:ok, :late}
              end
            }
          ]
      )

    command = command("restart-duplicate", "slow.command", %{})
    assert {:ok, _receipt} = CommandProcessor.accept(command, processor)
    assert_receive :handler_started
    stop_processor(processor)

    restarted =
      start_processor_opts(
        opts ++
          [
            handlers: %{
              "slow.command" => fn _payload, _context -> send(parent, :ran_after_restart) end
            }
          ]
      )

    assert {:ok, %CommandResult{status: :failed, error: :coordinator_restarted}} =
             CommandProcessor.result(command.command_id, restarted)

    assert {:ok, %CommandReceipt{duplicate: true}} =
             CommandProcessor.accept(command, restarted)

    refute_receive :ran_after_restart, 100
  end

  test "expired commands are acknowledged but never dispatched", %{tmp_dir: tmp_dir} do
    parent = self()
    now = ~U[2026-08-01 12:00:00Z]

    processor =
      start_processor(tmp_dir,
        now_fn: fn -> now end,
        handlers: %{"expired.command" => fn _payload -> send(parent, :unexpected_execution) end}
      )

    command = command("expired", "expired.command", %{}, ~U[2026-08-01 11:59:00Z], now)
    assert {:ok, %CommandReceipt{status: :received}} = CommandProcessor.accept(command, processor)

    assert {:ok, %CommandResult{status: :expired, error: :expired}} =
             CommandProcessor.result(command.command_id, processor)

    refute_receive :unexpected_execution

    assert [%{"kind" => "command.result", "command_id" => "expired"}] =
             CommandProcessor.events(processor)
  end

  test "unsupported command kinds produce a terminal result without a handler", %{
    tmp_dir: tmp_dir
  } do
    processor = start_processor(tmp_dir)
    command = command("unsupported", "not.registered", %{})

    assert {:ok, %CommandReceipt{status: :received}} = CommandProcessor.accept(command, processor)

    assert {:ok, %CommandResult{status: :failed, error: {:unsupported_kind, "not.registered"}}} =
             CommandProcessor.result(command.command_id, processor)
  end

  test "handler crashes become a durable failed result", %{tmp_dir: tmp_dir} do
    processor =
      start_processor(tmp_dir,
        handlers: %{"crashing.command" => fn _payload -> raise "handler exploded" end}
      )

    command = command("handler-crash", "crashing.command", %{})
    assert {:ok, %CommandReceipt{status: :received}} = CommandProcessor.accept(command, processor)

    assert {:ok, %CommandResult{status: :failed, error: {:handler_crash, "handler exploded"}}} =
             eventually_result(command.command_id, processor)
  end

  test "completed results and terminal events replay after duplicate delivery", %{
    tmp_dir: tmp_dir
  } do
    parent = self()

    processor =
      start_processor(tmp_dir,
        handlers: %{
          "result.command" => fn _payload, _context ->
            send(parent, :completed_once)
            {:ok, %{value: 42}}
          end
        }
      )

    command = command("completed-replay", "result.command", %{}, nil, nil, "corr-result")
    assert {:ok, _receipt} = CommandProcessor.accept(command, processor)
    assert_receive :completed_once

    first = eventually_result(command.command_id, processor)
    assert {:ok, %CommandResult{status: :completed, result: %{value: 42}} = result} = first
    assert {:ok, %CommandReceipt{duplicate: true}} = CommandProcessor.accept(command, processor)
    assert {:ok, ^result} = CommandProcessor.result(command.command_id, processor)
    refute_receive :completed_once, 100
    assert length(CommandProcessor.events(processor)) == 1
  end

  test "a completed result is replayed from durable storage after restart", %{tmp_dir: tmp_dir} do
    parent = self()
    opts = processor_opts(tmp_dir)

    processor =
      start_processor_opts(
        opts ++
          [
            handlers: %{
              "durable.command" => fn _payload ->
                send(parent, :durable_handler_ran)
                {:ok, %{persisted: true}}
              end
            }
          ]
      )

    command = command("durable-result", "durable.command", %{})
    assert {:ok, _receipt} = CommandProcessor.accept(command, processor)
    assert_receive :durable_handler_ran

    assert {:ok, %CommandResult{status: :completed}} =
             eventually_result(command.command_id, processor)

    stop_processor(processor)

    restarted =
      start_processor_opts(
        opts ++ [handlers: %{"durable.command" => fn _payload -> send(parent, :rerun) end}]
      )

    assert {:ok, %CommandResult{status: :completed, result: %{persisted: true}}} =
             CommandProcessor.result(command.command_id, restarted)

    assert {:ok, %CommandReceipt{duplicate: true}} =
             CommandProcessor.accept(command, restarted)

    assert length(CommandProcessor.events(restarted)) == 1
    refute_receive :rerun, 100
  end

  test "correlation fields identify both the receipt and terminal event", %{tmp_dir: tmp_dir} do
    processor = start_processor(tmp_dir, handlers: %{"correlated.command" => fn _ -> :done end})
    command = command("correlated", "correlated.command", %{}, nil, nil, "corr-original")

    assert {:ok, %CommandReceipt{command_id: "correlated", correlation_id: "corr-original"}} =
             CommandProcessor.accept(command, processor)

    assert {:ok, %CommandResult{command_id: "correlated", correlation_id: "corr-original"}} =
             eventually_result(command.command_id, processor)

    assert [
             %{
               "command_id" => "correlated",
               "correlation_id" => "corr-original",
               "payload" => payload
             }
           ] =
             CommandProcessor.events(processor)

    assert payload["command_id"] == "correlated"
  end

  test "schema validation rejects unsupported versions and unknown fields", %{tmp_dir: tmp_dir} do
    processor = start_processor(tmp_dir)
    base = command("invalid-schema", "health.check", %{})

    assert {:error, {:unsupported_schema_version, 2}} =
             CommandProcessor.accept(Map.put(base, :schema_version, 2), processor)

    assert {:error, {:unknown_fields, ["unexpected"]}} =
             CommandProcessor.accept(Map.put(base, :unexpected, true), processor)
  end

  defp start_processor(tmp_dir, extra_opts \\ []) do
    opts = processor_opts(tmp_dir) ++ extra_opts
    start_processor_opts(opts)
  end

  defp start_processor_opts(opts) do
    {:ok, processor} = CommandProcessor.start_link(opts)
    on_exit(fn -> stop_processor(processor) end)
    processor
  end

  defp processor_opts(tmp_dir) do
    id = System.unique_integer([:positive])

    [
      name: String.to_atom("command_processor_#{id}"),
      table: String.to_atom("command_ledger_#{id}"),
      path: Path.join(tmp_dir, "commands-#{id}.dets"),
      event_path: Path.join(tmp_dir, "command-results-#{id}.jsonl")
    ]
  end

  defp stop_processor(processor) do
    if is_pid(processor) and Process.alive?(processor), do: GenServer.stop(processor)
  catch
    :exit, _reason -> :ok
  end

  defp command(
         command_id,
         kind,
         payload,
         issued_at \\ nil,
         expires_at \\ nil,
         correlation_id \\ nil
       ) do
    issued_at = issued_at || DateTime.add(DateTime.utc_now(), -60, :second)
    expires_at = expires_at || DateTime.add(issued_at, 300, :second)

    %{
      command_id: command_id,
      kind: kind,
      issued_at: issued_at,
      expires_at: expires_at,
      payload: payload
    }
    |> maybe_put(:correlation_id, correlation_id)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp eventually_result(command_id, processor, attempts \\ 100)

  defp eventually_result(_command_id, _processor, 0),
    do: flunk("command did not reach a terminal result")

  defp eventually_result(command_id, processor, attempts) do
    case CommandProcessor.result(command_id, processor) do
      {:ok, _result} = result ->
        result

      {:error, :pending} ->
        Process.sleep(10)
        eventually_result(command_id, processor, attempts - 1)
    end
  end
end
