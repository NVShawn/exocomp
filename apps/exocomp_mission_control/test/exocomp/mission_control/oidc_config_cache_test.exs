# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCConfigCacheTest do
  use ExUnit.Case

  alias Exocomp.MissionControl.OIDCConfigCache

  setup do
    OIDCConfigCache.clear()
    :ok
  end

  test "serializes concurrent loads and returns the cached value" do
    counter = :atomics.new(1, [])

    loader = fn ->
      :atomics.add_get(counter, 1, 1)
      {:ok, %{issuer: "test"}}
    end

    results =
      1..12
      |> Task.async_stream(fn _ -> OIDCConfigCache.fetch(:discovery, loader) end,
        max_concurrency: 12,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.all?(results, &(&1 == {:ok, %{issuer: "test"}}))
    assert :atomics.get(counter, 1) == 1
  end

  test "does not cache failed loads" do
    counter = :atomics.new(1, [])

    loader = fn ->
      :atomics.add_get(counter, 1, 1)
      {:error, :unavailable}
    end

    assert OIDCConfigCache.fetch(:failing, loader) == {:error, :unavailable}
    assert OIDCConfigCache.fetch(:failing, loader) == {:error, :unavailable}
    assert :atomics.get(counter, 1) == 2
  end
end
