# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ErrorHTML do
  @moduledoc false

  use Phoenix.Component

  def render("401.html", %{message: message} = assigns) do
    assigns = assign(assigns, :message, message)

    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="alert" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">🔒</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Unauthorized</h1>
        <p class="text-gray-600 mt-2"><%= @message %></p>
        <a href="/auth/login" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Login
        </a>
      </div>
    </div>
    """
  end

  def render("401.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="alert" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">🔒</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Unauthorized</h1>
        <p class="text-gray-600 mt-2">Login required</p>
        <a href="/auth/login" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Login
        </a>
      </div>
    </div>
    """
  end

  def render("403.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="alert" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">🚫</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Forbidden</h1>
        <p class="text-gray-600 mt-2">You don't have permission to access this resource.</p>
        <a href="/" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Back to Dashboard
        </a>
        <a href="/auth/logout" class="mt-4 ml-2 inline-block px-6 py-2 bg-gray-600 text-white rounded hover:bg-gray-700">
          Logout
        </a>
      </div>
    </div>
    """
  end

  def render("404.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="main" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">🔍</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Page Not Found</h1>
        <p class="text-gray-600 mt-2">The page you're looking for doesn't exist.</p>
        <a href="/" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end

  def render("500.html", %{reason: reason} = assigns) do
    assigns = assign(assigns, :reason, reason)

    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="alert" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">💥</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Server Error</h1>
        <p class="text-gray-600 mt-2"><%= @reason %></p>
        <a href="/" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end

  def render("500.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="alert" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">💥</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Server Error</h1>
        <p class="text-gray-600 mt-2">An error occurred while processing your request.</p>
        <a href="/" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end

  def render(_template, assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center" role="alert" aria-labelledby="error-title">
        <p class="text-6xl mb-4" aria-hidden="true">⚠️</p>
        <h1 id="error-title" class="text-4xl font-bold text-gray-900">Error</h1>
        <p class="text-gray-600 mt-2">An error occurred</p>
        <a href="/" class="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end
end
