# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Identity.RoleBinding do
  @moduledoc """
  Represents a persistent binding of an OIDC subject to a role within a
  specific organization.

  Role bindings are always scoped to an `organization_id`. A binding for
  organization A is never valid for organization B (cross-organization
  bindings fail closed).

  ## Fields

  - `:organization_id` — the organization that owns this binding. Required.
  - `:sub` — the stable OIDC subject identifier being granted a role. Required.
  - `:role` — the role granted: `:viewer`, `:operator`, or `:admin`. Required.
  - `:display_hint` — optional hint used for display in the admin UI (e.g.,
    the operator's email at the time the binding was created).

  ## Schema note

  In the persistence layer, role bindings include `organization_id` as both a
  partitioning column and a foreign key to the `organizations` table. Every
  query through the context layer must supply the resolved organization ID
  rather than deriving it from the binding record, so that a mis-scoped record
  cannot grant cross-organization access.
  """

  @enforce_keys [:organization_id, :sub, :role]
  defstruct [:organization_id, :sub, :role, :display_hint]

  @type t :: %__MODULE__{
          organization_id: String.t(),
          sub: String.t(),
          role: Exocomp.MissionControl.Identity.Operator.role(),
          display_hint: String.t() | nil
        }

  @doc """
  Returns `true` when the binding's organization matches `organization_id`
  and the binding's `sub` matches `sub`.

  This is the canonical membership check used by the resolver.
  """
  @spec matches?(t(), String.t(), String.t()) :: boolean()
  def matches?(%__MODULE__{organization_id: org, sub: s}, organization_id, sub) do
    org == organization_id and s == sub
  end
end
