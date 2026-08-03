# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Mutations.Attribution do
  @moduledoc """
  Captures the stable OIDC subject and correlation ID for any Mission Control
  mutation.

  Every mutation that changes persistent state (acknowledgement, assignment,
  approval, denial, resolution, enrollment, revocation, etc.) records an
  `Attribution` value alongside the change. This provides a complete, tamper-
  evident audit trail that is separate from the change itself.

  ## Fields

  - `:sub` — the operator's stable OIDC subject identifier. Never changes for
    a given identity-provider identity; suitable for long-term audit linkage.
  - `:display_name` — the operator's human-readable display identity at the
    time of the mutation (e.g., name or email from the OIDC token). Stored for
    readability even if the operator's display identity later changes.
  - `:organization_id` — the organization under which the mutation occurred.
  - `:correlation_id` — a unique identifier for this specific mutation event.
    Callers may supply a correlation ID that was already attached to an
    incoming request; otherwise one is generated. Correlation IDs are URL-safe
    base64 strings prefixed with `"corr_"`.
  - `:at` — the UTC timestamp at which the attribution was captured.

  ## Usage

  ```elixir
  attr = Attribution.build(operator)
  # or, to propagate an existing correlation ID:
  attr = Attribution.build(operator, incoming_correlation_id)

  MyRepo.insert!(%AuditEntry{
    action: :approve,
    attribution_sub: attr.sub,
    attribution_display_name: attr.display_name,
    attribution_organization_id: attr.organization_id,
    attribution_correlation_id: attr.correlation_id,
    attribution_at: attr.at,
    ...
  })
  ```
  """

  @enforce_keys [:sub, :organization_id, :correlation_id, :at]
  defstruct [:sub, :display_name, :organization_id, :correlation_id, :at]

  @type t :: %__MODULE__{
          sub: String.t(),
          display_name: String.t() | nil,
          organization_id: String.t(),
          correlation_id: String.t(),
          at: DateTime.t()
        }

  @doc """
  Builds an `Attribution` for a mutation performed by `operator`.

  If `correlation_id` is provided and non-nil, it is recorded as-is.
  Otherwise a new correlation ID is generated using `:crypto.strong_rand_bytes/1`.
  """
  @spec build(Exocomp.MissionControl.Identity.Operator.t(), String.t() | nil) :: t()
  def build(operator, correlation_id \\ nil) do
    %__MODULE__{
      sub: operator.sub,
      display_name: operator.display_name,
      organization_id: operator.organization_id,
      correlation_id: correlation_id || generate_correlation_id(),
      at: DateTime.utc_now()
    }
  end

  @doc """
  Generates a new unique correlation ID.

  The format is `"corr_"` followed by 22 URL-safe base64 characters (16 bytes
  of random data), e.g. `"corr_7vBKfMNg2JQpXw3hTL5cAQ"`.
  """
  @spec generate_correlation_id() :: String.t()
  def generate_correlation_id do
    "corr_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end

  @doc """
  Returns a plain map suitable for embedding in JSON audit payloads.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = attr) do
    %{
      "sub" => attr.sub,
      "display_name" => attr.display_name,
      "organization_id" => attr.organization_id,
      "correlation_id" => attr.correlation_id,
      "at" => DateTime.to_iso8601(attr.at)
    }
  end
end
