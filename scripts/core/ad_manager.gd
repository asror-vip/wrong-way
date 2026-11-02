extends Node

# Wrong Way — AdManager (Google AdMob / Mobile Ad System)
# Provides top banner ad management and interactive full-screen rewarded ads.
# Rule: Banner is NEVER shown during active gameplay.
# Rule: Rewarded ad unlocks the next level for players who struggle to earn 2+ stars.

signal banner_visibility_changed(is_visible: bool)
signal rewarded_ad_started
signal rewarded_ad_completed(reward_granted: bool)

var canvas_layer: CanvasLayer = null
var banner_panel: Panel = null
var banner_label: Label = null

var rewarded_overlay: Control = null
var rewarded_card: Control = null
var rewarded_status_label: Label = null
var rewarded_timer_label: Label = null
var rewarded_progress: ProgressBar = null
var rewarded_claim_btn: Button = null
var rewarded_close_btn: Button = null

var is_banner_active: bool = false
var banner_enabled: bool = false # Foydalanuvchi talabiga binoan reklama banneri hozircha butunlay o'chirilgan
var is_rewarded_active: bool = false
var pending_reward_callback: Callable = Callable()

var ad_duration_sec: float = 5.0
var ad_elapsed_time: float = 0.0
var is_ad_finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ad_ui()
	hide_banner()

func _setup_ad_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # On top of HUD and gameplay
	canvas_layer.name = "AdLayer"
	add_child(canvas_layer)
	
	_create_banner_ui()
	_create_rewarded_ui()

func _create_banner_ui() -> void:
	banner_panel = Panel.new()
	banner_panel.name = "TopBannerPanel"
	banner_panel.custom_minimum_size = Vector2(320, 46)
	
	# Center top alignment
	banner_panel.anchors_preset = Control.PRESET_TOP_WIDE
	banner_panel.anchor_left = 0.5
	banner_panel.anchor_right = 0.5
	banner_panel.anchor_top = 0.0
	banner_panel.anchor_bottom = 0.0
	banner_panel.offset_left = -160.0
	banner_panel.offset_right = 160.0
	banner_panel.offset_top = 10.0
	banner_panel.offset_bottom = 56.0
	banner_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	# Sleek mobile ad container style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.13, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.28, 0.25, 0.35, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	banner_panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_panel.add_child(hbox)
	
	# Yellow Ad Tag
	var ad_tag = Label.new()
	ad_tag.text = "AD"
	ad_tag.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32, 1.0))
	ad_tag.add_theme_font_size_override("font_size", 11)
	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = Color(0.24, 0.20, 0.12, 0.9)
	tag_style.corner_radius_top_left = 4
	tag_style.corner_radius_top_right = 4
	tag_style.corner_radius_bottom_right = 4
	tag_style.corner_radius_bottom_left = 4
	tag_style.content_margin_left = 5.0
	tag_style.content_margin_right = 5.0
	tag_style.content_margin_top = 2.0
	tag_style.content_margin_bottom = 2.0
	ad_tag.add_theme_stylebox_override("normal", tag_style)
	hbox.add_child(ad_tag)
	
	# Main Banner Sponsor Text
	banner_label = Label.new()
	banner_label.text = "Google AdMob • Wrong Way Mobile Sponsor"
	banner_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.92, 1.0))
	banner_label.add_theme_font_size_override("font_size", 12)
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(banner_label)
	
	canvas_layer.add_child(banner_panel)

