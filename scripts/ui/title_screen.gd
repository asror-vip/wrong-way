extends Control

# Wrong Way — Initial Entry Screen
# Simple, clean startup screen featuring START and QUIT.

@onready var start_btn: Button = $VBox/StartButton
@onready var quit_btn: Button = $VBox/QuitButton

func _ready() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_banner"):
		adm.show_banner()
	start_btn.pressed.connect(_on_start_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	_play_click()
	get_tree().change_scene_to_file("res://scenes/menu/home_menu.tscn")

func _on_quit_pressed() -> void:
	_play_click()
	get_tree().quit()

func _play_click() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_click"):
		sm.play_click()
