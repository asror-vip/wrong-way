extends Control
class_name SettingsModal

signal closed

@onready var backdrop: ColorRect = $Backdrop
@onready var card: Panel = $Card
@onready var close_btn: Button = $Card/CloseBtn
@onready var title_label: Label = $Card/TitleRow/TitleLabel
@onready var title_icon_rect: TextureRect = $Card/TitleRow/TitleIcon

@onready var lang_label: Label = $Card/Content/LangRow/Header/LangLabel
@onready var lang_icon_rect: TextureRect = $Card/Content/LangRow/Header/LangIcon

@onready var btn_uz: Button = $Card/Content/LangRow/BtnBox/BtnUZ
@onready var btn_ru: Button = $Card/Content/LangRow/BtnBox/BtnRU
@onready var btn_en: Button = $Card/Content/LangRow/BtnBox/BtnEN
@onready var btn_tr: Button = $Card/Content/LangRow/BtnBox/BtnTR

@onready var music_label: Label = get_node_or_null("Card/Content/MusicRow/MusicLabel")
@onready var music_icon_rect: TextureRect = get_node_or_null("Card/Content/MusicRow/MusicIcon")
@onready var music_toggle_btn: Button = get_node_or_null("Card/Content/MusicRow/MusicToggleBtn")
@onready var music_vol_label: Label = get_node_or_null("Card/Content/MusicVolRow/MusicVolLabel")
@onready var music_vol_slider: HSlider = get_node_or_null("Card/Content/MusicVolRow/MusicVolSlider")
@onready var music_vol_percent: Label = get_node_or_null("Card/Content/MusicVolRow/MusicVolPercent")

@onready var sound_label: Label = $Card/Content/SoundRow/SoundLabel
@onready var sound_icon_rect: TextureRect = $Card/Content/SoundRow/SoundIcon
@onready var sound_toggle_btn: Button = $Card/Content/SoundRow/SoundToggleBtn
@onready var sound_vol_label: Label = get_node_or_null("Card/Content/SoundVolRow/SoundVolLabel")
@onready var sound_vol_slider: HSlider = get_node_or_null("Card/Content/SoundVolRow/SoundVolSlider")
@onready var sound_vol_percent: Label = get_node_or_null("Card/Content/SoundVolRow/SoundVolPercent")

@onready var shake_label: Label = $Card/Content/ShakeRow/ShakeLabel
@onready var shake_icon_rect: TextureRect = $Card/Content/ShakeRow/ShakeIcon
@onready var shake_toggle_btn: Button = $Card/Content/ShakeRow/ShakeToggleBtn

@onready var controls_title: Label = $Card/Content/ControlsBox/ControlsTitle
@onready var controls_desc: Label = $Card/Content/ControlsBox/ControlsDesc
@onready var customize_controls_btn: Button = get_node_or_null("Card/Content/ControlsBox/CustomizeControlsBtn")
@onready var control_customizer: Control = get_node_or_null("ControlCustomizer")

var style_white = preload("res://resources/themes/btn_capsule_white.tres")
var style_white_hov = preload("res://resources/themes/btn_capsule_white_hover.tres")
var style_white_press = preload("res://resources/themes/btn_capsule_white_pressed.tres")
var style_glass = preload("res://resources/themes/btn_capsule_glass.tres")
var style_glass_hov = preload("res://resources/themes/btn_capsule_glass_hover.tres")
var style_glass_press = preload("res://resources/themes/btn_capsule_glass_pressed.tres")

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if card:
		card.draw.connect(_on_card_draw)
	
	_setup_icons()
	_setup_signals()
	_update_ui_texts()
	_update_toggles()
	_update_lang_buttons()

func _setup_icons() -> void:
	if title_icon_rect: title_icon_rect.texture = IconFactory.get_icon("gear", 1.1)
	if lang_icon_rect: lang_icon_rect.texture = IconFactory.get_icon("globe", 0.9)
	if close_btn:
		close_btn.icon = IconFactory.get_icon("circle_btn_close", 1.0)
		close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		close_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if music_vol_slider:
		music_vol_slider.add_theme_icon_override("grabber", IconFactory.get_icon("slider_grabber", 1.0))
		music_vol_slider.add_theme_icon_override("grabber_highlight", IconFactory.get_icon("slider_grabber_hover", 1.0))
	if sound_vol_slider:
		sound_vol_slider.add_theme_icon_override("grabber", IconFactory.get_icon("slider_grabber", 1.0))
		sound_vol_slider.add_theme_icon_override("grabber_highlight", IconFactory.get_icon("slider_grabber_hover", 1.0))

