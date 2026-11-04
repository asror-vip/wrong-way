extends Node

# Wrong Way — AdManager (Google AdMob & Cross-Platform Ad System)
# - Banner: Displayed in all menus (Main Menu, Level Select, Editor), strictly HIDDEN during active gameplay.
# - Interstitial (To'liq ekranli oraliq reklama): Triggers immediately when a player replays an already beaten level.
# - Rewarded Video: Triggers when player watches an ad to unlock a level (alternating "cheriz" rule).

# Google AdMob Identifikatorlari (Official Production IDs)
const ADMOB_APP_ID := "ca-app-pub-9009277559004471~1297962659"
const ADMOB_BANNER_ID := "ca-app-pub-9009277559004471/5320968143"
const ADMOB_INTERSTITIAL_ID := "ca-app-pub-9009277559004471/1106390961"
const ADMOB_REWARDED_ID := "ca-app-pub-9009277559004471/5903035034"

signal banner_visibility_changed(is_visible: bool)
signal rewarded_ad_started
signal rewarded_ad_completed(reward_granted: bool)
signal interstitial_ad_completed

var canvas_layer: CanvasLayer = null

# Banner UI
var banner_panel: Panel = null
var banner_label: Label = null
var is_banner_active: bool = false
var banner_enabled: bool = true

# Rewarded UI
var rewarded_overlay: Control = null
var rewarded_card: Control = null
var rewarded_status_label: Label = null
var rewarded_timer_label: Label = null
var rewarded_progress: ProgressBar = null
var rewarded_claim_btn: Button = null
var is_rewarded_active: bool = false
var pending_reward_callback: Callable = Callable()
var rewarded_duration_sec: float = 5.0
var rewarded_elapsed: float = 0.0
var is_rewarded_finished: bool = false

# Interstitial UI
var interstitial_overlay: Control = null
var interstitial_card: Control = null
var interstitial_timer_label: Label = null
var interstitial_progress: ProgressBar = null
var interstitial_skip_btn: Button = null
var is_interstitial_active: bool = false
var pending_interstitial_callback: Callable = Callable()
var interstitial_duration_sec: float = 4.0
var interstitial_elapsed: float = 0.0
var is_interstitial_finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ad_ui()
	_init_native_admob()

func _setup_ad_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 120 # Above HUD and modals
	canvas_layer.name = "AdLayer"
	add_child(canvas_layer)
	
	_create_banner_ui()
	_create_rewarded_ui()
	_create_interstitial_ui()

# -------------------------------------------------------------
# 1. BANNER AD (Yuqorida, nozik va xalaqit bermaydigan)
# -------------------------------------------------------------
func _create_banner_ui() -> void:
	banner_panel = Panel.new()
	banner_panel.name = "TopBannerPanel"
	banner_panel.custom_minimum_size = Vector2(340, 42)
	banner_panel.size = Vector2(340, 42)
	
	banner_panel.anchors_preset = Control.PRESET_TOP_WIDE
	banner_panel.anchor_left = 0.5
	banner_panel.anchor_right = 0.5
	banner_panel.anchor_top = 0.0
	banner_panel.anchor_bottom = 0.0
	banner_panel.offset_left = -170.0
	banner_panel.offset_right = 170.0
	banner_panel.offset_top = 8.0
	banner_panel.offset_bottom = 50.0
	banner_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.15, 0.94)
	style.border_color = Color(0.24, 0.32, 0.45, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	banner_panel.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_panel.add_child(hbox)
	
	# Ad Badge
	var ad_tag := Label.new()
	ad_tag.text = "REKLAMA"
	ad_tag.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25, 1.0))
	ad_tag.add_theme_font_size_override("font_size", 10)
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = Color(0.22, 0.18, 0.08, 0.95)
	tag_style.border_color = Color(1.0, 0.82, 0.25, 0.5)
	tag_style.set_border_width_all(1)
	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 6.0
	tag_style.content_margin_right = 6.0
	tag_style.content_margin_top = 2.0
	tag_style.content_margin_bottom = 2.0
	ad_tag.add_theme_stylebox_override("normal", tag_style)
	hbox.add_child(ad_tag)
	
	banner_label = Label.new()
	banner_label.text = "Google AdMob • Wrong Way Rasmiy Homiysi"
	banner_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98, 0.90))
	banner_label.add_theme_font_size_override("font_size", 11)
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(banner_label)
	
	canvas_layer.add_child(banner_panel)
	banner_panel.visible = false

