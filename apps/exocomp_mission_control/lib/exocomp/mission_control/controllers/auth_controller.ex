# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuthController do
  use Phoenix.Controller

  require Logger

  alias Exocomp.MissionControl.OIDCClient

  def login(conn, _params) do
    case OIDCClient.create_authorization_request() do
      {:ok, auth_url, state, nonce, code_verifier} ->
        conn
        |> put_session(:oidc_state, state)
        |> put_session(:oidc_nonce, nonce)
        |> put_session(:oidc_code_verifier, code_verifier)
        |> redirect(external: auth_url)

      {:error, _reason} ->
        Logger.error("Failed to create OIDC authorization request")

        conn
        |> put_status(:internal_server_error)
        |> put_view(Exocomp.MissionControl.ErrorHTML)
        |> put_layout(false)
        |> render("500.html", reason: "OIDC login is unavailable")
    end
  end

  def callback(conn, params) do
    with :ok <- validate_state(params["state"], get_session(conn, :oidc_state)),
         :ok <- handle_provider_error(params),
         {:ok, code} <- required_param(params, "code"),
         {:ok, nonce} <- required_session(conn, :oidc_nonce),
         {:ok, code_verifier} <- required_session(conn, :oidc_code_verifier),
         {:ok, tokens} <- OIDCClient.exchange_code_for_token(code, code_verifier),
         {:ok, claims} <- OIDCClient.validate_and_extract_claims(tokens, nonce) do
      complete_login(conn, claims)
    else
      {:error, :provider_denied} -> handle_callback_error(conn, "Login denied")
      {:error, _reason} -> handle_callback_error(conn, "Login could not be completed")
    end
  end

  def logout(conn, _params) do
    logout_url = OIDCClient.get_end_session_url(get_session(conn, :oidc_issuer))
    conn = clear_session(conn)

    case logout_url do
      {:ok, url} -> redirect(conn, external: url)
      {:error, _reason} -> redirect(conn, to: "/auth/login")
    end
  end

  defp complete_login(conn, claims) do
    conn
    |> delete_session(:oidc_state)
    |> delete_session(:oidc_nonce)
    |> delete_session(:oidc_code_verifier)
    |> configure_session(renew: true)
    |> put_session(:operator_id, claims.subject)
    |> put_session(:operator_email, claims.email)
    |> put_session(:operator_name, claims.name)
    |> put_session(:oidc_issuer, claims.issuer)
    |> put_session(:login_at, DateTime.utc_now())
    |> redirect(to: "/")
  end

  defp validate_state(state, stored_state)
       when is_binary(state) and is_binary(stored_state) do
    if Plug.Crypto.secure_compare(state, stored_state), do: :ok, else: {:error, :state_mismatch}
  end

  defp validate_state(_, _), do: {:error, :state_missing}

  defp handle_provider_error(%{"error" => _error}) do
    Logger.warning("OIDC provider denied login")
    {:error, :provider_denied}
  end

  defp handle_provider_error(_), do: :ok

  defp required_param(params, key) do
    case params[key] do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, {:missing_parameter, key}}
    end
  end

  defp required_session(conn, key) do
    case get_session(conn, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, {:missing_session_value, key}}
    end
  end

  defp handle_callback_error(conn, title) do
    Logger.warning("OIDC callback rejected: #{title}")

    conn
    |> delete_session(:oidc_state)
    |> delete_session(:oidc_nonce)
    |> delete_session(:oidc_code_verifier)
    |> put_session(:login_error, title)
    |> put_status(:unauthorized)
    |> put_view(Exocomp.MissionControl.ErrorHTML)
    |> put_layout(false)
    |> render("401.html", message: title)
  end
end
