defmodule Exocomp.A2A.ErrorTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.Error

  test "can be constructed with required fields" do
    err = %Error{code: -32700, message: "Parse error"}
    assert err.code == -32700
    assert err.message == "Parse error"
    assert err.data == nil
  end

  test "can be constructed with data" do
    err = %Error{code: -32602, message: "Invalid params", data: %{"field" => "required"}}
    assert err.data == %{"field" => "required"}
  end

  test "raises when required field code is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Error, message: "oops")
    end
  end

  test "raises when required field message is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Error, code: -32700)
    end
  end
end

defmodule Exocomp.A2A.StandardErrorsTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{
    JSONParseError,
    InvalidRequestError,
    MethodNotFoundError,
    InvalidParamsError,
    InternalError,
    TaskNotFoundError,
    TaskNotCancelableError,
    PushNotificationNotSupportedError,
    UnsupportedOperationError,
    ContentTypeNotSupportedError
  }

  test "JSONParseError has code -32700 and default message" do
    err = %JSONParseError{}
    assert err.code == -32700
    assert err.message == "Parse error"
    assert JSONParseError.code() == -32700
  end

  test "InvalidRequestError has code -32600 and default message" do
    err = %InvalidRequestError{}
    assert err.code == -32600
    assert err.message == "Invalid Request"
    assert InvalidRequestError.code() == -32600
  end

  test "MethodNotFoundError has code -32601 and default message" do
    err = %MethodNotFoundError{}
    assert err.code == -32601
    assert err.message == "Method not found"
    assert MethodNotFoundError.code() == -32601
  end

  test "InvalidParamsError has code -32602 and default message" do
    err = %InvalidParamsError{}
    assert err.code == -32602
    assert err.message == "Invalid params"
    assert InvalidParamsError.code() == -32602
  end

  test "InternalError has code -32603 and default message" do
    err = %InternalError{}
    assert err.code == -32603
    assert err.message == "Internal error"
    assert InternalError.code() == -32603
  end

  test "TaskNotFoundError has code -32001 and default message" do
    err = %TaskNotFoundError{}
    assert err.code == -32001
    assert err.message == "Task not found"
    assert TaskNotFoundError.code() == -32001
  end

  test "TaskNotCancelableError has code -32002 and default message" do
    err = %TaskNotCancelableError{}
    assert err.code == -32002
    assert err.message == "Task not cancelable"
    assert TaskNotCancelableError.code() == -32002
  end

  test "PushNotificationNotSupportedError has code -32003 and default message" do
    err = %PushNotificationNotSupportedError{}
    assert err.code == -32003
    assert err.message == "Push notification not supported"
    assert PushNotificationNotSupportedError.code() == -32003
  end

  test "UnsupportedOperationError has code -32004 and default message" do
    err = %UnsupportedOperationError{}
    assert err.code == -32004
    assert err.message == "Unsupported operation"
    assert UnsupportedOperationError.code() == -32004
  end

  test "ContentTypeNotSupportedError has code -32005 and default message" do
    err = %ContentTypeNotSupportedError{}
    assert err.code == -32005
    assert err.message == "Content type not supported"
    assert ContentTypeNotSupportedError.code() == -32005
  end

  test "all standard error types support optional data field" do
    err = %JSONParseError{data: "extra info"}
    assert err.data == "extra info"
  end
end
