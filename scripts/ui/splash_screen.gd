extends Control

# Wrong Way - High-End Commercial Splash & Loading Screen
# - Atmospheric Ken Burns background camera drift
# - Volumetric vignette & glow-pulsing logo
# - Animated loading progress bar with cycling hints
# - On 100% load:
#     * Returning/Authenticated player: Prominent "BOSHLASH" (START) prompt with player greeting
#     * New/First-time player: Clear Google & Guest choice
# - Seamless crossfade into Main Menu

@onready var bg_texture: TextureRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var logo_container: VBoxContainer = $CenterBox
@onready var bottom_box: VBoxContainer = $BottomBox
@onready var progress_bar: ProgressBar = $BottomBox/ProgressBar
@onready var status_label: Label = $BottomBox/StatusLabel
@onready var version_label: Label = $BottomBox/VersionLabel

@onready var auth_box: VBoxContainer = get_node_or_null("AuthBox")
@onready var auth_title: Label = get_node_or_null("AuthBox/AuthTitle")
@onready var google_btn: Button = get_node_or_null("AuthBox/GoogleBtn")
@onready var guest_btn: Button = get_node_or_null("AuthBox/GuestBtn")
@onready var auth_hint: Label = get_node_or_null("AuthBox/AuthHint")

@onready var start_box: VBoxContainer = get_node_or_null("StartBox")
@onready var greeting_label: Label = get_node_or_null("StartBox/GreetingLabel")
@onready var start_btn: Button = get_node_or_null("StartBox/StartBtn")
@onready var switch_account_btn: Button = get_node_or_null("StartBox/SwitchAccountBtn")

@onready var auth_modal: Control = get_node_or_null("AuthModal")
@onready var curtain: ColorRect = $Curtain

var load_progress: float = 0.0
var target_progress: float = 0.0
var is_transitioning: bool = false
var pulse_tween: Tween

const HINTS := [
	"Sozlamalar va saqlangan o'yinlar tekshirilmoqda...",
	"Tuzoqlarning barcha mexanizmlari yashirilmoqda...",
	"Hech qachon pol va eshiklarga ko'r-ko'rona ishonmang...",
	"Supabase global serveriga ulanmoqda...",
	"Hamma narsa tayyor. Qorong'u olamga xush kelibsiz!"
]

func _ready() -> void:
	if curtain:
		curtain.modulate.a = 1.0
		var fade_in := create_tween()
		fade_in.tween_property(curtain, "modulate:a", 0.0, 0.45)

	if progress_bar:
		progress_bar.value = 0.0

	if auth_box:
		auth_box.visible = false
		auth_box.modulate.a = 0.0

	if start_box:
		start_box.visible = false
		start_box.modulate.a = 0.0

	_setup_buttons()
	_update_hint(0)
	_start_background_drift()
	_run_loading_flow()

func _unhandled_input(event: InputEvent) -> void:
	if start_box and start_box.visible and not is_transitioning:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_on_start_pressed()
				get_viewport().set_input_as_handled()

func _setup_buttons() -> void:
	if google_btn:
		google_btn.icon = IconFactory.get_icon("google", 1.0)
		google_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		google_btn.pressed.connect(_on_google_pressed)

	if guest_btn:
		guest_btn.icon = IconFactory.get_icon("guest_user", 1.0)
		guest_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		guest_btn.pressed.connect(_on_guest_pressed)

	if start_btn:
		start_btn.icon = IconFactory.get_icon("play_dark", 1.0)
		start_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		start_btn.pressed.connect(_on_start_pressed)

	if switch_account_btn:
		switch_account_btn.pressed.connect(_on_switch_account_pressed)

	GoogleAuthService.auth_succeeded.connect(func(_u):
		ProfileManager.has_chosen_auth = true
		ProfileManager.save_profile()
		if greeting_label:
			greeting_label.text = "Xush kelibsiz, " + ProfileManager.username + "!"
		await get_tree().create_timer(0.3).timeout
		_finish_and_open_main_menu()
	)
	GoogleAuthService.auth_failed.connect(func(err):
		print("SplashScreen: Google kirish xatosi: ", err)
	)

