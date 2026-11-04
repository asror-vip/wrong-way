extends Control

# Wrong Way - High-End Commercial Splash & Loading Screen
# - Atmospheric Ken Burns background camera drift
# - Volumetric vignette & glow-pulsing logo
# - Animated loading progress bar with cycling hints
# - On 100% load: displays Google & Guest sign-in options directly on screen
# - Seamless crossfade into Main Menu

@onready var bg_texture: TextureRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var logo_container: VBoxContainer = $CenterBox
@onready var bottom_box: VBoxContainer = $BottomBox
@onready var progress_bar: ProgressBar = $BottomBox/ProgressBar
@onready var status_label: Label = $BottomBox/StatusLabel
@onready var version_label: Label = $BottomBox/VersionLabel

@onready var auth_box: VBoxContainer = $AuthBox
@onready var auth_title: Label = $AuthBox/AuthTitle
@onready var google_btn: Button = $AuthBox/GoogleBtn
@onready var guest_btn: Button = $AuthBox/GuestBtn
@onready var auth_hint: Label = $AuthBox/AuthHint
@onready var auth_modal: Control = $AuthModal

@onready var curtain: ColorRect = $Curtain

var load_progress: float = 0.0
var target_progress: float = 0.0
var is_transitioning: bool = false
var has_logged_in_google: bool = false

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

	_setup_auth_buttons()
	_update_hint(0)
	_start_background_drift()
	_run_loading_flow()

func _setup_auth_buttons() -> void:
	if google_btn:
		google_btn.icon = IconFactory.get_icon("google", 1.0)
		google_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		google_btn.pressed.connect(_on_google_pressed)

	if guest_btn:
		guest_btn.icon = IconFactory.get_icon("guest_user", 1.0)
		guest_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		guest_btn.pressed.connect(_on_guest_pressed)

	if auth_modal:
		auth_modal.auth_completed.connect(_on_auth_completed)

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
	# Loading barni silliq yashirib, AuthBox ni ko'rsatamiz
	var tween := create_tween()
	if bottom_box:
		tween.tween_property(bottom_box, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func(): bottom_box.visible = false)

	# Foydalanuvchida avvaldan Google hisobi ulanganmi?
	has_logged_in_google = (ProfileManager.auth_provider == "google" and not ProfileManager.email.is_empty())
	
	if has_logged_in_google:
		if auth_title:
			auth_title.text = "Xush kelibsiz, " + ProfileManager.username + "!"
		if google_btn:
			google_btn.text = "   " + ProfileManager.email + " bilan kirish"
		if guest_btn:
			guest_btn.text = "   Boshqa hisob tanlash"
		if auth_hint:
			auth_hint.text = "Profil yutuqlaringiz bulut bilan sinxronlangan"
	else:
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

func _on_google_pressed() -> void:
	SoundManager.play("click")
	if has_logged_in_google:
		# Allaqachon ulangan hisob bilan to'g'ridan-to'g'ri o'yinga kirish
		_finish_and_open_main_menu()
	else:
		# Google Account Chooser oynasini ochish (Gmaillar ro'yxati va tanlash)
		if auth_modal:
			auth_modal.open(true)

func _on_guest_pressed() -> void:
	SoundManager.play("click")
	if has_logged_in_google:
		# Boshqa hisob tanlash rejimida Google Account Pickerni ochamiz
		if auth_modal:
			auth_modal.open(true)
	else:
		# Mehmon sifatida davom etish
		ProfileManager.auth_provider = "guest"
		_finish_and_open_main_menu()

func _on_auth_completed(_provider: String) -> void:
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
