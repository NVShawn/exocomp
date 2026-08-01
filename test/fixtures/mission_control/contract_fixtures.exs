# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ContractFixtures do
  @moduledoc """
  Loader and mutation helpers for the shared Mission Control contract corpus.

  This file intentionally lives beside the JSON rather than in either
  application. Both application test suites require it, so a fixture change
  cannot silently update only one protocol peer.
  """

  @fixture_dir Path.expand(__DIR__)

  def manifest, do: fixture!("contract_manifest.json")

  def fixture!(name) do
    path = Path.join(@fixture_dir, name)

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, value} -> value
          {:error, reason} -> raise "invalid Mission Control fixture #{name}: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise "missing Mission Control fixture #{name}: #{inspect(reason)}"
    end
  end

  def envelope_fixtures(type) do
    manifest()
    |> get_in(["envelopes", type, "fixture_file"])
    |> fixture!()
  end

  def status_fixtures do
    Enum.map(manifest()["status_event_fixtures"], &fixture!/1)
  end

  def assert_shape!(value, allowed_fields, label) when is_map(value) do
    actual = value |> Map.keys() |> Enum.sort()
    allowed = Enum.sort(allowed_fields)
    unexpected = actual -- allowed

    if unexpected != [] do
      raise ExUnit.AssertionError,
        message:
          "Mission Control fixture drift at #{label}: unexpected field(s) #{inspect(unexpected)}"
    end

    :ok
  end

  def assert_required_fields!(value, required_fields, label) when is_map(value) do
    missing = required_fields -- Map.keys(value)

    if missing != [] do
      raise ExUnit.AssertionError,
        message:
          "Mission Control fixture drift at #{label}: required field(s) #{inspect(missing)}"
    end

    :ok
  end

  def mutate(value, %{"op" => "delete", "field" => field}), do: Map.delete(value, field)

  def mutate(value, %{"op" => "put", "field" => field, "value" => replacement}),
    do: Map.put(value, field, replacement)

  def mutate(value, %{"op" => "oversize_payload"}) do
    Map.put(value, "payload", %{"blob" => String.duplicate("x", 102_401)})
  end

  def expected_reason!(result, expected, label) do
    case result do
      {:error, reason} ->
        actual = reason_name(reason)

        if actual != expected do
          raise ExUnit.AssertionError,
            message:
              "Mission Control contract failure at #{label}: expected #{expected}, got #{inspect(reason)}"
        end

        :ok

      other ->
        raise ExUnit.AssertionError,
          message:
            "Mission Control contract failure at #{label}: expected #{expected}, got #{inspect(other)}"
    end
  end

  defp reason_name(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp reason_name({reason, _value}) when is_atom(reason), do: Atom.to_string(reason)
  defp reason_name({reason, _field, _value}) when is_atom(reason), do: Atom.to_string(reason)
  defp reason_name(reason), do: inspect(reason)
end
