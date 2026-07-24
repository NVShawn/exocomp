defmodule Exocomp.Node.Safety.ReversibilityTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.Reversibility

  # ── parse/1 — valid inputs ─────────────────────────────────────────────

  test "parse/1 accepts string 'reversible'" do
    assert Reversibility.parse("reversible") == {:ok, :reversible}
  end

  test "parse/1 accepts string 'irreversible'" do
    assert Reversibility.parse("irreversible") == {:ok, :irreversible}
  end

  test "parse/1 accepts atom :reversible" do
    assert Reversibility.parse(:reversible) == {:ok, :reversible}
  end

  test "parse/1 accepts atom :irreversible" do
    assert Reversibility.parse(:irreversible) == {:ok, :irreversible}
  end

  # ── parse/1 — invalid/unknown scalar inputs (no default) ─────────────

  describe "parse/1 rejects unknown scalar values" do
    @scalar_unknown_inputs [
      nil,
      "",
      "unknown",
      "REVERSIBLE",
      "Reversible",
      "yes",
      "no",
      true,
      false,
      0,
      :unknown
    ]

    for value <- @scalar_unknown_inputs do
      test "#{inspect(value)} is rejected" do
        assert {:error, {:unknown_reversibility, unquote(value)}} =
                 Reversibility.parse(unquote(value))
      end
    end
  end

  test "parse/1 rejects a map" do
    assert {:error, {:unknown_reversibility, %{}}} = Reversibility.parse(%{})
  end

  test "parse/1 rejects a list" do
    assert {:error, {:unknown_reversibility, []}} = Reversibility.parse([])
  end
end
