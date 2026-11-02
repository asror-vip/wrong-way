extends Node

# Wrong Way — Global Game Application Controller (GameApp)
# Responsible for application lifecycle, global settings, scene transitions, and system orchestration.
# NEVER accumulates gameplay logic directly.

const LevelSystemScript = preload("res://scripts/systems/level_system.gd")

var level_system: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_system = LevelSystemScript.new()
	add_child(level_system)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			var tree = get_tree()
			if tree and tree.current_scene:
				if tree.current_scene.has_method("restart_attempt"):
					tree.current_scene.restart_attempt()
				else:
					tree.reload_current_scene()
		elif event.keycode == KEY_F11:
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
