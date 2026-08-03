# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints.Policy do
  @moduledoc """
  Fail-closed SSRF policy for webhook destinations.

  Every A and AAAA answer is checked before an endpoint is stored. A hostname
  with even one prohibited answer is rejected, preventing a round-robin name
  from bypassing the policy. Delivery code must repeat this check immediately
  before connecting to defend against DNS rebinding; delivery is deliberately
  outside this configuration context.

  The following options are read from this module's application configuration:

  - `:deny_private_ips`, `:deny_loopback`, `:deny_link_local` (all default
    to `true`)
  - `:blocked_domains` — exact names or `*.suffix` wildcard suffixes
  - `:blocked_ips` — IP literals or CIDR ranges

  Invalid policy configuration fails closed instead of silently weakening the
  destination filter.
  """

  @type reason ::
          :invalid_host
          | :dns_resolution_failed
          | :invalid_policy_configuration
          | :destination_is_loopback
          | :destination_is_link_local
          | :destination_is_private_ip
          | :destination_is_reserved_ip
          | :destination_blocked_by_policy

  import Bitwise

  @doc "Validates a destination URL against the configured outbound policy."
  @spec validate_destination(String.t()) :: {:ok, String.t()} | {:error, reason()}
  def validate_destination(url) when is_binary(url) do
    with {:ok, config} <- policy_config(),
         {:ok, host} <- extract_host(url),
         :ok <- check_blocked_domain(host, config.blocked_domains),
         {:ok, addresses} <- resolve_all(host),
         :ok <- check_addresses(addresses, config) do
      {:ok, url}
    end
  end

  def validate_destination(_url), do: {:error, :invalid_host}

  defp policy_config do
    case Application.get_env(:exocomp_mission_control, __MODULE__, []) do
      config when is_list(config) ->
        with {:ok, deny_private_ips} <- boolean_option(config, :deny_private_ips, true),
             {:ok, deny_loopback} <- boolean_option(config, :deny_loopback, true),
             {:ok, deny_link_local} <- boolean_option(config, :deny_link_local, true),
             {:ok, blocked_domains} <- string_list_option(config, :blocked_domains),
             {:ok, blocked_ips} <- string_list_option(config, :blocked_ips),
             :ok <- validate_ip_rules(blocked_ips) do
          {:ok,
           %{
             deny_private_ips: deny_private_ips,
             deny_loopback: deny_loopback,
             deny_link_local: deny_link_local,
             blocked_domains: blocked_domains,
             blocked_ips: blocked_ips
           }}
        end

      _ ->
        {:error, :invalid_policy_configuration}
    end
  end

  defp boolean_option(config, key, default) do
    case Keyword.get(config, key, default) do
      value when is_boolean(value) -> {:ok, value}
      _ -> {:error, :invalid_policy_configuration}
    end
  end

  defp string_list_option(config, key) do
    case Keyword.get(config, key, []) do
      values when is_list(values) ->
        if Enum.all?(values, &(is_binary(&1) and byte_size(String.trim(&1)) > 0)) do
          {:ok, values}
        else
          {:error, :invalid_policy_configuration}
        end

      _ ->
        {:error, :invalid_policy_configuration}
    end
  end

  defp extract_host(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) and byte_size(host) > 0 ->
        host =
          host
          |> String.trim_leading("[")
          |> String.trim_trailing("]")
          |> String.trim_trailing(".")
          |> String.downcase()

        if host == "", do: {:error, :invalid_host}, else: {:ok, host}

      _ ->
        {:error, :invalid_host}
    end
  end

  defp check_blocked_domain(host, blocked_domains) do
    if Enum.any?(blocked_domains, &domain_match?(host, &1)) do
      {:error, :destination_blocked_by_policy}
    else
      :ok
    end
  end

  defp domain_match?(host, pattern) do
    pattern = pattern |> String.trim_trailing(".") |> String.downcase()

    case pattern do
      <<"*.", suffix::binary>> when byte_size(suffix) > 0 ->
        host != suffix and String.ends_with?(host, "." <> suffix)

      _ ->
        host == pattern
    end
  end

  defp resolve_all(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, address} -> {:ok, [address]}
      {:error, _reason} -> resolve_hostname(host)
    end
  end

  defp resolve_hostname(host) do
    results =
      for family <- [:inet, :inet6] do
        :inet.getaddrs(String.to_charlist(host), family)
      end

    case Enum.find(results, &temporary_dns_error?/1) do
      nil ->
        addresses =
          results
          |> Enum.flat_map(fn
            {:ok, values} -> values
            {:error, :nxdomain} -> []
          end)
          |> Enum.uniq()

        if addresses == [], do: {:error, :dns_resolution_failed}, else: {:ok, addresses}

      _error ->
        {:error, :dns_resolution_failed}
    end
  end

  defp temporary_dns_error?({:ok, _addresses}), do: false
  defp temporary_dns_error?({:error, :nxdomain}), do: false
  defp temporary_dns_error?(_result), do: true

  defp check_addresses(addresses, config) do
    Enum.reduce_while(addresses, :ok, fn address, :ok ->
      case check_address(address, config) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp check_address(address, config) do
    cond do
      blocked_ip?(address, config.blocked_ips) ->
        {:error, :destination_blocked_by_policy}

      config.deny_loopback and loopback?(address) ->
        {:error, :destination_is_loopback}

      config.deny_link_local and link_local?(address) ->
        {:error, :destination_is_link_local}

      config.deny_private_ips and private?(address) ->
        {:error, :destination_is_private_ip}

      reserved?(address) ->
        {:error, :destination_is_reserved_ip}

      true ->
        :ok
    end
  end

  defp loopback?({127, _, _, _}), do: true
  defp loopback?({0, 0, 0, 0, 0, 0, 0, 1}), do: true
  defp loopback?(address), do: ipv4_mapped?(address, &loopback?/1)

  defp link_local?({169, 254, _, _}), do: true
  defp link_local?({first, _, _, _, _, _, _, _}) when first in 0xFE80..0xFEBF, do: true
  defp link_local?(address), do: ipv4_mapped?(address, &link_local?/1)

  defp private?({10, _, _, _}), do: true
  defp private?({172, second, _, _}) when second in 16..31, do: true
  defp private?({192, 168, _, _}), do: true
  defp private?({first, _, _, _, _, _, _, _}) when first in 0xFC00..0xFDFF, do: true
  defp private?(address), do: ipv4_mapped?(address, &private?/1)

  # Non-public destinations remain prohibited even if a legacy policy disables
  # one of the three configurable RFC ranges.
  defp reserved?({0, 0, 0, 0}), do: true
  defp reserved?({100, second, _, _}) when second in 64..127, do: true
  defp reserved?({192, 0, 0, _}), do: true
  defp reserved?({192, 0, 2, _}), do: true
  defp reserved?({198, second, _, _}) when second in [18, 19], do: true
  defp reserved?({198, 51, 100, _}), do: true
  defp reserved?({203, 0, 113, _}), do: true
  defp reserved?({first, _, _, _}) when first >= 224, do: true
  defp reserved?({0, 0, 0, 0, 0, 0, 0, 0}), do: true
  defp reserved?({first, _, _, _, _, _, _, _}) when first >= 0xFF00, do: true
  defp reserved?(address), do: ipv4_mapped?(address, &reserved?/1)

  defp ipv4_mapped?({0, 0, 0, 0, 0, 0xFFFF, high, low}, checker) do
    checker.({high >>> 8, high &&& 0xFF, low >>> 8, low &&& 0xFF})
  end

  defp ipv4_mapped?(_address, _checker), do: false

  defp blocked_ip?(address, blocked_ips) do
    Enum.any?(blocked_ips, fn rule ->
      case parse_ip_rule(rule) do
        {:ok, blocked_address, prefix} -> cidr_match?(address, blocked_address, prefix)
        :error -> false
      end
    end)
  end

  defp validate_ip_rules(rules) do
    if Enum.all?(rules, &match?({:ok, _, _}, parse_ip_rule(&1))) do
      :ok
    else
      {:error, :invalid_policy_configuration}
    end
  end

  defp parse_ip_rule(rule) do
    case String.split(rule, "/", parts: 2) do
      [address] -> parse_ip_rule(address, nil)
      [address, prefix] -> parse_ip_rule(address, prefix)
    end
  end

  defp parse_ip_rule(address, prefix) do
    with {:ok, parsed_address} <- :inet.parse_address(String.to_charlist(address)),
         {:ok, parsed_prefix} <- parse_prefix(prefix, tuple_size(parsed_address) * 8) do
      {:ok, parsed_address, parsed_prefix}
    else
      _ -> :error
    end
  end

  defp parse_prefix(nil, bits), do: {:ok, bits}

  defp parse_prefix(prefix, bits) do
    case Integer.parse(prefix) do
      {value, ""} when value >= 0 and value <= bits -> {:ok, value}
      _ -> :error
    end
  end

  defp cidr_match?(address, blocked_address, prefix)
       when tuple_size(address) == tuple_size(blocked_address) do
    bits = tuple_size(address) * 8
    shift = bits - prefix
    bsr(to_integer(address), shift) == bsr(to_integer(blocked_address), shift)
  end

  defp cidr_match?(_address, _blocked_address, _prefix), do: false

  defp to_integer(address) do
    address
    |> Tuple.to_list()
    |> Enum.reduce(0, fn part, acc -> Bitwise.bsl(acc, tuple_component_bits(address)) + part end)
  end

  defp tuple_component_bits(address) when tuple_size(address) == 4, do: 8
  defp tuple_component_bits(address) when tuple_size(address) == 8, do: 16
end