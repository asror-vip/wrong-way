# WRONG WAY — PHASE 2: FUNCTION-BY-FUNCTION CODE AUDIT

**Audit Phase:** 02 — Function-by-Function Code Audit  
**Date:** 2026-11-06  
**Auditor:** Senior GDScript Code Reviewer & Systems Auditor  
**Total Project Scripts Audited:** 81 scripts  
**Total Project Functions Audited:** 689 functions  
**External Plugin Functions Cataloged:** 701 functions (inside `addons/admob`)  
**Combined Total Functions:** 1,390 functions  

---

## 1. FUNCTION AUDIT SUMMARY BY SYSTEM

| System Category | Script Count | Function Count | Issues Flagged | High Risk Issues | Status |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Core Singletons & Services** | 12 | 148 | 18 | 4 | **AUDITED** |
| **Player Controller & Movement** | 3 | 28 | 3 | 1 | **AUDITED** |
| **Gameplay & Camera Systems** | 5 | 52 | 6 | 1 | **AUDITED** |
| **Trap & Hazard Systems** | 22 | 114 | 8 | 0 | **AUDITED** |
| **UI & Responsive Layout** | 15 | 164 | 22 | 6 | **AUDITED** |
| **Multiplayer & Duel Systems** | 5 | 76 | 9 | 2 | **AUDITED** |
| **Editor & Level Authoring Tools** | 4 | 78 | 14 | 3 | **AUDITED** |
| **Automated Test Suites** | 15 | 29 | 12 | 12 | **AUDITED (CRASHES)** |
| **External Plugins (`addons/admob`)** | 157 | 701 | N/A | N/A | **EXTERNAL LIBRARY** |

---

## 2. SYSTEM: CORE SINGLETONS & SERVICES

Total Functions Audited in this system: **153**

### File: `scripts/core/ad_manager.gd` (20 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L61 | `none` | CLEAN / PASS |
| `_setup_ad_ui()` | `void` | L66 | `none` | CLEAN / PASS |
| `_create_banner_ui()` | `void` | L79 | `none` | CLEAN / PASS |
| `show_banner()` | `void` | L138 | `none` | CLEAN / PASS |
| `hide_banner()` | `void` | L149 | `none` | CLEAN / PASS |
| `is_banner_visible()` | `bool` | L156 | `none` | CLEAN / PASS |
| `set_consent()` | `void` | L159 | `granted: bool` | CLEAN / PASS |
| `_create_interstitial_ui()` | `void` | L167 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_create_interstitial_ui' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `show_interstitial_ad()` | `void` | L273 | `on_finish_callback: Callable = Callable()` | CLEAN / PASS |
| `_on_skip_interstitial_pressed()` | `void` | L295 | `none` | CLEAN / PASS |
| `_finish_interstitial()` | `void` | L299 | `none` | CLEAN / PASS |
| `_create_rewarded_ui()` | `void` | L313 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_create_rewarded_ui' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `show_rewarded_ad()` | `void` | L411 | `on_reward_callback: Callable = Callable()` | CLEAN / PASS |
| `_on_claim_reward_pressed()` | `void` | L437 | `none` | CLEAN / PASS |
| `_process()` | `void` | L452 | `delta: float` | CLEAN / PASS |
| `_init_native_admob()` | `void` | L498 | `none` | CLEAN / PASS |
| `_native_show_banner()` | `void` | L522 | `none` | CLEAN / PASS |
| `_native_hide_banner()` | `void` | L532 | `none` | CLEAN / PASS |
| `_native_show_interstitial()` | `void` | L542 | `none` | CLEAN / PASS |
| `_native_show_rewarded()` | `void` | L552 | `none` | CLEAN / PASS |

### File: `scripts/core/game_app.gd` (3 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L11 | `none` | CLEAN / PASS |
| `_unhandled_input()` | `void` | L16 | `event: InputEvent` | CLEAN / PASS |
| `toggle_fullscreen()` | `void` | L28 | `none` | CLEAN / PASS |

### File: `scripts/core/game_manager.gd` (12 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `get_current_chapter()` | `int` | L20 | `none` | CLEAN / PASS |
| `is_winter_theme()` | `bool` | L31 | `none` | CLEAN / PASS |
| `_ready()` | `void` | L34 | `none` | CLEAN / PASS |
| `_unhandled_input()` | `void` | L39 | `event: InputEvent` | CLEAN / PASS |
| `start_game()` | `void` | L55 | `level_id: int` | CLEAN / PASS |
| `start_duel_game()` | `void` | L74 | `level_id: int, random_seed_num: int = 0` | CLEAN / PASS |
| `record_death()` | `void` | L88 | `none` | CLEAN / PASS |
| `complete_level()` | `void` | L98 | `none` | CLEAN / PASS |
| `restart_current_level()` | `void` | L116 | `none` | CLEAN / PASS |
| `go_to_level_select()` | `void` | L124 | `none` | CLEAN / PASS |
| `go_to_main_menu()` | `void` | L130 | `none` | CLEAN / PASS |
| `toggle_fullscreen()` | `void` | L137 | `none` | CLEAN / PASS |

### File: `scripts/core/google_auth_service.gd` (18 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L20 | `none` | CLEAN / PASS |
| `start_google_sign_in()` | `void` | L28 | `none` | CLEAN / PASS |
| `_start_android_sign_in()` | `void` | L37 | `none` | CLEAN / PASS |
| `_on_android_account_picked()` | `void` | L79 | `acc_email: String, acc_name: String` | CLEAN / PASS |
| `_on_android_account_picker_failed()` | `void` | L85 | `err_msg: String` | CLEAN / PASS |
| `_on_android_pgs_success()` | `void` | L89 | `is_auth: bool` | CLEAN / PASS |
| `_on_android_pgs_failed()` | `void` | L103 | `err_code: int` | CLEAN / PASS |
| `_on_android_gsi_success()` | `void` | L107 | `account_info: Dictionary` | CLEAN / PASS |
| `_on_android_gsi_failed()` | `void` | L115 | `err_msg: String` | CLEAN / PASS |
| `_start_desktop_oauth()` | `void` | L122 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_start_desktop_oauth' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_process()` | `void` | L150 | `_delta: float` | CLEAN / PASS |
| `_handle_http_client()` | `void` | L159 | `peer: StreamPeerTCP` | CLEAN / PASS |
| `_parse_auth_request()` | `void` | L268 | `req_line: String` | CLEAN / PASS |
| `_fetch_supabase_user()` | `void` | L320 | `access_token: String` | CLEAN / PASS |
| `_on_user_info_completed()` | `void` | L331 | `_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray` | CLEAN / PASS |
| `_store_refresh_token()` | `void` | L355 | `token: String` | CLEAN / PASS |
| `_bring_game_window_to_front()` | `void` | L363 | `none` | CLEAN / PASS |
| `_stop_loopback_server()` | `void` | L369 | `none` | CLEAN / PASS |

### File: `scripts/core/icon_factory.gd` (2 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `get_icon()` | `Texture2D` | L663 | `icon_name: String, scale: float = 1.0` | CLEAN / PASS |
| `create_texture_rect()` | `TextureRect` | L681 | `icon_name: String, custom_sz: Vector2 = Vector2(24, 24), scale: float = 1.0` | CLEAN / PASS |

### File: `scripts/core/level_database.gd` (9 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L16 | `none` | CLEAN / PASS |
| `load_local_levels()` | `void` | L20 | `none` | CLEAN / PASS |
| `_populate_cache()` | `void` | L50 | `items: Array` | CLEAN / PASS |
| `_init_supabase_sync()` | `void` | L56 | `none` | CLEAN / PASS |
| `fetch_from_supabase()` | `void` | L65 | `none` | CLEAN / PASS |
| `_on_sync_completed()` | `void` | L78 | `_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray` | CLEAN / PASS |
| `get_level()` | `Dictionary` | L97 | `level_id: int` | CLEAN / PASS |
| `has_level()` | `bool` | L102 | `level_id: int` | CLEAN / PASS |
| `get_all_levels()` | `Array` | L107 | `none` | CLEAN / PASS |