func show_banner() -> void:
	if not banner_enabled:
		hide_banner()
		return
	is_banner_active = true
	if banner_panel:
		banner_panel.visible = true
		banner_panel.modulate.a = 1.0
	banner_visibility_changed.emit(true)
	_native_show_banner()

func hide_banner() -> void:
	is_banner_active = false
	if banner_panel:
		banner_panel.visible = false
	banner_visibility_changed.emit(false)
	_native_hide_banner()

func is_banner_visible() -> bool:
	return is_banner_active and banner_panel != null and banner_panel.visible

# -------------------------------------------------------------
# 2. INTERSTITIAL AD (To'liq ekranli oraliq reklama)
# -------------------------------------------------------------
func _create_interstitial_ui() -> void:
	interstitial_overlay = Control.new()
	interstitial_overlay.name = "InterstitialOverlay"
	interstitial_overlay.anchors_preset = Control.PRESET_FULL_RECT
	interstitial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	interstitial_overlay.visible = false
	
	var backdrop := ColorRect.new()
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.color = Color(0.03, 0.04, 0.07, 0.96)
	interstitial_overlay.add_child(backdrop)
	
	interstitial_card = Control.new()
	interstitial_card.custom_minimum_size = Vector2(460, 300)
	interstitial_card.anchors_preset = Control.PRESET_CENTER
	interstitial_card.offset_left = -230.0
	interstitial_card.offset_right = 230.0
	interstitial_card.offset_top = -150.0
	interstitial_card.offset_bottom = 150.0
	interstitial_overlay.add_child(interstitial_card)
	
	var card_panel := Panel.new()
	card_panel.anchors_preset = Control.PRESET_FULL_RECT
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.09, 0.12, 0.18, 0.98)
	card_style.border_color = Color(0.25, 0.38, 0.55, 0.9)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(16)
	card_style.shadow_color = Color(0, 0, 0, 0.6)
	card_style.shadow_size = 12
	card_panel.add_theme_stylebox_override("panel", card_style)
	interstitial_card.add_child(card_panel)
	
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 24.0
	vbox.offset_top = 20.0
	vbox.offset_right = -24.0
	vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	interstitial_card.add_child(vbox)
	
	var header_hbox := HBoxContainer.new()
	var title := Label.new()
	title.text = "ORALIQ REKLAMA"
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	interstitial_timer_label = Label.new()
	interstitial_timer_label.text = "4s"
	interstitial_timer_label.add_theme_color_override("font_color", Color(0.38, 0.74, 0.97))
	interstitial_timer_label.add_theme_font_size_override("font_size", 15)
	header_hbox.add_child(interstitial_timer_label)
	vbox.add_child(header_hbox)
	
	# Preview Box
	var media_box := Panel.new()
	media_box.custom_minimum_size = Vector2(0, 110)
	var m_style := StyleBoxFlat.new()
	m_style.bg_color = Color(0.05, 0.07, 0.12, 1.0)
	m_style.set_corner_radius_all(10)
	media_box.add_theme_stylebox_override("panel", m_style)
	
	var m_vbox := VBoxContainer.new()
	m_vbox.anchors_preset = Control.PRESET_FULL_RECT
	m_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	m_vbox.add_theme_constant_override("separation", 6)
	media_box.add_child(m_vbox)
	
	var sponsor_lbl := Label.new()
	sponsor_lbl.text = "Google AdMob Interstitial"
	sponsor_lbl.add_theme_color_override("font_color", Color(0.70, 0.80, 0.95))
	sponsor_lbl.add_theme_font_size_override("font_size", 14)
	sponsor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_vbox.add_child(sponsor_lbl)
	
	var hint_lbl := Label.new()
	hint_lbl.text = "Qayta o'ynalgan daraja yuklanmoqda..."
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.70))
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_vbox.add_child(hint_lbl)
	
	interstitial_progress = ProgressBar.new()
	interstitial_progress.custom_minimum_size = Vector2(280, 8)
	interstitial_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	interstitial_progress.show_percentage = false
	interstitial_progress.max_value = 100.0
	interstitial_progress.value = 0.0
	m_vbox.add_child(interstitial_progress)
	
	vbox.add_child(media_box)
	
	interstitial_skip_btn = Button.new()
	interstitial_skip_btn.text = "O'tkazib yuborish (3s)"
	interstitial_skip_btn.custom_minimum_size = Vector2(0, 42)
	interstitial_skip_btn.disabled = true
	interstitial_skip_btn.add_theme_font_size_override("font_size", 14)
	interstitial_skip_btn.pressed.connect(_on_skip_interstitial_pressed)
	vbox.add_child(interstitial_skip_btn)
	
	canvas_layer.add_child(interstitial_overlay)

