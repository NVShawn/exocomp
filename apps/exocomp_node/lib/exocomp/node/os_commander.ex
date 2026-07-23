defmodule Exocomp.Node.OsCommander do
  @moduledoc """
  Behaviour for running OS subprocesses.

  The behaviour exists so that the `Executor` module can delegate all process
  invocation to an injectable implementation.  In production the
  `Exocomp.Node.SystemCommander` module is used; in tests a mock can be
  configured via application environment.

  ## Security contract

  Implementations MUST:
  - Accept an explicit `argv` list — never expand the list through a shell.
  - Honour the `timeout_ms` option and return `{:error, :timeout}` when it
    elapses, killing the subprocess.
  - Honour the `output_limit_bytes` option and return
    `{:error, {:output_limit_exceeded, actual_bytes}}` when the captured
    output exceeds the limit.
  - Never add caller-supplied strings to the environment; the `env` option
    contains only the fixed list provided by the action definition.
  """

  @type run_opts :: [
          env: [{String.t(), String.t()}],
          timeout_ms: pos_integer(),
          output_limit_bytes: pos_integer()
        ]

  @type run_result ::
          {:ok, output :: binary(), exit_code :: non_neg_integer()}
          | {:error, :timeout}
          | {:error, {:output_limit_exceeded, actual_bytes :: pos_integer()}}
          | {:error, term()}

  @doc """
  Execute `executable` with the given `argv` list and `opts`.

  `executable` must be an absolute path.  `argv` must be a list of strings.
  No shell is involved; no glob expansion, variable substitution, or
  metacharacter interpretation takes place.
  """
  @callback run(executable :: String.t(), argv :: [String.t()], opts :: run_opts()) ::
              run_result()
end

defmodule Exocomp.Node.SystemCommander do
  @moduledoc """
  Production `OsCommander` implementation using `System.cmd/3`.

  Uses an explicit argv list — no shell expansion.  Enforces timeout via
  `Task.yield/2` and hard-kills the subprocess on timeout or output overflow.
  """

  @behaviour Exocomp.Node.OsCommander

  @impl true
  def run(executable, argv, opts) when is_binary(executable) and is_list(argv) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 30_000)
    output_limit = Keyword.get(opts, :output_limit_bytes, 65_536)
    env = Keyword.get(opts, :env, [])

    task =
      Task.async(fn ->
        System.cmd(executable, argv,
          env: env,
          stderr_to_stdout: true
        )
      end)

    case Task.yield(task, timeout_ms) do
      {:ok, {output, exit_code}} ->
        actual = byte_size(output)

        if actual > output_limit do
          {:error, {:output_limit_exceeded, actual}}
        else
          {:ok, output, exit_code}
        end

      nil ->
        Task.shutdown(task, :brutal_kill)
        {:error, :timeout}
    end
  end
end