func _start_background_drift() -> void:
	if not bg_texture:
		return
	bg_texture.pivot_offset = Vector2(480, 270)
	var tween := create_tween().set_loops()
	tween.tween_property(bg_texture, "scale", Vector2(1.04, 1.04), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(bg_texture, "scale", Vector2(1.0, 1.0), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _update_hint(idx: int) -> void:
	if status_label and idx < HINTS.size():
		var tween := create_tween()
		tween.tween_property(status_label, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func():
			status_label.text = HINTS[idx]
		)
		tween.tween_property(status_label, "modulate:a", 1.0, 0.18)

func _run_loading_flow() -> void:
	# 1-bosqich: Baza va o'yin holati
	target_progress = 25.0
	await get_tree().create_timer(0.35).timeout
	_update_hint(1)

	# 2-bosqich: Tuzoqlar va darajalar
	target_progress = 60.0
	await get_tree().create_timer(0.40).timeout
	_update_hint(2)

	# 3-bosqich: Server
	target_progress = 85.0
	await get_tree().create_timer(0.35).timeout
	_update_hint(3)

	# 4-bosqich: Tayyor
	target_progress = 100.0
	await get_tree().create_timer(0.30).timeout
	_update_hint(4)
	await get_tree().create_timer(0.25).timeout

	_show_auth_selection()

func _process(delta: float) -> void:
	if load_progress < target_progress:
		load_progress = move_toward(load_progress, target_progress, delta * 120.0)
		if progress_bar:
			progress_bar.value = load_progress

func _show_auth_selection() -> void:
	# Loading barni silliq yashiramiz
	var tween := create_tween()
	if bottom_box:
		tween.tween_property(bottom_box, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func(): bottom_box.visible = false)

	# Foydalanuvchi allaqachon hisob tanlaganmi / tizimga kirganmi?
	var is_established: bool = ProfileManager.has_chosen_auth or (ProfileManager.auth_provider == "google" and not ProfileManager.email.is_empty()) or (not ProfileManager.player_id.is_empty() and ProfileManager.username != "Player")

	if is_established:
		# Avvaldan kirgan o'yinchiga qayta Google/Guest chiqmaydi, uning o'rniga "BOSHLASH" chiqadi!
		if greeting_label:
			greeting_label.text = "Xush kelibsiz, " + ProfileManager.username + "!"
		if start_box:
			start_box.visible = true
			start_box.modulate.a = 0.0
			tween.tween_property(start_box, "modulate:a", 1.0, 0.3)
			_pulse_start_button(start_btn)
	else:
		# Birinchi marta yangi o'yinchiga kirish usuli taklif etiladi
		if auth_title:
			auth_title.text = "O'yinga kirish usulini tanlang:"
		if google_btn:
			google_btn.text = "   Google orqali kirish"
		if guest_btn:
			guest_btn.text = "   Mehmon sifatida davom etish"
		if auth_hint:
			auth_hint.text = "Hisob bilan yutuqlaringiz bulutda saqlanadi"

		if auth_box:
			auth_box.visible = true
			auth_box.modulate.a = 0.0
			tween.tween_property(auth_box, "modulate:a", 1.0, 0.3)

func _pulse_start_button(btn: Button) -> void:
	if not btn:
		return
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	btn.pivot_offset = btn.size / 2.0
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(btn, "scale", Vector2(1.025, 1.025), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start_pressed() -> void:
	SoundManager.play("click")
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	_finish_and_open_main_menu()

func _on_switch_account_pressed() -> void:
	SoundManager.play("click")
	GoogleAuthService.start_google_sign_in()

func _on_google_pressed() -> void:
	SoundManager.play("click")
	GoogleAuthService.start_google_sign_in()

func _on_guest_pressed() -> void:
	SoundManager.play("click")
	ProfileManager.auth_provider = "guest"
	ProfileManager.has_chosen_auth = true
	ProfileManager.save_profile()
	_finish_and_open_main_menu()

func _on_auth_completed(_provider: String) -> void:
	ProfileManager.has_chosen_auth = true
	ProfileManager.save_profile()
	if greeting_label:
		greeting_label.text = "Xush kelibsiz, " + ProfileManager.username + "!"
	await get_tree().create_timer(0.3).timeout
	_finish_and_open_main_menu()

func _finish_and_open_main_menu() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if curtain:
		var fade_out := create_tween()
		fade_out.tween_property(curtain, "modulate:a", 1.0, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await fade_out.finished

	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
