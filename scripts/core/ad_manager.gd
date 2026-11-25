extends Node

# Wrong Way — AdManager (Yandex Mobile Ads SDK 8.7.0)
# - Banner: Disabled on mobile so native banners never cover menus or touch controls.
# - Interstitial (R-M-20506671-1): Triggers on replaying beaten levels,
#   every 10th death, or every 5th level beaten in a session.
# - Rewarded Video (R-M-20506671-2): Triggers when player unlocks the next
#   locked level via ad (alternating rule) or on every 4th pause restart.

const ADS_ENABLED: bool = true

const INTERSTITIAL_AD_UNIT_ID := "R-M-20506671-1"
const REWARDED_AD_UNIT_ID := "R-M-20506671-2"

signal banner_visibility_changed(is_visible: bool)
signal rewarded_ad_started
signal rewarded_ad_completed(reward_granted: bool)
signal interstitial_ad_completed

var is_banner_active: bool = false
var banner_enabled: bool = false
var consent_granted: bool = true

var _yandex_plugin: Object = null
var _interstitial_loaded: bool = false
var _interstitial_loading: bool = false
var _interstitial_retry_attempt: int = 0
var _pending_interstitial_cb: Callable = Callable()

var _rewarded_loaded: bool = false
var _rewarded_loading: bool = false
var _rewarded_showing: bool = false
var _rewarded_earned: bool = false
var _rewarded_finalized: bool = false
var _rewarded_retry_attempt: int = 0
var _pending_reward_cb: Callable = Callable()

var _audio_was_muted_before_ad: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_banner_active = false
	banner_enabled = false
	if ADS_ENABLED and _is_android_yandex_supported():
		_init_yandex_plugin()

func is_ads_enabled() -> bool:
	return ADS_ENABLED

func _is_android_yandex_supported() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("WrongWayYandexAds")

func _init_yandex_plugin() -> void:
	_yandex_plugin = Engine.get_singleton("WrongWayYandexAds")
	if _yandex_plugin == null:
		return

	_yandex_plugin.connect("interstitial_loaded", _on_interstitial_loaded)
	_yandex_plugin.connect("interstitial_failed_to_load", _on_interstitial_failed_to_load)
	_yandex_plugin.connect("interstitial_dismissed", _on_interstitial_dismissed)
	_yandex_plugin.connect("interstitial_failed_to_show", _on_interstitial_failed_to_show)

	_yandex_plugin.connect("rewarded_loaded", _on_rewarded_loaded)
	_yandex_plugin.connect("rewarded_failed_to_load", _on_rewarded_failed_to_load)
	_yandex_plugin.connect("rewarded_earned", _on_rewarded_earned)
	_yandex_plugin.connect("rewarded_dismissed", _on_rewarded_dismissed)
	_yandex_plugin.connect("rewarded_failed_to_show", _on_rewarded_failed_to_show)

	_load_interstitial()
	_load_rewarded()

func _set_ad_audio_muted(muted: bool) -> void:
	if muted:
		_audio_was_muted_before_ad = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, _audio_was_muted_before_ad)

# -------------------------------------------------------------
# 1. BANNER AD (Disabled on mobile & clean on desktop)
# -------------------------------------------------------------
func show_banner() -> void:
	is_banner_active = false

func hide_banner() -> void:
	if is_banner_active:
		is_banner_active = false
		banner_visibility_changed.emit(false)

func is_banner_visible() -> bool:
	return false

func get_top_banner_height() -> float:
	return 0.0

func set_consent(granted: bool) -> void:
	consent_granted = granted
	if not consent_granted:
		hide_banner()

# -------------------------------------------------------------
# 2. INTERSTITIAL AD (R-M-20506671-1)
# -------------------------------------------------------------
func _load_interstitial() -> void:
	if not ADS_ENABLED or _yandex_plugin == null:
		return
	if _interstitial_loading or _interstitial_loaded:
		return
	_interstitial_loading = true
	_yandex_plugin.call("loadInterstitial", INTERSTITIAL_AD_UNIT_ID)

func _on_interstitial_loaded() -> void:
	_interstitial_loading = false
	_interstitial_loaded = true
	_interstitial_retry_attempt = 0

func _on_interstitial_failed_to_load(err: String) -> void:
	_interstitial_loading = false
	_interstitial_loaded = false
	print("AdManager (Yandex): Interstitial load failed: ", err)
	_schedule_interstitial_retry()

func _schedule_interstitial_retry() -> void:
	if not is_inside_tree():
		return
	_interstitial_retry_attempt = mini(_interstitial_retry_attempt + 1, 4)
	var delay: float = minf(20.0, 3.0 * pow(2.0, float(_interstitial_retry_attempt - 1)))
	get_tree().create_timer(delay, true).timeout.connect(func() -> void:
		if not _interstitial_loaded and not _interstitial_loading:
			_load_interstitial()
	)

func show_interstitial(on_finish_callback: Callable = Callable()) -> void:
	show_interstitial_ad(on_finish_callback)

func show_interstitial_replay(on_finish_callback: Callable = Callable()) -> void:
	show_interstitial_ad(on_finish_callback)

