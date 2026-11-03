extends SceneTree

func _init() -> void:
	var root_vp := root
	root_vp.size = Vector2i(960, 540)
	
	var scene: PackedScene = load("res://scenes/levels/level_06.tscn")
	var inst: Node2D = scene.instantiate()
	root_vp.add_child(inst)
	
	# Wait a couple frames
	for i in range(5):
		await process_frame
	
	var img: Image = root_vp.get_texture().get_image()
	var save_path := "user://level_06_verify.png"
	img.save_png(save_path)
	print("SAVED_SCREENSHOT:", ProjectSettings.globalize_path(save_path))
	quit(0)

