# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.CoordinatorRouter do
  @moduledoc """
  Top-level HTTP router for the coordinator service.

  Dispatches incoming requests to the appropriate handler based on path:

  - `POST /v1/enroll` → `EnrollmentHandler` (Bearer token, no mTLS required)
  - `POST /v1/renew` → `RenewalHandler` (mTLS client certificate required)
  - `POST /api/v1/cluster-invitations` → `ClusterInvitationHandler`
    (OIDC-authenticated admin required)
  - `POST /api/v1/clusters/enroll` → `ClusterEnrollmentHandler` (Cluster invitation, no mTLS required)
  - All other paths → `A2ARouter` (mTLS required, A2A version header required)

  The coordinator listener uses `fail_if_no_peer_cert: false` so that
  enrollment connections (nodes and clusters without certificates) can reach the
  enrollment handlers. The mTLS requirement for A2A routes is enforced
  inside `A2ARouter` via the `authenticate_mtls` plug.
  """

  @behaviour Plug

  alias Exocomp.Coordinator.A2ARouter

  alias Exocomp.Coordinator.Handlers.{
    ClusterInvitationHandler,
    ClusterEnrollmentHandler,
    EnrollmentHandler,
    RenewalHandler
  }

  @impl true
  def init(opts), do: A2ARouter.init(opts)

  @impl true
  def call(%Plug.Conn{method: "POST", path_info: ["v1", "enroll"]} = conn, _opts) do
    EnrollmentHandler.call(conn, EnrollmentHandler.init([]))
  end

  def call(%Plug.Conn{method: "POST", path_info: ["v1", "renew"]} = conn, _opts) do
    RenewalHandler.call(conn, RenewalHandler.init([]))
  end

  def call(
        %Plug.Conn{method: "POST", path_info: ["api", "v1", "cluster-invitations"]} = conn,
        opts
      ) do
    ClusterInvitationHandler.call(conn, ClusterInvitationHandler.init(router_opts(opts)))
  end

  def call(
        %Plug.Conn{method: "POST", path_info: ["api", "v1", "clusters", "enroll"]} = conn,
        opts
      ) do
    ClusterEnrollmentHandler.call(conn, ClusterEnrollmentHandler.init(router_opts(opts)))
  end

  def call(conn, opts) do
    A2ARouter.call(conn, opts)
  end

  defp router_opts(opts) when is_list(opts), do: opts
  defp router_opts({_, opts}) when is_list(opts), do: opts
  defp router_opts(%{router_opts: opts}) when is_list(opts), do: opts
  defp router_opts(_opts), do: []
end
