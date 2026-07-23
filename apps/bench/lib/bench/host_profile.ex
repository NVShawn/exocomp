defmodule Bench.HostProfile do
  @moduledoc """
  Static reference host profiles for amd64 and arm64, plus runtime host
  detection and compatibility enforcement.

  A `Bench.HostProfile` struct records the hardware and OS properties that
  determine whether two benchmark runs are directly comparable.  Results
  produced on different architectures must never be compared — `compatible?/2`
  enforces this by raising when architectures differ.

  ## Struct fields

  | Field                 | Type    | Description                                            |
  |-----------------------|---------|--------------------------------------------------------|
  | `:architecture`       | string  | CPU architecture: `"amd64"` or `"arm64"`               |
  | `:cpu_model`          | string  | CPU model string from the OS                           |
  | `:cpu_count`          | integer | Logical CPU count (hardware threads)                   |
  | `:ram_bytes`          | integer | Total physical RAM in bytes                            |
  | `:kernel_version`     | string  | Kernel release string (`uname -r`)                     |
  | `:linux_distribution` | string  | OS pretty name from `/etc/os-release`                  |
  | `:libc_version`       | string  | glibc version string                                   |
  | `:governor`           | string  | CPU power/performance governor (`"performance"`, etc.) |
  | `:container_or_vm`    | string  | Execution boundary: `"none"`, `"docker"`, `"vm"`, etc. |

  ## Usage

      # Detect the current host
      profile = Bench.HostProfile.detect()

      # Load a pinned reference profile
      {:ok, ref} = Bench.HostProfile.load("amd64-ci")

      # Verify two profiles are comparable (same arch required)
      true = Bench.HostProfile.compatible?(profile, ref)

  ## Reference profiles

  Pinned TOML profiles live in `priv/bench/profiles/`:
  - `amd64-ci.toml` — GitHub Actions `ubuntu-22.04` (x86_64)
  - `arm64-ci.toml` — GitHub Actions `ubuntu-22.04-arm` (aarch64)
  """

  @typedoc "Host environment profile."
  @type t :: %__MODULE__{
          architecture: String.t(),
          cpu_model: String.t(),
          cpu_count: non_neg_integer(),
          ram_bytes: non_neg_integer(),
          kernel_version: String.t(),
          linux_distribution: String.t(),
          libc_version: String.t(),
          governor: String.t(),
          container_or_vm: String.t()
        }

  defstruct [
    :architecture,
    :cpu_model,
    :cpu_count,
    :ram_bytes,
    :kernel_version,
    :linux_distribution,
    :libc_version,
    :governor,
    :container_or_vm
  ]

  @required_fields ~w(
    architecture
    cpu_model
    cpu_count
    ram_bytes
    kernel_version
    linux_distribution
    libc_version
    governor
    container_or_vm
  )

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Detect the current host's profile by reading OS and hardware information.

  Reads `/proc/cpuinfo`, `/proc/meminfo`, `/etc/os-release`, and
  `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`, plus `uname`.
  Falls back to `"unknown"` / `0` for any field that cannot be read (e.g.
  when running on macOS or in an environment without `/proc`).

  Returns a `%Bench.HostProfile{}` struct.
  """
  @spec detect() :: t()
  def detect do
    %__MODULE__{
      architecture: detect_architecture(),
      cpu_model: detect_cpu_model(),
      cpu_count: detect_cpu_count(),
      ram_bytes: detect_ram_bytes(),
      kernel_version: detect_kernel_version(),
      linux_distribution: detect_linux_distribution(),
      libc_version: detect_libc_version(),
      governor: detect_governor(),
      container_or_vm: detect_container_or_vm()
    }
  end

  @doc """
  Load a named profile from `priv/bench/profiles/<name>.toml`.

  Returns `{:ok, %Bench.HostProfile{}}` on success, or:
  - `{:error, :not_found}` when the profile file does not exist
  - `{:error, {:parse_error, reason}}` when the TOML is malformed
  - `{:error, {:missing_fields, [field]}}` when required fields are absent
  - `{:error, {:invalid_field, field, reason}}` when a field has the wrong type
  """
  @spec load(String.t()) :: {:ok, t()} | {:error, term()}
  def load(name) when is_binary(name) do
    priv = :code.priv_dir(:bench)
    path = Path.join([to_string(priv), "bench", "profiles", "#{name}.toml"])

    case File.read(path) do
      {:ok, content} ->
        with {:ok, map} <- parse_toml(content),
             :ok <- check_missing_fields(map),
             {:ok, profile} <- build_and_validate(map) do
          {:ok, profile}
        end

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Verify that two profiles are comparable.

  Profiles are comparable when they share the same architecture.
  Returns `true` when both profiles have the same `:architecture` value.

  Raises `ArgumentError` with a descriptive message when the architectures
  differ — hardware benchmark results produced on different CPU architectures
  must never be compared directly.
  """
  @spec compatible?(t(), t()) :: true
  def compatible?(%__MODULE__{architecture: arch} = _a, %__MODULE__{architecture: arch} = _b) do
    true
  end

  def compatible?(%__MODULE__{architecture: a}, %__MODULE__{architecture: b}) do
    raise ArgumentError,
          "profiles have incompatible architectures: \"#{a}\" vs \"#{b}\"; " <>
            "benchmark results across different CPU architectures cannot be compared"
  end

  # ---------------------------------------------------------------------------
  # Host detection helpers
  # ---------------------------------------------------------------------------

  defp detect_architecture do
    case run_cmd("uname", ["-m"]) do
      {:ok, "x86_64"} -> "amd64"
      {:ok, "aarch64"} -> "arm64"
      {:ok, other} -> other
      _ -> "unknown"
    end
  end

  defp detect_cpu_model do
    read_proc_cpuinfo_field("model name") ||
      read_proc_cpuinfo_field("Model name") ||
      read_proc_cpuinfo_field("CPU part") ||
      "unknown"
  end

  defp detect_cpu_count do
    case File.read("/proc/cpuinfo") do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.count(&String.starts_with?(&1, "processor"))

      {:error, _} ->
        0
    end
  end

  defp detect_ram_bytes do
    case File.read("/proc/meminfo") do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.find_value(0, fn line ->
          case Regex.run(~r/^MemTotal:\s+(\d+)\s+kB/, line) do
            [_, kb] -> String.to_integer(kb) * 1024
            _ -> nil
          end
        end)

      {:error, _} ->
        0
    end
  end

  defp detect_kernel_version do
    case run_cmd("uname", ["-r"]) do
      {:ok, ver} -> ver
      _ -> "unknown"
    end
  end

  defp detect_linux_distribution do
    case File.read("/etc/os-release") do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.find_value("unknown", fn line ->
          case Regex.run(~r/^PRETTY_NAME="(.+)"/, line) do
            [_, name] -> name
            _ -> nil
          end
        end)

      {:error, _} ->
        "unknown"
    end
  end

  defp detect_libc_version do
    # Try getconf first (available on most GNU/Linux systems)
    with {:ok, ver} <- run_cmd("getconf", ["GNU_LIBC_VERSION"]) do
      String.replace(ver, "glibc ", "")
    else
      _ ->
        # Fall back to ldd --version
        case run_cmd("ldd", ["--version"], stderr_to_stdout: true) do
          {:ok, output} ->
            output
            |> String.split("\n")
            |> List.first("")
            |> then(fn line ->
              case Regex.run(~r/(\d+\.\d+)/, line) do
                [_, ver] -> ver
                _ -> "unknown"
              end
            end)

          _ ->
            "unknown"
        end
    end
  end

  defp detect_governor do
    path = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

    case File.read(path) do
      {:ok, content} -> String.trim(content)
      {:error, _} -> "unknown"
    end
  end

  defp detect_container_or_vm do
    cond do
      File.exists?("/.dockerenv") ->
        "docker"

      File.exists?("/run/.containerenv") ->
        "podman"

      is_systemd_virt_container?() ->
        "container"

      true ->
        detect_vm_or_none()
    end
  end

  defp is_systemd_virt_container? do
    case run_cmd("systemd-detect-virt", ["--container"], stderr_to_stdout: true) do
      {:ok, output} -> String.trim(output) != "none"
      _ -> false
    end
  end

  defp detect_vm_or_none do
    case run_cmd("systemd-detect-virt", ["--vm"], stderr_to_stdout: true) do
      {:ok, output} ->
        case String.trim(output) do
          "none" -> "none"
          virt -> virt
        end

      _ ->
        "none"
    end
  end

  defp read_proc_cpuinfo_field(field_name) do
    with {:ok, content} <- File.read("/proc/cpuinfo") do
      content
      |> String.split("\n")
      |> Enum.find_value(fn line ->
        case String.split(line, ":", parts: 2) do
          [^field_name, value] -> String.trim(value)
          _ -> nil
        end
      end)
    else
      _ -> nil
    end
  end

  defp run_cmd(cmd, args, opts \\ []) do
    case System.cmd(cmd, args, opts ++ [stderr_to_stdout: false]) do
      {output, 0} -> {:ok, String.trim(output)}
      {_output, _code} -> {:error, :nonzero_exit}
    end
  rescue
    _ -> {:error, :not_available}
  end

  # ---------------------------------------------------------------------------
  # TOML parsing (minimal flat subset)
  # ---------------------------------------------------------------------------
  #
  # Supports:
  #   - Blank lines and lines beginning with "#" (comments)
  #   - key = "string value"
  #   - key = integer
  #   - key = true | false
  #
  # Does NOT support: nested tables, arrays, multi-line strings, inline tables.
  # The reference profile files are intentionally kept within this subset.

  @spec parse_toml(String.t()) :: {:ok, map()} | {:error, term()}
  defp parse_toml(content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, %{}}, fn {line, lineno}, {:ok, acc} ->
      trimmed = String.trim(line)

      cond do
        trimmed == "" or String.starts_with?(trimmed, "#") ->
          {:cont, {:ok, acc}}

        String.contains?(trimmed, "=") ->
          [raw_key | rest] = String.split(trimmed, "=", parts: 2)
          key = String.trim(raw_key)
          value_str = String.trim(Enum.join(rest, "="))

          case parse_toml_value(value_str) do
            {:ok, value} ->
              {:cont, {:ok, Map.put(acc, key, value)}}

            {:error, reason} ->
              {:halt, {:error, {:parse_error, "line #{lineno}: #{reason}"}}}
          end

        true ->
          {:halt, {:error, {:parse_error, "line #{lineno}: unexpected content: #{trimmed}"}}}
      end
    end)
  end

  @spec parse_toml_value(String.t()) :: {:ok, term()} | {:error, String.t()}
  defp parse_toml_value(str) do
    cond do
      String.starts_with?(str, ~s(")) and String.ends_with?(str, ~s(")) ->
        {:ok, str |> String.slice(1..-2//1) |> unescape_toml_string()}

      Regex.match?(~r/^-?\d+$/, str) ->
        {:ok, String.to_integer(str)}

      str == "true" ->
        {:ok, true}

      str == "false" ->
        {:ok, false}

      true ->
        {:error, "cannot parse value: #{str}"}
    end
  end

  defp unescape_toml_string(s) do
    s
    |> String.replace("\\\"", "\"")
    |> String.replace("\\\\", "\\")
    |> String.replace("\\n", "\n")
    |> String.replace("\\t", "\t")
  end

  # ---------------------------------------------------------------------------
  # Struct building from a parsed TOML map
  # ---------------------------------------------------------------------------

  defp check_missing_fields(map) do
    missing = Enum.reject(@required_fields, &Map.has_key?(map, &1))

    if missing == [] do
      :ok
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp build_and_validate(map) do
    profile = %__MODULE__{
      architecture: map["architecture"],
      cpu_model: map["cpu_model"],
      cpu_count: map["cpu_count"],
      ram_bytes: map["ram_bytes"],
      kernel_version: map["kernel_version"],
      linux_distribution: map["linux_distribution"],
      libc_version: map["libc_version"],
      governor: map["governor"],
      container_or_vm: map["container_or_vm"]
    }

    with :ok <- validate_string_field(:architecture, profile.architecture),
         :ok <- validate_string_field(:cpu_model, profile.cpu_model),
         :ok <- validate_non_neg_integer(:cpu_count, profile.cpu_count),
         :ok <- validate_non_neg_integer(:ram_bytes, profile.ram_bytes),
         :ok <- validate_string_field(:kernel_version, profile.kernel_version),
         :ok <- validate_string_field(:linux_distribution, profile.linux_distribution),
         :ok <- validate_string_field(:libc_version, profile.libc_version),
         :ok <- validate_string_field(:governor, profile.governor),
         :ok <- validate_string_field(:container_or_vm, profile.container_or_vm) do
      {:ok, profile}
    end
  end

  defp validate_string_field(_field, val)
       when is_binary(val) and byte_size(val) > 0,
       do: :ok

  defp validate_string_field(field, _),
    do: {:error, {:invalid_field, field, :must_be_non_empty_string}}

  defp validate_non_neg_integer(_field, val)
       when is_integer(val) and val >= 0,
       do: :ok

  defp validate_non_neg_integer(field, _),
    do: {:error, {:invalid_field, field, :must_be_non_negative_integer}}
end