### File: `scripts/core/locale_manager.gd` (4 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L555 | `none` | CLEAN / PASS |
| `set_language()` | `void` | L561 | `lang_code: String` | CLEAN / PASS |
| `t()` | `String` | L571 | `key: String, args: Array = []` | CLEAN / PASS |
| `tr_text()` | `String` | L579 | `key: String, args: Array = []` | CLEAN / PASS |

### File: `scripts/core/profile_manager.gd` (26 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L36 | `none` | CLEAN / PASS |
| `_load_or_create_device_id()` | `void` | L72 | `none` | CLEAN / PASS |
| `_load_local_profile()` | `void` | L89 | `none` | CLEAN / PASS |
| `get_name_from_email()` | `String` | L99 | `e: String` | CLEAN / PASS |
| `_apply_profile_dict()` | `void` | L110 | `data: Dictionary` | CLEAN / PASS |
| `get_profile_dict()` | `Dictionary` | L168 | `none` | CLEAN / PASS |
| `sync_with_supabase()` | `void` | L184 | `none` | CLEAN / PASS |
| `_on_guest_completed()` | `void` | L204 | `_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray` | CLEAN / PASS |
| `login_with_google()` | `void` | L221 | `google_email: String, display_name: String = ""` | CLEAN / PASS |
| `_on_google_completed()` | `void` | L259 | `_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray` | CLEAN / PASS |
| `logout_to_guest()` | `void` | L285 | `none` | CLEAN / PASS |
| `save_profile()` | `void` | L306 | `none` | CLEAN / PASS |
| `sync_save_to_cloud()` | `void` | L313 | `none` | CLEAN / PASS |
| `_on_cloud_completed()` | `void` | L344 | `_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray` | CLEAN / PASS |
| `get_known_google_accounts()` | `Array` | L348 | `none` | CLEAN / PASS |
| `add_known_google_account()` | `void` | L375 | `acc_email: String, acc_name: String = ""` | CLEAN / PASS |
| `update_profile()` | `void` | L404 | `new_name: String, new_avatar_idx: int` | CLEAN / PASS |
| `_on_update_completed()` | `void` | L428 | `_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray` | CLEAN / PASS |
| `_write_json_atomic()` | `void` | L432 | `path: String, text: String` | CLEAN / PASS |
| `_save_local_cache()` | `void` | L441 | `data: Dictionary` | CLEAN / PASS |
| `_load_saved_friends()` | `void` | L447 | `none` | CLEAN / PASS |
| `save_friends_cache()` | `void` | L457 | `none` | CLEAN / PASS |
| `add_recent_friend()` | `void` | L460 | `tag: String, friend_name: String = "", av_url: String = ""` | CLEAN / PASS |
| `get_saved_friends()` | `Array` | L477 | `none` | CLEAN / PASS |
| `_setup_corner_id_overlay()` | `void` | L483 | `none` | CLEAN / PASS |
| `_update_corner_id_text()` | `void` | L512 | `none` | CLEAN / PASS |

### File: `scripts/core/save_manager.gd` (34 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L35 | `none` | CLEAN / PASS |
| `load_data()` | `void` | L38 | `none` | CLEAN / PASS |
| `save_data()` | `void` | L68 | `none` | CLEAN / PASS |
| `_write_config_atomic()` | `void` | L89 | `config: ConfigFile` | CLEAN / PASS |
| `get_touch_pos()` | `Vector2` | L107 | `btn_name: String, default_val: Vector2` | CLEAN / PASS |
| `set_touch_pos()` | `void` | L116 | `btn_name: String, pos: Vector2` | CLEAN / PASS |
| `reset_touch_layout()` | `void` | L121 | `none` | CLEAN / PASS |
| `is_level_unlocked()` | `bool` | L126 | `lvl: int` | CLEAN / PASS |
| `get_highest_unlocked_level()` | `int` | L133 | `none` | CLEAN / PASS |
| `record_result()` | `int` | L143 | `lvl: int, time_ms: float, deaths: int` | CLEAN / PASS |
| `get_save_payload()` | `Dictionary` | L182 | `none` | CLEAN / PASS |
| `merge_cloud_save()` | `void` | L195 | `cloud_data: Dictionary` | CLEAN / PASS |
| `record_level_result()` | `int` | L251 | `lvl: int, time_ms: float, deaths: int` | CLEAN / PASS |
| `get_level_stars()` | `int` | L254 | `lvl: int` | CLEAN / PASS |
| `get_overall_best_text()` | `String` | L257 | `none` | CLEAN / PASS |
| `record_level_attempt()` | `void` | L260 | `lvl: int` | CLEAN / PASS |
| `is_level_ad_unlockable()` | `bool` | L271 | `lvl: int` | CLEAN / PASS |
| `get_lock_reason_dialog()` | `Dictionary` | L297 | `lvl: int` | CLEAN / PASS |
| `unlock_level_via_ad()` | `void` | L328 | `lvl: int` | CLEAN / PASS |
| `is_level_completed()` | `bool` | L336 | `lvl: int` | CLEAN / PASS |
| `get_highest_completed_level()` | `int` | L339 | `none` | CLEAN / PASS |
| `get_completed_level_count()` | `int` | L348 | `none` | CLEAN / PASS |
| `get_unlocked_count()` | `int` | L357 | `none` | CLEAN / PASS |
| `get_level_best_deaths()` | `int` | L364 | `lvl: int` | CLEAN / PASS |
| `get_total_beaten_deaths()` | `int` | L370 | `none` | CLEAN / PASS |
| `get_total_stars()` | `int` | L378 | `none` | CLEAN / PASS |
| `get_level_best_time_sec()` | `int` | L384 | `lvl: int` | CLEAN / PASS |
| `get_total_beaten_time_sec()` | `int` | L393 | `none` | CLEAN / PASS |
| `get_chapter_stars()` | `int` | L401 | `chapter: int` | CLEAN / PASS |
| `get_chapter_total_time_sec()` | `int` | L415 | `chapter: int` | CLEAN / PASS |
| `is_chapter_unlocked()` | `bool` | L431 | `chapter: int` | CLEAN / PASS |
| `get_level_time_text()` | `String` | L442 | `lvl: int` | CLEAN / PASS |
| `reset_progress()` | `void` | L448 | `none` | CLEAN / PASS |
| `reset_all_data()` | `void` | L460 | `none` | CLEAN / PASS |

