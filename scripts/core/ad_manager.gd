extends Node

# Wrong Way — AdManager (v1.0 Ad-Free Release Mode)
# - v1.0 is published 100% ad-free to app stores (Uptodown, Samsung Galaxy Store,
#   Amazon Appstore) so the live store listing URL can be registered with Unity Ads.
# - In v1.1, set ADS_ENABLED = true and wire the Unity Ads SDK into the methods below.
# - All public signals and methods are preserved so gameplay/UI hooks stay clean.

const ADS_ENABLED: bool = false

signal banner_visibility_changed(is_visible: bool)
signal rewarded_ad_started
signal rewarded_ad_completed(reward_granted: bool)
signal interstitial_ad_completed

var is_banner_active: bool = false
var banner_enabled: bool = false
var consent_granted: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_banner_active = false
	banner_enabled = false

func is_ads_enabled() -> bool:
	return ADS_ENABLED

# -------------------------------------------------------------
# 1. BANNER AD (Disabled in v1.0)
# -------------------------------------------------------------
func show_banner() -> void:
	if not ADS_ENABLED:
		is_banner_active = false
		return

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
# 2. INTERSTITIAL AD (No-op pass-through in v1.0)
# -------------------------------------------------------------
func show_interstitial(on_finish_callback: Callable = Callable()) -> void:
	show_interstitial_ad(on_finish_callback)

func show_interstitial_replay(on_finish_callback: Callable = Callable()) -> void:
	show_interstitial_ad(on_finish_callback)

func show_interstitial_ad(on_finish_callback: Callable = Callable()) -> void:
	if on_finish_callback.is_valid():
		on_finish_callback.call()
	interstitial_ad_completed.emit()

# -------------------------------------------------------------
# 3. REWARDED AD (Disabled in v1.0)
# -------------------------------------------------------------
func is_rewarded_ready() -> bool:
	return false

func show_rewarded_ad(
	on_reward_callback: Callable = Callable(),
	allow_fallback_if_unavailable: bool = false,
	on_unavailable_callback: Callable = Callable()
) -> void:
	if allow_fallback_if_unavailable:
		rewarded_ad_started.emit()
		if on_reward_callback.is_valid():
			on_reward_callback.call()
		rewarded_ad_completed.emit(true)
	else:
		if on_unavailable_callback.is_valid():
			on_unavailable_callback.call()
		rewarded_ad_completed.emit(false)