func _setup_signals() -> void:
	if btn_uz: btn_uz.pressed.connect(func(): _select_language("uz"))
	if btn_ru: btn_ru.pressed.connect(func(): _select_language("ru"))
	if btn_en: btn_en.pressed.connect(func(): _select_language("en"))
	if btn_tr: btn_tr.pressed.connect(func(): _select_language("tr"))
	
	if music_toggle_btn:
		music_toggle_btn.pressed.connect(func():
			SoundManager.play("click")
			SaveManager.music_enabled = not SaveManager.music_enabled
			SaveManager.save_data()
			SoundManager.set_music_enabled(SaveManager.music_enabled)
			_update_toggles()
		)

	if music_vol_slider:
		music_vol_slider.value_changed.connect(func(val: float):
			if music_vol_percent: music_vol_percent.text = "%d%%" % int(val)
			SaveManager.music_volume = clampf(val / 100.0, 0.0, 1.0)
			SaveManager.save_data()
			SoundManager.update_music_volume(false)
		)
		
	if sound_toggle_btn:
		sound_toggle_btn.pressed.connect(func():
			SoundManager.play("click")
			SaveManager.sfx_enabled = not SaveManager.sfx_enabled
			SaveManager.save_data()
			_update_toggles()
		)

	if sound_vol_slider:
		sound_vol_slider.value_changed.connect(func(val: float):
			if sound_vol_percent: sound_vol_percent.text = "%d%%" % int(val)
			SaveManager.sfx_volume = clampf(val / 100.0, 0.0, 1.0)
			SaveManager.save_data()
			SoundManager.update_sfx_volume()
		)
		
	if shake_toggle_btn:
		shake_toggle_btn.pressed.connect(func():
			SoundManager.play("click")
			SaveManager.shake_enabled = not SaveManager.shake_enabled
			SaveManager.save_data()
			_update_toggles()
		)
		
	if customize_controls_btn:
		customize_controls_btn.pressed.connect(func():
			SoundManager.play("click")
			if control_customizer:
				control_customizer.open()
		)
		
	if close_btn:
		close_btn.pressed.connect(func():
			SoundManager.play("click")
			close()
		)
		
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				SoundManager.play("click")
				close()
		)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			SoundManager.play("click")
			close()
			get_viewport().set_input_as_handled()

func _on_card_draw() -> void:
	if not card: return
	var s := card.size
	var arm := 12.0
	var c := Color(0.85, 0.90, 1.0, 0.55)
	var w := 1.5
	var m := 6.0
	
	# Top-Left ┌
	card.draw_line(Vector2(m, m + arm), Vector2(m, m), c, w)
	card.draw_line(Vector2(m, m), Vector2(m + arm, m), c, w)
	
	# Top-Right ┐
	card.draw_line(Vector2(s.x - m - arm, m), Vector2(s.x - m, m), c, w)
	card.draw_line(Vector2(s.x - m, m), Vector2(s.x - m, m + arm), c, w)
	
	# Bottom-Left └
	card.draw_line(Vector2(m, s.y - m - arm), Vector2(m, s.y - m), c, w)
	card.draw_line(Vector2(m, s.y - m), Vector2(m + arm, s.y - m), c, w)
	
	# Bottom-Right ┘
	card.draw_line(Vector2(s.x - m - arm, s.y - m), Vector2(s.x - m, s.y - m), c, w)
	card.draw_line(Vector2(s.x - m, s.y - m), Vector2(s.x - m, s.y - m - arm), c, w)

func open() -> void:
	_update_ui_texts()
	_update_toggles()
	_update_lang_buttons()
	visible = true
	if card:
		card.queue_redraw()

func close() -> void:
	visible = false
	closed.emit()

func _select_language(lang: String) -> void:
	SoundManager.play("click")
	LocaleManager.set_language(lang)
	_update_ui_texts()
	_update_lang_buttons()
	_update_toggles()

func _update_ui_texts() -> void:
	if title_label: title_label.text = LocaleManager.t("settings_title")
	if lang_label: lang_label.text = LocaleManager.t("setting_language")
	if music_label: music_label.text = LocaleManager.t("setting_music")
	if music_vol_label: music_vol_label.text = LocaleManager.t("setting_music_volume")
	if sound_label: sound_label.text = LocaleManager.t("setting_sound")
	if sound_vol_label: sound_vol_label.text = LocaleManager.t("setting_sound_volume")
	if shake_label: shake_label.text = LocaleManager.t("setting_shake")
	if controls_title: controls_title.text = LocaleManager.t("controls_title")
	if controls_desc: controls_desc.text = LocaleManager.t("controls_desc")
	if customize_controls_btn:
		customize_controls_btn.text = "  " + LocaleManager.t("btn_customize_controls")
		customize_controls_btn.icon = IconFactory.get_icon("gamepad", 0.85)

func _update_lang_buttons() -> void:
	var cur := LocaleManager.current_language
	_style_btn(btn_uz, cur == "uz")
	_style_btn(btn_ru, cur == "ru")
	_style_btn(btn_en, cur == "en")
	_style_btn(btn_tr, cur == "tr")

func _style_btn(btn: Button, active: bool) -> void:
	if not btn: return
	if active:
		btn.add_theme_stylebox_override("normal", style_white)
		btn.add_theme_stylebox_override("hover", style_white_hov)
		btn.add_theme_stylebox_override("pressed", style_white_press)
		btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.1))
		btn.add_theme_color_override("font_hover_color", Color(0.02, 0.03, 0.05))
		btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.03, 0.05))
		btn.add_theme_color_override("font_focus_color", Color(0.06, 0.07, 0.1))
	else:
		btn.add_theme_stylebox_override("normal", style_glass)
		btn.add_theme_stylebox_override("hover", style_glass_hov)
		btn.add_theme_stylebox_override("pressed", style_glass_press)
		btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.93, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(0.85, 0.88, 0.95))