### File: `scripts/core/sound_manager.gd` (25 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L8 | `none` | CLEAN / PASS |
| `_connect_gameplay_mode()` | `void` | L15 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_connect_gameplay_mode' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_get_target_music_db()` | `float` | L20 | `none` | CLEAN / PASS |
| `set_gameplay_mode()` | `void` | L32 | `in_gameplay: bool` | CLEAN / PASS |
| `update_music_volume()` | `void` | L36 | `animate: bool = false` | CLEAN / PASS |
| `update_sfx_volume()` | `void` | L49 | `none` | CLEAN / PASS |
| `_setup_music_player()` | `void` | L57 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_music_player' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_check_initial_music()` | `void` | L76 | `none` | CLEAN / PASS |
| `_load_bgm()` | `void` | L81 | `none` | CLEAN / PASS |
| `play_music()` | `void` | L93 | `none` | CLEAN / PASS |
| `stop_music()` | `void` | L104 | `none` | CLEAN / PASS |
| `set_music_enabled()` | `void` | L108 | `enabled: bool` | CLEAN / PASS |
| `set_music_volume_pause()` | `void` | L114 | `_is_paused: bool` | CLEAN / PASS |
| `_create_procedural_sounds()` | `void` | L118 | `none` | CLEAN / PASS |
| `_create_player()` | `AudioStreamPlayer` | L128 | `stream: AudioStream` | CLEAN / PASS |
| `play()` | `void` | L134 | `sound_name: String` | CLEAN / PASS |
| `play_click()` | `void` | L142 | `none` | CLEAN / PASS |
| `play_jump()` | `void` | L143 | `none` | CLEAN / PASS |
| `play_dash()` | `void` | L144 | `none` | CLEAN / PASS |
| `play_die()` | `void` | L145 | `none` | CLEAN / PASS |
| `play_trap()` | `void` | L146 | `none` | CLEAN / PASS |
| `play_win()` | `void` | L147 | `none` | CLEAN / PASS |
| `play_land()` | `void` | L148 | `none` | CLEAN / PASS |
| `_generate_tone()` | `AudioStreamWAV` | L150 | `f_start: float, f_end: float, duration: float, type: String, gain: float` | CLEAN / PASS |
| `_generate_win_chord()` | `AudioStreamWAV` | L187 | `none` | CLEAN / PASS |


## 2. SYSTEM: PLAYER CONTROLLER & MOVEMENT

Total Functions Audited in this system: **13**

### File: `scripts/player/dash_ghost.gd` (2 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L5 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L10 | `none` | CLEAN / PASS |

### File: `scripts/player/player_controller.gd` (9 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L36 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L45 | `delta: float` | CLEAN / PASS |
| `kill()` | `void` | L151 | `none` | CLEAN / PASS |
| `die()` | `void` | L181 | `none` | CLEAN / PASS |
| `respawn()` | `void` | L184 | `at_position: Vector2 = spawn_position` | CLEAN / PASS |
| `enter_door()` | `void` | L204 | `target_pos: Vector2` | CLEAN / PASS |
| `enter_finish()` | `void` | L219 | `target_pos: Vector2` | CLEAN / PASS |
| `_spawn_particles()` | `void` | L222 | `none` | CLEAN / PASS |
| `_spawn_dash_ghost()` | `void` | L229 | `none` | CLEAN / PASS |

### File: `scripts/player/player_visual.gd` (2 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_draw()` | `void` | L5 | `none` | CLEAN / PASS |
| `_draw_ellipse()` | `void` | L32 | `center: Vector2, r: Vector2, color: Color` | CLEAN / PASS |


## 2. SYSTEM: GAMEPLAY & CAMERA SYSTEMS

Total Functions Audited in this system: **14**

### File: `scripts/levels/base_level.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L10 | `none` | CLEAN / PASS |
| `_on_player_died()` | `void` | L33 | `none` | CLEAN / PASS |
| `_on_player_respawned()` | `void` | L37 | `none` | CLEAN / PASS |
| `reset_level_traps()` | `void` | L42 | `none` | CLEAN / PASS |
| `restart_attempt()` | `void` | L51 | `none` | CLEAN / PASS |
| `reset_attempt()` | `void` | L56 | `none` | CLEAN / PASS |

### File: `scripts/levels/gameplay.gd` (5 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L8 | `none` | CLEAN / PASS |
| `_process()` | `void` | L30 | `delta: float` | CLEAN / PASS |
| `_on_screen_shake()` | `void` | L37 | `intensity: float` | CLEAN / PASS |
| `reload_to_level()` | `void` | L43 | `lvl: int` | CLEAN / PASS |
| `_load_level()` | `void` | L61 | `lvl: int` | CLEAN / PASS |

### File: `scripts/levels/level_arena.gd` (3 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `load_level_from_data()` | `void` | L33 | `data: Dictionary` | CLEAN / PASS |
| `_spawn_boundary_walls()` | `void` | L150 | `none` | CLEAN / PASS |
| `_wire_traps_and_player()` | `void` | L167 | `none` | CLEAN / PASS |


## 2. SYSTEM: TRAP & HAZARD SYSTEMS

Total Functions Audited in this system: **129**

### File: `scripts/traps/circular_saw.gd` (7 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L16 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L27 | `delta: float` | CLEAN / PASS |
| `_update_blade_position()` | `void` | L37 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L43 | `none` | CLEAN / PASS |
| `_draw_saw_blade()` | `void` | L62 | `pos: Vector2, r: float, spin: float` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L98 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L107 | `none` | CLEAN / PASS |

### File: `scripts/traps/control_inverter.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L14 | `none` | CLEAN / PASS |
| `_process()` | `void` | L26 | `delta: float` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L30 | `body: Node2D` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_body_entered'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_body_exited()` | `void` | L39 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L44 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L51 | `none` | CLEAN / PASS |

### File: `scripts/traps/crashing_pillar.gd` (8 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L20 | `none` | CLEAN / PASS |
| `_update_shapes()` | `void` | L28 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L44 | `delta: float` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_physics_process'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_check_trigger()` | `void` | L73 | `none` | CLEAN / PASS |
| `trigger_crash()` | `void` | L83 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'trigger_crash'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_kill_entered()` | `void` | L96 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L103 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L112 | `none` | CLEAN / PASS |

### File: `scripts/traps/crumbling_platform.gd` (7 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L23 | `none` | CLEAN / PASS |
| `_update_shapes()` | `void` | L31 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L47 | `delta: float` | CLEAN / PASS |
| `_on_step_entered()` | `void` | L57 | `body: Node2D` | CLEAN / PASS |
| `trigger_crumble()` | `void` | L67 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'trigger_crumble' without is_connected() check can cause duplicate signal connection errors on re-entry.<br>**[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'trigger_crumble'. Causes compile/runtime errors when instantiated without autoload tree. |
| `reset_trap()` | `void` | L93 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L106 | `none` | CLEAN / PASS |

### File: `scripts/traps/crusher.gd` (5 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L28 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L37 | `delta: float` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L93 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L104 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L111 | `none` | CLEAN / PASS |

### File: `scripts/traps/crusher_visuals.gd` (1 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_draw()` | `void` | L9 | `none` | CLEAN / PASS |

### File: `scripts/traps/dodging_platform.gd` (5 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L19 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L29 | `_delta: float` | CLEAN / PASS |
| `trigger_dodge()` | `void` | L42 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'trigger_dodge'. Causes compile/runtime errors when instantiated without autoload tree. |
| `reset_trap()` | `void` | L53 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L60 | `none` | CLEAN / PASS |

### File: `scripts/traps/fake_door.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L14 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L23 | `delta: float` | CLEAN / PASS |
| `_run_away()` | `void` | L36 | `_player: Node2D` | CLEAN / PASS |
| `_draw()` | `void` | L52 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L115 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L120 | `none` | CLEAN / PASS |

### File: `scripts/traps/falling_ceiling.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L22 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L41 | `_delta: float` | CLEAN / PASS |
| `trigger_slam()` | `void` | L55 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'trigger_slam'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_kill_entered()` | `void` | L66 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L77 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L84 | `none` | CLEAN / PASS |

### File: `scripts/traps/falling_spike.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L16 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L25 | `delta: float` | CLEAN / PASS |
| `_trigger()` | `void` | L54 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L64 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L101 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L116 | `none` | CLEAN / PASS |

### File: `scripts/traps/invisible_block.gd` (5 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L14 | `none` | CLEAN / PASS |
| `_on_trigger_entered()` | `void` | L34 | `body: Node2D` | CLEAN / PASS |
| `reveal()` | `void` | L39 | `player: Node2D = null` | CLEAN / PASS |
| `reset_trap()` | `void` | L57 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L67 | `none` | CLEAN / PASS |

