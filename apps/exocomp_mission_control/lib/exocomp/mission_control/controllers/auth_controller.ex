# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuthController do
  use Phoenix.Controller
  require Logger

  alias Exocomp.MissionControl.OIDCClient

  def login(conn, _params) do
    case OIDCClient.create_authorization_request() do
      {:ok, auth_url, state, nonce} ->
        conn
        |> put_session(:oidc_state, state)
        |> put_session(:oidc_nonce, nonce)
        |> redirect(external: auth_url)

      {:error, reason} ->
        Logger.error("Failed to create authorization request: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> put_view(html: Exocomp.MissionControl.ErrorHTML)
        |> render("500.html", reason: reason)
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    stored_state = get_session(conn, :oidc_state)
    stored_nonce = get_session(conn, :oidc_nonce)

    # Validate state parameter
    case validate_state(state, stored_state) do
      :ok ->
        # Exchange code for tokens
        case OIDCClient.exchange_code_for_token(code) do
          {:ok, tokens} ->
            # Validate ID token and extract claims
            case OIDCClient.validate_and_extract_claims(tokens, stored_nonce) do
              {:ok, claims} ->
                # Store user session
                conn
                |> delete_session(:oidc_state)
                |> delete_session(:oidc_nonce)
                |> renew_session()
                |> put_session(:operator_id, claims.subject)
                |> put_session(:operator_email, claims.email)
                |> put_session(:operator_name, claims.name)
                |> put_session(:oidc_issuer, claims.issuer)
                |> put_session(:login_at, DateTime.utc_now())
                |> redirect(to: "/")

              {:error, reason} ->
                Logger.error("Failed to validate ID token: #{inspect(reason)}")
                handle_callback_error(conn, "Token validation failed", reason)
            end

          {:error, reason} ->
            Logger.error("Failed to exchange code for tokens: #{inspect(reason)}")
            handle_callback_error(conn, "Token exchange failed", reason)
        end

      {:error, reason} ->
        Logger.error("State validation failed: #{inspect(reason)}")
        handle_callback_error(conn, "Invalid state parameter", reason)
    end
  end

  def callback(conn, %{"error" => error, "error_description" => description}) do
    Logger.warning("OIDC provider returned error: #{error} - #{description}")
    handle_callback_error(conn, "Login denied", "#{error}: #{description}")
  end

  def callback(conn, %{"error" => error}) do
    Logger.warning("OIDC provider returned error: #{error}")
    handle_callback_error(conn, "Login denied", error)
  end

  def callback(conn, _params) do
    Logger.error("Invalid callback parameters")
    handle_callback_error(conn, "Invalid callback", "Missing required parameters")
  end

  def logout(conn, _params) do
    case OIDCClient.get_end_session_url(get_session(conn, :oidc_issuer)) do
      {:ok, logout_url} ->
        conn
        |> clear_session()
        |> redirect(external: logout_url)

      {:error, _reason} ->
        # If we can't get the logout URL, just clear the session locally
        conn
        |> clear_session()
        |> redirect(to: "/login")
    end
  end

  # Private functions

  defp validate_state(state, stored_state) when is_binary(state) and is_binary(stored_state) do
    case Plug.Crypto.secure_compare(state, stored_state) do
      true -> :ok
      false -> {:error, "State mismatch"}
    end
  end

  defp validate_state(state, stored_state) do
    {:error, "Invalid state parameters: #{inspect({state, stored_state})}"}
  end

  defp renew_session(conn) do
    # Regenerate session ID to prevent session fixation attacks
    conn
    |> configure_session(renew: true)
  end

  defp handle_callback_error(conn, title, reason) do
    conn
    |> put_session(:login_error, title)
    |> put_status(:unauthorized)
    |> put_view(html: Exocomp.MissionControl.ErrorHTML)
    |> render("401.html", message: "#{title}: #{inspect(reason)}")
  end
end
