defmodule Exocomp.Node.Safety.PolicyContextTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.PolicyContext

  @now ~U[2024-01-01 12:00:00Z]

  @valid_opts [
    authorized_action_ids: MapSet.new(["systemd.service.restart"]),
    cooldown_state: %{},
    retry_counts: %{},
    now: @now
  ]

  describe "build/1 — valid input" do
    test "returns {:ok, %PolicyContext{}} for valid opts" do
      assert {:ok, %PolicyContext{} = ctx} = PolicyContext.build(@valid_opts)
      assert %MapSet{} = ctx.authorized_action_ids
      assert MapSet.member?(ctx.authorized_action_ids, "systemd.service.restart")
      assert ctx.cooldown_state == %{}
      assert ctx.retry_counts == %{}
      assert ctx.now == @now
    end

    test "accepts empty authorized_action_ids (no actions permitted)" do
      opts = Keyword.put(@valid_opts, :authorized_action_ids, MapSet.new())
      assert {:ok, %PolicyContext{authorized_action_ids: ids}} = PolicyContext.build(opts)
      assert MapSet.size(ids) == 0
    end

    test "accepts populated cooldown_state and retry_counts" do
      opts =
        @valid_opts
        |> Keyword.put(:cooldown_state, %{{"a.b", "target-1"} => @now})
        |> Keyword.put(:retry_counts, %{{"a.b", "target-1"} => 2})

      assert {:ok, %PolicyContext{cooldown_state: cd, retry_counts: rc}} =
               PolicyContext.build(opts)

      assert Map.get(cd, {"a.b", "target-1"}) == @now
      assert Map.get(rc, {"a.b", "target-1"}) == 2
    end
  end

  describe "build/1 — invalid input" do
    test "rejects nil authorized_action_ids" do
      opts = Keyword.put(@valid_opts, :authorized_action_ids, nil)
      assert {:error, {:missing_field, :authorized_action_ids}} = PolicyContext.build(opts)
    end

    test "rejects non-MapSet authorized_action_ids" do
      opts = Keyword.put(@valid_opts, :authorized_action_ids, ["list", "not", "mapset"])
      assert {:error, {:invalid_field, :authorized_action_ids, _}} = PolicyContext.build(opts)
    end

    test "rejects nil cooldown_state" do
      opts = Keyword.put(@valid_opts, :cooldown_state, nil)
      assert {:error, {:missing_field, :cooldown_state}} = PolicyContext.build(opts)
    end

    test "rejects non-map cooldown_state" do
      opts = Keyword.put(@valid_opts, :cooldown_state, "not a map")
      assert {:error, {:invalid_field, :cooldown_state, "not a map"}} = PolicyContext.build(opts)
    end

    test "rejects nil retry_counts" do
      opts = Keyword.put(@valid_opts, :retry_counts, nil)
      assert {:error, {:missing_field, :retry_counts}} = PolicyContext.build(opts)
    end

    test "rejects non-map retry_counts" do
      opts = Keyword.put(@valid_opts, :retry_counts, 42)
      assert {:error, {:invalid_field, :retry_counts, 42}} = PolicyContext.build(opts)
    end

    test "rejects nil now" do
      opts = Keyword.put(@valid_opts, :now, nil)
      assert {:error, {:missing_field, :now}} = PolicyContext.build(opts)
    end

    test "rejects non-DateTime now" do
      opts = Keyword.put(@valid_opts, :now, "2024-01-01T12:00:00Z")
      assert {:error, {:invalid_field, :now, _}} = PolicyContext.build(opts)
    end
  end
end