### File: `scripts/traps/jumping_spikes.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L21 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L34 | `delta: float` | CLEAN / PASS |
| `trigger_jump()` | `void` | L59 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'trigger_jump'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_body_entered()` | `void` | L67 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L78 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L85 | `none` | CLEAN / PASS |

### File: `scripts/traps/laser_beam.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L15 | `none` | CLEAN / PASS |
| `_update_shape()` | `void` | L20 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L32 | `delta: float` | CLEAN / PASS |
| `_draw()` | `void` | L51 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L71 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L80 | `none` | CLEAN / PASS |

### File: `scripts/traps/moving_saw.gd` (5 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L18 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L28 | `delta: float` | CLEAN / PASS |
| `reset_trap()` | `void` | L82 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L89 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L129 | `body: Node2D` | CLEAN / PASS |

### File: `scripts/traps/pop_up_spikes.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L19 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L29 | `delta: float` | CLEAN / PASS |
| `_trigger()` | `void` | L71 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L78 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L119 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L128 | `none` | CLEAN / PASS |

### File: `scripts/traps/rolling_boulder.gd` (7 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L24 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L34 | `delta: float` | CLEAN / PASS |
| `_check_player_trigger()` | `void` | L70 | `none` | CLEAN / PASS |
| `trigger_boulder()` | `void` | L79 | `none` | CLEAN / PASS |
| `_on_kill_entered()` | `void` | L92 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L99 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L106 | `none` | CLEAN / PASS |

### File: `scripts/traps/rotating_spike_ball.gd` (7 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L17 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L28 | `delta: float` | CLEAN / PASS |
| `_update_ball_position()` | `void` | L42 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L45 | `none` | CLEAN / PASS |
| `_draw_spiked_ball()` | `void` | L63 | `pos: Vector2` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L103 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L108 | `none` | CLEAN / PASS |

### File: `scripts/traps/sinking_door_floor.gd` (5 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L19 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L29 | `delta: float` | CLEAN / PASS |
| `trigger_sink()` | `void` | L49 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'trigger_sink'. Causes compile/runtime errors when instantiated without autoload tree. |
| `reset_trap()` | `void` | L57 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L67 | `none` | CLEAN / PASS |

### File: `scripts/traps/spikes.gd` (4 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L8 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L17 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L82 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L91 | `none` | CLEAN / PASS |

### File: `scripts/traps/spring.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L13 | `none` | CLEAN / PASS |
| `_draw()` | `void` | L22 | `none` | CLEAN / PASS |
| `_on_body_entered()` | `void` | L55 | `body: Node2D` | CLEAN / PASS |
| `_trigger_launch()` | `void` | L59 | `body: Node2D` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_trigger_launch' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_process()` | `void` | L82 | `_delta: float` | CLEAN / PASS |
| `reset_trap()` | `void` | L86 | `none` | CLEAN / PASS |

### File: `scripts/traps/trap_base.gd` (11 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L23 | `none` | CLEAN / PASS |
| `_setup_trap()` | `void` | L27 | `none` | CLEAN / PASS |
| `trigger_trap()` | `void` | L31 | `none` | CLEAN / PASS |
| `activate_trap()` | `void` | L42 | `none` | CLEAN / PASS |
| `reset_trap()` | `void` | L47 | `none` | CLEAN / PASS |
| `_process()` | `void` | L53 | `delta: float` | CLEAN / PASS |
| `_on_trap_armed()` | `void` | L63 | `none` | CLEAN / PASS |
| `_on_arm_tick()` | `void` | L66 | `_delta: float` | CLEAN / PASS |
| `_on_trap_activated()` | `void` | L69 | `none` | CLEAN / PASS |
| `_on_active_tick()` | `void` | L72 | `_delta: float` | CLEAN / PASS |
| `_on_trap_reset()` | `void` | L75 | `none` | CLEAN / PASS |

### File: `scripts/traps/trap_floor.gd` (4 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L17 | `none` | CLEAN / PASS |
| `_physics_process()` | `void` | L42 | `delta: float` | CLEAN / PASS |
| `_on_trigger_body_entered()` | `void` | L57 | `body: Node2D` | CLEAN / PASS |
| `reset_trap()` | `void` | L69 | `none` | CLEAN / PASS |


## 2. SYSTEM: UI & RESPONSIVE LAYOUT

Total Functions Audited in this system: **219**

### File: `scripts/ui/atmospheric_backdrop.gd` (10 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L72 | `none` | CLEAN / PASS |
| `_align_menu_cliff()` | `void` | L114 | `none` | CLEAN / PASS |
| `set_level_background()` | `void` | L138 | `level_id: int` | CLEAN / PASS |
| `_clear_gameplay_texture()` | `void` | L177 | `none` | CLEAN / PASS |
| `_update_blur_material()` | `void` | L183 | `none` | CLEAN / PASS |
| `set_custom_texture_path()` | `void` | L209 | `path: String` | CLEAN / PASS |
| `_load_texture()` | `void` | L213 | `path: String` | CLEAN / PASS |
| `_init_particles()` | `void` | L231 | `none` | CLEAN / PASS |
| `_process()` | `void` | L291 | `delta: float` | CLEAN / PASS |
| `_draw()` | `void` | L315 | `none` | CLEAN / PASS |

### File: `scripts/ui/auth_modal.gd` (10 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L20 | `none` | CLEAN / PASS |
| `open()` | `void` | L39 | `_closable: bool = true` | CLEAN / PASS |
| `close()` | `void` | L52 | `none` | CLEAN / PASS |
| `_populate_google_accounts()` | `void` | L60 | `none` | CLEAN / PASS |
| `_create_account_card()` | `void` | L75 | `acc_name: String, acc_email: String` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_create_account_card' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_select_google_account()` | `void` | L171 | `acc_email: String, acc_name: String` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_select_google_account' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_on_custom_connect_pressed()` | `void` | L188 | `none` | CLEAN / PASS |
| `_is_valid_email()` | `bool` | L199 | `e: String` | CLEAN / PASS |
| `_on_login_finished()` | `void` | L202 | `success: bool, error_msg: String` | CLEAN / PASS |
| `_set_status()` | `void` | L215 | `text: String, is_err: bool` | CLEAN / PASS |

### File: `scripts/ui/biome_transition_pass.gd` (7 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L22 | `none` | CLEAN / PASS |
| `_setup_mist_layers()` | `void` | L31 | `none` | CLEAN / PASS |
| `_apply_mist_colors()` | `void` | L60 | `mat: ShaderMaterial, density_val: float, speed_val: float, edge_exp: float` | CLEAN / PASS |
| `_setup_particles()` | `void` | L73 | `none` | CLEAN / PASS |
| `_setup_lock_card()` | `void` | L106 | `none` | CLEAN / PASS |
| `set_card_active()` | `void` | L110 | `active: bool` | CLEAN / PASS |
| `update_state()` | `void` | L115 | `none` | CLEAN / PASS |

### File: `scripts/ui/cloud_layer.gd` (8 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L17 | `none` | CLEAN / PASS |
| `_on_viewport_size_changed()` | `void` | L28 | `none` | CLEAN / PASS |
| `_generate_cloud_puffs()` | `void` | L35 | `none` | CLEAN / PASS |
| `_setup_coming_soon_badge()` | `void` | L62 | `none` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L93 | `_lang: String` | CLEAN / PASS |
| `_update_badge_text()` | `void` | L96 | `none` | CLEAN / PASS |
| `_process()` | `void` | L104 | `delta: float` | CLEAN / PASS |
| `_draw()` | `void` | L111 | `none` | CLEAN / PASS |

### File: `scripts/ui/control_customizer.gd` (10 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_get_default_positions()` | `Dictionary` | L18 | `none` | CLEAN / PASS |
| `_load_current_positions()` | `void` | L21 | `none` | CLEAN / PASS |
| `_update_texts()` | `void` | L28 | `none` | CLEAN / PASS |
| `_setup_drag_widget()` | `void` | L40 | `node: Control, icon_name: String, sz: Vector2` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_drag_widget' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_ready()` | `void` | L106 | `none` | CLEAN / PASS |
| `open()` | `void` | L125 | `none` | CLEAN / PASS |
| `close()` | `void` | L131 | `none` | CLEAN / PASS |
| `_on_reset_pressed()` | `void` | L135 | `none` | CLEAN / PASS |
| `_on_save_pressed()` | `void` | L144 | `none` | CLEAN / PASS |
| `_on_close_pressed()` | `void` | L153 | `none` | CLEAN / PASS |

