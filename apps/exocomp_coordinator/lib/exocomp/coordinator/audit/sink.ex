defmodule Exocomp.Coordinator.Audit.Sink do
  @moduledoc false

  @callback init(keyword()) :: {:ok, term()} | {:error, term()}
  @callback write(term(), map()) :: {:ok, term()} | {:error, term()}
  @callback close(term()) :: :ok
end