func show_interstitial_ad(on_finish_callback: Callable = Callable()) -> void:
	pending_interstitial_callback = on_finish_callback
	is_interstitial_active = true
	is_interstitial_finished = false
	interstitial_elapsed = 0.0
	
	if interstitial_progress:
		interstitial_progress.value = 0.0
	if interstitial_timer_label:
		interstitial_timer_label.text = "4s"
	if interstitial_skip_btn:
		interstitial_skip_btn.disabled = true
		interstitial_skip_btn.text = "O'tkazib yuborish (3s)"
		
	if interstitial_overlay:
		interstitial_overlay.visible = true
		interstitial_overlay.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(interstitial_overlay, "modulate:a", 1.0, 0.2)
		
	_native_show_interstitial()

func _on_skip_interstitial_pressed() -> void:
	SoundManager.play("click")
	_finish_interstitial()

func _finish_interstitial() -> void:
	is_interstitial_active = false
	if interstitial_overlay:
		interstitial_overlay.visible = false
		
	if pending_interstitial_callback.is_valid():
		pending_interstitial_callback.call()
		pending_interstitial_callback = Callable()
		
	interstitial_ad_completed.emit()

# -------------------------------------------------------------
# 3. REWARDED VIDEO AD (Darajani ochish uchun mukofotli video)
# -------------------------------------------------------------
func _create_rewarded_ui() -> void:
	rewarded_overlay = Control.new()
	rewarded_overlay.name = "RewardedOverlay"
	rewarded_overlay.anchors_preset = Control.PRESET_FULL_RECT
	rewarded_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	rewarded_overlay.visible = false
	
	var backdrop := ColorRect.new()
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.color = Color(0.03, 0.04, 0.07, 0.96)
	rewarded_overlay.add_child(backdrop)
	
	rewarded_card = Control.new()
	rewarded_card.custom_minimum_size = Vector2(460, 300)
	rewarded_card.anchors_preset = Control.PRESET_CENTER
	rewarded_card.offset_left = -230.0
	rewarded_card.offset_right = 230.0
	rewarded_card.offset_top = -150.0
	rewarded_card.offset_bottom = 150.0
	rewarded_overlay.add_child(rewarded_card)
	
	var card_panel := Panel.new()
	card_panel.anchors_preset = Control.PRESET_FULL_RECT
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.09, 0.12, 0.18, 0.98)
	card_style.border_color = Color(0.95, 0.75, 0.20, 0.9)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(16)
	card_style.shadow_color = Color(0, 0, 0, 0.6)
	card_style.shadow_size = 12
	card_panel.add_theme_stylebox_override("panel", card_style)
	rewarded_card.add_child(card_panel)
	
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 24.0
	vbox.offset_top = 20.0
	vbox.offset_right = -24.0
	vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rewarded_card.add_child(vbox)
	
	var header_hbox := HBoxContainer.new()
	var title := Label.new()
	title.text = "MUKOFOTLI REKLAMA"
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40))
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	rewarded_timer_label = Label.new()
	rewarded_timer_label.text = "5s"
	rewarded_timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	rewarded_timer_label.add_theme_font_size_override("font_size", 15)
	header_hbox.add_child(rewarded_timer_label)
	vbox.add_child(header_hbox)
	
	var video_box := Panel.new()
	video_box.custom_minimum_size = Vector2(0, 110)
	var v_style := StyleBoxFlat.new()
	v_style.bg_color = Color(0.05, 0.07, 0.12, 1.0)
	v_style.set_corner_radius_all(10)
	video_box.add_theme_stylebox_override("panel", v_style)
	
	var v_vbox := VBoxContainer.new()
	v_vbox.anchors_preset = Control.PRESET_FULL_RECT
	v_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	v_vbox.add_theme_constant_override("separation", 8)
	video_box.add_child(v_vbox)
	
	rewarded_status_label = Label.new()
	rewarded_status_label.text = "Keyingi darajani ochish uchun video tomosha qilinmoqda..."
	rewarded_status_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.94))
	rewarded_status_label.add_theme_font_size_override("font_size", 12)
	rewarded_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_vbox.add_child(rewarded_status_label)
	
	rewarded_progress = ProgressBar.new()
	rewarded_progress.custom_minimum_size = Vector2(280, 8)
	rewarded_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rewarded_progress.show_percentage = false
	rewarded_progress.max_value = 100.0
	rewarded_progress.value = 0.0
	v_vbox.add_child(rewarded_progress)
	
	vbox.add_child(video_box)
	
	rewarded_claim_btn = Button.new()
	rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (5s)"
	rewarded_claim_btn.custom_minimum_size = Vector2(0, 42)
	rewarded_claim_btn.disabled = true
	rewarded_claim_btn.add_theme_font_size_override("font_size", 14)
	rewarded_claim_btn.pressed.connect(_on_claim_reward_pressed)
	vbox.add_child(rewarded_claim_btn)
	
	canvas_layer.add_child(rewarded_overlay)

