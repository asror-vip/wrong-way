extends Control
class_name OfflineOverlay

## Reusable frosted/blurred "No Internet" overlay with wifi_off icon,
## 4-language localized text, and working Retry (+ optional Close) button.

signal retry_pressed
signal dismissed

const FROSTED_SHADER := preload("res://shaders/frosted_blur.gdshader")
const STYLE_WHITE := preload("res://resources/themes/btn_capsule_white.tres")
const STYLE_WHITE_HOV := preload("res://resources/themes/btn_capsule_white_hover.tres")
const STYLE_WHITE_PRESS := preload("res://resources/themes/btn_capsule_white_pressed.tres")
const STYLE_GLASS := preload("res://resources/themes/btn_capsule_glass.tres")
const STYLE_GLASS_HOV := preload("res://resources/themes/btn_capsule_glass_hover.tres")
const STYLE_GLASS_PRESS := preload("res://resources/themes/btn_capsule_glass_pressed.tres")
const STYLE_FOCUS := preload("res://resources/themes/btn_focus_empty.tres")

var show_close_button: bool = true
var card_max_width: float = 340.0

var blur_backdrop: ColorRect = null
var card_panel: PanelContainer = null
var icon_rect: TextureRect = null
var title_label: Label = null
var desc_label: Label = null
var retry_btn: Button = null
var close_btn: Button = null
var _anim_tween: Tween = null

static func is_network_error(err_msg: String) -> bool:
	var low := err_msg.strip_edges().to_lower()
	if low.is_empty():
		return false
	if low.contains("bekor") or low.contains("canceled") or low.contains("cancelled") or low.contains("no_credential"):
		return false
	for kw in [
		"offline", "no_network", "network_error", "network", "internet",
		"timeout", "timed out", "cant_connect", "cant_resolve", "unable to connect",
		"connection", "unreachable", "dns", "http 0", "ulanish", "tarmoq",
		"socket", "failed to connect", "no address", "server bilan"
	]:
		if low.contains(kw):
			return true
	return false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_update_texts()
	var loc = get_node_or_null("/root/LocaleManager")
	if loc and not loc.language_changed.is_connected(_on_language_changed):
		loc.language_changed.connect(_on_language_changed)

func _exit_tree() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	var loc = get_node_or_null("/root/LocaleManager")
	if loc and loc.language_changed.is_connected(_on_language_changed):
		loc.language_changed.disconnect(_on_language_changed)

func _build_ui() -> void:
	# Frosted blur backdrop (captures viewport behind this overlay cleanly)
	var bbc := BackBufferCopy.new()
	bbc.name = "FrostedCopy"
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bbc)

	blur_backdrop = ColorRect.new()
	blur_backdrop.name = "BlurBackdrop"
	blur_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_backdrop.color = Color(0.04, 0.06, 0.11, 0.84)
	blur_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	var mat := ShaderMaterial.new()
	mat.shader = FROSTED_SHADER
	mat.set_shader_parameter("blur_radius", 4.5)
	mat.set_shader_parameter("tint_color", Color(0.04, 0.06, 0.11, 0.74))
	blur_backdrop.material = mat
	add_child(blur_backdrop)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.name = "OfflineCard"
	card_panel.custom_minimum_size = Vector2(card_max_width, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.15, 0.92)
	sb.border_color = Color(0.38, 0.48, 0.65, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 18
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 24.0
	sb.content_margin_bottom = 22.0
	card_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(card_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	card_panel.add_child(vbox)

	# Circular frosted badge behind wifi_off icon
	var icon_wrap := CenterContainer.new()
	icon_wrap.name = "IconWrap"
	vbox.add_child(icon_wrap)

	var icon_bg := PanelContainer.new()
	icon_bg.custom_minimum_size = Vector2(68, 68)
	var ib_sb := StyleBoxFlat.new()
	ib_sb.bg_color = Color(0.97, 0.44, 0.44, 0.12)
	ib_sb.border_color = Color(0.97, 0.44, 0.44, 0.40)
	ib_sb.set_border_width_all(1)
	ib_sb.set_corner_radius_all(34)
	icon_bg.add_theme_stylebox_override("panel", ib_sb)
	icon_wrap.add_child(icon_bg)

	var icon_center := CenterContainer.new()
	icon_bg.add_child(icon_center)

	icon_rect = TextureRect.new()
	icon_rect.name = "WifiOffIcon"
	icon_rect.custom_minimum_size = Vector2(38, 38)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icf = get_node_or_null("/root/IconFactory")
	if icf:
		icon_rect.texture = icf.get_icon("wifi_off", 2.0)
	icon_center.add_child(icon_rect)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	vbox.add_child(title_label)

	desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.66, 0.74, 0.86))
	vbox.add_child(desc_label)

	var btn_row := HBoxContainer.new()
	btn_row.name = "BtnRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	retry_btn = Button.new()
	retry_btn.name = "RetryBtn"
	retry_btn.custom_minimum_size = Vector2(142, 40)
	retry_btn.focus_mode = Control.FOCUS_NONE
	retry_btn.add_theme_stylebox_override("normal", STYLE_WHITE)
	retry_btn.add_theme_stylebox_override("hover", STYLE_WHITE_HOV)
	retry_btn.add_theme_stylebox_override("pressed", STYLE_WHITE_PRESS)
	retry_btn.add_theme_stylebox_override("focus", STYLE_FOCUS)
	retry_btn.add_theme_color_override("font_color", Color(0.06, 0.08, 0.12))
	retry_btn.add_theme_color_override("font_hover_color", Color(0.02, 0.04, 0.08))
	retry_btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.04, 0.08))
	retry_btn.add_theme_font_size_override("font_size", 13)
	var icf_retry = get_node_or_null("/root/IconFactory")
	if icf_retry:
		retry_btn.icon = icf_retry.get_icon("restart_dark", 0.75)
	retry_btn.pressed.connect(_on_retry_pressed)
	btn_row.add_child(retry_btn)

	close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.custom_minimum_size = Vector2(104, 40)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_stylebox_override("normal", STYLE_GLASS)
	close_btn.add_theme_stylebox_override("hover", STYLE_GLASS_HOV)
	close_btn.add_theme_stylebox_override("pressed", STYLE_GLASS_PRESS)
	close_btn.add_theme_stylebox_override("focus", STYLE_FOCUS)
	close_btn.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.visible = show_close_button
	close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(close_btn)

func _on_language_changed(_lang: String) -> void:
	_update_texts()

func _update_texts() -> void:
	var loc = get_node_or_null("/root/LocaleManager")
	if title_label:
		title_label.text = loc.t("offline_title") if loc else "No Internet"
	if desc_label:
		desc_label.text = loc.t("offline_desc") if loc else ""
	if retry_btn:
		retry_btn.text = "  " + (loc.t("btn_retry") if loc else "Retry")
	if close_btn:
		close_btn.text = loc.t("btn_close") if loc else "Close"
		close_btn.visible = show_close_button

func show_overlay() -> void:
	_update_texts()
	visible = true
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	modulate.a = 0.0
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func hide_overlay() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	visible = false

func _on_retry_pressed() -> void:
	var snd = get_node_or_null("/root/SoundManager")
	if snd:
		snd.play("click")
	hide_overlay()
	retry_pressed.emit()

func _on_close_pressed() -> void:
	var snd = get_node_or_null("/root/SoundManager")
	if snd:
		snd.play("click")
	hide_overlay()
	dismissed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible and show_close_button:
		_on_close_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if visible and show_close_button and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
