extends Node

# Wrong Way — AdManager (Poing Studios Google AdMob v5.1.0)
# - Banner: Displayed in menus (Main Menu, Level Select, Editor),
#   strictly HIDDEN during active gameplay.
# - Interstitial: Triggers when a player replays a beaten level
#   or completes every 5th level in a session.
# - Rewarded Video: Triggers when player watches an ad to unlock
#   a level (alternating rule) or on every 4th pause restart.

# Google AdMob Identifikatorlari (Official Production IDs)
const ADMOB_APP_ID := "ca-app-pub-9009277559004471~1297962659"
const ADMOB_BANNER_ID := "ca-app-pub-9009277559004471/5320968143"
const ADMOB_INTERSTITIAL_ID := "ca-app-pub-9009277559004471/1106390961"
const ADMOB_REWARDED_ID := "ca-app-pub-9009277559004471/5903035034"

signal banner_visibility_changed(is_visible: bool)
signal rewarded_ad_started
signal rewarded_ad_completed(reward_granted: bool)
signal interstitial_ad_completed

var is_banner_active: bool = false
var banner_enabled: bool = true
var consent_granted: bool = true

var _admob_initialized: bool = false
var _ad_view: AdView = null

var _interstitial_ad: InterstitialAd = null
var _interstitial_loading: bool = false
var _pending_interstitial_cb: Callable = Callable()

var _rewarded_ad: RewardedAd = null
var _rewarded_loading: bool = false
var _pending_reward_cb: Callable = Callable()
var _reward_earned: bool = false

var _audio_was_muted_before_ad: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _is_mobile_admob_supported():
		_init_admob()

func _exit_tree() -> void:
	if _ad_view != null:
		_ad_view.destroy()
		_ad_view = null
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null

func _is_mobile_admob_supported() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

func _set_ad_audio_muted(muted: bool) -> void:
	if muted:
		_audio_was_muted_before_ad = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, _audio_was_muted_before_ad)

# -------------------------------------------------------------
# 1. INITIALIZATION (MobileAds)
# -------------------------------------------------------------
func _init_admob() -> void:
	var request_config := RequestConfiguration.new()
	MobileAds.set_request_configuration(request_config)

	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_admob_initialized = true
		_load_interstitial()
		_load_rewarded()
		if is_banner_active and banner_enabled and consent_granted:
			_create_and_load_banner()

	MobileAds.initialize(listener)

# -------------------------------------------------------------
# 2. BANNER AD (AdView)
# -------------------------------------------------------------
func show_banner() -> void:
	if not banner_enabled or not consent_granted:
		hide_banner()
		return
	is_banner_active = true
	banner_visibility_changed.emit(true)
	if _admob_initialized:
		_create_and_load_banner()

func hide_banner() -> void:
	is_banner_active = false
	banner_visibility_changed.emit(false)
	if _ad_view != null:
		_ad_view.hide()

func is_banner_visible() -> bool:
	return is_banner_active

func set_consent(granted: bool) -> void:
	consent_granted = granted
	if not consent_granted:
		hide_banner()

func _create_and_load_banner() -> void:
	if not _is_mobile_admob_supported() or not _admob_initialized:
		return
	if _ad_view == null:
		var w := AdSize.FULL_WIDTH
		var ad_size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(w)
		_ad_view = AdView.new(ADMOB_BANNER_ID, ad_size, AdPosition.TOP)

		var listener := AdListener.new()
		listener.on_ad_loaded = func() -> void:
			if not is_banner_active and _ad_view != null:
				_ad_view.hide()
		listener.on_ad_failed_to_load = func(err: LoadAdError) -> void:
			print("AdManager: Banner load failed: ", err.message)

		_ad_view.ad_listener = listener
		_ad_view.load_ad(AdRequest.new())
	else:
		_ad_view.show()

