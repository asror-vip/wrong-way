extends Control

# AuthModal - Wrong Way Google & Guest Authentication Dialog
# Provides two primary authentication choices:
# 1. Google Account Sign-In (with Google account picker dialog)
# 2. Guest Mode (Instant device-based offline play)

signal auth_completed(provider: String)

@onready var modal_card: Control = $CenterContainer/CardPanel
@onready var close_btn: Button = $CenterContainer/CardPanel/CloseBtn

# Views
@onready var select_view: VBoxContainer = $CenterContainer/CardPanel/ContentVBox/SelectView
@onready var google_btn: Button = $CenterContainer/CardPanel/ContentVBox/SelectView/GoogleBtn
@onready var guest_btn: Button = $CenterContainer/CardPanel/ContentVBox/SelectView/GuestBtn

@onready var google_picker_view: VBoxContainer = $CenterContainer/CardPanel/ContentVBox/GooglePickerView
@onready var accounts_container: VBoxContainer = $CenterContainer/CardPanel/ContentVBox/GooglePickerView/AccountsVBox
@onready var custom_email_input: LineEdit = $CenterContainer/CardPanel/ContentVBox/GooglePickerView/CustomEmailRow/EmailInput
@onready var custom_connect_btn: Button = $CenterContainer/CardPanel/ContentVBox/GooglePickerView/CustomEmailRow/ConnectBtn
@onready var picker_back_btn: Button = $CenterContainer/CardPanel/ContentVBox/GooglePickerView/PickerBackBtn
@onready var status_lbl: Label = $CenterContainer/CardPanel/StatusLabel

var is_authenticating: bool = false

func _ready() -> void:
	visible = false
	if close_btn: close_btn.pressed.connect(close)
	if google_btn: google_btn.pressed.connect(_on_google_pressed)
	if guest_btn: guest_btn.pressed.connect(_on_guest_pressed)
	if picker_back_btn: picker_back_btn.pressed.connect(_show_select_view)
	if custom_connect_btn: custom_connect_btn.pressed.connect(_on_custom_connect_pressed)
	if custom_email_input: custom_email_input.text_submitted.connect(func(_t): _on_custom_connect_pressed())
	
	ProfileManager.google_login_finished.connect(_on_login_finished)
	_setup_styles()

func open() -> void:
	visible = true
	modulate.a = 0.0
	is_authenticating = false
	if status_lbl: status_lbl.text = ""
	_show_select_view()
	
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	visible = false

func _setup_styles() -> void:
	if google_btn:
		google_btn.icon = IconFactory.get_icon("google", 1.0)
		google_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if guest_btn:
		guest_btn.icon = IconFactory.get_icon("guest_user", 1.0)
		guest_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if picker_back_btn:
		picker_back_btn.icon = IconFactory.get_icon("arrow_left", 0.8)
		picker_back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _show_select_view() -> void:
	if select_view: select_view.visible = true
	if google_picker_view: google_picker_view.visible = false
	if status_lbl: status_lbl.text = ""

func _on_google_pressed() -> void:
	SoundManager.play("click")
	if select_view: select_view.visible = false
	if google_picker_view: google_picker_view.visible = true
	_populate_google_accounts()

func _on_guest_pressed() -> void:
	SoundManager.play("click")
	ProfileManager.auth_provider = "guest"
	auth_completed.emit("guest")
	close()

func _populate_google_accounts() -> void:
	if not accounts_container:
		return
		
	for child in accounts_container.get_children():
		child.queue_free()
		
	# Detect OS user or saved email to suggest accounts
	var user_name := OS.get_environment("USERNAME")
	if user_name.is_empty():
		user_name = "Player"
	
	var suggested_emails: Array[Dictionary] = []
	
	if not ProfileManager.email.is_empty():
		suggested_emails.append({
			"email": ProfileManager.email,
			"name": ProfileManager.username
		})
	else:
		var default_email = user_name.to_lower().replace(" ", "") + "@gmail.com"
		suggested_emails.append({
			"email": default_email,
			"name": user_name
		})
		
	for acc in suggested_emails:
		_create_account_card(acc["name"], acc["email"])

func _create_account_card(acc_name: String, acc_email: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 48)
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Glass stylebox
	var sb_norm := StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.10, 0.14, 0.22, 0.9)
	sb_norm.border_color = Color(0.25, 0.38, 0.55, 0.6)
	sb_norm.set_border_width_all(1)
	sb_norm.set_corner_radius_all(12)
	sb_norm.content_margin_left = 14.0
	sb_norm.content_margin_right = 14.0
	
	var sb_hov := sb_norm.duplicate() as StyleBoxFlat
	sb_hov.bg_color = Color(0.16, 0.22, 0.34, 0.95)
	sb_hov.border_color = Color(0.38, 0.74, 0.97, 0.9)
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_hov)
	
	var hbox := HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	btn.add_child(hbox)
	
	var icon_rect := TextureRect.new()
	icon_rect.texture = IconFactory.get_icon("google", 0.9)
	icon_rect.custom_minimum_size = Vector2(28, 28)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_rect)
	
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
	email_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.88, 0.8))
	vbox.add_child(email_lbl)
	
	hbox.add_child(vbox)
	
	btn.pressed.connect(func():
		_start_google_login(acc_email, acc_name)
	)
	
	accounts_container.add_child(btn)

func _on_custom_connect_pressed() -> void:
	if not custom_email_input:
		return
	var mail := custom_email_input.text.strip_edges()
	if mail.is_empty():
		_set_status("Email manzilini kiriting!", true)
		return
	if not mail.contains("@"):
		mail += "@gmail.com"
	var name_part := mail.split("@")[0].capitalize()
	_start_google_login(mail, name_part)

func _start_google_login(email_addr: String, display_name: String) -> void:
	if is_authenticating:
		return
	is_authenticating = true
	SoundManager.play("click")
	_set_status("Google hisobiga ulanmoqda...", false)
	ProfileManager.login_with_google(email_addr, display_name)

func _on_login_finished(success: bool, err_msg: String) -> void:
	is_authenticating = false
	if success:
		_set_status("Muvaffaqiyatli ulandi!", false)
		SoundManager.play("win")
		auth_completed.emit("google")
		await get_tree().create_timer(0.6).timeout
		close()
	else:
		_set_status(err_msg if not err_msg.is_empty() else "Ulanishda xatolik yuz berdi", true)

func _set_status(text: String, is_err: bool) -> void:
	if status_lbl:
		status_lbl.text = text
		status_lbl.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35) if is_err else Color(0.38, 0.85, 0.55))
