# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterChatClientTest do
  @moduledoc """
  Unit tests for `Exocomp.Coordinator.ClusterChatClient`.

  Tests the request building, response parsing, and schema validation pipeline.
  """

  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.ClusterChatClient

  setup do
    # Clear any existing inference config
    Application.delete_env(:exocomp_coordinator, :inference_base_url)
    Application.delete_env(:exocomp_coordinator, :max_context_bytes)
    Application.delete_env(:exocomp_coordinator, :max_tokens)
    Application.delete_env(:exocomp_coordinator, :inference_timeout_ms)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "returns error when inference endpoint not configured" do
    assert {:error, :inference_unavailable} =
             ClusterChatClient.chat(%{
               "message" => "test",
               "thread" => [],
               "evidence" => []
             })
  end

  test "returns error when inference endpoint is empty string" do
    Application.put_env(:exocomp_coordinator, :inference_base_url, "")

    assert {:error, :inference_unavailable} =
             ClusterChatClient.chat(%{
               "message" => "test",
               "thread" => [],
               "evidence" => []
             })
  end

  test "returns error when inference endpoint is nil" do
    Application.put_env(:exocomp_coordinator, :inference_base_url, nil)

    assert {:error, :inference_unavailable} =
             ClusterChatClient.chat(%{
               "message" => "test",
               "thread" => [],
               "evidence" => []
             })
  end

  # Note: Tests that actually make HTTP requests would require mocking :httpc
  # or using ExVCR. For now, we test the error paths that don't require
  # network I/O. A full integration test would use a real or stubbed
  # inference endpoint.
end
