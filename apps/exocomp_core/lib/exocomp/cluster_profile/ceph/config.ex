# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.Ceph.Config do
  @moduledoc """
  Configuration parameters for the Ceph cluster profile.

  All three path fields must be exact absolute paths.  Relative paths,
  nil values, or paths containing shell expansions are rejected by the
  validator before startup.

  ## Fields

  - `version` — profile version (must equal `1`)
  - `ceph_binary_path` — absolute path to the `ceph` CLI executable
  - `ceph_conf_path` — absolute path to `ceph.conf`
  - `keyring_path` — absolute path to the `client.exocomp` keyring file
  """

  @enforce_keys [:version, :ceph_binary_path, :ceph_conf_path, :keyring_path]
  defstruct [:version, :ceph_binary_path, :ceph_conf_path, :keyring_path]

  @type t :: %__MODULE__{
          version: pos_integer(),
          ceph_binary_path: String.t(),
          ceph_conf_path: String.t(),
          keyring_path: String.t()
        }
end