func show_interstitial_ad(on_finish_callback: Callable = Callable()) -> void:
	if not ADS_ENABLED or _yandex_plugin == null or not _interstitial_loaded:
		if ADS_ENABLED and _yandex_plugin != null:
			_load_interstitial()
		if on_finish_callback.is_valid():
			on_finish_callback.call()
		interstitial_ad_completed.emit()
		return

	_interstitial_loaded = false
	_pending_interstitial_cb = on_finish_callback
	_set_ad_audio_muted(true)
	_yandex_plugin.call("showInterstitial")

func _on_interstitial_dismissed() -> void:
	_finish_interstitial()

func _on_interstitial_failed_to_show(err: String) -> void:
	print("AdManager (Yandex): Interstitial show failed: ", err)
	_finish_interstitial()

func _finish_interstitial() -> void:
	_set_ad_audio_muted(false)
	var cb := _pending_interstitial_cb
	_pending_interstitial_cb = Callable()
	if cb.is_valid():
		cb.call()
	interstitial_ad_completed.emit()
	_load_interstitial()

# -------------------------------------------------------------
# 3. REWARDED AD (R-M-20506671-2)
# -------------------------------------------------------------
func _load_rewarded() -> void:
	if not ADS_ENABLED or _yandex_plugin == null:
		return
	if _rewarded_loading or _rewarded_loaded:
		return
	_rewarded_loading = true
	_yandex_plugin.call("loadRewarded", REWARDED_AD_UNIT_ID)

func _on_rewarded_loaded() -> void:
	_rewarded_loading = false
	_rewarded_loaded = true
	_rewarded_retry_attempt = 0

func _on_rewarded_failed_to_load(err: String) -> void:
	_rewarded_loading = false
	_rewarded_loaded = false
	print("AdManager (Yandex): Rewarded load failed: ", err)
	_schedule_rewarded_retry()

func _schedule_rewarded_retry() -> void:
	if not is_inside_tree():
		return
	_rewarded_retry_attempt = mini(_rewarded_retry_attempt + 1, 4)
	var delay: float = minf(20.0, 3.0 * pow(2.0, float(_rewarded_retry_attempt - 1)))
	get_tree().create_timer(delay, true).timeout.connect(func() -> void:
		if not _rewarded_loaded and not _rewarded_loading:
			_load_rewarded()
	)

func is_rewarded_ready() -> bool:
	if not ADS_ENABLED:
		return false
	if _yandex_plugin == null:
		return OS.get_name() != "Android"
	return _rewarded_loaded and not _rewarded_showing

func show_rewarded_ad(
	on_reward_callback: Callable = Callable(),
	allow_fallback_if_unavailable: bool = false,
	on_unavailable_callback: Callable = Callable()
) -> void:
	if _rewarded_showing:
		return

	if not ADS_ENABLED:
		if allow_fallback_if_unavailable:
			rewarded_ad_started.emit()
			if on_reward_callback.is_valid():
				on_reward_callback.call()
			rewarded_ad_completed.emit(true)
		else:
			if on_unavailable_callback.is_valid():
				on_unavailable_callback.call()
			rewarded_ad_completed.emit(false)
		return

	# Desktop / non-Android pass-through for testing
	if _yandex_plugin == null:
		if OS.get_name() != "Android" or allow_fallback_if_unavailable:
			rewarded_ad_started.emit()
			if on_reward_callback.is_valid():
				on_reward_callback.call()
			rewarded_ad_completed.emit(true)
		else:
			if on_unavailable_callback.is_valid():
				on_unavailable_callback.call()
			rewarded_ad_completed.emit(false)
		return

	if not _rewarded_loaded:
		_load_rewarded()
		if allow_fallback_if_unavailable:
			rewarded_ad_started.emit()
			if on_reward_callback.is_valid():
				on_reward_callback.call()
			rewarded_ad_completed.emit(true)
		else:
			if on_unavailable_callback.is_valid():
				on_unavailable_callback.call()
			rewarded_ad_completed.emit(false)
		return

	rewarded_ad_started.emit()
	_rewarded_loaded = false
	_rewarded_showing = true
	_rewarded_earned = false
	_rewarded_finalized = false
	_pending_reward_cb = on_reward_callback
	_set_ad_audio_muted(true)
	_yandex_plugin.call("showRewarded")

func _on_rewarded_earned() -> void:
	_rewarded_earned = true

func _on_rewarded_dismissed() -> void:
	_finalize_rewarded(_rewarded_earned)

func _on_rewarded_failed_to_show(err: String) -> void:
	print("AdManager (Yandex): Rewarded show failed: ", err)
	_finalize_rewarded(false)

func _finalize_rewarded(granted: bool) -> void:
	if _rewarded_finalized:
		return
	_rewarded_finalized = true
	_rewarded_showing = false
	_set_ad_audio_muted(false)

	var earned := granted or _rewarded_earned
	_rewarded_earned = false
	var cb := _pending_reward_cb
	_pending_reward_cb = Callable()
	if earned and cb.is_valid():
		cb.call()

	rewarded_ad_completed.emit(earned)
	_load_rewarded()
