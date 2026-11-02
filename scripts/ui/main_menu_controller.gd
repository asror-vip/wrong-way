extends Control

# Wrong Way — Main Menu Controller
# Handles menu navigation, Play transition to Level 1, and clean UI audio.

@onready var play_btn: Button = $VBox/PlayButton
@onready var quit_btn: Button = $VBox/QuitButton

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	_play_click()
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")

func _on_quit_pressed() -> void:
	_play_click()
	get_tree().quit()

func _play_click() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_click"):
		sm.play_click()
