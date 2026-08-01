# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile do
  @moduledoc """
  Contract implemented by every cluster profile shipped by Exocomp.

  Profiles are release code, not configuration.  The registry only exposes
  modules compiled into the release, so a profile cannot be added by a local
  file, an environment variable, or a caller-supplied command.
  """

  @type id :: String.t()
  @type version :: pos_integer()
  @type node_discovery_capability :: map()
  @type typed_action :: String.t() | map()
  @type redaction_metadata :: map()

  @callback id() :: id()
  @callback version() :: version()
  @callback node_discovery_capability() :: node_discovery_capability()
  @callback expected_services(term()) :: {:ok, [term()]} | {:error, term()}
  @callback health_reduction(term()) :: term()
  @callback supported_typed_actions() :: [typed_action()]
  @callback redaction_metadata() :: redaction_metadata()

  @doc "Returns the immutable public descriptor for a shipped profile module."
  @spec descriptor(module()) :: map()
  def descriptor(profile) when is_atom(profile) do
    %{
      id: profile.id(),
      version: profile.version(),
      node_discovery_capability: profile.node_discovery_capability(),
      expected_service_derivation: "expected_services/1",
      health_reduction: "health_reduction/1",
      supported_typed_actions: profile.supported_typed_actions(),
      redaction_metadata: profile.redaction_metadata()
    }
  end
end
