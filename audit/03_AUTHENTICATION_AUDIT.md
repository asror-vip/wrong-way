# WRONG WAY — PHASE 3: AUTHENTICATION & REGISTRATION AUDIT

**Audit Phase:** 03 — Authentication & Player Identity  
**Audit Date:** 2026-11-06  
**Auditor:** Application Security & QA Engineering Team  
**Backend:** Supabase Cloud REST / RPC API  
**Status:** **AUDITED — CRITICAL VULNERABILITY CONFIRMED**  

---

## 1. EXECUTIVE AUTHENTICATION SUMMARY

| Authentication Flow | Platform | Real OAuth Flow? | Cryptographic Token Validation? | Account Hijacking Risk | Verdict |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Guest Profile Creation** | All | N/A (UUID device-based) | N/A (Anonymous Key) | Low (Isolated per device UUID) | **PASS** |
| **Desktop Google Sign-In** | Windows / PC | **YES** (Supabase OAuth Loopback) | **NO** (Client drops JWT; sends raw email string) | **CRITICAL (IDOR)** | **FAIL** |
| **Android Google Sign-In** | Android Mobile | **NO** (Missing plugins) | **NO** | Blocked on device | **FAIL** |
| **Session Persistence** | All | Local JSON cache | Plaintext on disk | Low | **PASS** |
| **Token Refresh Lifecycle** | Desktop | Refresh token stored | Never called | Stale session risk | **NEEDS WORK** |

---

## 2. DETAILED LIFECYCLE REVIEWS

### 2.1 First Application Launch & Guest Identity
- **Entry Point:** [scripts/ui/splash_screen.gd](file:///d:/Documents/wrong-way/scripts/ui/splash_screen.gd) -> [scripts/core/profile_manager.gd](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd).
- **Mechanism:**
  1. Checks `user://device_id.txt`. If missing, generates UUID via `OS.get_unique_id()` or timestamp fallback.
  2. Calls Supabase RPC `register_or_login_guest` with `p_device_id`.
  3. Supabase returns `WW-XXXX` player tag and UUID `id`.
  4. Cached locally in `user://player_profile.json`.
- **Verdict:** **PASS**. Clean anonymous onboarding without blocking user.

---

### 2.2 Desktop Google Sign-In (Windows / Mac)
- **Files:** [scripts/core/google_auth_service.gd](file:///d:/Documents/wrong-way/scripts/core/google_auth_service.gd#L122-L354).
- **Mechanism:**
  1. `GoogleAuthService` launches local loopback HTTP server on `127.0.0.1:8943/callback`.
  2. Opens system browser to Supabase Google OAuth endpoint:
     `https://<supabase-url>/auth/v1/authorize?provider=google&redirect_to=http://127.0.0.1:8943/callback`.
  3. Browser receives Google redirect containing `access_token` and `refresh_token` in fragment.
  4. JavaScript extracts fragment and queries loopback server: `/callback?access_token=...`.
  5. `_fetch_supabase_user(access_token)` queries `/auth/v1/user` with `Authorization: Bearer <access_token>`.
  6. Supabase confirms authenticated user identity (email and name).
- **Verdict:** Real Google OAuth flow operates correctly on PC.

---

### 2.3 Android Google Sign-In
- **Files:** [scripts/core/google_auth_service.gd](file:///d:/Documents/wrong-way/scripts/core/google_auth_service.gd#L37-L78).
- **Mechanism:**
  1. Checks for singletons: `WrongWayAccountPicker`, `GodotPlayGames`, `GoogleSignIn`.
  2. **None of these singletons exist in the Android APK export.**
  3. Immediately fails with signal:
     `auth_failed.emit("Google orqali kirish bu qurilmada mavjud emas.")`.
- **Verdict:** **FAIL (BLOCKED)**. Google sign-in is completely non-functional on Android devices.

---

## 3. CRITICAL SECURITY DEFECT: IDOR & RAW EMAIL IMPERSONATION (BUG-AUTH-001)

### Technical Analysis:
Although `GoogleAuthService` retrieves a valid Google OAuth access token on PC, **it does not pass this JWT to the database**.
Instead, [scripts/core/profile_manager.gd](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L244-L257) executes:
```gdscript
var url: String = Env.get_supabase_url() + "/rest/v1/rpc/login_or_link_google"
var anon_key: String = Env.get_supabase_anon_key()
var headers := [
    "apikey: " + anon_key,
    "Authorization: Bearer " + anon_key,
    "Content-Type: application/json"
]
var payload := JSON.stringify({
    "p_device_id": device_id,
    "p_email": clean_email,
    "p_username": clean_name,
    "p_avatar_url": "av_" + str(avatar_index)
})
http_google.request(url, headers, HTTPClient.METHOD_POST, payload)
```

### Empirical Penetration Test:
We executed an unauthorized curl/Node.js request with a spoofed device ID and raw email:
```bash
POST https://wcwjobrrwwjfthpflzhg.supabase.co/rest/v1/rpc/login_or_link_google
{
  "p_device_id": "fake_test_device_9999",
  "p_email": "asror8471@gmail.com",
  "p_username": "Test Hacker"
}
```
**Server Response (Status 200 OK):**
```json
{
  "id": "3ff8c9ae-963e-4b1b-a653-0efae00c8687",
  "email": "asror8471@gmail.com",
  "username": "Asror",
  "player_tag": "WW-6336",
  "total_stars": 25,
  "highest_level": 11,
  "save_data": { ... }
}
```
### Impact:
Anyone with the public anon key (embedded in the game code) can impersonate any Google user and download or overwrite their cloud saves simply by passing their email address string.

---

## 4. PERSISTENCE & MULTI-DEVICE EDGE CASES

| Scenario | Behavior | Evaluation |
| :--- | :--- | :--- |
| **Offline Startup** | Loads `user://player_profile.json` locally; game plays offline with local tag. | **PASS** |
| **Logout to Guest** | `logout_to_guest()` generates a new randomized `device_id` and resets player tag to prevent data leakage. | **PASS** |
| **Two Devices, Same Account** | The latest `sync_save_to_cloud()` RPC overwrites `save_data` in Supabase; `SaveManager.merge_cloud_save()` takes the higher star count. | **PASS** |
| **Token Refresh** | `_store_refresh_token()` writes to disk, but `ProfileManager` never calls `/auth/v1/token?grant_type=refresh_token`. | **RISK** |