func _create_rewarded_ui() -> void:
	rewarded_overlay = Control.new()
	rewarded_overlay.name = "RewardedOverlay"
	rewarded_overlay.anchors_preset = Control.PRESET_FULL_RECT
	rewarded_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	rewarded_overlay.visible = false
	
	# Dark backdrop
	var backdrop = ColorRect.new()
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.color = Color(0.04, 0.03, 0.06, 0.95)
	rewarded_overlay.add_child(backdrop)
	
	# Center card
	rewarded_card = Control.new()
	rewarded_card.custom_minimum_size = Vector2(440, 290)
	rewarded_card.anchors_preset = Control.PRESET_CENTER
	rewarded_card.offset_left = -220.0
	rewarded_card.offset_right = 220.0
	rewarded_card.offset_top = -145.0
	rewarded_card.offset_bottom = 145.0
	rewarded_overlay.add_child(rewarded_card)
	
	var card_panel = Panel.new()
	card_panel.anchors_preset = Control.PRESET_FULL_RECT
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.11, 0.15, 0.98)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_color_border(card_style)
	card_panel.add_theme_stylebox_override("panel", card_style)
	rewarded_card.add_child(card_panel)
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 24.0
	vbox.offset_top = 20.0
	vbox.offset_right = -24.0
	vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rewarded_card.add_child(vbox)
	
	# Top Header
	var header_hbox = HBoxContainer.new()
	var title = Label.new()
	title.text = "MUKOFOTLI REKLAMA"
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	rewarded_timer_label = Label.new()
	rewarded_timer_label.text = "5s"
	rewarded_timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	rewarded_timer_label.add_theme_font_size_override("font_size", 15)
	header_hbox.add_child(rewarded_timer_label)
	vbox.add_child(header_hbox)
	
	# Mock Video Screen Display
	var video_box = Panel.new()
	video_box.custom_minimum_size = Vector2(0, 110)
	var v_style = StyleBoxFlat.new()
	v_style.bg_color = Color(0.07, 0.06, 0.09, 1.0)
	v_style.corner_radius_top_left = 10
	v_style.corner_radius_top_right = 10
	v_style.corner_radius_bottom_right = 10
	v_style.corner_radius_bottom_left = 10
	video_box.add_theme_stylebox_override("panel", v_style)
	
	var v_vbox = VBoxContainer.new()
	v_vbox.anchors_preset = Control.PRESET_FULL_RECT
	v_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	v_vbox.add_theme_constant_override("separation", 8)
	video_box.add_child(v_vbox)
	
	rewarded_status_label = Label.new()
	rewarded_status_label.text = "Reklama namoyish etilmoqda..."
	rewarded_status_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.94))
	rewarded_status_label.add_theme_font_size_override("font_size", 14)
	rewarded_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_vbox.add_child(rewarded_status_label)
	
	rewarded_progress = ProgressBar.new()
	rewarded_progress.custom_minimum_size = Vector2(300, 12)
	rewarded_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rewarded_progress.show_percentage = false
	rewarded_progress.max_value = 100.0
	rewarded_progress.value = 0.0
	v_vbox.add_child(rewarded_progress)
	
	vbox.add_child(video_box)
	
	# Action Button: Initially disabled / hidden until 5s finishes
	rewarded_claim_btn = Button.new()
	rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (5s)"
	rewarded_claim_btn.custom_minimum_size = Vector2(0, 44)
	rewarded_claim_btn.disabled = true
	rewarded_claim_btn.add_theme_font_size_override("font_size", 15)
	rewarded_claim_btn.pressed.connect(_on_claim_reward_pressed)
	vbox.add_child(rewarded_claim_btn)
	
	canvas_layer.add_child(rewarded_overlay)

func card_color_border(style: StyleBoxFlat) -> void:
	style.border_color = Color(0.38, 0.32, 0.48, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14

func _process(delta: float) -> void:
	if is_rewarded_active and not is_ad_finished:
		ad_elapsed_time += delta
		var remaining = maxf(0.0, ad_duration_sec - ad_elapsed_time)
		var progress_pct = clampf((ad_elapsed_time / ad_duration_sec) * 100.0, 0.0, 100.0)
		
		if rewarded_progress:
			rewarded_progress.value = progress_pct
		if rewarded_timer_label:
			rewarded_timer_label.text = "%0.1fs" % remaining
		if rewarded_claim_btn:
			rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (%ds)" % int(ceilf(remaining))
		
		if ad_elapsed_time >= ad_duration_sec:
			_complete_rewarded_ad()

func _complete_rewarded_ad() -> void:
	is_ad_finished = true
	if rewarded_timer_label:
		rewarded_timer_label.text = "Tugadi!"
		rewarded_timer_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	if rewarded_status_label:
		rewarded_status_label.text = "Reklama tugadi! Mukofot olindi!"
		rewarded_status_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
	if rewarded_claim_btn:
		rewarded_claim_btn.disabled = false
		rewarded_claim_btn.text = "DAVOM ETISH"
		rewarded_claim_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_win"):
		sm.play_win()

func show_banner() -> void:
	if not banner_enabled:
		hide_banner()
		return
	is_banner_active = true
	if banner_panel:
		banner_panel.visible = true
		banner_panel.modulate.a = 1.0
	banner_visibility_changed.emit(true)

func hide_banner() -> void:
	is_banner_active = false
	if banner_panel:
		banner_panel.visible = false
	banner_visibility_changed.emit(false)

func is_banner_visible() -> bool:
	return is_banner_active and banner_panel != null and banner_panel.visible

func show_rewarded_ad(on_reward_callback: Callable = Callable()) -> void:
	pending_reward_callback = on_reward_callback
	is_rewarded_active = true
	is_ad_finished = false
	ad_elapsed_time = 0.0
	
	if rewarded_progress:
		rewarded_progress.value = 0.0
	if rewarded_timer_label:
		rewarded_timer_label.text = "5s"
		rewarded_timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	if rewarded_status_label:
		rewarded_status_label.text = "Reklama namoyish etilmoqda..."
		rewarded_status_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.94))
	if rewarded_claim_btn:
		rewarded_claim_btn.disabled = true
		rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (5s)"
	
	# Animate card entry
	rewarded_overlay.visible = true
	rewarded_overlay.modulate.a = 0.0
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(rewarded_overlay, "modulate:a", 1.0, 0.20)
	
	rewarded_ad_started.emit()

func _on_claim_reward_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_click"):
		sm.play_click()
	
	is_rewarded_active = false
	rewarded_overlay.visible = false
	
	if pending_reward_callback.is_valid():
		pending_reward_callback.call()
		pending_reward_callback = Callable()
	
	rewarded_ad_completed.emit(true)
