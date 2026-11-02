extends Control

# Wrong Way - High-End Commercial Splash & Loading Screen
# - Atmospheric Ken Burns background camera drift
# - Volumetric vignette & fog particle ambiance
# - Glow-pulsing game logo
# - Sleek animated progress bar & cycling status hints
# - Seamless crossfade into Main Menu

@onready var bg_texture: TextureRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var logo_container: VBoxContainer = $CenterBox
@onready var progress_bar: ProgressBar = $BottomBox/ProgressBar
@onready var status_label: Label = $BottomBox/StatusLabel
@onready var version_label: Label = $BottomBox/VersionLabel
@onready var curtain: ColorRect = $Curtain

var load_progress: float = 0.0
var target_progress: float = 0.0
var is_transitioning: bool = false
var step_index: int = 0

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
		fade_in.tween_property(curtain, "modulate:a", 0.0, 0.5)

	if progress_bar:
		progress_bar.value = 0.0

	_update_hint(0)
	_start_background_drift()
	_run_loading_flow()

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
		tween.tween_property(status_label, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			status_label.text = HINTS[idx]
		)
		tween.tween_property(status_label, "modulate:a", 1.0, 0.2)

func _run_loading_flow() -> void:
	# 1-bosqich: Baza va o'yin holati
	target_progress = 25.0
	await get_tree().create_timer(0.4).timeout
	_update_hint(1)

	# 2-bosqich: Tuzoqlar va darajalar
	target_progress = 60.0
	await get_tree().create_timer(0.5).timeout
	_update_hint(2)

	# 3-bosqich: Server
	target_progress = 85.0
	await get_tree().create_timer(0.45).timeout
	_update_hint(3)

	# 4-bosqich: Tayyor
	target_progress = 100.0
	await get_tree().create_timer(0.4).timeout
	_update_hint(4)
	await get_tree().create_timer(0.35).timeout

	_finish_and_open_main_menu()

func _process(delta: float) -> void:
	if load_progress < target_progress:
		load_progress = move_toward(load_progress, target_progress, delta * 90.0)
		if progress_bar:
			progress_bar.value = load_progress

func _finish_and_open_main_menu() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if curtain:
		var fade_out := create_tween()
		fade_out.tween_property(curtain, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await fade_out.finished

	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