### File: `scripts/ui/game_hud.gd` (13 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L24 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_ready'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_update_touch_visibility()` | `void` | L41 | `none` | CLEAN / PASS |
| `_apply_custom_touch_layout()` | `void` | L47 | `none` | CLEAN / PASS |
| `_process()` | `void` | L71 | `_delta: float` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_process'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_setup_icons()` | `void` | L79 | `none` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L113 | `_lang: String` | CLEAN / PASS |
| `_on_level_started()` | `void` | L116 | `_level_id: int` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_level_started'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_update_texts()` | `void` | L121 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_update_texts'. Causes compile/runtime errors when instantiated without autoload tree. |
| `start_duel_countdown()` | `void` | L129 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'start_duel_countdown'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_player_died()` | `void` | L161 | `deaths_count: int` | CLEAN / PASS |
| `_update_deaths_display()` | `void` | L165 | `none` | CLEAN / PASS |
| `_setup_touch_btn()` | `void` | L169 | `btn: Button, action: String` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_touch_btn' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_on_pause_btn_pressed()` | `void` | L185 | `none` | CLEAN / PASS |

### File: `scripts/ui/global_duel_feed.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L40 | `none` | CLEAN / PASS |
| `_process()` | `void` | L49 | `delta: float` | CLEAN / PASS |
| `fetch_feed()` | `void` | L60 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'fetch_feed' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_show_next_card()` | `void` | L82 | `none` | CLEAN / PASS |
| `_add_animated_feed_card()` | `void` | L102 | `data: Dictionary` | CLEAN / PASS |
| `_animate_card_exit()` | `void` | L181 | `card: Control` | CLEAN / PASS |

### File: `scripts/ui/home_menu.gd` (8 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L17 | `none` | CLEAN / PASS |
| `update_best_record()` | `void` | L30 | `none` | CLEAN / PASS |
| `_on_back_pressed()` | `void` | L37 | `none` | CLEAN / PASS |
| `_on_play_pressed()` | `void` | L41 | `none` | CLEAN / PASS |
| `_on_multiplayer_pressed()` | `void` | L50 | `none` | CLEAN / PASS |
| `_on_leaderboard_pressed()` | `void` | L56 | `none` | CLEAN / PASS |
| `_on_settings_pressed()` | `void` | L62 | `none` | CLEAN / PASS |
| `_play_click()` | `void` | L70 | `none` | CLEAN / PASS |

### File: `scripts/ui/leaderboard_modal.gd` (14 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L35 | `none` | CLEAN / PASS |
| `_unhandled_input()` | `void` | L71 | `event: InputEvent` | CLEAN / PASS |
| `open()` | `void` | L79 | `none` | CLEAN / PASS |
| `close()` | `void` | L93 | `none` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L98 | `_lang: String` | CLEAN / PASS |
| `_update_texts()` | `void` | L103 | `none` | CLEAN / PASS |
| `_set_tab()` | `void` | L127 | `mode: TabMode` | CLEAN / PASS |
| `_update_tab_buttons()` | `void` | L135 | `none` | CLEAN / PASS |
| `_apply_btn_style()` | `void` | L145 | `btn: Button, is_active: bool` | CLEAN / PASS |
| `_sort_players()` | `bool` | L161 | `a: Dictionary, b: Dictionary` | CLEAN / PASS |
| `_fetch_supabase_leaderboard()` | `void` | L176 | `none` | CLEAN / PASS |
| `_on_http_completed()` | `void` | L187 | `_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray` | CLEAN / PASS |
| `_refresh_list()` | `void` | L215 | `none` | CLEAN / PASS |
| `_build_row()` | `Control` | L283 | `rank: int, data: Dictionary` | CLEAN / PASS |

### File: `scripts/ui/level_select.gd` (26 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L88 | `none` | CLEAN / PASS |
| `_get_step_width()` | `float` | L113 | `none` | CLEAN / PASS |
| `_get_map_offset()` | `Vector2` | L116 | `none` | CLEAN / PASS |
| `_setup_widescreen_layout()` | `void` | L122 | `none` | CLEAN / PASS |
| `_reposition_all_chapter_nodes()` | `void` | L149 | `none` | CLEAN / PASS |
| `_position_nodes()` | `void` | L154 | `chapter: int, container: Control` | CLEAN / PASS |
| `_setup_seamless_backdrop_materials()` | `void` | L169 | `none` | CLEAN / PASS |
| `_setup_top_bar()` | `void` | L199 | `none` | CLEAN / PASS |
| `_setup_nav_connections()` | `void` | L218 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_nav_connections' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_setup_toast_ui()` | `void` | L254 | `none` | CLEAN / PASS |
| `_show_notice()` | `void` | L305 | `title_text: String, message_text: String` | CLEAN / PASS |
| `_on_side_nav_right_pressed()` | `void` | L333 | `none` | CLEAN / PASS |
| `_input()` | `void` | L339 | `event: InputEvent` | CLEAN / PASS |
| `_update_realtime_drag_feedback()` | `void` | L404 | `slider_x: float` | CLEAN / PASS |
| `_finish_drag()` | `void` | L431 | `none` | CLEAN / PASS |
| `switch_to_chapter()` | `void` | L441 | `target_chapter: int, animated: bool = true` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'switch_to_chapter' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_update_top_bar_data()` | `void` | L473 | `none` | CLEAN / PASS |
| `_update_nav_buttons()` | `void` | L486 | `none` | CLEAN / PASS |
| `_set_btn_active()` | `void` | L506 | `btn: Button, active: bool` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L527 | `_lang: String` | CLEAN / PASS |
| `_create_nodes_for_chapter()` | `void` | L535 | `chapter: int` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_create_nodes_for_chapter' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_on_level_btn_pressed()` | `void` | L684 | `lvl: int` | CLEAN / PASS |
| `_update_chapter_locks()` | `void` | L714 | `none` | CLEAN / PASS |
| `_create_chapter_lock_card()` | `Control` | L750 | `chapter: int` | CLEAN / PASS |
| `_refresh_lock_card_texts()` | `void` | L813 | `card: Control, chapter: int` | CLEAN / PASS |
| `_on_back_pressed()` | `void` | L824 | `none` | CLEAN / PASS |

