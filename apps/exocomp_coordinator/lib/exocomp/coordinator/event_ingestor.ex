# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.EventIngestor do
  @moduledoc "Convenience alias for the cluster event ingestion boundary."

  alias Exocomp.Coordinator.ClusterEventIngestor

  defdelegate start_link(opts), to: ClusterEventIngestor
  defdelegate ingest(envelope, identity, server \\ ClusterEventIngestor), to: ClusterEventIngestor
  defdelegate acknowledgement(identity, server \\ ClusterEventIngestor), to: ClusterEventIngestor
  defdelegate events(identity, server \\ ClusterEventIngestor), to: ClusterEventIngestor
  defdelegate status(server \\ ClusterEventIngestor), to: ClusterEventIngestor
end
