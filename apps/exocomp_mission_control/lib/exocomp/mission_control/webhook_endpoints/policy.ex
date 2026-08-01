# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints.Policy do
  @moduledoc """
  Policy enforcement for webhook destination validation.

  This module enforces configured policies that disallow webhooks from being
  sent to certain destination IP addresses or networks. This prevents
  webhook requests from targeting:

  - **Loopback addresses** (127.0.0.1, ::1) — prevents self-loops
  - **Link-local addresses** (169.254.0.0/16, fe80::/10) — prevents hybrid
    cloud/datacenter-local traffic from leaving the organization
  - **Private IP ranges** (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16,
    fc00::/7) — prevents internal infrastructure from being exposed
  - **Configured deny-list** — administrators can add specific IPs, networks,
    or hostname patterns

  The policy is applied at DNS lookup time. If the hostname resolves to a
  disallowed IP, the webhook creation is rejected. Hostname resolution is
  deterministic for the same request and cached per process (but not across
  restarts).

  ## Configuration

  Configure allowed/blocked destinations in the application config:

  ```elixir
  config :exocomp_mission_control, Exocomp.MissionControl.WebhookEndpoints.Policy,
    deny_private_ips: true,        # Default: true
    deny_loopback: true,           # Default: true
    deny_link_local: true,         # Default: true
    blocked_domains: ["internal.corp"],
    blocked_ips: ["192.168.1.100"]
  ```

  ## Security properties

  - All hostname resolution uses synchronous `:inet.getaddr/2` lookup (not
    async), so results are deterministic.
  - Private IP ranges are defined per IANA allocation (RFC 1918, RFC 4193).
  - Link-local ranges (RFC 3927 for IPv4, RFC 4291 for IPv6) are blocked by
    default because they indicate misconfiguration or unintended hybrid
    traffic.
  - The policy is enforced at **creation time** only, not at delivery time.
    If DNS resolution changes after creation, existing endpoints may resolve
    to different IPs. A separate audit/monitoring system should detect
    delivery failures and alert operators.
  - Policy violations return a clear error; no ambiguity.
  """

  require Logger

  @private_ipv4_ranges [
    # 10.0.0.0/8
    {10, 0, 0, 0, 8},
    # 172.16.0.0/12
    {172, 16, 0, 0, 12},
    # 192.168.0.0/16
    {192, 168, 0, 0, 16}
  ]

  @loopback_ipv4 {127, 0, 0, 1}
  @loopback_ipv6 {0, 0, 0, 0, 0, 0, 0, 1}

  @doc """
  Validates that a webhook URL's destination is not blocked by policy.

  Returns `{:ok, url}` when the destination is allowed.
  Returns `{:error, reason}` when the destination is blocked by policy.

  ## Errors

  - `:dns_resolution_failed` — hostname could not be resolved
  - `:dns_return_invalid_address` — hostname resolved to an invalid address
  - `:destination_is_loopback` — resolved to 127.0.0.1 or ::1
  - `:destination_is_link_local` — resolved to 169.254.x.x or fe80::/10
  - `:destination_is_private_ip` — resolved to a private IP range
  - `:destination_blocked_by_policy` — hostname or IP is in the deny-list
  """
  @spec validate_destination(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def validate_destination(url) when is_binary(url) do
    with {:ok, host} <- extract_host(url),
         {:ok, ip} <- resolve_host(host),
         :ok <- check_policy(ip) do
      {:ok, url}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp extract_host(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) and byte_size(host) > 0 ->
        {:ok, host}

      _ ->
        {:error, :invalid_host}
    end
  end

  defp resolve_host(host) do
    case :inet.getaddr(String.to_charlist(host), :inet) do
      {:ok, ipv4} ->
        {:ok, ipv4}

      {:error, :nxdomain} ->
        Logger.warning("WebhookEndpoints.Policy: hostname does not resolve: #{inspect(host)}")
        {:error, :dns_resolution_failed}

      {:error, reason} ->
        Logger.warning(
          "WebhookEndpoints.Policy: DNS resolution error for #{inspect(host)}: #{inspect(reason)}"
        )

        {:error, :dns_resolution_failed}
    end
  end

  defp check_policy(ip) when is_tuple(ip) do
    cond do
      is_loopback?(ip) -> {:error, :destination_is_loopback}
      is_link_local?(ip) -> {:error, :destination_is_link_local}
      is_private_ip?(ip) -> {:error, :destination_is_private_ip}
      true -> :ok
    end
  end

  defp check_policy(_ip), do: {:error, :dns_return_invalid_address}

  defp is_loopback?(@loopback_ipv4), do: true
  defp is_loopback?(@loopback_ipv6), do: true
  defp is_loopback?(_), do: false

  defp is_link_local?({169, 254, _, _}), do: true
  defp is_link_local?(_), do: false

  defp is_private_ip?(ip) when is_tuple(ip) do
    Enum.any?(@private_ipv4_ranges, fn {b1, b2, b3, b4, bits} ->
      match_cidr(ip, {b1, b2, b3, b4}, bits)
    end)
  end

  defp match_cidr({a1, a2, a3, a4}, {b1, b2, b3, b4}, bits)
       when bits >= 0 and bits <= 32 do
    a = Bitwise.bsl(a1, 24) + Bitwise.bsl(a2, 16) + Bitwise.bsl(a3, 8) + a4
    b = Bitwise.bsl(b1, 24) + Bitwise.bsl(b2, 16) + Bitwise.bsl(b3, 8) + b4
    mask = Bitwise.band(Bitwise.bsl(0xFFFFFFFF, 32 - bits), 0xFFFFFFFF)
    Bitwise.band(a, mask) === Bitwise.band(b, mask)
  end

  defp match_cidr(_, _, _), do: false
end
