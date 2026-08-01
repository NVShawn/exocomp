# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Auth.OIDCResolverTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Auth.OIDCResolver
  alias Exocomp.MissionControl.Identity.Operator

  @org_id "org-001"
  @sub "user-sub-001"

  defp config(overrides \\ %{}) do
    base = %{
      @org_id => %{
        group_claim: "groups",
        group_role_map: %{
          "platform-admin" => :admin,
          "platform-ops" => :operator,
          "platform-reader" => :viewer
        }
      }
    }

    Map.merge(base, overrides)
  end

  # ── No config ────────────────────────────────────────────────────────────────

  describe "resolve/4 with no org config" do
    test "returns {:error, :no_config} when org is absent from config" do
      cfg = config()

      assert {:error, :no_config} =
               OIDCResolver.resolve("org-unknown", @sub, %{"groups" => ["platform-admin"]}, cfg)
    end

    test "returns {:error, :no_config} for empty config map" do
      assert {:error, :no_config} = OIDCResolver.resolve(@org_id, @sub, %{}, %{})
    end
  end

  # ── Subject override ─────────────────────────────────────────────────────────

  describe "resolve/4 with subject_role_map" do
    test "resolves admin role from subject override" do
      cfg =
        config(%{
          @org_id => Map.put(config()[@org_id], :subject_role_map, %{@sub => :admin})
        })

      assert {:ok, %Operator{role: :admin, sub: @sub, organization_id: @org_id}} =
               OIDCResolver.resolve(@org_id, @sub, %{}, cfg)
    end

    test "subject override takes priority over group membership" do
      cfg =
        config(%{
          @org_id => Map.put(config()[@org_id], :subject_role_map, %{@sub => :viewer})
        })

      # The subject is in the admin group, but subject_role_map wins.
      claims = %{"groups" => ["platform-admin"]}

      assert {:ok, %Operator{role: :viewer}} =
               OIDCResolver.resolve(@org_id, @sub, claims, cfg)
    end

    test "falls through to group resolution when subject is not in override map" do
      cfg =
        config(%{
          @org_id => Map.put(config()[@org_id], :subject_role_map, %{"other-sub" => :admin})
        })

      claims = %{"groups" => ["platform-ops"]}

      assert {:ok, %Operator{role: :operator}} =
               OIDCResolver.resolve(@org_id, @sub, claims, cfg)
    end
  end

  # ── Group claim mapping ───────────────────────────────────────────────────────

  describe "resolve/4 with group_claim" do
    test "resolves admin from admin group" do
      claims = %{"groups" => ["platform-admin"]}

      assert {:ok, %Operator{role: :admin}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "resolves operator from ops group" do
      claims = %{"groups" => ["platform-ops"]}

      assert {:ok, %Operator{role: :operator}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "resolves viewer from reader group" do
      claims = %{"groups" => ["platform-reader"]}

      assert {:ok, %Operator{role: :viewer}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "returns highest privilege when user belongs to multiple groups" do
      claims = %{"groups" => ["platform-reader", "platform-ops", "platform-admin"]}

      assert {:ok, %Operator{role: :admin}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "returns viewer when lower-privilege groups overlap with higher unmapped groups" do
      claims = %{"groups" => ["platform-reader", "some-other-group"]}

      assert {:ok, %Operator{role: :viewer}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "accepts a single string for the group claim (not a list)" do
      claims = %{"groups" => "platform-admin"}

      assert {:ok, %Operator{role: :admin}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "returns {:error, :no_role} when no group matches" do
      claims = %{"groups" => ["some-unrelated-group"]}

      assert {:error, :no_role} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "returns {:error, :no_role} when groups claim is absent" do
      assert {:error, :no_role} = OIDCResolver.resolve(@org_id, @sub, %{}, config())
    end

    test "returns {:error, :no_role} when groups claim is nil" do
      claims = %{"groups" => nil}

      assert {:error, :no_role} = OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "ignores non-string group entries gracefully" do
      claims = %{"groups" => [123, "platform-ops", nil]}

      assert {:ok, %Operator{role: :operator}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end
  end

  # ── No group_claim configured ────────────────────────────────────────────────

  describe "resolve/4 when no group_claim is configured" do
    test "returns {:error, :no_role} when no subject_role_map or group_claim" do
      cfg = %{@org_id => %{group_role_map: %{"x" => :admin}}}

      assert {:error, :no_role} =
               OIDCResolver.resolve(@org_id, @sub, %{"groups" => ["x"]}, cfg)
    end
  end

  # ── Display name extraction ──────────────────────────────────────────────────

  describe "resolve/4 display name" do
    test "uses the 'name' claim by default" do
      claims = %{"groups" => ["platform-admin"], "name" => "Alice Smith"}

      assert {:ok, %Operator{display_name: "Alice Smith"}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "falls back to 'email' when name claim is absent" do
      claims = %{"groups" => ["platform-admin"], "email" => "alice@example.com"}

      assert {:ok, %Operator{display_name: "alice@example.com"}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "falls back to sub when neither name nor email is present" do
      claims = %{"groups" => ["platform-admin"]}

      assert {:ok, %Operator{display_name: @sub}} =
               OIDCResolver.resolve(@org_id, @sub, claims, config())
    end

    test "uses configured display_claim over default 'name'" do
      cfg = %{
        @org_id => Map.put(config()[@org_id], :display_claim, "preferred_username")
      }

      claims = %{
        "groups" => ["platform-admin"],
        "name" => "Alice",
        "preferred_username" => "asmith"
      }

      assert {:ok, %Operator{display_name: "asmith"}} =
               OIDCResolver.resolve(@org_id, @sub, claims, cfg)
    end
  end

  # ── Returned Operator struct ─────────────────────────────────────────────────

  describe "resolve/4 returned Operator struct" do
    test "sets sub, organization_id, and role correctly" do
      claims = %{"groups" => ["platform-ops"]}

      assert {:ok, op} = OIDCResolver.resolve(@org_id, @sub, claims, config())
      assert op.sub == @sub
      assert op.organization_id == @org_id
      assert op.role == :operator
    end
  end

  # ── Application config fallback ──────────────────────────────────────────────

  describe "resolve/3 (no config_override) — application config fallback" do
    setup do
      prev = Application.get_env(:exocomp_mission_control, :oidc_role_config)

      on_exit(fn ->
        if prev == nil do
          Application.delete_env(:exocomp_mission_control, :oidc_role_config)
        else
          Application.put_env(:exocomp_mission_control, :oidc_role_config, prev)
        end
      end)

      :ok
    end

    test "reads oidc_role_config from application env" do
      Application.put_env(:exocomp_mission_control, :oidc_role_config, %{
        @org_id => %{
          group_claim: "roles",
          group_role_map: %{"sre" => :operator}
        }
      })

      claims = %{"roles" => ["sre"]}
      assert {:ok, %Operator{role: :operator}} = OIDCResolver.resolve(@org_id, @sub, claims)
    end

    test "returns {:error, :no_config} when application env is empty" do
      Application.delete_env(:exocomp_mission_control, :oidc_role_config)

      assert {:error, :no_config} = OIDCResolver.resolve(@org_id, @sub, %{})
    end
  end
end
