defmodule Exocomp.Node.Safety do
  @moduledoc """
  Milestone 3 safety-validation type system.

  This module is the entry point for the M3 policy domain. It re-exports the
  main type aliases and documents the security invariants that every consumer
  must respect.

  ## Module map

  | Module                 | Purpose                                           |
  |------------------------|---------------------------------------------------|
  | `Safety.DataClassification` | Classify resources; unknown → `:protected_user_data` |
  | `Safety.RiskRank`      | Four-dimensional risk ordering for policy selection |
  | `Safety.Reversibility` | Reversibility tag for action definitions          |
  | `Safety.ActionDefinition` | Typed, allow-listed action catalog entry        |
  | `Safety.Evidence`      | Deterministic, versioned evidence records         |
  | `Safety.Proposal`      | Untrusted LLM action proposals (strict parsing)   |
  | `Safety.ValidatorResult` | Policy engine output (fail-closed default: deny) |

  ## Safety invariants

  1. **Unknown data is protected user data.** `DataClassification.classify/1`
     returns `:protected_user_data` for any unrecognized value.

  2. **User-data deletion is unrepresentable.** An `ActionDefinition` with
     `action_class: :deletion` and `data_classification: :protected_user_data`
     cannot be constructed; `build/1` returns an error.

  3. **Fail-closed validation.** All schema parsers reject unknown versions and
     unknown fields. `ValidatorResult` defaults to `:deny`.

  4. **No atom injection.** All parsers use explicit pattern matching on string
     literals. `String.to_atom/1` and `String.to_existing_atom/1` are never
     used on external input.
  """
end
