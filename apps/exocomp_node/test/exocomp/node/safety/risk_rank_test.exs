defmodule Exocomp.Node.Safety.RiskRankTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.RiskRank

  # ── schema_version/0 ───────────────────────────────────────────────────

  test "schema_version/0 returns '1'" do
    assert RiskRank.schema_version() == "1"
  end

  # ── parse/1 — valid inputs ─────────────────────────────────────────────

  describe "parse/1 valid level strings" do
    @valid_levels ~w[none minimal moderate high critical]

    for level <- @valid_levels do
      test "#{level} is accepted for all fields" do
        attrs = %{
          "data_loss" => unquote(level),
          "work_loss" => unquote(level),
          "disruption" => unquote(level),
          "scope" => unquote(level)
        }

        assert {:ok, %RiskRank{} = rr} = RiskRank.parse(attrs)
        level_atom = String.to_existing_atom(unquote(level))
        assert rr.data_loss == level_atom
        assert rr.work_loss == level_atom
        assert rr.disruption == level_atom
        assert rr.scope == level_atom
      end
    end
  end

  test "parse/1 defaults missing fields to :none" do
    assert {:ok, %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}} =
             RiskRank.parse(%{})
  end

  test "parse/1 accepts a partial map" do
    assert {:ok, %RiskRank{data_loss: :high, work_loss: :none, disruption: :none, scope: :none}} =
             RiskRank.parse(%{"data_loss" => "high"})
  end

  # ── parse/1 — invalid inputs ───────────────────────────────────────────

  describe "parse/1 rejects unknown level strings" do
    @unknown_levels ["galaxy_brain", "", "NONE", "Minimal", "0", "severe"]

    for bad <- @unknown_levels do
      test "unknown level '#{bad}' on data_loss field" do
        assert {:error, {:unknown_risk_level, :data_loss, unquote(bad)}} =
                 RiskRank.parse(%{"data_loss" => unquote(bad)})
      end
    end
  end

  test "parse/1 rejects non-string level values" do
    assert {:error, {:unknown_risk_level, :data_loss, 42}} =
             RiskRank.parse(%{"data_loss" => 42})
  end

  test "parse/1 rejects nil level value" do
    assert {:error, {:unknown_risk_level, :data_loss, nil}} =
             RiskRank.parse(%{"data_loss" => nil})
  end

  # ── compare/2 ─────────────────────────────────────────────────────────

  describe "compare/2 ordering primitives" do
    test ":none < :minimal" do
      a = %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}
      b = %RiskRank{data_loss: :minimal, work_loss: :none, disruption: :none, scope: :none}
      assert RiskRank.compare(a, b) == :lt
    end

    test ":critical > :high" do
      a = %RiskRank{data_loss: :critical, work_loss: :none, disruption: :none, scope: :none}
      b = %RiskRank{data_loss: :high, work_loss: :none, disruption: :none, scope: :none}
      assert RiskRank.compare(a, b) == :gt
    end

    test "equal ranks are :eq" do
      a = %RiskRank{data_loss: :moderate, work_loss: :minimal, disruption: :none, scope: :high}
      assert RiskRank.compare(a, a) == :eq
    end

    test "data_loss tiebreaks before work_loss" do
      a = %RiskRank{data_loss: :none, work_loss: :critical, disruption: :none, scope: :none}
      b = %RiskRank{data_loss: :minimal, work_loss: :none, disruption: :none, scope: :none}
      # a has lower data_loss; data_loss wins even though work_loss is much higher
      assert RiskRank.compare(a, b) == :lt
    end

    test "work_loss tiebreaks before disruption when data_loss is equal" do
      a = %RiskRank{data_loss: :none, work_loss: :none, disruption: :critical, scope: :none}
      b = %RiskRank{data_loss: :none, work_loss: :minimal, disruption: :none, scope: :none}
      # a has lower work_loss; work_loss wins
      assert RiskRank.compare(a, b) == :lt
    end

    test "disruption tiebreaks before scope" do
      a = %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :critical}
      b = %RiskRank{data_loss: :none, work_loss: :none, disruption: :minimal, scope: :none}
      # a has lower disruption
      assert RiskRank.compare(a, b) == :lt
    end

    test "full level ordering: none < minimal < moderate < high < critical" do
      levels = [:none, :minimal, :moderate, :high, :critical]

      pairs =
        for {a, i} <- Enum.with_index(levels),
            {b, j} <- Enum.with_index(levels),
            i < j,
            do: {a, b}

      for {lower, higher} <- pairs do
        rank_lower = %RiskRank{
          data_loss: lower,
          work_loss: :none,
          disruption: :none,
          scope: :none
        }

        rank_higher = %RiskRank{
          data_loss: higher,
          work_loss: :none,
          disruption: :none,
          scope: :none
        }

        assert RiskRank.compare(rank_lower, rank_higher) == :lt,
               "Expected #{lower} < #{higher}"

        assert RiskRank.compare(rank_higher, rank_lower) == :gt,
               "Expected #{higher} > #{lower}"
      end
    end
  end

  # ── less_than?/2 ──────────────────────────────────────────────────────

  describe "less_than?/2" do
    test "returns true when first rank is strictly lower impact" do
      a = %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}
      b = %RiskRank{data_loss: :minimal, work_loss: :none, disruption: :none, scope: :none}
      assert RiskRank.less_than?(a, b) == true
    end

    test "returns false for equal ranks" do
      r = %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}
      assert RiskRank.less_than?(r, r) == false
    end

    test "returns false when first rank is higher impact" do
      a = %RiskRank{data_loss: :high, work_loss: :none, disruption: :none, scope: :none}
      b = %RiskRank{data_loss: :none, work_loss: :none, disruption: :none, scope: :none}
      assert RiskRank.less_than?(a, b) == false
    end
  end
end
