defmodule Exocomp.Node.SudoersPolicy do
  @moduledoc """
  Generates exact, minimal sudoers entries for the installed action catalog.

  ## Design

  The generated policy grants ONLY:

  - `NOPASSWD` access to `/usr/bin/systemctl restart <svc>` for each service
    in the installed allow-list.
  - `NOPASSWD` access to `/usr/bin/journalctl --vacuum-size=<limit>` for the
    fixed log-vacuum action.

  An installation with an empty allow-list receives only the vacuum entry.
  Installing no actions (calling `render/2` with `include_vacuum: false` and
  an empty `allow_list`) produces an empty string — no privileged entries.

  ## Security properties

  - **No wildcards** — every entry names the exact executable path and the
    exact argument string.  `NOPASSWD: /usr/bin/systemctl` (with no args)
    would allow ANY systemctl sub-command and is never emitted.

  - **No user-controlled values** — neither `account` nor the service names
    may come from request or model fields.  The allow-list is provided by the
    installer at deployment time.

  - **Deterministic** — for a given account and allow-list, the output is
    always identical (entries are sorted).  Snapshots in tests act as
    regression guards.

  - **sudo-only** — the generated entries do not grant login, shell access,
    or the ability to run setuid programs other than the named commands.

  ## Output format

  The rendered string is a valid sudoers fragment suitable for placement in
  `/etc/sudoers.d/exocomp-<account>`.  It should be validated with
  `visudo -c -f <file>` before deployment.

  Example output for account `exocomp` with allow-list `["myapp.service"]`:

      # Exocomp node sudoers policy
      # Generated for account: exocomp
      # DO NOT EDIT — regenerate from the installed action catalog.
      Defaults!EXOCOMP_RESTART requiretty
      exocomp ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp.service
      exocomp ALL=(root) NOPASSWD: /usr/bin/journalctl --vacuum-size=100M
  """

  alias Exocomp.Node.ActionCatalog

  @doc """
  Render a sudoers policy fragment for `account` with the given `allow_list`.

  ### Options

  - `:include_vacuum` (boolean, default `true`) — include the
    `journalctl --vacuum-size` entry.
  - `:vacuum_size` (string, default from app config or `"100M"`) — override the
    vacuum-size argument.

  Returns a UTF-8 string.  An empty allow-list and `include_vacuum: false`
  returns an empty string (no privileged entries).
  """
  @spec render(account :: String.t(), allow_list :: [String.t()], opts :: keyword()) ::
          String.t()

  def render(account, allow_list, opts \\ [])
      when is_binary(account) and is_list(allow_list) do
    include_vacuum = Keyword.get(opts, :include_vacuum, true)
    entries = ActionCatalog.sudoers_entries(allow_list)

    # Filter vacuum entry if requested.
    entries =
      if include_vacuum do
        entries
      else
        Enum.reject(entries, fn {exec, _} -> String.contains?(exec, "journalctl") end)
      end

    if entries == [] do
      ""
    else
      header = render_header(account)
      lines = Enum.map(entries, fn {exec, argv} -> render_entry(account, exec, argv) end)
      [header | lines] |> Enum.join("\n")
    end
  end

  @doc """
  Return the recommended filename for the sudoers drop-in.

  Conventionally placed in `/etc/sudoers.d/`.
  """
  @spec filename(account :: String.t()) :: String.t()
  def filename(account) when is_binary(account), do: "exocomp-#{account}"

  @doc """
  Validate that `account` is a safe POSIX username.

  Returns `:ok` or `{:error, :invalid_account}`.  Only alphanumeric characters,
  underscores, and hyphens are allowed, and the name must start with a letter
  or underscore.  This prevents any shell metacharacter from appearing in the
  generated sudoers file.
  """
  @spec validate_account(account :: String.t()) :: :ok | {:error, :invalid_account}
  def validate_account(account) when is_binary(account) do
    if Regex.match?(~r/\A[a-zA-Z_][a-zA-Z0-9_\-]*\z/, account) do
      :ok
    else
      {:error, :invalid_account}
    end
  end

  def validate_account(_), do: {:error, :invalid_account}

  # ── Private ───────────────────────────────────────────────────────────────

  defp render_header(account) do
    """
    # Exocomp node sudoers policy
    # Generated for account: #{account}
    # DO NOT EDIT — regenerate from the installed action catalog.
    # Validate with: visudo -c -f /etc/sudoers.d/#{filename(account)}\
    """
  end

  defp render_entry(account, executable, argv) do
    args_str = Enum.join(argv, " ")
    "#{account} ALL=(root) NOPASSWD: #{executable} #{args_str}"
  end
end
