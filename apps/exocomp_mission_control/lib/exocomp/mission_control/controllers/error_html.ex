# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ErrorHTML do
  @moduledoc false

  use Phoenix.Component

  attr(:message, :string, default: "Login required")

  def render("401.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50" role="main">
      <div class="text-center max-w-md mx-auto px-4">
        <div class="mb-4" aria-hidden="true">
          <span class="text-6xl">🔒</span>
        </div>
        <h1 class="text-4xl font-bold text-gray-900" id="error-title">Unauthorized</h1>
        <p class="text-gray-600 mt-2" id="error-description"><%= @message %></p>
        <a href="/auth/login" 
           class="mt-6 inline-block px-6 py-3 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium transition-colors"
           aria-label="Login to Mission Control">
          Login to Mission Control
        </a>
      </div>
    </div>
    """
  end

  def render("403.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50" role="main">
      <div class="text-center max-w-md mx-auto px-4">
        <div class="mb-4" aria-hidden="true">
          <span class="text-6xl">🚫</span>
        </div>
        <h1 class="text-4xl font-bold text-gray-900" id="error-title">Forbidden</h1>
        <p class="text-gray-600 mt-2" id="error-description">
          You don't have permission to access this resource. 
          Your current role is insufficient for this action.
        </p>
        <div class="mt-6">
          <a href="/" 
             class="inline-block px-6 py-3 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium transition-colors"
             aria-label="Return to dashboard">
            Back to Dashboard
          </a>
          <a href="/auth/logout" 
             class="ml-3 inline-block px-6 py-3 bg-gray-300 text-gray-900 rounded hover:bg-gray-400 font-medium transition-colors"
             aria-label="Logout">
            Logout
          </a>
        </div>
      </div>
    </div>
    """
  end

  attr(:reason, :string, default: "An error occurred")

  def render("500.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50" role="main">
      <div class="text-center max-w-md mx-auto px-4">
        <div class="mb-4" aria-hidden="true">
          <span class="text-6xl">⚠️</span>
        </div>
        <h1 class="text-4xl font-bold text-gray-900" id="error-title">Server Error</h1>
        <p class="text-gray-600 mt-2" id="error-description">
          Something went wrong on our end. Please try again later.
        </p>
        <% if @reason do %>
          <p class="text-gray-500 text-sm mt-3">
            Technical details: <%= @reason %>
          </p>
        <% end %>
        <a href="/" 
           class="mt-6 inline-block px-6 py-3 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium transition-colors"
           aria-label="Return to dashboard">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end

  def render("404.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50" role="main">
      <div class="text-center max-w-md mx-auto px-4">
        <div class="mb-4" aria-hidden="true">
          <span class="text-6xl">🔍</span>
        </div>
        <h1 class="text-4xl font-bold text-gray-900" id="error-title">Page Not Found</h1>
        <p class="text-gray-600 mt-2" id="error-description">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <a href="/" 
           class="mt-6 inline-block px-6 py-3 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium transition-colors"
           aria-label="Return to dashboard">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end

  def render(_template, assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900">Error</h1>
        <p class="text-gray-600 mt-2">An error occurred</p>
        <a href="/" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end
end
