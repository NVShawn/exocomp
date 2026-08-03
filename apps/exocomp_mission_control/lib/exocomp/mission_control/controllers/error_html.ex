# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ErrorHTML do
  def render("401.html", assigns) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Unauthorized</title>
        <style>
          body { font-family: sans-serif; margin: 2rem; }
          .error-box { border: 1px solid #ccc; padding: 1rem; margin: 1rem 0; }
          h1 { color: #d00; }
          a { color: #00d; }
        </style>
      </head>
      <body>
        <div class="error-box">
          <h1>Unauthorized (401)</h1>
          <p>#{assigns.message}</p>
          <p><a href="/auth/login">Try logging in again</a></p>
        </div>
      </body>
    </html>
    """
  end

  def render("500.html", _assigns) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Server Error</title>
        <style>
          body { font-family: sans-serif; margin: 2rem; }
          .error-box { border: 1px solid #ccc; padding: 1rem; margin: 1rem 0; }
          h1 { color: #d00; }
          a { color: #00d; }
        </style>
      </head>
      <body>
        <div class="error-box">
          <h1>Internal Server Error (500)</h1>
          <p>An error occurred while processing your request.</p>
          <p><a href="/">Return home</a></p>
        </div>
      </body>
    </html>
    """
  end
end
