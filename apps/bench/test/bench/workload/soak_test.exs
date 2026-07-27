# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Workload.SoakTest do
  use ExUnit.Case, async: true

  alias Bench.Sample
  alias Bench.Workload.Soak

  test "runs a finite number of bounded load iterations" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    workload = fn ->
      value = Agent.get_and_update(calls, &{&1 + 1, &1 + 1})

      {:ok,
       [
         %Sample{
           timestamp: value,
           source: :llama,
           metric_name: "llama.soak.request",
           value: value,
           unit: "count",
           tags: []
         }
       ]}
    end

    assert {:ok, samples} =
             Soak.run(10_000, 3_000, workload,
               sleep_fn: fn _ -> :ok end,
               now_fn: fn -> 0 end
             )

    assert Agent.get(calls, & &1) == 4
    assert Enum.find(samples, &(&1.metric_name == "soak.load.iterations")).value == 4
  end

  test "reports the exact failing iteration" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    workload = fn ->
      call = Agent.get_and_update(calls, &{&1 + 1, &1 + 1})
      if call == 2, do: {:error, :injected}, else: {:ok, []}
    end

    assert {:error, {:soak_workload_failed, 2, :injected}} =
             Soak.run(2_000, 1_000, workload, sleep_fn: fn _ -> :ok end)
  end
end
