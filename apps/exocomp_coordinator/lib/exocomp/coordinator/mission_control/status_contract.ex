# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.StatusEvent do
  @moduledoc "Coordinator-facing facade for the shared Mission Control status contract."

  alias Exocomp.MissionControl.StatusEvent, as: Shared

  defdelegate schema_version(), to: Shared
  defdelegate current_schema_version(), to: Shared
  defdelegate kinds(), to: Shared
  defdelegate valid_kinds(), to: Shared
  defdelegate max_event_bytes(), to: Shared
  defdelegate new(attrs), to: Shared
  defdelegate new(attrs, opts), to: Shared
  defdelegate validate(attrs), to: Shared
  defdelegate validate(attrs, opts), to: Shared
  defdelegate encode(event), to: Shared
  defdelegate encode_json(event), to: Shared
  defdelegate decode(attrs), to: Shared
  defdelegate decode(attrs, opts), to: Shared
  defdelegate decode_json(json), to: Shared
  defdelegate decode_json(json, opts), to: Shared
  defdelegate redact(value), to: Shared
end

defmodule Exocomp.Coordinator.MissionControl.StatusReducer do
  @moduledoc "Coordinator-facing facade for deterministic status replay."

  alias Exocomp.MissionControl.StatusReducer, as: Shared

  defdelegate new(), to: Shared
  defdelegate apply_event(state, event), to: Shared
  defdelegate apply(state, event), to: Shared
  defdelegate apply_all(state, events), to: Shared
  defdelegate current(state), to: Shared
  defdelegate events(state), to: Shared
  defdelegate last_sequence(state), to: Shared
  defdelegate size(state), to: Shared
end