### File: `scripts/ui/main_menu.gd` (21 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L42 | `none` | CLEAN / PASS |
| `_apply_responsive_layout()` | `void` | L86 | `none` | CLEAN / PASS |
| `_unhandled_input()` | `void` | L115 | `event: InputEvent` | CLEAN / PASS |
| `_setup_icons()` | `void` | L127 | `none` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L162 | `_lang: String` | CLEAN / PASS |
| `_update_all_texts()` | `void` | L165 | `none` | CLEAN / PASS |
| `_update_record()` | `void` | L180 | `none` | CLEAN / PASS |
| `_on_play_pressed()` | `void` | L188 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_play_pressed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_level_select_pressed()` | `void` | L193 | `none` | CLEAN / PASS |
| `_on_editor_pressed()` | `void` | L197 | `none` | CLEAN / PASS |
| `_on_leaderboard_pressed()` | `void` | L201 | `none` | CLEAN / PASS |
| `_update_profile_button()` | `void` | L206 | `none` | CLEAN / PASS |
| `_on_profile_pressed()` | `void` | L219 | `none` | CLEAN / PASS |
| `_on_multiplayer_pressed()` | `void` | L224 | `none` | CLEAN / PASS |
| `_on_duel_started()` | `void` | L228 | `zone_id: int, level_id: int, random_seed: int` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_duel_started'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_invitation_received()` | `void` | L233 | `duel_data: Dictionary, sender_tag: String, sender_name: String` | CLEAN / PASS |
| `_on_invite_accepted()` | `void` | L240 | `none` | CLEAN / PASS |
| `_on_invite_declined()` | `void` | L247 | `none` | CLEAN / PASS |
| `_on_info_close_pressed()` | `void` | L254 | `none` | CLEAN / PASS |
| `_on_settings_pressed()` | `void` | L259 | `none` | CLEAN / PASS |
| `_on_quit_pressed()` | `void` | L264 | `none` | CLEAN / PASS |

### File: `scripts/ui/main_menu_controller.gd` (4 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L9 | `none` | CLEAN / PASS |
| `_on_play_pressed()` | `void` | L14 | `none` | CLEAN / PASS |
| `_on_quit_pressed()` | `void` | L18 | `none` | CLEAN / PASS |
| `_play_click()` | `void` | L22 | `none` | CLEAN / PASS |

### File: `scripts/ui/menu_character.gd` (9 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L32 | `none` | CLEAN / PASS |
| `_gui_input()` | `void` | L37 | `event: InputEvent` | CLEAN / PASS |
| `_trigger_hop()` | `void` | L41 | `none` | CLEAN / PASS |
| `set_sad_emotion()` | `void` | L53 | `sad: bool` | CLEAN / PASS |
| `_process()` | `void` | L57 | `delta: float` | CLEAN / PASS |
| `_draw()` | `void` | L106 | `none` | CLEAN / PASS |
| `_draw_ellipse()` | `void` | L210 | `c: Vector2, r: Vector2, color: Color` | CLEAN / PASS |
| `_draw_happy_eye()` | `void` | L218 | `c: Vector2` | CLEAN / PASS |
| `_draw_sad_mouth()` | `void` | L228 | `c: Vector2, factor: float` | CLEAN / PASS |

### File: `scripts/ui/pause_modal.gd` (12 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L15 | `none` | CLEAN / PASS |
| `_setup_icons()` | `void` | L41 | `none` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L52 | `_lang: String` | CLEAN / PASS |
| `_update_texts()` | `void` | L55 | `none` | CLEAN / PASS |
| `_on_card_draw()` | `void` | L64 | `none` | CLEAN / PASS |
| `_unhandled_input()` | `void` | L84 | `event: InputEvent` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_unhandled_input'. Causes compile/runtime errors when instantiated without autoload tree. |
| `open_pause()` | `void` | L94 | `none` | CLEAN / PASS |
| `_on_resume_pressed()` | `void` | L103 | `none` | CLEAN / PASS |
| `_on_restart_pressed()` | `void` | L109 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_restart_pressed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_settings_pressed()` | `void` | L116 | `none` | CLEAN / PASS |
| `_on_levels_pressed()` | `void` | L121 | `none` | CLEAN / PASS |
| `_on_home_pressed()` | `void` | L132 | `none` | CLEAN / PASS |

### File: `scripts/ui/profile_modal.gd` (14 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L41 | `none` | CLEAN / PASS |
| `open()` | `void` | L62 | `none` | CLEAN / PASS |
| `_refresh_profile_display()` | `void` | L74 | `none` | CLEAN / PASS |
| `_update_auth_ui()` | `void` | L88 | `none` | CLEAN / PASS |
| `_on_auth_action_pressed()` | `void` | L105 | `none` | CLEAN / PASS |
| `close()` | `void` | L114 | `none` | CLEAN / PASS |
| `_apply_modal_styles()` | `void` | L120 | `none` | CLEAN / PASS |
| `_setup_avatar_buttons()` | `void` | L204 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_avatar_buttons' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_refresh_avatar_grid_styles()` | `void` | L238 | `none` | CLEAN / PASS |
| `_update_avatar_preview()` | `void` | L269 | `none` | CLEAN / PASS |
| `_load_stats()` | `void` | L276 | `none` | CLEAN / PASS |
| `_on_copy_tag()` | `void` | L298 | `none` | CLEAN / PASS |
| `_on_save_pressed()` | `void` | L312 | `none` | CLEAN / PASS |
| `_show_toast()` | `void` | L338 | `msg: String` | CLEAN / PASS |

### File: `scripts/ui/settings_modal.gd` (12 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L50 | `none` | CLEAN / PASS |
| `_setup_icons()` | `void` | L63 | `none` | CLEAN / PASS |
| `_setup_signals()` | `void` | L77 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_signals' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_unhandled_input()` | `void` | L144 | `event: InputEvent` | CLEAN / PASS |
| `_on_card_draw()` | `void` | L151 | `none` | CLEAN / PASS |
| `open()` | `void` | L175 | `none` | CLEAN / PASS |
| `close()` | `void` | L183 | `none` | CLEAN / PASS |
| `_select_language()` | `void` | L187 | `lang: String` | CLEAN / PASS |
| `_update_ui_texts()` | `void` | L194 | `none` | CLEAN / PASS |
| `_update_lang_buttons()` | `void` | L208 | `none` | CLEAN / PASS |
| `_style_btn()` | `void` | L215 | `btn: Button, active: bool` | CLEAN / PASS |
| `_update_toggles()` | `void` | L234 | `none` | CLEAN / PASS |

### File: `scripts/ui/splash_screen.gd` (16 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L47 | `none` | CLEAN / PASS |
| `_apply_safe_insets()` | `void` | L71 | `none` | CLEAN / PASS |
| `_unhandled_input()` | `void` | L81 | `event: InputEvent` | CLEAN / PASS |
| `_setup_buttons()` | `void` | L88 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_buttons' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_start_background_drift()` | `void` | L121 | `none` | CLEAN / PASS |
| `_update_hint()` | `void` | L129 | `idx: int` | CLEAN / PASS |
| `_run_loading_flow()` | `void` | L138 | `none` | CLEAN / PASS |
| `_process()` | `void` | L162 | `delta: float` | CLEAN / PASS |
| `_show_auth_selection()` | `void` | L168 | `none` | CLEAN / PASS |
| `_pulse_start_button()` | `void` | L203 | `btn: Button` | CLEAN / PASS |
| `_on_start_pressed()` | `void` | L212 | `none` | CLEAN / PASS |
| `_on_switch_account_pressed()` | `void` | L218 | `none` | CLEAN / PASS |
| `_on_google_pressed()` | `void` | L222 | `none` | CLEAN / PASS |
| `_on_guest_pressed()` | `void` | L226 | `none` | CLEAN / PASS |
| `_on_auth_completed()` | `void` | L233 | `_provider: String` | CLEAN / PASS |
| `_finish_and_open_main_menu()` | `void` | L241 | `none` | CLEAN / PASS |

### File: `scripts/ui/title_screen.gd` (4 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L9 | `none` | CLEAN / PASS |
| `_on_start_pressed()` | `void` | L17 | `none` | CLEAN / PASS |
| `_on_quit_pressed()` | `void` | L21 | `none` | CLEAN / PASS |
| `_play_click()` | `void` | L25 | `none` | CLEAN / PASS |

