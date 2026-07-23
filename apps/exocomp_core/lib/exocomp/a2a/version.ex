defmodule Exocomp.A2A.Version do
  @moduledoc """
  Validates A2A protocol versions and HTTP media types.
  """

  alias Exocomp.A2A.{ContentTypeNotSupportedError, UnsupportedOperationError}

  @version "1.0"
  @content_type "application/a2a+json"

  @doc "Returns the A2A protocol versions supported by this implementation."
  @spec supported_versions() :: [String.t()]
  def supported_versions, do: [@version]

  @doc "Validates the value of an `A2A-Version` request header."
  @spec check_version(term()) :: :ok | {:error, UnsupportedOperationError.t()}
  def check_version(@version), do: :ok
  def check_version(_version), do: {:error, %UnsupportedOperationError{}}

  @doc "Validates the value of a request `Content-Type` header."
  @spec parse_content_type(term()) :: :ok | {:error, ContentTypeNotSupportedError.t()}
  def parse_content_type(@content_type), do: :ok
  def parse_content_type(_content_type), do: {:error, %ContentTypeNotSupportedError{}}
end