func show_rewarded_ad(on_reward_callback: Callable = Callable()) -> void:
	pending_reward_callback = on_reward_callback
	is_rewarded_active = true
	is_rewarded_finished = false
	rewarded_elapsed = 0.0
	
	if rewarded_progress: rewarded_progress.value = 0.0
	if rewarded_timer_label:
		rewarded_timer_label.text = "5s"
		rewarded_timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	if rewarded_status_label:
		rewarded_status_label.text = "Keyingi darajani ochish uchun video tomosha qilinmoqda..."
		rewarded_status_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.94))
	if rewarded_claim_btn:
		rewarded_claim_btn.disabled = true
		rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (5s)"
		
	if rewarded_overlay:
		rewarded_overlay.visible = true
		rewarded_overlay.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(rewarded_overlay, "modulate:a", 1.0, 0.2)
		
	rewarded_ad_started.emit()
	_native_show_rewarded()

func _on_claim_reward_pressed() -> void:
	SoundManager.play("click")
	is_rewarded_active = false
	if rewarded_overlay:
		rewarded_overlay.visible = false
		
	if pending_reward_callback.is_valid():
		pending_reward_callback.call()
		pending_reward_callback = Callable()
		
	rewarded_ad_completed.emit(true)

# -------------------------------------------------------------
# Process & Loop Updates
# -------------------------------------------------------------
func _process(delta: float) -> void:
	# Rewarded Video Update
	if is_rewarded_active and not is_rewarded_finished:
		rewarded_elapsed += delta
		var remaining := maxf(0.0, rewarded_duration_sec - rewarded_elapsed)
		var pct := clampf((rewarded_elapsed / rewarded_duration_sec) * 100.0, 0.0, 100.0)
		
		if rewarded_progress: rewarded_progress.value = pct
		if rewarded_timer_label: rewarded_timer_label.text = "%0.1fs" % remaining
		if rewarded_claim_btn: rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (%ds)" % int(ceilf(remaining))
		
		if rewarded_elapsed >= rewarded_duration_sec:
			is_rewarded_finished = true
			if rewarded_timer_label:
				rewarded_timer_label.text = "Tugadi!"
				rewarded_timer_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
			if rewarded_status_label:
				rewarded_status_label.text = "Reklama yakunlandi! Daraja ochildi!"
				rewarded_status_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
			if rewarded_claim_btn:
				rewarded_claim_btn.disabled = false
				rewarded_claim_btn.text = "DARAJANI OCHISH"
			SoundManager.play("win")

	# Interstitial Update
	if is_interstitial_active and not is_interstitial_finished:
		interstitial_elapsed += delta
		var rem := maxf(0.0, interstitial_duration_sec - interstitial_elapsed)
		var pct := clampf((interstitial_elapsed / interstitial_duration_sec) * 100.0, 0.0, 100.0)
		
		if interstitial_progress: interstitial_progress.value = pct
		if interstitial_timer_label: interstitial_timer_label.text = "%0.1fs" % rem
		
		# 3 soniyadan keyin o'tkazib yuborish tugmasi faollashadi
		if interstitial_elapsed >= 2.5:
			if interstitial_skip_btn:
				interstitial_skip_btn.disabled = false
				interstitial_skip_btn.text = "O'TKAZIB YUBORISH (X)"
				
		if interstitial_elapsed >= interstitial_duration_sec:
			is_interstitial_finished = true
			_finish_interstitial()