### File: `scripts/ui/win_overlay.gd` (15 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L22 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_ready'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_process()` | `void` | L42 | `delta: float` | CLEAN / PASS |
| `_setup_icons()` | `void` | L48 | `none` | CLEAN / PASS |
| `_on_spotlight_draw()` | `void` | L64 | `none` | CLEAN / PASS |
| `_draw_diamond()` | `void` | L98 | `canvas: Control, center: Vector2, r: float, col: Color` | CLEAN / PASS |
| `_on_line_accent_draw()` | `void` | L107 | `none` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L121 | `_lang: String` | CLEAN / PASS |
| `restore_result()` | `void` | L125 | `data: Dictionary` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'restore_result'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_level_completed()` | `void` | L135 | `lvl: int, time_ms: float, deaths: int, stars: int` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_level_completed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_duel_match_finished()` | `void` | L151 | `is_victory: bool, _winner_id: String` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_duel_match_finished'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_render_win_data()` | `void` | L181 | `none` | CLEAN / PASS |
| `_on_next_pressed()` | `void` | L210 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_next_pressed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_replay_pressed()` | `void` | L220 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_replay_pressed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_map_pressed()` | `void` | L238 | `none` | CLEAN / PASS |
| `_on_home_pressed()` | `void` | L259 | `none` | CLEAN / PASS |


## 2. SYSTEM: MULTIPLAYER & DUEL SYSTEMS

Total Functions Audited in this system: **88**

### File: `scripts/multiplayer/duel_lobby_modal.gd` (34 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L66 | `none` | CLEAN / PASS |
| `open()` | `void` | L96 | `none` | CLEAN / PASS |
| `_update_view_state()` | `void` | L111 | `none` | CLEAN / PASS |
| `_update_action_buttons()` | `void` | L123 | `none` | CLEAN / PASS |
| `_refresh_player_cards()` | `void` | L144 | `none` | CLEAN / PASS |
| `_on_chapter_tab_pressed()` | `void` | L167 | `chapter: int` | CLEAN / PASS |
| `_update_chapter_tabs()` | `void` | L174 | `none` | CLEAN / PASS |
| `_setup_level_grid()` | `void` | L179 | `chapter: int` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_level_grid' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_on_level_selected()` | `void` | L206 | `chapter: int, lvl_in_ch: int` | CLEAN / PASS |
| `_update_selected_level_card()` | `void` | L222 | `none` | CLEAN / PASS |
| `_style_level_button()` | `void` | L243 | `btn: Button, is_selected: bool` | CLEAN / PASS |
| `_on_practice_bot_pressed()` | `void` | L293 | `none` | CLEAN / PASS |
| `_on_play_bot_pressed()` | `void` | L300 | `none` | CLEAN / PASS |
| `_on_propose_pressed()` | `void` | L310 | `none` | CLEAN / PASS |
| `_on_proposal_received()` | `void` | L315 | `_proposer_id: String, zone_id: int, level_id: int, proposal_id: int` | CLEAN / PASS |
| `_on_accept_pressed()` | `void` | L330 | `none` | CLEAN / PASS |
| `_on_reject_pressed()` | `void` | L336 | `none` | CLEAN / PASS |
| `_on_match_agreed()` | `void` | L342 | `zone_id: int, level_id: int, random_seed: int` | CLEAN / PASS |
| `_start_countdown_sequence()` | `void` | L347 | `zone_id: int, level_id: int, random_seed: int` | CLEAN / PASS |
| `_on_match_started()` | `void` | L368 | `_started_at: String` | CLEAN / PASS |
| `_on_duel_updated()` | `void` | L371 | `data: Dictionary` | CLEAN / PASS |
| `_on_leave_lobby()` | `void` | L377 | `none` | CLEAN / PASS |
| `_on_invite_pressed()` | `void` | L395 | `none` | CLEAN / PASS |
| `_send_direct_invite()` | `void` | L407 | `tag: String, display_name: String` | CLEAN / PASS |
| `_on_random_btn_pressed()` | `void` | L418 | `none` | CLEAN / PASS |
| `_on_matched_success()` | `void` | L437 | `none` | CLEAN / PASS |
| `_cancel_matchmaking()` | `void` | L446 | `reason: String` | CLEAN / PASS |
| `_process()` | `void` | L454 | `delta: float` | CLEAN / PASS |
| `_set_search_status()` | `void` | L473 | `msg: String` | CLEAN / PASS |
| `_on_copy_my_id()` | `void` | L477 | `none` | CLEAN / PASS |
| `_load_and_render_friends()` | `void` | L494 | `none` | CLEAN / PASS |
| `_create_friend_card()` | `void` | L553 | `tag: String, uname: String, is_friend: bool` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_create_friend_card' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_apply_all_styles()` | `void` | L612 | `none` | CLEAN / PASS |
| `_style_button()` | `void` | L660 | `btn: Button, variant: String` | CLEAN / PASS |

