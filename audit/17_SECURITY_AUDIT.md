# WRONG WAY — PHASE 17: SECURITY REVIEW & BACKEND INTEGRATION

**Document ID:** `audit/17_SECURITY_AUDIT.md`  
**Classification:** Cloud Threat Modeling, Authorization Boundaries & Backend Integrity Review  
**Audit Date:** 2026-11-06  
**Auditor:** Senior Security Architect & Penetration Tester  
**Supabase Endpoint:** `https://wcwjobrrwwjfthpflzhg.supabase.co`  
**Target Architecture:** Supabase PostgreSQL + REST / RPC + Google OAuth  

---

## 1. THREAT MODEL & ARCHITECTURAL VULNERABILITIES

The security model of the **Wrong Way** application was audited across all network communication, data persistence, and remote procedure call boundaries.

The core vulnerability stems from an architectural misunderstanding:
The application relies on Supabase Remote Procedure Calls (RPCs) defined with `SECURITY DEFINER`, while all client HTTP requests use the static public anonymous API key (`DEFAULT_SUPABASE_ANON_KEY`). Because the client never establishes an authenticated Supabase Auth session (`auth.signInWithIdToken`), the PostgreSQL session variable `auth.uid()` evaluates to `NULL` on every invocation.

Consequently, the backend RPC functions rely entirely on client-supplied parameters (`p_email`, `p_player_id`, `p_device_id`), resulting in critical authorization bypasses.

---

## 2. DETAILED SECURITY VERIFICATION MATRIX

### 2.1. BUG-008: IDOR Account Takeover via `login_or_link_google`
- **Severity:** **CRITICAL (CVSS 9.8)**
- **Endpoint:** `POST /rest/v1/rpc/login_or_link_google`
- **Vulnerability:** The RPC accepts a raw string email (`p_email`) and immediately maps the caller's device ID to that account, returning the target's full profile UUID, username, tag, and cloud save data.
- **Empirical Proof:** An unauthenticated curl request using an arbitrary device ID and target email immediately returned full profile data with HTTP 200 OK.
- **Risk:** Complete account takeover of any player whose email is known.

### 2.2. BUG-009: Unauthenticated Cloud Save Overwrite via `sync_cloud_save`
- **Severity:** **HIGH (CVSS 8.6)**
- **Endpoint:** `POST /rest/v1/rpc/sync_cloud_save`
- **Vulnerability:** The RPC accepts `p_player_id` as an input parameter and performs an `UPDATE profiles SET save_data = p_save_data WHERE id = p_player_id;` without checking if the caller owns that UUID.
- **Risk:** Any user can overwrite or wipe the cloud progression of any other player.

### 2.3. RPC Function Permissions (`SECURITY DEFINER` & `GRANT EXECUTE`)
- All 14 custom database functions are granted `EXECUTE` permission to the public `anon` role.
- In PostgreSQL, functions marked `SECURITY DEFINER` execute with the permissions of the database owner, bypassing table-level Row-Level Security (RLS). Because the functions lack caller validation (`auth.uid() = p_player_id`), any user holding the anon key can execute privileged operations across the entire database.

### 2.4. Row-Level Security (RLS) Policy Exposure
- Direct table queries to `/rest/v1/profiles` and `/rest/v1/duels` return active rows when called with the anon key.
- While profiles table exposure facilitates friend search and leaderboards, exposing raw player IDs and device hashes enables user enumeration and targeted attacks.

### 2.5. Google OAuth Token Server Verification
- **Current State:** Zero cryptographic verification. On Android, the client obtains the user's Google email string and sends it bare to Supabase.
- **Requirement:** The client must obtain a Google OAuth ID Token (`id_token`) and exchange it with Supabase Auth via `/auth/v1/token?grant_type=id_token`, allowing Supabase to verify Google's cryptographic RSA signature.

### 2.6. API Keys & Secret Leakage Inspection
- **`Env.get_supabase_url()` & `get_supabase_anon_key()`:** Hardcoded in `scripts/core/env.gd`.
- **Verdict: NORMAL FOR PUBLIC CLIENTS.** The Supabase anon key is designed to be public, provided that backend tables enforce RLS and RPCs enforce `auth.uid()`.
- **Service Role Key:** **NOT LEAKED.** An exhaustive scan of the repository confirmed that the Supabase `service_role` master key is not present in any client code or config.

### 2.7. Rewarded Ad Reward Delivery Integrity
- **Mechanism:** In `ad_manager.gd:437-448`, rewards are granted via local GDScript callback when the countdown reaches 5.0 seconds.
- **Evaluation:** Because the game is primarily a single-player offline platformer, local client-side reward granting is standard industry practice. However, because `sync_cloud_save` accepts arbitrary unlock arrays without validation, an attacker can mark all 60 levels as beaten without watching any ads.

---

## 3. MULTIPLAYER BACKEND SECURITY & 2.0.0 FREEZE

Per engineering guidelines, the multiplayer system will remain dormant until version 2.0.0.

### Audit of Multiplayer Freezing:
1. **Main Menu UI Concealment:**
   In [scripts/ui/main_menu.gd:72-73](file:///d:/Documents/wrong-way/scripts/ui/main_menu.gd#L72-L73):
   ```gdscript
   if multiplayer_btn:
       multiplayer_btn.visible = false
   ```
   The "Multiplayer" button is explicitly hidden from the main menu.
2. **Background Polling Deactivation:**
   In [scripts/multiplayer/duel_service.gd:42-47](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L42-L47):
   The 3-second background invitation polling timer is commented out.
3. **Verdict:**
   The multiplayer system is cleanly frozen. The source code remains intact for the v2.0.0 release, but zero background network requests or socket listeners are dispatched during normal gameplay.

---

## 4. REMEDIATION PROTOCOL FOR SUPABASE SECURITY

To transition the backend to enterprise production standards:

```sql
-- 1. Enforce Row-Level Security on Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read of player tags"
ON profiles FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Allow users to update only own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- 2. Refactor sync_cloud_save to enforce caller identity
CREATE OR REPLACE FUNCTION sync_cloud_save(
    p_save_data jsonb,
    p_total_stars int,
    p_highest_level int
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Caller must be authenticated';
    END IF;

    UPDATE profiles
    SET save_data = p_save_data,
        stars = p_total_stars,
        highest_level = p_highest_level,
        updated_at = now()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;
```

