# WRONG WAY — PHASE 11: ADVERTISING & MONETIZATION AUDIT

**Document ID:** `audit/11_MONETIZATION_AUDIT.md`  
**Classification:** AdMob Integration, Monetization Lifecycle & SDK Verification  
**Audit Date:** 2026-11-06  
**Auditor:** Senior Monetization & SDK Integration Engineer  
**Files Audited:**
- [scripts/core/ad_manager.gd](file:///d:/Documents/wrong-way/scripts/core/ad_manager.gd)
- [export_presets.cfg](file:///d:/Documents/wrong-way/export_presets.cfg)
- `build/wrong-way.apk` (DEX Disassembly)
- [scripts/core/save_manager.gd](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd)
- [scripts/ui/level_select.gd](file:///d:/Documents/wrong-way/scripts/ui/level_select.gd)

---

## 1. EXECUTIVE SUMMARY & CORE MONETIZATION VERDICT

The monetization subsystem was thoroughly audited across both GDScript runtime logic and Android compiled binary structures.

The audit establishes a critical discrepancy between architecture and reality:
1. **Zero Real Ads in Production APK:** Although production Google AdMob IDs (`ca-app-pub-9009277559004471~...`) are hardcoded, **real Google AdMob advertisements cannot execute on devices**. The APK was exported with `gradle_build/use_gradle_build=false`. Binary disassembly of all 13 DEX files confirms **zero Google Mobile Ads SDK classes** exist in the compiled APK.
2. **Deceptive Mock Fallback (BUG-001):** When native AdMob singletons (`PoingGodotAdMob` or `GodotAdMob`) fail to load, `ad_manager.gd` falls back to an internal Godot UI card displaying a local 5-second countdown timer. Players perceive this as a fake/broken ad system.
3. **Release Reward Auto-Grant Bypass:** In release mode without debug flags (lines 564-566), if no ad plugin is found, `ad_manager.gd` automatically triggers `_on_claim_reward_pressed()`, unlocking levels instantly without watching any ad.
4. **Desktop Windows Behavior:** On Windows, all AdMob calls gracefully default to the mock UI timer or instant bypass, allowing non-mobile development without crashes.

---

## 2. PRODUCTION ADMOB CONFIGURATION AUDIT

### 2.1. Hardcoded Ad Unit Identifiers
In [scripts/core/ad_manager.gd](file:///d:/Documents/wrong-way/scripts/core/ad_manager.gd#L8-L12):
```gdscript
const ADMOB_APP_ID := "ca-app-pub-9009277559004471~1297962659"
const ADMOB_BANNER_ID := "ca-app-pub-9009277559004471/5320968143"
const ADMOB_INTERSTITIAL_ID := "ca-app-pub-9009277559004471/1106390961"
const ADMOB_REWARDED_ID := "ca-app-pub-9009277559004471/5903035034"
```
- **Evaluation:** Valid Google AdMob format (App ID with tilde `~`, Ad Units with slash `/`).
- **Policy Compliance Risk:** Hardcoding live production IDs without a developer test device toggle (`admob.add_test_device()`) violates Google AdMob terms of service and risks account suspension for invalid traffic during development and internal testing.

### 2.2. Export Presets Failure
In [export_presets.cfg](file:///d:/Documents/wrong-way/export_presets.cfg#L22):
```ini
gradle_build/use_gradle_build=false
```
Because Godot 4.x prebuilt standard templates do not include Google Play Services or AdMob dependencies, setting `use_gradle_build=false` bypasses the Android Gradle build pipeline. Consequently, `addons/admob` plugins remain inert GDScript wrappers with no underlying Android Java classes.

---

## 3. AD FORMAT IMPLEMENTATION AUDIT

### 3.1. Banner Advertisements
- **UI Container:** `TopBannerPanel` (Layer 120 CanvasLayer, height: 42px).
- **Placement & Layout:** Anchored top-center `(width: 340, height: 42, offset_top: 8)`.
- **Gameplay Collision Check:**
  - In `scripts/levels/gameplay.gd:8-11`:
    ```gdscript
    var adm = get_node_or_null("/root/AdManager")
    if adm and adm.has_method("hide_banner"):
        adm.hide_banner()
    ```
  - **Verdict: PASS.** Banner ads are strictly hidden during active level runs. They never overlap or obscure on-screen player controls or hazard zones.

### 3.2. Rewarded Video Ads (Level Unlock)
- **Trigger Scenario:** Player selects a locked level in `level_select.gd` and clicks "Mukofotli Reklama".
- **Pacing Rules Enforced:**
  1. Only the immediate next locked level can be unlocked.
  2. Prior stage must have been attempted at least once.
  3. Alternating "skip-one" rule: at least 1 stage must be beaten normally between ad unlocks.
- **Reward Delivery & Deduplication:**
  - Uses `pending_reward_callback = on_reward_callback`.
  - Once user clicks "DARAJANI OCHISH" (after timer reaches 5.0s):
    ```gdscript
    if pending_reward_callback.is_valid():
        pending_reward_callback.call()
        pending_reward_callback = Callable()
    ```
  - **Verdict: PASS.** Setting `pending_reward_callback = Callable()` immediately after execution prevents duplicate reward disbursement on repeated button taps.

### 3.3. Interstitial Advertisements (Replay Level)
- **Trigger Scenario:** Player replays a previously completed level.
- **Duration:** 4.0 seconds with skip button (`interstitial_skip_btn`) enabled after 2.5 seconds.
- **Gameplay Interruption:** Only triggers before the level reload, paused via `process_mode = PROCESS_MODE_ALWAYS`.

---

## 4. REGULATORY & PRIVACY AUDIT (GDPR / UMP / COPPA)

- **User Consent Verification:**
  Line 34 of `ad_manager.gd`:
  ```gdscript
  var consent_granted: bool = true
  ```
- **Finding:**
  The game does **not** implement Google's User Messaging Platform (UMP) SDK.
  In the European Economic Area (EEA) and the UK, Google requires a certified Consent Management Platform (CMP) to serve personalized or non-personalized ads.
  Without UMP integration, Google Mobile Ads SDK will automatically drop ad fill rates to near zero for European users upon publication on Google Play.

---

## 5. MONETIZATION LIFECYCLE AUDIT MATRIX

| Check Item | Result | Evidence / Implementation | Severity |
| :--- | :---: | :--- | :---: |
| **Real AdMob Ads on Android** | **FAIL** | Zero DEX classes; `use_gradle_build=false` (BUG-001). | **HIGH** |
| **Banner Hiding in Gameplay** | **PASS** | `gameplay.gd` calls `AdManager.hide_banner()` on load. | **PASS** |
| **Rewarded Ad Callback Safety** | **PASS** | Callable cleared upon execution; zero duplicate grants. | **PASS** |
| **Ad Freezes Gameplay Physics** | **PASS** | Ad layer runs on independent CanvasLayer 120. | **PASS** |
| **Unplanned Ads During Level** | **PASS** | Zero mid-level interstitial popups. | **PASS** |
| **Network Failure Handling** | **PASS** | Offline players gracefully fall back to local UI timer. | **PASS** |
| **Test Device Protection** | **WARN** | Production AdMob IDs called without test device flags. | **MEDIUM** |
| **UMP / GDPR Consent Dialog** | **FAIL** | Hardcoded `consent_granted = true`; no UMP dialog. | **HIGH** |

---

## 6. RECOMMENDATIONS FOR PRODUCTION RELEASE

1. **Enable Gradle Build in Export Preset:**
   In `export_presets.cfg`, set `gradle_build/use_gradle_build=true`.
2. **Install Official Godot Android AdMob Plugin:**
   Download the compiled `.aar` library from the official Poing Studios Godot AdMob release and place it into `android/plugins/`.
3. **Integrate Google UMP Consent:**
   Implement UMP consent request before initializing AdMob on first launch in European regions.
4. **Implement Test Device IDs:**
   Add developer device hashes to `admob.initialize()` to prevent ad network bans during testing.

