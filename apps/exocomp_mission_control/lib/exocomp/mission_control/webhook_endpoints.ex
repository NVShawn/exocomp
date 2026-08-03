# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints do
  @moduledoc """
  Admin-only, organization-scoped webhook endpoint configuration.

  The context is the only write boundary for endpoint secrets. It generates a
  secret with cryptographic randomness, encrypts it before beginning database
  persistence, and returns plaintext only after the endpoint and its audit
  event have committed. Update and disable never read or return a plaintext
  secret; rotation replaces the ciphertext atomically and returns the new
  plaintext once.
  """

  import Ecto.Query

  import Exocomp.MissionControl.WebhookEndpoints.Validation

  alias Ecto.Multi

  alias Exocomp.MissionControl.{
    AuditEvents,
    Authorization,
    Identity.Operator,
    Mutations.Attribution,
    OrganizationScope,
    Repo,
    WebhookEndpoint,
    WebhookEndpoints.Encryption
  }

  @type result_reason ::
          :endpoint_not_found
          | :invalid_update_fields
          | :update_empty
          | :enabled_not_boolean
          | :persistence_failed
          | atom()
          | tuple()

  @doc """
  Creates an enabled endpoint and returns its generated plaintext secret once.

  The secret is never included in the endpoint schema, audit event, log, or
  error. If the transaction cannot commit, no plaintext is returned and no
  endpoint is persisted.
  """
  @spec create(Operator.t() | nil, String.t(), map(), keyword()) ::
          {:ok, WebhookEndpoint.t(), String.t()} | {:error, result_reason()}
  def create(operator, organization_id, params, opts \\ [])
      when is_binary(organization_id) and is_map(params) and is_list(opts) do
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    repo = Keyword.get(opts, :repo, Repo)
    endpoint_id = Ecto.UUID.generate()

    with {:ok, url} <- validate_url(params),
         {:ok, event_types} <- validate_event_types(params),
         {:ok, plaintext_secret} <- generate_secret(),
         {:ok, encrypted_secret, version} <-
           Encryption.encrypt(plaintext_secret, encryption_aad(organization_id, endpoint_id)) do
      attribution = Attribution.build(operator)

      endpoint_changeset =
        WebhookEndpoint.create_changeset(%WebhookEndpoint{id: endpoint_id}, %{
          organization_id: organization_id,
          url: url,
          subscribed_event_types: event_types,
          enabled: true,
          encrypted_secret: encrypted_secret,
          encrypted_secret_version: version,
          creator_operator_sub: attribution.sub,
          creator_correlation_id: attribution.correlation_id
        })

      case repo.transaction(
             endpoint_multi(:insert, endpoint_changeset, organization_id, attribution)
           ) do
        {:ok, %{endpoint: endpoint}} -> {:ok, endpoint, plaintext_secret}
        {:error, _operation, _reason, _changes} -> {:error, :persistence_failed}
      end
    end
  end

  @doc """
  Updates the URL, subscriptions, and/or enabled state of one endpoint.

  Every lookup includes the organization predicate, so an endpoint ID from a
  different organization is indistinguishable from a nonexistent ID.
  """
  @spec update(Operator.t() | nil, String.t(), String.t(), map(), keyword()) ::
          {:ok, WebhookEndpoint.t()} | {:error, result_reason()}
  def update(operator, organization_id, endpoint_id, params, opts \\ [])
      when is_binary(organization_id) and is_binary(endpoint_id) and is_map(params) and
             is_list(opts) do
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, endpoint} <- get_scoped(repo, organization_id, endpoint_id),
         {:ok, attrs} <- update_attrs(params) do
      attribution = Attribution.build(operator)
      changeset = WebhookEndpoint.update_changeset(endpoint, attrs)

      case repo.transaction(endpoint_multi(:update, changeset, organization_id, attribution)) do
        {:ok, %{endpoint: updated}} -> {:ok, updated}
        {:error, _operation, _reason, _changes} -> {:error, :persistence_failed}
      end
    end
  end

  @doc "Disables one endpoint without exposing or changing its secret."
  @spec disable(Operator.t() | nil, String.t(), String.t(), keyword()) ::
          {:ok, WebhookEndpoint.t()} | {:error, result_reason()}
  def disable(operator, organization_id, endpoint_id, opts \\ [])
      when is_binary(organization_id) and is_binary(endpoint_id) and is_list(opts) do
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, endpoint} <- get_scoped(repo, organization_id, endpoint_id) do
      attribution = Attribution.build(operator)
      changeset = WebhookEndpoint.update_changeset(endpoint, %{enabled: false})

      case repo.transaction(endpoint_multi(:disable, changeset, organization_id, attribution)) do
        {:ok, %{endpoint: disabled}} -> {:ok, disabled}
        {:error, _operation, _reason, _changes} -> {:error, :persistence_failed}
      end
    end
  end

  @doc """
  Replaces an endpoint's ciphertext and returns the new plaintext secret once.

  The old secret remains active if encryption or the accompanying transaction
  fails. This prevents an operator from being handed a secret that was not
  durably stored.
  """
  @spec rotate_secret(Operator.t() | nil, String.t(), String.t(), keyword()) ::
          {:ok, WebhookEndpoint.t(), String.t()} | {:error, result_reason()}
  def rotate_secret(operator, organization_id, endpoint_id, opts \\ [])
      when is_binary(organization_id) and is_binary(endpoint_id) and is_list(opts) do
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, endpoint} <- get_scoped(repo, organization_id, endpoint_id),
         {:ok, plaintext_secret} <- generate_secret(),
         {:ok, encrypted_secret, version} <-
           Encryption.encrypt(plaintext_secret, encryption_aad(organization_id, endpoint.id)) do
      attribution = Attribution.build(operator)
      changeset = WebhookEndpoint.secret_changeset(endpoint, encrypted_secret, version)

      case repo.transaction(
             endpoint_multi(:rotate_secret, changeset, organization_id, attribution)
           ) do
        {:ok, %{endpoint: rotated}} -> {:ok, rotated, plaintext_secret}
        {:error, _operation, _reason, _changes} -> {:error, :persistence_failed}
      end
    end
  end

  defp get_scoped(repo, organization_id, endpoint_id) do
    with {:ok, endpoint_id} <- Ecto.UUID.cast(endpoint_id),
         {:ok, organization_id} <- OrganizationScope.require_id(organization_id) do
      case WebhookEndpoint
           |> OrganizationScope.query(organization_id)
           |> where([endpoint], endpoint.id == ^endpoint_id)
           |> repo.one() do
        %WebhookEndpoint{} = endpoint -> {:ok, endpoint}
        nil -> {:error, :endpoint_not_found}
      end
    else
      _ -> {:error, :endpoint_not_found}
    end
  end

  defp endpoint_multi(action, changeset, organization_id, attribution) do
    Multi.new()
    |> endpoint_write(action, changeset)
    |> AuditEvents.put_in_multi(
      :audit,
      organization_id,
      audit_attributes(action, changeset.data, attribution)
    )
  end

  defp endpoint_write(multi, :insert, changeset), do: Multi.insert(multi, :endpoint, changeset)
  defp endpoint_write(multi, _action, changeset), do: Multi.update(multi, :endpoint, changeset)

  defp audit_attributes(action, endpoint, attribution) do
    %{
      actor_type: :operator,
      actor_sub: attribution.sub,
      actor_display_name: attribution.display_name,
      event_type: "webhook.endpoint_#{action}",
      target: %{"type" => "webhook_endpoint", "id" => endpoint.id},
      outcome: :ok,
      correlation_id: attribution.correlation_id,
      occurred_at: attribution.at
    }
  end

  defp update_attrs(params) do
    allowed = MapSet.new(["url", "subscribed_event_types", "enabled"])

    cond do
      map_size(params) == 0 ->
        {:error, :update_empty}

      Enum.any?(Map.keys(params), &(not is_binary(&1) or not MapSet.member?(allowed, &1))) ->
        {:error, :invalid_update_fields}

      true ->
        with {:ok, attrs} <- maybe_put_url(params, %{}),
             {:ok, attrs} <- maybe_put_event_types(params, attrs),
             {:ok, attrs} <- maybe_put_enabled(params, attrs) do
          {:ok, attrs}
        end
    end
  end

  defp maybe_put_url(params, attrs) do
    case Map.fetch(params, "url") do
      {:ok, _url} ->
        with {:ok, url} <- validate_url(params), do: {:ok, Map.put(attrs, :url, url)}

      :error ->
        {:ok, attrs}
    end
  end

  defp maybe_put_event_types(params, attrs) do
    case Map.fetch(params, "subscribed_event_types") do
      {:ok, _event_types} ->
        with {:ok, event_types} <- validate_event_types(params),
             do: {:ok, Map.put(attrs, :subscribed_event_types, event_types)}

      :error ->
        {:ok, attrs}
    end
  end

  defp maybe_put_enabled(params, attrs) do
    case Map.fetch(params, "enabled") do
      {:ok, enabled} when is_boolean(enabled) -> {:ok, Map.put(attrs, :enabled, enabled)}
      {:ok, _enabled} -> {:error, :enabled_not_boolean}
      :error -> {:ok, attrs}
    end
  end

  defp generate_secret do
    try do
      {:ok, :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)}
    rescue
      _exception -> {:error, :secret_generation_failed}
    end
  end

  defp encryption_aad(organization_id, endpoint_id), do: organization_id <> "\0" <> endpoint_id
end