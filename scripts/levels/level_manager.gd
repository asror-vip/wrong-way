extends RefCounted
class_name LevelManager

# Wrong Way — Level Manager
# Utility class for querying and resolving level scenes.

const TOTAL_LEVELS: int = 20


static func get_level_path(level_num: int) -> String:
	var path_padded = "res://scenes/levels/level_%02d.tscn" % level_num
	var path_normal = "res://scenes/levels/level_%d.tscn" % level_num
	if ResourceLoader.exists(path_padded):
		return path_padded
	elif ResourceLoader.exists(path_normal):
		return path_normal
	return "res://scenes/levels/level_01.tscn"

static func load_level(tree: SceneTree, level_num: int) -> void:
	var path = get_level_path(level_num)
	tree.change_scene_to_file(path)

