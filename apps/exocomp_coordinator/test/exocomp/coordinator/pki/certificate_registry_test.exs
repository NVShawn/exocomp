# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.PKI.CertificateRegistryTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.PKI.CertificateRegistry

  @node_alpha "node-alpha.example.internal"
  @node_beta "node-beta.example.internal"
  @serial_1 12_345_678
  @serial_2 87_654_321
  @serial_3 11_111_111

  # Unix timestamps for test
  @issued_at 1_700_000_000
  @expires_at 1_702_592_000

  defp start_registry(opts \\ []) do
    name = :"cert_reg_#{System.unique_integer([:positive, :monotonic])}"
    opts = Keyword.merge([name: name, store_path: nil], opts)
    start_supervised!({CertificateRegistry, opts}, id: name)
    name
  end

  # ---------------------------------------------------------------------------
  # Registration
  # ---------------------------------------------------------------------------

  describe "register/5" do
    test "registers a serial and reports active status" do
      reg = start_registry()

      assert :ok =
               CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at,
                 server: reg
               )

      assert CertificateRegistry.certificate_status(@serial_1, server: reg) == :active
    end

    test "re-registering the same serial is idempotent" do
      reg = start_registry()

      assert :ok =
               CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at,
                 server: reg
               )

      assert :ok =
               CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at,
                 server: reg
               )

      assert CertificateRegistry.certificate_status(@serial_1, server: reg) == :active
    end

    test "unregistered serial reports :unknown status" do
      reg = start_registry()
      assert CertificateRegistry.certificate_status(99_999_999, server: reg) == :unknown
    end
  end

  # ---------------------------------------------------------------------------
  # Serial revocation
  # ---------------------------------------------------------------------------

  describe "revoke_serial/2" do
    test "revoked serial reports :revoked status" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      assert :ok = CertificateRegistry.revoke_serial(@serial_1, server: reg)
      assert CertificateRegistry.certificate_status(@serial_1, server: reg) == :revoked
    end

    test "revoking an unregistered serial is accepted (unknown becomes revoked)" do
      reg = start_registry()
      assert :ok = CertificateRegistry.revoke_serial(99_999_999, server: reg)
      assert CertificateRegistry.certificate_status(99_999_999, server: reg) == :revoked
    end

    test "revocation is idempotent" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      assert :ok = CertificateRegistry.revoke_serial(@serial_1, server: reg)
      assert :ok = CertificateRegistry.revoke_serial(@serial_1, server: reg)
      assert CertificateRegistry.certificate_status(@serial_1, server: reg) == :revoked
    end

    test "revoking one serial does not affect another serial for the same identity" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      :ok =
        CertificateRegistry.register(@serial_2, @node_alpha, @issued_at, @expires_at, server: reg)

      :ok = CertificateRegistry.revoke_serial(@serial_1, server: reg)

      assert CertificateRegistry.certificate_status(@serial_1, server: reg) == :revoked
      assert CertificateRegistry.certificate_status(@serial_2, server: reg) == :active
    end
  end

  # ---------------------------------------------------------------------------
  # Identity revocation
  # ---------------------------------------------------------------------------

  describe "revoke_identity/2" do
    test "revoked identity reports :revoked for all its serials" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      :ok =
        CertificateRegistry.register(@serial_2, @node_alpha, @issued_at, @expires_at, server: reg)

      assert :ok = CertificateRegistry.revoke_identity(@node_alpha, server: reg)

      assert CertificateRegistry.certificate_status(@serial_1, server: reg) == :revoked
      assert CertificateRegistry.certificate_status(@serial_2, server: reg) == :revoked
    end

    test "revoked identity reports :revoked for identity_status" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      :ok = CertificateRegistry.revoke_identity(@node_alpha, server: reg)

      assert CertificateRegistry.identity_status(@node_alpha, server: reg) == :revoked
    end

    test "revoking one identity does not affect another" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      :ok =
        CertificateRegistry.register(@serial_3, @node_beta, @issued_at, @expires_at, server: reg)

      :ok = CertificateRegistry.revoke_identity(@node_alpha, server: reg)

      assert CertificateRegistry.identity_status(@node_alpha, server: reg) == :revoked
      assert CertificateRegistry.identity_status(@node_beta, server: reg) == :active
      assert CertificateRegistry.certificate_status(@serial_3, server: reg) == :active
    end

    test "revoke_identity is idempotent" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      assert :ok = CertificateRegistry.revoke_identity(@node_alpha, server: reg)
      assert :ok = CertificateRegistry.revoke_identity(@node_alpha, server: reg)
      assert CertificateRegistry.identity_status(@node_alpha, server: reg) == :revoked
    end

    test "serial registered after identity revocation also reports :revoked" do
      reg = start_registry()
      :ok = CertificateRegistry.revoke_identity(@node_alpha, server: reg)
      # Register a new serial for the already-revoked identity
      :ok =
        CertificateRegistry.register(@serial_2, @node_alpha, @issued_at, @expires_at, server: reg)

      assert CertificateRegistry.certificate_status(@serial_2, server: reg) == :revoked
    end
  end

  # ---------------------------------------------------------------------------
  # Identity status
  # ---------------------------------------------------------------------------

  describe "identity_status/2" do
    test "unknown identity reports :unknown" do
      reg = start_registry()
      assert CertificateRegistry.identity_status("nonexistent-node", server: reg) == :unknown
    end

    test "identity with active serial reports :active" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      assert CertificateRegistry.identity_status(@node_alpha, server: reg) == :active
    end
  end

  # ---------------------------------------------------------------------------
  # Status/observability
  # ---------------------------------------------------------------------------

  describe "status/1" do
    test "returns counts of issued, revoked serials, and revoked identities" do
      reg = start_registry()

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at, server: reg)

      :ok =
        CertificateRegistry.register(@serial_2, @node_beta, @issued_at, @expires_at, server: reg)

      :ok = CertificateRegistry.revoke_serial(@serial_1, server: reg)
      :ok = CertificateRegistry.revoke_identity(@node_beta, server: reg)

      status = CertificateRegistry.status(server: reg)
      assert status.issued_count == 2
      assert status.revoked_serial_count == 2
      assert status.revoked_identity_count == 1
    end
  end

  # ---------------------------------------------------------------------------
  # ASN.1 time parsing
  # ---------------------------------------------------------------------------

  describe "asn1_time_to_unix/1" do
    test "parses UTC time format (2-digit year, before 2050)" do
      # 2026-08-01 00:00:00Z in utcTime format
      value = CertificateRegistry.asn1_time_to_unix({:utcTime, ~c"260801000000Z"})
      # 2026-08-01 00:00:00 UTC = 1785542400
      expected = 1_785_542_400
      assert value == expected
    end

    test "parses generalTime format (4-digit year)" do
      value = CertificateRegistry.asn1_time_to_unix({:generalTime, ~c"20260801000000Z"})
      # 2026-08-01 00:00:00 UTC = 1785542400
      expected = 1_785_542_400
      assert value == expected
    end

    test "utcTime and generalTime are consistent for same date" do
      utc = CertificateRegistry.asn1_time_to_unix({:utcTime, ~c"260801000000Z"})
      general = CertificateRegistry.asn1_time_to_unix({:generalTime, ~c"20260801000000Z"})
      assert utc == general
    end

    test "year < 50 in utcTime resolves to 2000s" do
      # "26..." → 2026
      value = CertificateRegistry.asn1_time_to_unix({:utcTime, ~c"260101120000Z"})
      # 2026-01-01 12:00:00 UTC = 1767268800
      expected = 1_767_268_800
      assert value == expected
    end

    test "year >= 50 in utcTime resolves to 1900s" do
      # "70..." → 1970
      value = CertificateRegistry.asn1_time_to_unix({:utcTime, ~c"700101000000Z"})
      # 1970-01-01 00:00:00 UTC = 0
      assert value == 0
    end
  end

  # ---------------------------------------------------------------------------
  # Persistence
  # ---------------------------------------------------------------------------

  describe "persistence" do
    @tag :tmp_dir
    test "revocations survive process restart", %{tmp_dir: tmp_dir} do
      store = Path.join(tmp_dir, "cert-reg")

      name1 = :"certreg_p1_#{System.unique_integer([:positive, :monotonic])}"
      start_supervised!({CertificateRegistry, [name: name1, store_path: store]}, id: name1)

      :ok =
        CertificateRegistry.register(@serial_1, @node_alpha, @issued_at, @expires_at,
          server: name1
        )

      :ok = CertificateRegistry.revoke_identity(@node_alpha, server: name1)

      assert CertificateRegistry.identity_status(@node_alpha, server: name1) == :revoked

      stop_supervised(name1)

      name2 = :"certreg_p2_#{System.unique_integer([:positive, :monotonic])}"
      start_supervised!({CertificateRegistry, [name: name2, store_path: store]}, id: name2)

      # Revocation must survive restart
      assert CertificateRegistry.identity_status(@node_alpha, server: name2) == :revoked
      assert CertificateRegistry.certificate_status(@serial_1, server: name2) == :revoked
    end

    @tag :tmp_dir
    test "first start with no store file is not an error", %{tmp_dir: tmp_dir} do
      store = Path.join(tmp_dir, "new-cert-reg")
      name = :"certreg_new_#{System.unique_integer([:positive, :monotonic])}"
      pid = start_supervised!({CertificateRegistry, [name: name, store_path: store]}, id: name)
      assert is_pid(pid)
      assert CertificateRegistry.status(server: name).issued_count == 0
    end
  end
end