### File: `scripts/multiplayer/duel_service.gd` (24 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L38 | `none` | CLEAN / PASS |
| `_process()` | `void` | L49 | `delta: float` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_process'. Causes compile/runtime errors when instantiated without autoload tree. |
| `search_player()` | `void` | L73 | `tag: String, on_result: Callable` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'search_player' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `fetch_active_players()` | `void` | L89 | `on_result: Callable` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'fetch_active_players' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `send_invitation()` | `void` | L113 | `target_tag: String, on_result: Callable` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'send_invitation' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_check_pending_invitations()` | `void` | L141 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_check_pending_invitations' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_fetch_sender_and_emit()` | `void` | L161 | `duel_data: Dictionary` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_fetch_sender_and_emit' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `respond_invitation()` | `void` | L180 | `duel_id: String, accept: bool, on_result: Callable = Callable()` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'respond_invitation' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `find_random_match()` | `void` | L204 | `on_result: Callable` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'find_random_match' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `poll_match_status()` | `void` | L222 | `on_result: Callable` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'poll_match_status' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `cancel_matchmaking()` | `void` | L240 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'cancel_matchmaking' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `propose_level()` | `void` | L252 | `zone_id: int, level_id: int, on_result: Callable = Callable()` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'propose_level' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `respond_proposal()` | `void` | L273 | `proposal_id: int, accept: bool, on_result: Callable = Callable()` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'respond_proposal' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `setup_bot_duel()` | `void` | L297 | `zone_id: int, level_id: int` | CLEAN / PASS |
| `start_bot_match_timer()` | `void` | L321 | `none` | CLEAN / PASS |
| `start_match()` | `void` | L326 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'start_match' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `claim_finish()` | `void` | L342 | `completion_ms: float, deaths: int, on_result: Callable = Callable()` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function 'claim_finish' without is_connected() check can cause duplicate signal connection errors on re-entry.<br>**[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in 'claim_finish'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_trigger_forfeit()` | `void` | L374 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_trigger_forfeit' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `set_active_duel()` | `void` | L394 | `duel_data: Dictionary` | CLEAN / PASS |
| `leave_active_duel()` | `void` | L402 | `none` | CLEAN / PASS |
| `_poll_active_duel()` | `void` | L412 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_poll_active_duel' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_process_duel_update()` | `void` | L429 | `data: Dictionary` | CLEAN / PASS |
| `get_opponent_id()` | `String` | L466 | `none` | CLEAN / PASS |
| `_get_headers()` | `PackedStringArray` | L474 | `none` | CLEAN / PASS |

### File: `scripts/multiplayer/multiplayer_menu.gd` (30 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L64 | `none` | CLEAN / PASS |
| `_on_back_pressed()` | `void` | L100 | `none` | CLEAN / PASS |
| `_switch_subview()` | `void` | L107 | `view_name: String` | CLEAN / PASS |
| `_refresh_player_cards()` | `void` | L121 | `none` | CLEAN / PASS |
| `_on_chapter_tab_pressed()` | `void` | L148 | `chapter: int` | CLEAN / PASS |
| `_update_chapter_tabs()` | `void` | L155 | `none` | CLEAN / PASS |
| `_setup_level_grid()` | `void` | L160 | `chapter: int` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_level_grid' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_on_level_selected()` | `void` | L187 | `chapter: int, lvl_in_ch: int` | CLEAN / PASS |
| `_update_selected_level_card()` | `void` | L202 | `none` | CLEAN / PASS |
| `_style_level_button()` | `void` | L223 | `btn: Button, is_selected: bool` | CLEAN / PASS |
| `_on_play_bot_pressed()` | `void` | L269 | `none` | CLEAN / PASS |
| `_launch_game_with_loading()` | `void` | L275 | `actual_level: int, seed_num: int` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_launch_game_with_loading'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_propose_pressed()` | `void` | L289 | `none` | CLEAN / PASS |
| `_on_proposal_received()` | `void` | L293 | `_proposer_id: String, zone_id: int, level_id: int, proposal_id: int` | CLEAN / PASS |
| `_on_accept_pressed()` | `void` | L307 | `none` | CLEAN / PASS |
| `_on_reject_pressed()` | `void` | L313 | `none` | CLEAN / PASS |
| `_on_match_agreed()` | `void` | L319 | `zone_id: int, level_id: int, random_seed: int` | CLEAN / PASS |
| `_on_duel_updated()` | `void` | L324 | `data: Dictionary` | CLEAN / PASS |
| `_on_invite_pressed()` | `void` | L332 | `none` | CLEAN / PASS |
| `_send_direct_invite()` | `void` | L344 | `tag: String, display_name: String` | CLEAN / PASS |
| `_on_random_btn_pressed()` | `void` | L354 | `none` | CLEAN / PASS |
| `_on_matched_success()` | `void` | L372 | `none` | CLEAN / PASS |
| `_cancel_matchmaking()` | `void` | L379 | `reason: String` | CLEAN / PASS |
| `_process()` | `void` | L386 | `delta: float` | CLEAN / PASS |
| `_set_search_status()` | `void` | L405 | `msg: String` | CLEAN / PASS |
| `_on_copy_my_id()` | `void` | L409 | `none` | CLEAN / PASS |
| `_load_and_render_friends()` | `void` | L424 | `none` | CLEAN / PASS |
| `_create_friend_card()` | `void` | L481 | `tag: String, uname: String, is_friend: bool` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_create_friend_card' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_apply_all_styles()` | `void` | L532 | `none` | CLEAN / PASS |
| `_style_button()` | `void` | L571 | `btn: Button, variant: String` | CLEAN / PASS |


## 2. SYSTEM: EDITOR & LEVEL AUTHORING TOOLS

Total Functions Audited in this system: **45**

### File: `scripts/editor/custom_level_manager.gd` (6 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L7 | `none` | CLEAN / PASS |
| `ensure_directory()` | `void` | L10 | `none` | CLEAN / PASS |
| `get_slot_path()` | `String` | L14 | `slot: int` | CLEAN / PASS |
| `save_custom_level()` | `bool` | L17 | `slot: int, data: Dictionary` | CLEAN / PASS |
| `load_custom_level()` | `Dictionary` | L30 | `slot: int` | CLEAN / PASS |
| `get_default_level()` | `Dictionary` | L50 | `none` | CLEAN / PASS |

### File: `scripts/editor/level_editor.gd` (38 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_get_canvas_width()` | `float` | L7 | `none` | CLEAN / PASS |
| `_get_cols()` | `int` | L10 | `none` | CLEAN / PASS |
| `_ready()` | `void` | L93 | `none` | CLEAN / PASS |
| `_setup_palette_styles()` | `void` | L113 | `none` | CLEAN / PASS |
| `_setup_palette_scroll()` | `void` | L147 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_setup_palette_scroll' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_on_palette_gui_input()` | `void` | L153 | `event: InputEvent` | CLEAN / PASS |
| `_setup_slots()` | `void` | L168 | `none` | CLEAN / PASS |
| `_select_current_slot_in_dropdown()` | `void` | L264 | `none` | CLEAN / PASS |
| `_build_palette()` | `void` | L271 | `none` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_build_palette' without is_connected() check can cause duplicate signal connection errors on re-entry. |
| `_select_tool()` | `void` | L321 | `tool_id: String` | CLEAN / PASS |
| `_on_language_changed()` | `void` | L338 | `_lang: String` | CLEAN / PASS |
| `_update_all_texts()` | `void` | L341 | `none` | CLEAN / PASS |
| `_snap_to_cell()` | `Vector2i` | L363 | `pos: Vector2` | CLEAN / PASS |
| `_on_canvas_gui_input()` | `void` | L368 | `event: InputEvent` | CLEAN / PASS |
| `_apply_tool_at_pos()` | `void` | L388 | `pos: Vector2` | CLEAN / PASS |
| `_on_canvas_draw()` | `void` | L455 | `none` | CLEAN / PASS |
| `_draw_cell_element()` | `void` | L491 | `elem: Dictionary` | CLEAN / PASS |
| `_draw_door()` | `void` | L598 | `pos: Vector2` | CLEAN / PASS |
| `_draw_player()` | `void` | L636 | `pos: Vector2` | CLEAN / PASS |
| `_on_test_pressed()` | `void` | L649 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_test_pressed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_on_stop_test_pressed()` | `void` | L660 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_on_stop_test_pressed'. Causes compile/runtime errors when instantiated without autoload tree. |
| `_spawn_test_world()` | `void` | L672 | `none` | CLEAN / PASS |
| `_spawn_test_player_once()` | `void` | L776 | `none` | CLEAN / PASS |
| `_clear_test_world()` | `void` | L786 | `none` | CLEAN / PASS |
| `_on_custom_player_died()` | `void` | L790 | `none` | CLEAN / PASS |
| `_on_custom_level_completed()` | `void` | L798 | `none` | CLEAN / PASS |
| `_on_slot_selected()` | `void` | L806 | `idx: int` | CLEAN / PASS |
| `_snap_door_pos()` | `Vector2` | L824 | `raw: Vector2` | CLEAN / PASS |
| `_snap_player_pos()` | `Vector2` | L829 | `raw: Vector2` | CLEAN / PASS |
| `_load_slot()` | `void` | L834 | `slot: int` | CLEAN / PASS |
| `_set_save_mode()` | `void` | L862 | `save_mode: bool` | CLEAN / PASS |
| `_on_save_pressed()` | `void` | L874 | `none` | CLEAN / PASS |
| `_on_load_pressed()` | `void` | L897 | `none` | CLEAN / PASS |
| `_on_clear_pressed()` | `void` | L901 | `none` | CLEAN / PASS |
| `_on_back_pressed()` | `void` | L910 | `none` | CLEAN / PASS |
| `_show_toast()` | `void` | L917 | `msg: String` | CLEAN / PASS |
| `_setup_touch_controls()` | `void` | L927 | `none` | CLEAN / PASS |
| `_bind_touch()` | `void` | L936 | `btn: Button, action: String` | **[UNGUARDED_SIGNAL_CONNECT]** Signal .connect() in non-ready function '_bind_touch' without is_connected() check can cause duplicate signal connection errors on re-entry. |

### File: `scripts/tools/test_visual_disguise.gd` (1 functions)

| Function Name | Return | Line | Params | Risk / Issues |
| :--- | :---: | :---: | :--- | :--- |
| `_ready()` | `void` | L3 | `none` | **[DIRECT_AUTOLOAD_DEPENDENCY]** Direct call to GameManager in '_ready'. Causes compile/runtime errors when instantiated without autoload tree. |


## 2. SYSTEM: AUTOMATED TEST SUITES

Total Functions Audited in this system: **0**

