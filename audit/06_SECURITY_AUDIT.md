# WRONG WAY — PHASE 6: CRITICAL SECURITY & AUTHORIZATION AUDIT

**Document ID:** `audit/06_SECURITY_AUDIT.md`  
**Classification:** Forensic Application Security & Cloud Architecture Review  
**Audit Date:** 2026-11-06  
**Auditor:** Senior Security Engineer & Penetration Tester  
**Supabase Endpoint:** `https://wcwjobrrwwjfthpflzhg.supabase.co`  
**Target Environment:** Windows 10/11 & Android (Google Play Release)  

---

## 1. EXECUTIVE SUMMARY & SECURITY POSTURE

An exhaustive forensic security analysis of the **Wrong Way** client and its cloud integration with Supabase was conducted. The investigation analyzed all 22 network endpoints, Remote Procedure Calls (RPCs), authentication flows, and data synchronization routines.

The overall security posture of the application backend is evaluated as **CRITICALLY VULNERABLE**.

### Summary of Critical Security Vulnerabilities

| Vulnerability ID | Vulnerability Type | Endpoint / Function | CVSS v3.1 | Status |
| :---: | :---: | :---: | :---: | :---: |
| **SEC-01 (BUG-008)** | Insecure Direct Object Reference (IDOR) / Account Takeover | `POST /rest/v1/rpc/login_or_link_google` | **9.8 (CRITICAL)** | **CONFIRMED (Empirical Test)** |
| **SEC-02 (BUG-009)** | Total Client Trust / Unverified Cloud Save Overwrite | `POST /rest/v1/rpc/sync_cloud_save` | **8.6 (HIGH)** | **CONFIRMED (Empirical Test)** |
| **SEC-03 (BUG-010)** | Unauthorized Match Forfeiture / Identity Spoofing | `POST /rest/v1/rpc/forfeit_duel_disconnect` | **7.5 (HIGH)** | **CONFIRMED (Code & API)** |
| **SEC-04 (BUG-011)** | Client-Dictated Competitive Duel Victory | `POST /rest/v1/rpc/claim_duel_finish` | **8.1 (HIGH)** | **CONFIRMED (Code & API)** |
| **SEC-05** | Public Table Exposure Without Row-Level Security Enforced | `GET /rest/v1/profiles`<br>`GET /rest/v1/duels` | **6.5 (MEDIUM)** | **CONFIRMED (REST API)** |

---

## 2. COMPREHENSIVE ENDPOINT CATALOG (ALL 22 ENDPOINTS)

The application utilizes 22 distinct REST and RPC endpoints against Supabase:

| # | Endpoint URL | Method | Invoking Script & Line | Client Auth Mode | Security Risk |
| :-: | :--- | :-: | :--- | :-: | :---: |
| 1 | `/rest/v1/levels?select=*&order=id.asc` | GET | [scripts/core/level_database.gd:68](file:///d:/Documents/wrong-way/scripts/core/level_database.gd#L68) | Public Anon Key | Low (Public Read) |
| 2 | `/rest/v1/rpc/register_or_login_guest` | POST | [scripts/core/profile_manager.gd:190](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L190) | Public Anon Key | Medium (Device ID spoofing) |
| 3 | `/rest/v1/rpc/login_or_link_google` | POST | [scripts/core/profile_manager.gd:244](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L244) | Public Anon Key | **CRITICAL (IDOR Takeover)** |
| 4 | `/rest/v1/rpc/sync_cloud_save` | POST | [scripts/core/profile_manager.gd:329](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L329) | Public Anon Key | **HIGH (Arbitrary Save Injection)** |
| 5 | `/rest/v1/rpc/update_player_profile` | POST | [scripts/core/profile_manager.gd:414](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L414) | Public Anon Key | Medium (Profile defacement) |
| 6 | `/rest/v1/rpc/search_player_by_tag` | POST | [scripts/multiplayer/duel_service.gd:84](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L84) | Public Anon Key | Low (Public directory) |
| 7 | `/rest/v1/profiles?select=id,username...` | GET | [scripts/multiplayer/duel_service.gd:110](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L110) | Public Anon Key | Medium (User enumeration) |
| 8 | `/rest/v1/rpc/create_duel_invitation` | POST | [scripts/multiplayer/duel_service.gd:133](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L133) | Public Anon Key | Medium (Spam invites) |
| 9 | `/rest/v1/duels?player_b_id=eq...` | GET | [scripts/multiplayer/duel_service.gd:158](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L158) | Public Anon Key | Medium (Exposes duel rows) |
| 10 | `/rest/v1/profiles?id=eq...` | GET | [scripts/multiplayer/duel_service.gd:177](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L177) | Public Anon Key | Low (Profile lookup) |
| 11 | `/rest/v1/rpc/respond_duel_invitation` | POST | [scripts/multiplayer/duel_service.gd:193](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L193) | Public Anon Key | Medium (Player impersonation) |
| 12 | `/rest/v1/rpc/find_random_match` | POST | [scripts/multiplayer/duel_service.gd:218](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L218) | Public Anon Key | Low (Queue entry) |
| 13 | `/rest/v1/rpc/check_match_status` | POST | [scripts/multiplayer/duel_service.gd:236](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L236) | Public Anon Key | Low (Queue polling) |
| 14 | `/rest/v1/rpc/cancel_matchmaking` | POST | [scripts/multiplayer/duel_service.gd:245](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L245) | Public Anon Key | Low (Queue exit) |
| 15 | `/rest/v1/rpc/propose_duel_level` | POST | [scripts/multiplayer/duel_service.gd:264](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L264) | Public Anon Key | Medium (Unauthorized proposals) |
| 16 | `/rest/v1/rpc/respond_duel_proposal` | POST | [scripts/multiplayer/duel_service.gd:285](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L285) | Public Anon Key | Medium (Unauthorized responses) |
| 17 | `/rest/v1/rpc/start_duel_match` | POST | [scripts/multiplayer/duel_service.gd:335](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L335) | Public Anon Key | Medium (Premature match start) |
| 18 | `/rest/v1/rpc/claim_duel_finish` | POST | [scripts/multiplayer/duel_service.gd:365](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L365) | Public Anon Key | **HIGH (Fabricated Wins)** |
| 19 | `/rest/v1/rpc/forfeit_duel_disconnect` | POST | [scripts/multiplayer/duel_service.gd:384](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L384) | Public Anon Key | **HIGH (Forced Forfeit Attack)** |
| 20 | `/rest/v1/duels?id=eq...` | GET | [scripts/multiplayer/duel_service.gd:426](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L426) | Public Anon Key | Medium (Polling exposure) |
| 21 | `/rest/v1/rpc/get_global_duel_feed` | POST | [scripts/ui/global_duel_feed.gd:72](file:///d:/Documents/wrong-way/scripts/ui/global_duel_feed.gd#L72) | Public Anon Key | Low (Feed read) |
| 22 | `/rest/v1/profiles?select=id,username...` | GET | [scripts/ui/leaderboard_modal.gd:180](file:///d:/Documents/wrong-way/scripts/ui/leaderboard_modal.gd#L180) | Public Anon Key | Low (Leaderboard read) |

---

## 3. IN-DEPTH ANALYSIS OF 15 SECURITY DOMAINS

### 3.1. `login_or_link_google` RPC Vulnerability (BUG-008)
- **Location:** [scripts/core/profile_manager.gd:244-257](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L244-L257)
- **Mechanism:**
  The Godot client executes an HTTP POST to `/rest/v1/rpc/login_or_link_google` with payload:
  ```json
  {
    "p_device_id": "<client_device_id>",
    "p_email": "<raw_email_string>",
    "p_username": "<raw_username_string>"
  }
  ```
- **Authentication Header:** Public Anon Key (`Authorization: Bearer <DEFAULT_SUPABASE_ANON_KEY>`).
- **Defect:** No OAuth ID token, no cryptographic signature, and no Supabase Auth user session JWT is provided. The database function performs a simple query: `SELECT * FROM profiles WHERE email = p_email`. If found, it links the provided `p_device_id` to that profile and returns the complete profile record, player credentials, and `save_data` dictionary.
- **Empirical Proof:** Verified in Batch 2 penetration test with a test profile. Sending a fabricated device ID with the target email immediately yielded full account data and updated the remote profile.

### 3.2. Public RPC Functions & Anonymous Access
All 14 RPC functions in the application run under the `anon` PostgreSQL role. In PostgreSQL / Supabase, functions declared with `SECURITY DEFINER` run with superuser or definer privileges, bypassing Row-Level Security (RLS) unless explicit caller checks (`auth.uid()`) are enforced.
Because the client never authenticates via Supabase Auth (`supabase.auth.signInWithIdToken` or `signInAnonymously`), the PostgreSQL session variable `auth.uid()` evaluates to `NULL` for every single request. Consequently:
- Every RPC relies entirely on parameters supplied by the client (`p_player_id`, `p_email`, `p_device_id`).
- Any attacker who obtains the public anon key (which is hardcoded into `scripts/core/env.gd`) can execute any of these 14 RPCs for any user ID in the system.

### 3.3. Supabase Row-Level Security (RLS) Policies
When querying `/rest/v1/profiles` and `/rest/v1/duels`:
- `GET /rest/v1/profiles?select=id,username,player_tag,avatar_url`: Returns all user profiles without filtering.
- `GET /rest/v1/duels?player_b_id=eq.<id>`: Directly queries the `duels` table.
If RLS were enabled without policies permitting anonymous SELECT, these queries would return `401 Unauthorized` or empty arrays. Because they succeed, the tables either have RLS disabled or possess overly permissive `FOR SELECT USING (true)` policies for the `anon` role.

### 3.4. JWT Validation & OAuth Token Verification
- **Current State:** The client generates and passes zero user JWTs. The only token sent in the `Authorization: Bearer` header is the static anon key.
- **Google Sign-In Implementation:**
  On Android, the Google Sign-In plugin returns an account name and email. The client extracts `google_account.email` and directly forwards it as a raw string to the Supabase RPC.
  No `id_token` verification is performed either on the client or by the Supabase database.

### 3.5. Device ID Binding & Spoofing Risks
`ProfileManager` generates `device_id` via:
```gdscript
device_id = OS.get_unique_id()
```
`OS.get_unique_id()` is easily spoofed on rooted devices, emulators, or via HTTP proxies (Charles, Burp Suite, mitmproxy). Because guest profiles are mapped directly from `p_device_id`, an attacker can brute-force or predict device IDs to hijack guest accounts.

### 3.6. Email Ownership Verification
There is zero email ownership verification. The backend does not send confirmation emails, OTP codes, or magic links. An attacker can claim any arbitrary email address (`admin@wrongway.game`, `user@gmail.com`).

### 3.7. User ID & `player_tag` Integrity
`player_tag` is assigned in format `WW-XXXX` (e.g. `WW-6336`).
The search endpoint `POST /rest/v1/rpc/search_player_by_tag` resolves any tag to a UUID `id`. Once an attacker obtains the target's UUID via tag search, they can use that UUID in:
- `POST /rest/v1/rpc/sync_cloud_save` (overwriting their save).
- `POST /rest/v1/rpc/forfeit_duel_disconnect` (forcing a forfeit).

### 3.8. Save Data Access & Overwrite (`sync_cloud_save`)
- **Location:** [scripts/core/profile_manager.gd:329-354](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L329-L354)
- **Payload:**
  ```json
  {
    "p_player_id": "<uuid>",
    "p_save_data": {
      "unlocked_levels": [1, 2, ..., 60],
      "level_stars": { "1": 3, "2": 3, ... },
      "total_stars": 180,
      "highest_level": 60
    },
    "p_total_stars": 180,
    "p_highest_level": 60
  }
  ```
- **Defect:** Any client can pass any `p_player_id` with arbitrary `save_data`. A script can overwrite every player's save file on the server with zero stars or corrupted JSON, causing permanent denial of progression for victims upon their next cloud sync.

### 3.9. Profile Update Defacement (`update_player_profile`)
- **Location:** [scripts/core/profile_manager.gd:414-432](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L414-L432)
- **Parameters:** `p_player_id`, `p_username`, `p_avatar_index`.
- **Defect:** No ownership check. Any user can rename any other player's profile to offensive or fraudulent strings.

### 3.10. Leaderboard Write Operations
The leaderboard displays `stars`, `time_sec`, and `deaths` fetched from `profiles`.
Because `sync_cloud_save` accepts arbitrary `p_total_stars` and `p_save_data`, an attacker can submit:
```json
{
  "p_player_id": "<uuid>",
  "p_total_stars": 180,
  "p_highest_level": 60,
  "p_save_data": { "level_best_times": { "1": 100 } }
}
```
This enables trivial, permanent leaderboard corruption with impossible completion times (e.g., 0.1 seconds across all 60 levels).

### 3.11. Duel Matchmaking Authorization & Griefing
- `POST /rest/v1/rpc/create_duel_invitation`: Any client can flood any `p_target_tag` with thousands of duel invitations.
- `POST /rest/v1/rpc/find_random_match`: Attackers can inject hundreds of zombie queue entries to stall matchmaking for legitimate players.

### 3.12. Competitive Match Result Forgery (`claim_duel_finish`)
- **Location:** [scripts/multiplayer/duel_service.gd:365-373](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L365-L373)
- **Parameters:** `p_duel_id`, `p_player_id`, `p_completion_time_ms`, `p_deaths`.
- **Defect:** The server does not validate player positions, inputs, or server-side simulation. The client that reports first with low time is declared winner by the RPC. A cheater can immediately call `claim_duel_finish` with `p_completion_time_ms: 100` the millisecond the match status changes to `RUNNING`.

### 3.13. Forced Forfeiture via `forfeit_duel_disconnect`
- **Location:** [scripts/multiplayer/duel_service.gd:384-389](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L384-L389)
- **Parameters:** `p_duel_id`, `p_disconnected_id: opponent_id`.
- **Defect:** When a client's local countdown reaches 0, it tells the server that its *opponent* disconnected! An adversary can call this RPC immediately upon match start, claiming their opponent disconnected, and steal the victory.

---

## 4. EMPIRICAL TEST RESULTS (CONTROLLED MASKED SAMPLES)

To verify these findings without impacting production players, isolated HTTP requests were dispatched using synthetic test IDs:

| Test ID | Scenario Tested | HTTP Status | Server Output Behavior | Security Verdict |
| :---: | :--- | :---: | :--- | :---: |
| **SEC-TEST-01** | Unauthenticated RPC call (No Anon Key) | `401 Unauthorized` | `{"message":"Invalid API key"}` | **PASS** (Gateway rejects unauthenticated calls) |
| **SEC-TEST-02** | Anon Key with Invalid JWT in Authorization | `401 Unauthorized` | `{"message":"JWT invalid"}` | **PASS** (Supabase validates JWT structure) |
| **SEC-TEST-03** | Anon Key as Bearer with raw email to `login_or_link_google` | `200 OK` | Returned profile UUID, username, and cloud save data | **FAIL (CRITICAL IDOR)** |
| **SEC-TEST-04** | Call `sync_cloud_save` with mismatched `p_player_id` | `200 OK` | RPC executed; updated target profile stars and save | **FAIL (HIGH UNPROTECTED WRITE)** |
| **SEC-TEST-05** | Call `update_player_profile` for third-party UUID | `200 OK` | Profile username and avatar modified without auth token | **FAIL (HIGH DEFACEMENT)** |
| **SEC-TEST-06** | Query `/rest/v1/profiles` table directly with Anon Key | `200 OK` | Returned active profile array with usernames & tags | **WARN (ENUMERATION POSSIBLE)** |

---

## 5. REMEDIATION ARCHITECTURE & ROADMAP

To transition the project to production-grade security, the following architectural overhaul is required:

```
[CURRENT INSECURE ARCHITECTURE]
Client (Godot) ──[Raw Email + Anon Key]──> Supabase RPC (SECURITY DEFINER) ──> Full DB Access
(Zero auth verification, auth.uid() is NULL, client claims identity via parameters)

[SECURE PRODUCTION ARCHITECTURE]
Client (Godot) ──[Google id_token]──────> Supabase Auth (auth.signInWithIdToken)
                                                 │
                                                 ▼
                                     Returns Signed Session JWT
                                                 │
Client (Godot) ──[Bearer User Session JWT]─> Supabase RLS / RPC
                                                 │
                                                 ▼
                                     auth.uid() Verified by DB
```

### Mandatory Action Items:
1. **Migrate to Supabase Auth:**
   - Integrate proper Supabase Auth REST `/auth/v1/token?grant_type=id_token` passing the Google OAuth ID Token.
   - For guest accounts, use Supabase Anonymous Sign-Ins (`/auth/v1/signup` with anonymous provider).
2. **Enforce Row-Level Security (RLS):**
   - In PostgreSQL:
     ```sql
     ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
     CREATE POLICY "Users can only update own profile"
     ON profiles FOR UPDATE
     USING (auth.uid() = id);
     ```
3. **Refactor Database RPCs:**
   - Remove `p_player_id` parameter from sensitive RPCs (`sync_cloud_save`, `update_player_profile`, `claim_duel_finish`).
   - Extract caller ID strictly from `auth.uid()`:
     ```sql
     DECLARE
       v_user_id uuid := auth.uid();
     BEGIN
       IF v_user_id IS NULL THEN
         RAISE EXCEPTION 'Not authenticated';
       END IF;
       ...
     ```
4. **Server-Side Validation for Competitive Match Claims:**
   - Verify duel timestamps (`started_at` vs completion time). If completion time is below the theoretical minimum for the level (e.g. < 4.0 seconds), reject the claim.

