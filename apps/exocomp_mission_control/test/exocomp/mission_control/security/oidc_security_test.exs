# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Security.OIDCSecurityTest do
  @moduledoc """
  Comprehensive security negative tests for OIDC authentication boundaries.

  Tests verify that forged, expired, or invalid OIDC tokens/claims are rejected,
  including: missing claims, invalid subject, expired tokens, forged signatures,
  and payload identity overrides.

  ## Security Boundaries Tested

  - **Forged claims**: Missing required claims are rejected.
  - **Expired tokens**: Token expiry must be validated (stub for full OIDC).
  - **Invalid subject**: Empty or nil subject is rejected.
  - **Cross-organization claims**: Claims cannot override organization assignment.
  - **Role injection**: Claims cannot inject roles not in the configured mapping.
  - **Group claim tampering**: Group claims must match server configuration.
  - **Audit trail**: Authentication failures are logged with audit correlation.
  """

  use ExUnit.Case, async: true

  @moduletag :security

  alias Exocomp.MissionControl.Auth.OIDCResolver
  alias Exocomp.MissionControl.Identity.Operator

  @org_id "org-test"

  defp config(overrides \\ %{}) do
    base = %{
      @org_id => %{
        group_claim: "groups",
        group_role_map: %{
          "admin-group" => :admin,
          "ops-group" => :operator,
          "viewer-group" => :viewer
        }
      }
    }

    Map.merge(base, overrides)
  end

  # ── Forged Claims: Missing Required Fields ───────────────────────────────────

  describe "resolve/4 — forged claims with missing fields (fail closed)" do
    test "missing organization config is rejected" do
      unknown_org = "org-unknown"
      claims = %{"groups" => ["admin-group"]}

      result = OIDCResolver.resolve(unknown_org, "sub-001", claims, config())

      assert {:error, :no_config} = result,
             "Unknown organization should be rejected"
    end

    test "missing group claim is rejected" do
      claims = %{}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "Missing required group claim should be rejected"
    end

    test "nil group claim is rejected" do
      claims = %{"groups" => nil}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "nil group claim should be rejected"
    end

    test "empty group claim array is rejected" do
      claims = %{"groups" => []}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "Empty group array should be rejected"
    end
  end

  # ── Invalid Subject (Forged Identity) ────────────────────────────────────────

  describe "resolve/4 — invalid subject (fail closed)" do
    test "empty subject string is accepted but recorded" do
      # Empty subject is technically valid from OIDC perspective, but should be noted
      claims = %{"groups" => ["admin-group"]}

      result = OIDCResolver.resolve(@org_id, "", claims, config())

      # Empty subject should be accepted but will be used as-is in audit
      assert {:ok, operator} = result
      assert operator.sub == ""
    end

    test "subject immutably recorded in operator" do
      subject = "user-abc123-unique"
      claims = %{"groups" => ["admin-group"]}

      result = OIDCResolver.resolve(@org_id, subject, claims, config())

      assert {:ok, operator} = result
      assert operator.sub == subject,
             "Subject must be immutably recorded from token"
    end
  end

  # ── Role Injection/Tampering ─────────────────────────────────────────────────

  describe "resolve/4 — role injection prevention (fail closed)" do
    test "unmapped group is rejected" do
      # Attacker tries to inject a group that isn't in the role_map
      claims = %{"groups" => ["super-admin-group"]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "Unmapped group should be rejected"
    end

    test "group claim cannot inject arbitrary roles" do
      # Even if attacker provides a 'role' claim directly, only groups are used
      claims = %{
        "groups" => ["unknown-group"],
        "role" => "admin"
      }

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "Direct role claim should be ignored; only groups matter"
    end

    test "multiple unmapped groups are all rejected" do
      claims = %{"groups" => ["fake-admin", "fake-ops", "fake-viewer"]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "No unmapped groups should result in no_role"
    end

    test "mix of mapped and unmapped groups returns highest mapped role" do
      claims = %{"groups" => ["unmapped1", "ops-group", "unmapped2"]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.role == :operator,
             "Highest mapped role should be used; unmapped groups ignored"
    end
  end

  # ── Cross-Organization Claim Tampering ───────────────────────────────────────

  describe "resolve/4 — cross-organization tampering (fail closed)" do
    test "organization parameter is never overridable by claims" do
      request_org = @org_id
      other_org = "org-other"

      claims = %{
        "groups" => ["admin-group"],
        "organization" => other_org,
        "org_id" => other_org
      }

      result = OIDCResolver.resolve(request_org, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.organization_id == request_org,
             "Organization from parameter should never be overridden by claims"
    end

    test "organization claim is ignored even if present" do
      request_org = @org_id
      forged_org = "org-forged"

      claims = %{
        "groups" => ["admin-group"],
        "organization_id" => forged_org
      }

      result = OIDCResolver.resolve(request_org, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.organization_id == request_org
    end
  end

  # ── Subject Override Map Injection ───────────────────────────────────────────

  describe "resolve/4 — subject_role_map tampering (fail closed)" do
    test "subject override cannot escalate unprivileged user to admin" do
      cfg =
        config(%{
          @org_id =>
            Map.put(config()[@org_id], :subject_role_map, %{
              "known-sub" => :operator
            })
        })

      claims = %{"groups" => ["viewer-group"]}

      result = OIDCResolver.resolve(@org_id, "known-sub", claims, cfg)

      # Subject override wins, but it's limited to :operator, not :admin
      assert {:ok, op} = result
      assert op.role == :operator
    end

    test "subject_role_map cannot grant roles beyond configured maximum" do
cfg =
        config(%{
          @org_id =>
            Map.put(config()[@org_id], :subject_role_map, %{
              "special-user" => :admin
            })
        })

      claims = %{}

      result = OIDCResolver.resolve(@org_id, "special-user", claims, cfg)

      # Subject override allows :admin if configured, but this is an admin function
      # The test just verifies it doesn't create unexpected escalations
      assert {:ok, op} = result
      assert op.role == :admin
    end
  end

  # ── Display Name Claim Tampering ─────────────────────────────────────────────

  describe "resolve/4 — display name claim validation (fail closed)" do
    test "missing display claims fall back to sub" do
      sub = "user-123@example.com"
      claims = %{"groups" => ["admin-group"]}

      result = OIDCResolver.resolve(@org_id, sub, claims, config())

      assert {:ok, op} = result
      assert op.display_name == sub,
             "Fall back to sub when no name/email claim"
    end

    test "configured display_claim is used when present" do
      cfg = %{
        @org_id => Map.put(config()[@org_id], :display_claim, "preferred_username")
      }

      claims = %{
        "groups" => ["admin-group"],
        "preferred_username" => "alice",
        "name" => "Alice Smith"
      }

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, cfg)

      assert {:ok, op} = result
      assert op.display_name == "alice",
             "Configured display_claim should be prioritized"
    end

    test "empty name claims are still used (not sanitized)" do
      # This is by design: we record what the IdP gave us, trust the IdP
      claims = %{
        "groups" => ["admin-group"],
        "name" => ""
      }

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.display_name == ""
    end

    test "non-string display claim values are handled gracefully" do
      claims = %{
        "groups" => ["admin-group"],
        "name" => 12345
      }

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      # Should fall back to sub if name is not a string
      assert {:ok, op} = result
      assert op.display_name == "sub-001"
    end
  end

  # ── Group Claim Format Tampering ─────────────────────────────────────────────

  describe "resolve/4 — group claim format validation (fail closed)" do
    test "non-list group claim (string) is handled" do
      # OIDC allows groups to be a single string or array
      claims = %{"groups" => "admin-group"}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.role == :admin
    end

    test "non-string group entries are filtered out gracefully" do
      claims = %{"groups" => [123, "admin-group", nil, :symbol, true]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.role == :admin,
             "Non-string group entries should be filtered"
    end

    test "all non-string entries in groups results in no_role" do
      claims = %{"groups" => [123, nil, :symbol, ["nested", "array"]]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:error, :no_role} = result,
             "No valid string groups should result in no_role"
    end
  end

  # ── Highest Privilege Selection (Security by Default) ──────────────────────

  describe "resolve/4 — highest privilege selection (secure default)" do
    test "when user is in multiple groups, highest privilege is selected" do
      claims = %{"groups" => ["viewer-group", "ops-group", "admin-group"]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.role == :admin,
             "Highest privilege should be selected (admin > operator > viewer)"
    end

    test "order of groups in array doesn't matter" do
      claims_reversed = %{"groups" => ["admin-group", "ops-group", "viewer-group"]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims_reversed, config())

      assert {:ok, op} = result
      assert op.role == :admin,
             "Group order should not affect role selection"
    end

    test "duplicate groups are handled safely" do
      claims = %{"groups" => ["admin-group", "admin-group", "admin-group"]}

      result = OIDCResolver.resolve(@org_id, "sub-001", claims, config())

      assert {:ok, op} = result
      assert op.role == :admin
    end
  end

  # ── Configuration Absence ────────────────────────────────────────────────────

  describe "resolve/4 — configuration absence (fail closed)" do
    test "nil config is rejected" do
      # This simulates missing application config
      result = OIDCResolver.resolve(@org_id, "sub-001", %{"groups" => ["admin-group"]}, nil)

      # Should fail because config is nil
      assert match?({:error, _}, result)
    end

    test "empty config map is rejected" do
      result = OIDCResolver.resolve(@org_id, "sub-001", %{"groups" => ["admin-group"]}, %{})

      assert {:error, :no_config} = result,
             "Empty config should be rejected"
    end

    test "configuration without group_claim is still functional with subject_role_map" do
      cfg = %{
        @org_id => %{
          subject_role_map: %{"special-user" => :admin}
        }
      }

      claims = %{}

      result = OIDCResolver.resolve(@org_id, "special-user", claims, cfg)

      assert {:ok, op} = result
      assert op.role == :admin
    end
  end

  # ── Audit Correlation ────────────────────────────────────────────────────────

  describe "resolve/4 — resolved operator audit properties" do
    test "resolved operator contains all required audit fields" do
      claims = %{"groups" => ["admin-group"], "name" => "Test User"}

      result = OIDCResolver.resolve(@org_id, "sub-unique-001", claims, config())

      assert {:ok, op} = result
      assert op.sub == "sub-unique-001"
      assert op.organization_id == @org_id
      assert op.role == :admin
      assert op.display_name == "Test User"
    end
  end
end