# -------------------------------------------------------------
# 3. INTERSTITIAL AD (InterstitialAdLoader / InterstitialAd)
# -------------------------------------------------------------
func _load_interstitial() -> void:
	if not _is_mobile_admob_supported() or not _admob_initialized:
		return
	if _interstitial_loading or _interstitial_ad != null:
		return

	_interstitial_loading = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial_ad = ad
		_setup_interstitial_callbacks()
	cb.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_interstitial_loading = false
		print("AdManager: Interstitial load failed: ", err.message)

	InterstitialAdLoader.new().load(ADMOB_INTERSTITIAL_ID, AdRequest.new(), cb)

func _setup_interstitial_callbacks() -> void:
	if _interstitial_ad == null:
		return
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_interstitial()
	cb.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("AdManager: Interstitial show failed: ", err.message)
		_finish_interstitial()
	_interstitial_ad.full_screen_content_callback = cb

func show_interstitial(on_finish_callback: Callable = Callable()) -> void:
	show_interstitial_ad(on_finish_callback)

func show_interstitial_replay(on_finish_callback: Callable = Callable()) -> void:
	show_interstitial_ad(on_finish_callback)

func show_interstitial_ad(on_finish_callback: Callable = Callable()) -> void:
	if not _is_mobile_admob_supported() or not _admob_initialized \
			or _interstitial_ad == null:
		if _admob_initialized:
			_load_interstitial()
		if on_finish_callback.is_valid():
			on_finish_callback.call()
		interstitial_ad_completed.emit()
		return

	_pending_interstitial_cb = on_finish_callback
	_set_ad_audio_muted(true)
	_interstitial_ad.show()

func _finish_interstitial() -> void:
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	_set_ad_audio_muted(false)

	var cb := _pending_interstitial_cb
	_pending_interstitial_cb = Callable()
	if cb.is_valid():
		cb.call()

	interstitial_ad_completed.emit()
	_load_interstitial()

# -------------------------------------------------------------
# 4. REWARDED AD (RewardedAdLoader / RewardedAd)
# -------------------------------------------------------------
func _load_rewarded() -> void:
	if not _is_mobile_admob_supported() or not _admob_initialized:
		return
	if _rewarded_loading or _rewarded_ad != null:
		return

	_rewarded_loading = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		_rewarded_ad = ad
		_setup_rewarded_callbacks()
	cb.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_rewarded_loading = false
		print("AdManager: Rewarded load failed: ", err.message)

	RewardedAdLoader.new().load(ADMOB_REWARDED_ID, AdRequest.new(), cb)

func _setup_rewarded_callbacks() -> void:
	if _rewarded_ad == null:
		return
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_rewarded(false)
	cb.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("AdManager: Rewarded show failed: ", err.message)
		_finish_rewarded(true)
	_rewarded_ad.full_screen_content_callback = cb

func is_rewarded_ready() -> bool:
	if not _is_mobile_admob_supported():
		return true
	return _rewarded_ad != null

func show_rewarded_ad(on_reward_callback: Callable = Callable()) -> void:
	rewarded_ad_started.emit()
	if not _is_mobile_admob_supported() or not _admob_initialized \
			or _rewarded_ad == null:
		if _admob_initialized:
			_load_rewarded()
		if on_reward_callback.is_valid():
			on_reward_callback.call()
		rewarded_ad_completed.emit(true)
		return

	_pending_reward_cb = on_reward_callback
	_reward_earned = false
	_set_ad_audio_muted(true)

	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_reward_earned = true

	_rewarded_ad.show(reward_listener)

func _finish_rewarded(fallback_grant: bool) -> void:
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	_set_ad_audio_muted(false)

	var granted := _reward_earned or fallback_grant
	_reward_earned = false
	var cb := _pending_reward_cb
	_pending_reward_cb = Callable()
	if granted and cb.is_valid():
		cb.call()

	rewarded_ad_completed.emit(granted)
	_load_rewarded()
