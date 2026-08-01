# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Auth.OIDCResolver do
  @moduledoc """
  Maps OIDC token claims to a Mission Control operator identity and role.

  Resolution runs in two phases for each organization:

  1. **Subject override** — if the OIDC `sub` claim has an explicit entry in
     the configured `subject_role_map`, that role is used directly.
  2. **Group claim** — if a `group_claim` key is configured, the resolver
     extracts that claim from the token, maps each group value through
     `group_role_map`, and selects the highest-privilege role found.

  If neither phase produces a match, the resolver returns `{:error, :no_role}`.
  Cross-organization resolution is never performed: the organization supplied
  by the caller must match the OIDC session's organization before any claim
  inspection occurs.

  ## Application configuration

  ```elixir
  config :exocomp_mission_control, :oidc_role_config, %{
    "org-123" => %{
      group_claim: "groups",
      group_role_map: %{
        "platform-admin"  => :admin,
        "platform-ops"    => :operator,
        "platform-reader" => :viewer
      },
      subject_role_map: %{
        "breakglass-sub-1234" => :admin
      }
    }
  }
  ```

  The `group_role_map` and `subject_role_map` keys are optional. The resolver
  falls back to `{:error, :no_role}` when neither map is present or matches.
  The highest-privilege role wins when a subject belongs to multiple groups.

  ## Token claims format

  The `claims` argument is a plain `%{}` map with string keys, as produced by
  `JOSE` or any OpenID Connect library after JWT validation.

  ## Display identity

  `resolve/3` also extracts a display name from the token. It checks the
  `display_claim` key in the org config (defaults to `"name"`) and then falls
  back to the `"email"` claim. If neither is present, the `sub` is used.
  """

  alias Exocomp.MissionControl.Identity.Operator

  @role_priority %{admin: 2, operator: 1, viewer: 0}

  @doc """
  Resolves an operator identity from a validated OIDC token claim map.

  ## Parameters

  - `organization_id` — the organization the authenticated session belongs to.
  - `sub` — the stable OIDC subject claim (must be pre-validated and non-empty).
  - `claims` — the full decoded OIDC token claims as a string-keyed map.
  - `config_override` — optional config override for testing; when `nil`,
    config is loaded from `:exocomp_mission_control, :oidc_role_config`.

  ## Returns

  - `{:ok, %Operator{}}` on success.
  - `{:error, :no_role}` when no configured mapping matches.
  - `{:error, :no_config}` when no configuration exists for the organization.
  """
  @spec resolve(String.t(), String.t(), map(), map() | nil) ::
          {:ok, Operator.t()} | {:error, :no_role | :no_config}
  def resolve(organization_id, sub, claims, config_override \\ nil)
      when is_binary(organization_id) and is_binary(sub) and is_map(claims) do
    role_config = config_override || load_config()

    case Map.get(role_config, organization_id) do
      nil ->
        {:error, :no_config}

      org_config ->
        case resolve_role(sub, claims, org_config) do
          nil ->
            {:error, :no_role}

          role ->
            display_name = extract_display_name(sub, claims, org_config)

            {:ok,
             %Operator{
               sub: sub,
               organization_id: organization_id,
               display_name: display_name,
               role: role
             }}
        end
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp load_config do
    Application.get_env(:exocomp_mission_control, :oidc_role_config, %{})
  end

  defp resolve_role(sub, claims, org_config) do
    subject_role_map = Map.get(org_config, :subject_role_map, %{})

    case Map.get(subject_role_map, sub) do
      nil ->
        resolve_from_groups(claims, org_config)

      role when role in [:viewer, :operator, :admin] ->
        role
    end
  end

  defp resolve_from_groups(claims, org_config) do
    group_claim = Map.get(org_config, :group_claim)
    group_role_map = Map.get(org_config, :group_role_map, %{})

    if group_claim do
      groups = extract_groups(claims, group_claim)

      groups
      |> Enum.flat_map(fn group ->
        case Map.get(group_role_map, group) do
          nil -> []
          role when role in [:viewer, :operator, :admin] -> [role]
        end
      end)
      |> highest_role()
    else
      nil
    end
  end

  defp extract_groups(claims, claim_key) do
    case Map.get(claims, claim_key) do
      groups when is_list(groups) -> Enum.filter(groups, &is_binary/1)
      group when is_binary(group) -> [group]
      _ -> []
    end
  end

  defp highest_role([]), do: nil

  defp highest_role(roles) do
    Enum.max_by(roles, &Map.fetch!(@role_priority, &1))
  end

  defp extract_display_name(sub, claims, org_config) do
    display_claim = Map.get(org_config, :display_claim, "name")

    claims[display_claim] || claims["email"] || sub
  end
end
