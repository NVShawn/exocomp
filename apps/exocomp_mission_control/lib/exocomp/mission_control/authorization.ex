# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Authorization do
  @moduledoc """
  Context-level authorization for Mission Control operations.

  Every context function that performs a side effect or returns sensitive data
  **must** call one of the `authorize!/3` or `authorize/3` variants before
  proceeding. UI controls (hidden buttons, disabled links) are **not**
  authorization boundaries; they are presentation hints only.

  ## Actions

  - `:read` — view fleet, incident, conversation, and audit state. Requires
    the `:viewer` role or higher.
  - `:operate` — acknowledge, assign, snooze, chat, approve, deny, and
    resolve. Requires the `:operator` role or higher.
  - `:administer` — cluster enrollment and revocation, OIDC role mapping,
    retention, and webhook administration. Requires the `:admin` role.

  ## Organization scoping

  `authorize/3` and `authorize!/3` accept an `organization_id` against which
  the operator's own organization is checked. A request from an operator in
  organization A is always denied for resources belonging to organization B,
  regardless of the operator's role. Unknown or mismatched organizations
  fail closed.

  ## Usage

  ```elixir
  with :ok <- Authorization.authorize(operator, organization_id, :operate) do
    # safe to mutate
    MyContext.create_something(params)
  end
  ```

  Or, in contexts where an unauthorized call is a programming error:

  ```elixir
  :ok = Authorization.authorize!(operator, organization_id, :administer)
  MyContext.enroll_cluster(params)
  ```
  """

  alias Exocomp.MissionControl.Authorization.ForbiddenError
  alias Exocomp.MissionControl.Identity.Operator

  @type action :: :read | :operate | :administer
  @type deny_reason :: :insufficient_role | :cross_organization | :unauthenticated

  @doc """
  Returns `:ok` when `operator` may perform `action` on a resource owned by
  `organization_id`, or `{:error, reason}` otherwise.

  ## Deny reasons

  - `:unauthenticated` — `operator` is `nil` or not an `Operator` struct.
  - `:cross_organization` — operator's `organization_id` differs from the
    supplied `organization_id` argument.
  - `:insufficient_role` — the operator belongs to the right organization but
    lacks the required role for `action`.
  """
  @spec authorize(Operator.t() | nil, String.t(), action()) ::
          :ok | {:error, deny_reason()}
  def authorize(nil, _organization_id, _action), do: {:error, :unauthenticated}

  def authorize(%Operator{} = operator, organization_id, action)
      when is_binary(organization_id) do
    cond do
      operator.organization_id != organization_id ->
        {:error, :cross_organization}

      not role_satisfies?(operator.role, action) ->
        {:error, :insufficient_role}

      true ->
        :ok
    end
  end

  def authorize(_operator, _organization_id, _action), do: {:error, :unauthenticated}

  @doc """
  Raises `Exocomp.MissionControl.Authorization.ForbiddenError` when
  `operator` is not authorized. Returns `:ok` when authorized.

  Prefer `authorize/3` in pipelines where errors are propagated as tagged
  tuples. Use `authorize!/3` inside context functions when an unauthorized
  call would be a programming error (e.g., when the caller already holds a
  verified session).
  """
  @spec authorize!(Operator.t() | nil, String.t(), action()) :: :ok
  def authorize!(operator, organization_id, action) do
    case authorize(operator, organization_id, action) do
      :ok ->
        :ok

      {:error, reason} ->
        raise ForbiddenError, reason: reason, action: action
    end
  end

  @doc """
  Returns `true` when the operator may read data owned by `organization_id`.

  Equivalent to `authorize(operator, organization_id, :read) == :ok`.
  """
  @spec can_read?(Operator.t() | nil, String.t()) :: boolean()
  def can_read?(operator, organization_id),
    do: authorize(operator, organization_id, :read) == :ok

  @doc """
  Returns `true` when the operator may perform operational mutations on data
  owned by `organization_id`.

  Equivalent to `authorize(operator, organization_id, :operate) == :ok`.
  """
  @spec can_operate?(Operator.t() | nil, String.t()) :: boolean()
  def can_operate?(operator, organization_id),
    do: authorize(operator, organization_id, :operate) == :ok

  @doc """
  Returns `true` when the operator may perform administrative mutations on data
  owned by `organization_id`.

  Equivalent to `authorize(operator, organization_id, :administer) == :ok`.
  """
  @spec can_administer?(Operator.t() | nil, String.t()) :: boolean()
  def can_administer?(operator, organization_id),
    do: authorize(operator, organization_id, :administer) == :ok

  # ── Private ──────────────────────────────────────────────────────────────────

  # Maps an action to the minimum operator role required.
  # :read    → viewer or higher
  # :operate → operator or higher
  # :administer → admin only
  defp role_satisfies?(role, :read), do: Operator.compare_roles(role, :viewer) >= 0
  defp role_satisfies?(role, :operate), do: Operator.compare_roles(role, :operator) >= 0
  defp role_satisfies?(role, :administer), do: Operator.compare_roles(role, :admin) >= 0
  defp role_satisfies?(_role, _action), do: false
end
