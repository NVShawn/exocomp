# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Identity.Operator do
  @moduledoc """
  Represents an authenticated operator principal resolved from an OIDC session.

  An `Operator` is the in-process identity used by authorization checks.
  It is derived from a validated OIDC token and attached to the current
  request or LiveView session.

  ## Fields

  - `:sub` — stable OIDC subject identifier (never changes for a given
    identity provider identity).
  - `:organization_id` — the organization this operator belongs to. All
    authorization checks scope through this field.
  - `:display_name` — human-readable name or email from the OIDC claims
    (e.g., the `name` or `email` claim). May be `nil` when not present.
  - `:role` — the resolved role for this operator within `:organization_id`.
    One of `:viewer`, `:operator`, or `:admin`.

  ## Role hierarchy

  - `:viewer` — may read fleet, incident, conversation, and audit state.
  - `:operator` — viewer rights plus acknowledge, assign, snooze, chat,
    approve, deny, and resolve.
  - `:admin` — operator rights plus cluster enrollment and revocation, OIDC
    role mapping, retention, and webhook administration.
  """

  @enforce_keys [:sub, :organization_id, :role]
  defstruct [:sub, :organization_id, :display_name, :role]

  @type role :: :viewer | :operator | :admin

  @type t :: %__MODULE__{
          sub: String.t(),
          organization_id: String.t(),
          display_name: String.t() | nil,
          role: role()
        }

  @doc """
  Returns all valid role atoms in ascending privilege order.
  """
  @spec roles() :: [role()]
  def roles, do: [:viewer, :operator, :admin]

  @doc """
  Returns `true` when `role` is a valid role atom.
  """
  @spec valid_role?(term()) :: boolean()
  def valid_role?(role), do: role in roles()

  @doc """
  Returns `true` when the operator's role has at least `minimum_role` privilege.

  The hierarchy (ascending) is: `:viewer` < `:operator` < `:admin`.

  Returns `false` for any unrecognized role.

  ## Examples

      iex> alias Exocomp.MissionControl.Identity.Operator
      iex> op = %Operator{sub: "s", organization_id: "org-1", role: :operator}
      iex> Operator.has_role_at_least?(op, :viewer)
      true
      iex> Operator.has_role_at_least?(op, :operator)
      true
      iex> Operator.has_role_at_least?(op, :admin)
      false
  """
  @spec has_role_at_least?(t(), role()) :: boolean()
  def has_role_at_least?(%__MODULE__{role: role}, minimum) do
    compare_roles(role, minimum) >= 0
  end

  @doc """
  Compares two role atoms by privilege level.

  Returns a negative integer, zero, or a positive integer as the first role is
  less than, equal to, or greater than the second role in privilege.

  Returns `-1` for any unrecognized role on either side.

  ## Examples

      iex> alias Exocomp.MissionControl.Identity.Operator
      iex> Operator.compare_roles(:admin, :operator)
      1
      iex> Operator.compare_roles(:viewer, :viewer)
      0
      iex> Operator.compare_roles(:viewer, :admin)
      -2
  """
  @spec compare_roles(role(), role()) :: integer()
  def compare_roles(role_a, role_b) do
    role_index(role_a) - role_index(role_b)
  end

  defp role_index(:viewer), do: 0
  defp role_index(:operator), do: 1
  defp role_index(:admin), do: 2
  defp role_index(_), do: -1
end
