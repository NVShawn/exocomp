# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Telemetry do
  @moduledoc "Namespaced telemetry helpers for Mission Control instrumentation."

  @prefix [:exocomp, :mission_control]

  @doc "Emits a bounded-domain event consumed by the Prometheus registry."
  @spec emit(atom(), map(), map()) :: :ok
  def emit(domain, measurements \\ %{}, metadata \\ %{})
      when domain in [
             :connection,
             :ingest,
             :incident,
             :conversation,
             :proposal,
             :command,
             :webhook,
             :database,
             :retention,
             :desired_state,
             :discovery,
             :profile,
             :ceph,
             :recovery
           ] and is_map(measurements) and is_map(metadata) do
    :telemetry.execute(@prefix ++ [domain], measurements, metadata)
    :ok
  end
end
