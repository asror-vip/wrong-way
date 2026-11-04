extends Control

# AuthModal - Wrong Way Official Google Account Chooser Dialog
# Directly presents user's real Google accounts for 1-click authentication

signal auth_completed(provider: String)

@onready var modal_card: Control = $CenterContainer/CardPanel
@onready var close_btn: Button = $CenterContainer/CardPanel/CloseBtn
@onready var google_logo: TextureRect = $CenterContainer/CardPanel/ContentVBox/GoogleLogo
@onready var accounts_container: VBoxContainer = $CenterContainer/CardPanel/ContentVBox/AccountsScroll/AccountsVBox
@onready var other_account_btn: Button = $CenterContainer/CardPanel/ContentVBox/OtherAccountBtn
@onready var custom_email_row: HBoxContainer = $CenterContainer/CardPanel/ContentVBox/CustomEmailRow
@onready var email_input: LineEdit = $CenterContainer/CardPanel/ContentVBox/CustomEmailRow/EmailInput
@onready var connect_btn: Button = $CenterContainer/CardPanel/ContentVBox/CustomEmailRow/ConnectBtn
@onready var status_lbl: Label = $CenterContainer/CardPanel/ContentVBox/StatusLabel

var is_authenticating: bool = false

func _ready() -> void:
	visible = false
	if close_btn: close_btn.pressed.connect(close)
	if other_account_btn:
		other_account_btn.pressed.connect(func():
			SoundManager.play("click")
			if custom_email_row:
				custom_email_row.visible = !custom_email_row.visible
				if custom_email_row.visible and email_input:
					email_input.grab_focus()
		)
	if connect_btn: connect_btn.pressed.connect(_on_custom_connect_pressed)
	if email_input: email_input.text_submitted.connect(func(_t): _on_custom_connect_pressed())
	
	if google_logo:
		google_logo.texture = IconFactory.get_icon("google", 1.0)
		
	ProfileManager.google_login_finished.connect(_on_login_finished)

func open(_closable: bool = true) -> void:
	visible = true
	modulate.a = 0.0
	is_authenticating = false
	if status_lbl: status_lbl.text = ""
	if custom_email_row: custom_email_row.visible = false
	if email_input: email_input.text = ""
	
	_populate_google_accounts()
	
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func close() -> void:
	if is_authenticating:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	visible = false

func _populate_google_accounts() -> void:
	if not accounts_container:
		return
		
	for child in accounts_container.get_children():
		child.queue_free()
		
	var accounts: Array = ProfileManager.get_known_google_accounts()
	for acc in accounts:
		if acc is Dictionary:
			var aname: String = acc.get("name", "Player")
			var aemail: String = acc.get("email", "")
			if not aemail.is_empty():
				_create_account_card(aname, aemail)

func _create_account_card(acc_name: String, acc_email: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var sb_norm := StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.10, 0.14, 0.22, 0.90)
	sb_norm.border_color = Color(0.24, 0.36, 0.54, 0.70)
	sb_norm.set_border_width_all(1)
	sb_norm.set_corner_radius_all(14)
	sb_norm.content_margin_left = 12.0
	sb_norm.content_margin_right = 14.0
	
	var sb_hov := StyleBoxFlat.new()
	sb_hov.bg_color = Color(0.15, 0.22, 0.35, 0.95)
	sb_hov.border_color = Color(0.38, 0.74, 0.97, 0.95)
	sb_hov.set_border_width_all(1)
	sb_hov.set_corner_radius_all(14)
	sb_hov.content_margin_left = 12.0
	sb_hov.content_margin_right = 14.0
	
	var sb_press := StyleBoxFlat.new()
	sb_press.bg_color = Color(0.20, 0.30, 0.48, 1.0)
	sb_press.border_color = Color(0.38, 0.74, 0.97, 1.0)
	sb_press.set_border_width_all(1)
	sb_press.set_corner_radius_all(14)
	sb_press.content_margin_left = 12.0
	sb_press.content_margin_right = 14.0
	
	var sb_foc := StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("focus", sb_foc)
	
	var hbox := HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	btn.add_child(hbox)
	
	# Circular initial badge or Google avatar
	var avatar_panel := PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(32, 32)
	avatar_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = Color(0.18, 0.42, 0.72, 1.0)
	av_style.set_corner_radius_all(16)
	avatar_panel.add_theme_stylebox_override("panel", av_style)
	
	var letter_lbl := Label.new()
	letter_lbl.text = acc_name.substr(0, 1).to_upper() if not acc_name.is_empty() else "G"
	letter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter_lbl.add_theme_font_size_override("font_size", 14)
	letter_lbl.add_theme_color_override("font_color", Color.WHITE)
	avatar_panel.add_child(letter_lbl)
	hbox.add_child(avatar_panel)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	
	var name_lbl := Label.new()
	name_lbl.text = acc_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	vbox.add_child(name_lbl)
	
	var email_lbl := Label.new()
	email_lbl.text = acc_email
	email_lbl.add_theme_font_size_override("font_size", 11)
	email_lbl.add_theme_color_override("font_color", Color(0.60, 0.70, 0.85, 0.90))
	vbox.add_child(email_lbl)
	
	hbox.add_child(vbox)
	
	var arrow_lbl := Label.new()
	arrow_lbl.text = "›"
	arrow_lbl.add_theme_font_size_override("font_size", 20)
	arrow_lbl.add_theme_color_override("font_color", Color(0.38, 0.74, 0.97, 0.85))
	arrow_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(arrow_lbl)
	
	btn.pressed.connect(func():
		_select_google_account(acc_email, acc_name)
	)
	
	accounts_container.add_child(btn)

func _select_google_account(acc_email: String, acc_name: String) -> void:
	if is_authenticating:
		return
	is_authenticating = true
	SoundManager.play("click")
	_set_status("Google hisobiga ulanmoqda...", false)
	ProfileManager.login_with_google(acc_email, acc_name)
	
	# 8 soniyalik xavfsizlik taymeri
	var auth_generation := Time.get_ticks_msec()
	set_meta("auth_token", auth_generation)
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_authenticating and get_meta("auth_token", 0) == auth_generation:
			is_authenticating = false
			_set_status("Server javob bermadi. Internetni tekshirib qayta urining.", true)
	)

func _on_custom_connect_pressed() -> void:
	if not email_input or is_authenticating:
		return
	var raw_email := email_input.text.strip_edges()
	if not _is_valid_email(raw_email):
		_set_status("Haqiqiy Gmail manzil kiriting (user@gmail.com)", true)
		return
		
	var custom_name := raw_email.split("@")[0].capitalize()
	_select_google_account(raw_email, custom_name)

func _is_valid_email(e: String) -> bool:
	return e.contains("@") and e.contains(".") and e.length() >= 6

func _on_login_finished(success: bool, error_msg: String) -> void:
	is_authenticating = false
	if success:
		_set_status("Ulandi! Xush kelibsiz, " + ProfileManager.username + "!", false)
		auth_completed.emit("google")
		await get_tree().create_timer(0.5).timeout
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		await tw.finished
		visible = false
	else:
		_set_status(error_msg if not error_msg.is_empty() else "Serverga ulanishda xatolik", true)

func _set_status(text: String, is_err: bool) -> void:
	if status_lbl:
		status_lbl.text = text
		status_lbl.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35) if is_err else Color(0.38, 0.85, 0.55))