# -------------------------------------------------------------
# Android Native Google AdMob Hook
# -------------------------------------------------------------
func _init_native_admob() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		var admob = Engine.get_singleton("PoingGodotAdMob")
		print("AdManager: Native Android PoingGodotAdMob aniqlandi")
		if admob.has_method("initialize"):
			admob.initialize()
		if admob.has_method("load_banner"):
			admob.load_banner(ADMOB_BANNER_ID, false, 0)
		if admob.has_method("load_interstitial"):
			admob.load_interstitial(ADMOB_INTERSTITIAL_ID)
		if admob.has_method("load_rewarded_video"):
			admob.load_rewarded_video(ADMOB_REWARDED_ID)
	elif Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		print("AdManager: Native Android GodotAdMob aniqlandi")
		if admob.has_method("init"):
			admob.init(false, get_instance_id())
		if admob.has_method("loadBanner"):
			admob.loadBanner(ADMOB_BANNER_ID, true)
		if admob.has_method("loadInterstitial"):
			admob.loadInterstitial(ADMOB_INTERSTITIAL_ID)
		if admob.has_method("loadRewardedVideo"):
			admob.loadRewardedVideo(ADMOB_REWARDED_ID)

func _native_show_banner() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		var admob = Engine.get_singleton("PoingGodotAdMob")
		if admob.has_method("show_banner"):
			admob.show_banner()
	elif Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		if admob.has_method("showBanner"):
			admob.showBanner()

func _native_hide_banner() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		var admob = Engine.get_singleton("PoingGodotAdMob")
		if admob.has_method("hide_banner"):
			admob.hide_banner()
	elif Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		if admob.has_method("hideBanner"):
			admob.hideBanner()

func _native_show_interstitial() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		var admob = Engine.get_singleton("PoingGodotAdMob")
		if admob.has_method("show_interstitial"):
			admob.show_interstitial()
	elif Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		if admob.has_method("showInterstitial"):
			admob.showInterstitial()

func _native_show_rewarded() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		var admob = Engine.get_singleton("PoingGodotAdMob")
		if admob.has_method("show_rewarded_video"):
			admob.show_rewarded_video()
	elif Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		if admob.has_method("showRewardedVideo"):
			admob.showRewardedVideo()