func _update_toggles() -> void:
	if music_toggle_btn:
		music_toggle_btn.icon = null
		if SaveManager.music_enabled:
			music_toggle_btn.text = LocaleManager.t("status_on")
			music_toggle_btn.add_theme_stylebox_override("normal", style_white)
			music_toggle_btn.add_theme_stylebox_override("hover", style_white_hov)
			music_toggle_btn.add_theme_stylebox_override("pressed", style_white_press)
			music_toggle_btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.1))
			music_toggle_btn.add_theme_color_override("font_hover_color", Color(0.02, 0.03, 0.05))
			music_toggle_btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.03, 0.05))
			music_toggle_btn.add_theme_color_override("font_focus_color", Color(0.06, 0.07, 0.1))
		else:
			music_toggle_btn.text = LocaleManager.t("status_off")
			music_toggle_btn.add_theme_stylebox_override("normal", style_glass)
			music_toggle_btn.add_theme_stylebox_override("hover", style_glass_hov)
			music_toggle_btn.add_theme_stylebox_override("pressed", style_glass_press)
			music_toggle_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75))
			music_toggle_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.90, 1.0))
			music_toggle_btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.90, 1.0))
			music_toggle_btn.add_theme_color_override("font_focus_color", Color(0.60, 0.65, 0.75))
			
	if music_icon_rect:
		music_icon_rect.texture = IconFactory.get_icon("music_on" if SaveManager.music_enabled else "music_off", 0.9)

	if music_vol_slider:
		music_vol_slider.value = SaveManager.music_volume * 100.0
		if music_vol_percent:
			music_vol_percent.text = "%d%%" % int(music_vol_slider.value)

	if sound_toggle_btn:
		sound_toggle_btn.icon = null
		if SaveManager.sfx_enabled:
			sound_toggle_btn.text = LocaleManager.t("status_on")
			sound_toggle_btn.add_theme_stylebox_override("normal", style_white)
			sound_toggle_btn.add_theme_stylebox_override("hover", style_white_hov)
			sound_toggle_btn.add_theme_stylebox_override("pressed", style_white_press)
			sound_toggle_btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.1))
			sound_toggle_btn.add_theme_color_override("font_hover_color", Color(0.02, 0.03, 0.05))
			sound_toggle_btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.03, 0.05))
			sound_toggle_btn.add_theme_color_override("font_focus_color", Color(0.06, 0.07, 0.1))
		else:
			sound_toggle_btn.text = LocaleManager.t("status_off")
			sound_toggle_btn.add_theme_stylebox_override("normal", style_glass)
			sound_toggle_btn.add_theme_stylebox_override("hover", style_glass_hov)
			sound_toggle_btn.add_theme_stylebox_override("pressed", style_glass_press)
			sound_toggle_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75))
			sound_toggle_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.90, 1.0))
			sound_toggle_btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.90, 1.0))
			sound_toggle_btn.add_theme_color_override("font_focus_color", Color(0.60, 0.65, 0.75))
			
	if sound_icon_rect:
		sound_icon_rect.texture = IconFactory.get_icon("sound_on" if SaveManager.sfx_enabled else "sound_off", 0.9)

	if sound_vol_slider:
		sound_vol_slider.value = SaveManager.sfx_volume * 100.0
		if sound_vol_percent:
			sound_vol_percent.text = "%d%%" % int(sound_vol_slider.value)

	if shake_toggle_btn:
		if SaveManager.shake_enabled:
			shake_toggle_btn.text = LocaleManager.t("status_on")
			shake_toggle_btn.add_theme_stylebox_override("normal", style_white)
			shake_toggle_btn.add_theme_stylebox_override("hover", style_white_hov)
			shake_toggle_btn.add_theme_stylebox_override("pressed", style_white_press)
			shake_toggle_btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.1))
			shake_toggle_btn.add_theme_color_override("font_hover_color", Color(0.02, 0.03, 0.05))
			shake_toggle_btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.03, 0.05))
			shake_toggle_btn.add_theme_color_override("font_focus_color", Color(0.06, 0.07, 0.1))
		else:
			shake_toggle_btn.text = LocaleManager.t("status_off")
			shake_toggle_btn.add_theme_stylebox_override("normal", style_glass)
			shake_toggle_btn.add_theme_stylebox_override("hover", style_glass_hov)
			shake_toggle_btn.add_theme_stylebox_override("pressed", style_glass_press)
			shake_toggle_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75))
			shake_toggle_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.90, 1.0))
			shake_toggle_btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.90, 1.0))
			shake_toggle_btn.add_theme_color_override("font_focus_color", Color(0.60, 0.65, 0.75))
			
	if shake_icon_rect:
		shake_icon_rect.texture = IconFactory.get_icon("shake", 0.9)
