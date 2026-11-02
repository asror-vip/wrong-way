extends Control

func _ready() -> void:
	var gameplay_scene = load("res://scenes/game/gameplay.tscn")
	var gp = gameplay_scene.instantiate()
	add_child(gp)
	
	# Test Level 5
	GameManager.current_level_id = 5
	gp._load_level(5)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	var img5_start := get_viewport().get_texture().get_image()
	img5_start.save_png("C:/Users/asror/.gemini/antigravity/brain/e8e16c92-b1ce-4557-9005-b70c46ad996a/level_05_ceiling_disguised.png")
	print("Saved level_05_ceiling_disguised.png")
	
	# Trigger the slam by moving player forward
	var arena = gp.level_holder.get_child(0)
	var player = arena.player
	player.global_position.x = 480.0
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	
	var img5_slammed := get_viewport().get_texture().get_image()
	img5_slammed.save_png("C:/Users/asror/.gemini/antigravity/brain/e8e16c92-b1ce-4557-9005-b70c46ad996a/level_05_ceiling_slammed.png")
	print("Saved level_05_ceiling_slammed.png")
	
	# Test Level 4
	GameManager.current_level_id = 4
	gp._load_level(4)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	var img4_start := get_viewport().get_texture().get_image()
	img4_start.save_png("C:/Users/asror/.gemini/antigravity/brain/e8e16c92-b1ce-4557-9005-b70c46ad996a/level_04_runaway_start.png")
	print("Saved level_04_runaway_start.png")
	
	# Approach the door in Level 4
	arena = gp.level_holder.get_child(0)
	player = arena.player
	player.global_position.x = 720.0
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	
	var img4_ran := get_viewport().get_texture().get_image()
	img4_ran.save_png("C:/Users/asror/.gemini/antigravity/brain/e8e16c92-b1ce-4557-9005-b70c46ad996a/level_04_runaway_escaped.png")
	print("Saved level_04_runaway_escaped.png")
	
	get_tree().quit(0)

