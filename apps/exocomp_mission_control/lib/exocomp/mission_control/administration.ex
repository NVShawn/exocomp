# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Administration do
  @moduledoc """
  Organization-scoped administration operations used by Mission Control's UI.

  This small context is intentionally independent of the database-backed
  contexts. It gives the LiveViews a safe boundary while those contexts are
  assembled: authorization is checked before every operation, records are
  scoped by organization, and secret material is never stored in the UI
  representation. The ETS store is also useful for local development and
  focused LiveView tests; replacing it with a repository does not change the
  public context contract.
  """

  alias Exocomp.MissionControl.{
    AdminAction,
    AdminCluster,
    AdminInvitation,
    AdminRoleMapping,
    AdminWebhook,
    Authorization,
    Identity.Operator,
    RetentionSettings
  }

  @table :exocomp_mission_control_admin_records
  @default_status_history_days 90
  @default_incident_days 365
  @status_history_day_bounds {1, 365}
  @incident_day_bounds {30, 3_650}

  @doc "Returns the supported and deliberately bounded retention ranges."
  def retention_bounds do
    %{status_history_days: @status_history_day_bounds, incident_days: @incident_day_bounds}
  end

  @doc "Clears the development/test store. Production callers should not use this."
  def reset! do
    :ets.delete_all_objects(table())
    :ok
  end

  @doc "Creates a single-use invitation and returns its plaintext token once."
  def create_invitation(%Operator{} = operator, params) when is_map(params) do
    create_invitation(operator, operator.organization_id, params)
  end

  def create_invitation(_operator, _params), do: {:error, :unauthenticated}

  def create_invitation(%Operator{} = operator, organization_id, params)
      when is_binary(organization_id) and is_map(params) do
    with :ok <- authorize_admin(operator, organization_id),
         {:ok, cluster_name} <- required_string(params, "cluster_name"),
         {:ok, labels} <- labels(params),
         {:ok, expires_at} <- invitation_expiry(params) do
      now = DateTime.utc_now()
      token = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

      invitation = %AdminInvitation{
        id: identifier(),
        organization_id: organization_id,
        cluster_name: cluster_name,
        labels: labels,
        token_digest: :crypto.hash(:sha256, token),
        expires_at: expires_at,
        inserted_at: now,
        consumed_at: nil
      }

      put(:invitation, invitation.id, invitation)
      {:ok, invitation, token}
    end
  end

  def create_invitation(_operator, _organization_id, _params), do: {:error, :unauthenticated}

  @doc "Lists invitations belonging to the operator's organization."
  def list_invitations(%Operator{} = operator) do
    list_invitations(operator, operator.organization_id)
  end

  def list_invitations(_operator), do: {:error, :unauthenticated}

  def list_invitations(%Operator{} = operator, organization_id) when is_binary(organization_id) do
    with :ok <- authorize_admin(operator, organization_id) do
      {:ok, list(:invitation, organization_id)}
    end
  end

  @doc "Consumes an invitation atomically without returning or storing its plaintext."
  def consume_invitation(organization_id, token)
      when is_binary(organization_id) and is_binary(token) do
    digest = :crypto.hash(:sha256, token)

    :global.trans({{@table, organization_id, digest}, self()}, fn ->
      case Enum.find(list(:invitation, organization_id), fn invitation ->
             is_nil(invitation.consumed_at) and
               Plug.Crypto.secure_compare(invitation.token_digest, digest) and
               DateTime.compare(invitation.expires_at, DateTime.utc_now()) == :gt
           end) do
        nil ->
          {:error, :invalid_or_expired_invitation}

        invitation ->
          consumed = %{invitation | consumed_at: DateTime.utc_now()}
          put(:invitation, consumed.id, consumed)
          {:ok, AdminInvitation.public(consumed)}
      end
    end)
  end

  def consume_invitation(_organization_id, _token), do: {:error, :invalid_or_expired_invitation}

  @doc "Registers safe cluster metadata for the certificate/status admin page."
  def register_cluster(%Operator{} = operator, attrs) when is_map(attrs) do
    register_cluster(operator, operator.organization_id, attrs)
  end

  def register_cluster(_operator, _attrs), do: {:error, :unauthenticated}

  def register_cluster(%Operator{} = operator, organization_id, attrs)
      when is_binary(organization_id) and is_map(attrs) do
    with :ok <- authorize_admin(operator, organization_id),
         {:ok, name} <- required_string(attrs, "name") do
      cluster = %AdminCluster{
        id: string_or_default(attrs, "id", identifier()),
        organization_id: organization_id,
        name: name,
        status:
          valid_cluster_status(Map.get(attrs, "status", Map.get(attrs, :status, :disconnected))),
        certificate_status:
          valid_certificate_status(
            Map.get(attrs, "certificate_status", Map.get(attrs, :certificate_status, :active))
          ),
        certificate_serial: safe_string(attrs, "certificate_serial"),
        certificate_fingerprint: safe_string(attrs, "certificate_fingerprint"),
        certificate_expires_at: datetime(attrs, "certificate_expires_at"),
        labels: safe_labels(attrs),
        revoked_at: nil,
        last_seen_at: datetime(attrs, "last_seen_at")
      }

      put(:cluster, cluster.id, cluster)
      {:ok, cluster}
    end
  end

  def register_cluster(_operator, _organization_id, _attrs), do: {:error, :unauthenticated}

  @doc "Lists clusters without exposing certificates, CSRs, or private keys."
  def list_clusters(%Operator{} = operator) do
    list_clusters(operator, operator.organization_id)
  end

  def list_clusters(_operator), do: {:error, :unauthenticated}

  def list_clusters(%Operator{} = operator, organization_id) when is_binary(organization_id) do
    with :ok <- authorize_admin(operator, organization_id) do
      {:ok, list(:cluster, organization_id)}
    end
  end

  @doc "Requests no state change; the LiveView must call `revoke_cluster/3` only after confirmation."
  def revoke_cluster(%Operator{} = operator, organization_id, cluster_id)
      when is_binary(organization_id) and is_binary(cluster_id) do
    with :ok <- authorize_admin(operator, organization_id),
         {:ok, cluster} <- fetch_scoped(:cluster, organization_id, cluster_id),
         false <- cluster.certificate_status == :revoked do
      now = DateTime.utc_now()
      revoked = %{cluster | certificate_status: :revoked, status: :disconnected, revoked_at: now}
      put(:cluster, cluster.id, revoked)
      action = record_action(operator, organization_id, "cluster.revoked", cluster.id)
      {:ok, revoked, action}
    else
      true -> {:error, :already_revoked}
      {:error, _reason} = error -> error
    end
  end

  def revoke_cluster(_operator, _organization_id, _cluster_id), do: {:error, :unauthenticated}

  @doc "Returns auditable administrative actions in organization order."
  def list_admin_actions(%Operator{} = operator) do
    list_admin_actions(operator, operator.organization_id)
  end

  def list_admin_actions(_operator), do: {:error, :unauthenticated}

  def list_admin_actions(%Operator{} = operator, organization_id)
      when is_binary(organization_id) do
    with :ok <- authorize_admin(operator, organization_id) do
      {:ok, list(:action, organization_id)}
    end
  end

  @doc "Adds an OIDC claim mapping after validating its role."
  def create_role_mapping(%Operator{} = operator, params) when is_map(params) do
    create_role_mapping(operator, operator.organization_id, params)
  end

  def create_role_mapping(_operator, _params), do: {:error, :unauthenticated}

  def create_role_mapping(%Operator{} = operator, organization_id, params)
      when is_binary(organization_id) and is_map(params) do
    with :ok <- authorize_admin(operator, organization_id),
         {:ok, claim} <- required_claim(params),
         {:ok, role} <- role(params) do
      mapping = %AdminRoleMapping{
        id: identifier(),
        organization_id: organization_id,
        claim: claim,
        role: role,
        inserted_at: DateTime.utc_now()
      }

      put(:role_mapping, mapping.id, mapping)
      {:ok, mapping}
    end
  end

  def create_role_mapping(_operator, _organization_id, _params), do: {:error, :unauthenticated}

  @doc "Lists role mappings only for the operator's organization."
  def list_role_mappings(%Operator{} = operator) do
    list_role_mappings(operator, operator.organization_id)
  end

  def list_role_mappings(_operator), do: {:error, :unauthenticated}

  def list_role_mappings(%Operator{} = operator, organization_id)
      when is_binary(organization_id) do
    with :ok <- authorize_admin(operator, organization_id) do
      {:ok, list(:role_mapping, organization_id)}
    end
  end

  @doc "Returns the current organization retention settings."
  def get_retention(%Operator{} = operator) do
    get_retention(operator, operator.organization_id)
  end

  def get_retention(_operator), do: {:error, :unauthenticated}

  def get_retention(%Operator{} = operator, organization_id) when is_binary(organization_id) do
    with :ok <- authorize_admin(operator, organization_id) do
      value =
        case :ets.lookup(table(), {:retention, organization_id}) do
          [{{:retention, ^organization_id}, settings}] -> settings
          [] -> default_retention(organization_id)
        end

      {:ok, value}
    end
  end

  @doc "Updates retention values while enforcing independent documented bounds."
  def update_retention(%Operator{} = operator, params) when is_map(params) do
    update_retention(operator, operator.organization_id, params)
  end

  def update_retention(_operator, _params), do: {:error, :unauthenticated}

  def update_retention(%Operator{} = operator, organization_id, params)
      when is_binary(organization_id) and is_map(params) do
    with :ok <- authorize_admin(operator, organization_id),
         {:ok, current} <- get_retention(operator, organization_id),
         {:ok, status_history_days} <-
           bounded_days(
             params,
             "status_history_days",
             current.status_history_days,
             @status_history_day_bounds
           ),
         {:ok, incident_days} <-
           bounded_days(params, "incident_days", current.incident_days, @incident_day_bounds) do
      settings = %RetentionSettings{
        organization_id: organization_id,
        status_history_days: status_history_days,
        incident_days: incident_days,
        updated_at: DateTime.utc_now()
      }

      :ets.insert(table(), {{:retention, organization_id}, settings})
      {:ok, settings}
    end
  end

  def update_retention(_operator, _organization_id, _params), do: {:error, :unauthenticated}

  @doc "Lists webhook endpoint metadata; encrypted and plaintext secrets are omitted."
  def list_webhooks(%Operator{} = operator) do
    list_webhooks(operator, operator.organization_id)
  end

  def list_webhooks(_operator), do: {:error, :unauthenticated}

  def list_webhooks(%Operator{} = operator, organization_id) when is_binary(organization_id) do
    with :ok <- authorize_admin(operator, organization_id) do
      {:ok, list(:webhook, organization_id)}
    end
  end

  @doc "Registers safe endpoint metadata for local UI/test fixtures."
  def register_webhook(%Operator{} = operator, attrs) when is_map(attrs) do
    register_webhook(operator, operator.organization_id, attrs)
  end

  def register_webhook(%Operator{} = operator, organization_id, attrs)
      when is_binary(organization_id) and is_map(attrs) do
    with :ok <- authorize_admin(operator, organization_id),
         {:ok, url} <- required_string(attrs, "url") do
      endpoint = %AdminWebhook{
        id: string_or_default(attrs, "id", identifier()),
        organization_id: organization_id,
        url: url,
        enabled: Map.get(attrs, "enabled", true),
        event_types: safe_event_types(attrs),
        created_at: datetime(attrs, "created_at") || DateTime.utc_now()
      }

      put(:webhook, endpoint.id, endpoint)
      {:ok, endpoint}
    end
  end

  def register_webhook(_operator, _organization_id, _attrs), do: {:error, :unauthenticated}

  # Public aliases keep the context easy to use from controller/API work that
  # may be introduced alongside these LiveViews.
  def role_mappings(operator), do: list_role_mappings(operator)
  def retention(operator), do: get_retention(operator)
  def webhooks(operator), do: list_webhooks(operator)

  defp authorize_admin(operator, organization_id),
    do: Authorization.authorize(operator, organization_id, :administer)

  defp table do
    case :ets.whereis(@table) do
      :undefined ->
        try do
          :ets.new(@table, [
            :named_table,
            :public,
            read_concurrency: true,
            write_concurrency: true
          ])
        catch
          :error, :already_exists -> @table
        end

      _ ->
        @table
    end
  end

  defp put(kind, id, value), do: :ets.insert(table(), {{kind, id}, value})

  defp list(kind, organization_id) do
    table()
    |> :ets.tab2list()
    |> Enum.flat_map(fn
      {{^kind, _id}, %{organization_id: ^organization_id} = value} -> [value]
      _ -> []
    end)
    |> Enum.sort_by(
      fn value ->
        value
        |> Map.get(:inserted_at, Map.get(value, :created_at, DateTime.utc_now()))
        |> DateTime.to_unix()
      end,
      :desc
    )
  end

  defp fetch_scoped(kind, organization_id, id) do
    case :ets.lookup(table(), {kind, id}) do
      [{{^kind, ^id}, %{organization_id: ^organization_id} = value}] -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  defp record_action(operator, organization_id, action_name, resource_id) do
    action = %AdminAction{
      id: identifier(),
      organization_id: organization_id,
      operator_sub: operator.sub,
      action: action_name,
      resource_id: resource_id,
      correlation_id: "corr_" <> identifier(),
      inserted_at: DateTime.utc_now()
    }

    put(:action, action.id, action)
    action
  end

  defp required_string(params, key) do
    case Map.get(params, key, Map.get(params, String.to_existing_atom(key), nil)) do
      value when is_binary(value) ->
        value = String.trim(value)
        if value == "", do: {:error, {:invalid, key}}, else: {:ok, value}

      _ ->
        {:error, {:invalid, key}}
    end
  rescue
    ArgumentError -> {:error, {:invalid, key}}
  end

  defp required_claim(params) do
    case required_string(params, "claim") do
      {:ok, claim} ->
        {:ok, claim}

      {:error, _} ->
        case required_string(params, "group") do
          {:ok, group} -> {:ok, group}
          {:error, _} -> {:error, {:invalid, "claim"}}
        end
    end
  end

  defp labels(params) do
    value = Map.get(params, "labels", Map.get(params, :labels, %{}))

    cond do
      is_map(value) and Enum.all?(value, fn {key, val} -> is_binary(key) and is_binary(val) end) ->
        {:ok, value}

      value in [nil, ""] ->
        {:ok, %{}}

      true ->
        {:error, {:invalid, "labels"}}
    end
  end

  defp safe_labels(params),
    do: if(match?({:ok, _}, labels(params)), do: elem(labels(params), 1), else: %{})

  defp invitation_expiry(params) do
    days = Map.get(params, "expires_in_days", Map.get(params, :expires_in_days, 30))

    with {:ok, days} <- positive_integer(days),
         true <- days in 1..30 do
      {:ok, DateTime.add(DateTime.utc_now(), days * 86_400, :second)}
    else
      false -> {:error, :invalid_expiration}
      {:error, _} -> {:error, :invalid_expiration}
    end
  end

  defp role(params) do
    value = Map.get(params, "role", Map.get(params, :role))

    case value do
      role when role in [:viewer, :operator, :admin] ->
        {:ok, role}

      role when is_binary(role) ->
        case String.downcase(String.trim(role)) do
          "viewer" -> {:ok, :viewer}
          "operator" -> {:ok, :operator}
          "admin" -> {:ok, :admin}
          _ -> {:error, :invalid_role}
        end

      _ ->
        {:error, :invalid_role}
    end
  end

  defp bounded_days(params, key, default, {minimum, maximum}) do
    value = Map.get(params, key, Map.get(params, String.to_existing_atom(key), default))

    with {:ok, value} <- positive_integer(value), true <- value in minimum..maximum do
      {:ok, value}
    else
      false -> {:error, {:retention_out_of_bounds, key, minimum, maximum}}
      {:error, _} -> {:error, {:retention_out_of_bounds, key, minimum, maximum}}
    end
  rescue
    ArgumentError -> {:error, {:retention_out_of_bounds, key, minimum, maximum}}
  end

  defp positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}

  defp positive_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} when integer > 0 -> {:ok, integer}
      _ -> {:error, :not_positive_integer}
    end
  end

  defp positive_integer(_value), do: {:error, :not_positive_integer}

  defp valid_cluster_status(value) when value in [:connected, :disconnected, :reconnecting],
    do: value

  defp valid_cluster_status(value) when value in ["connected", "disconnected", "reconnecting"],
    do: String.to_existing_atom(value)

  defp valid_cluster_status(_value), do: :disconnected

  defp valid_certificate_status(value) when value in [:active, :expired, :revoked, :unknown],
    do: value

  defp valid_certificate_status(value) when value in ["active", "expired", "revoked", "unknown"],
    do: String.to_existing_atom(value)

  defp valid_certificate_status(_value), do: :unknown

  defp safe_string(params, key) do
    case Map.get(params, key, Map.get(params, String.to_existing_atom(key), nil)) do
      value when is_binary(value) and byte_size(value) > 0 -> String.trim(value)
      _ -> nil
    end
  rescue
    ArgumentError -> nil
  end

  defp string_or_default(params, key, default) do
    safe_string(params, key) || default
  end

  defp datetime(params, key) do
    case Map.get(params, key, Map.get(params, String.to_existing_atom(key), nil)) do
      %DateTime{} = value ->
        value

      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> datetime
          _ -> nil
        end

      _ ->
        nil
    end
  rescue
    ArgumentError -> nil
  end

  defp safe_event_types(params) do
    case Map.get(params, "event_types", Map.get(params, :event_types, [])) do
      values when is_list(values) -> Enum.filter(values, &is_binary/1)
      _ -> []
    end
  end

  defp default_retention(organization_id) do
    %RetentionSettings{
      organization_id: organization_id,
      status_history_days: @default_status_history_days,
      incident_days: @default_incident_days,
      updated_at: nil
    }
  end

  defp identifier, do: Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
end
