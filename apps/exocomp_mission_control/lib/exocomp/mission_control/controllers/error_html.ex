# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ErrorHTML do
  @moduledoc false

  use Phoenix.Component

  def render("401.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900">Unauthorized</h1>
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
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900">Forbidden</h1>
        <p class="text-gray-600 mt-2">You don't have permission to access this resource.</p>
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

  def render("404.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900">404</h1>
        <p class="text-gray-600 mt-2">Page not found</p>
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
