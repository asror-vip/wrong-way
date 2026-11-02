extends Node

const SAVE_DIR := "user://custom_levels/"
const MAX_SLOTS := 5
const GRID_SIZE := 32

func _ready() -> void:
	ensure_directory()

func ensure_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func get_slot_path(slot: int) -> String:
	return SAVE_DIR + "custom_level_%d.json" % slot

func save_custom_level(slot: int, data: Dictionary) -> bool:
	ensure_directory()
	var file_path := get_slot_path(slot)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("CustomLevelManager: Fayl ochib bo'lmadi: " + file_path)
		return false
	
	var json_string := JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true

func load_custom_level(slot: int) -> Dictionary:
	var file_path := get_slot_path(slot)
	if not FileAccess.file_exists(file_path):
		return get_default_level()
		
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return get_default_level()
		
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK or not (json.data is Dictionary):
		push_warning("CustomLevelManager: JSON o'qishda xatolik, standart daraja yuklanadi")
		return get_default_level()
		
	return json.data as Dictionary

func get_default_level() -> Dictionary:
	var default_elements: Array = []
	
	# Chap devor (gx = 0, gy = 3..12)
	for gy in range(3, 13):
		default_elements.append({"type": "platform", "gx": 0, "gy": gy, "x": 0, "y": gy * 32})
	
	# O'ng devor (gx = 29, gy = 3..12)
	for gy in range(3, 13):
		default_elements.append({"type": "platform", "gx": 29, "gy": gy, "x": 29 * 32, "y": gy * 32})
		
	# Chap pol (gx = 1..10, gy = 12)
	for gx in range(1, 11):
		default_elements.append({"type": "platform", "gx": gx, "gy": 12, "x": gx * 32, "y": 12 * 32})
		
	# O'rta tuzoq pol (gx = 11..14, gy = 12)
	for gx in range(11, 15):
		default_elements.append({"type": "trap_floor", "gx": gx, "gy": 12, "x": gx * 32, "y": 12 * 32})
		
	# O'ng pol (gx = 15..28, gy = 12)
	for gx in range(15, 29):
		default_elements.append({"type": "platform", "gx": gx, "gy": 12, "x": gx * 32, "y": 12 * 32})
		
	# Boshlang'ich tikanlar (gx = 19..20, gy = 11) - pol ustida
	default_elements.append({"type": "spikes", "gx": 19, "gy": 11, "x": 19 * 32, "y": 11 * 32})
	default_elements.append({"type": "spikes", "gx": 20, "gy": 11, "x": 20 * 32, "y": 11 * 32})

	return {
		"name": "Mening Zonam",
		"player_spawn": [144, 384],
		"exit_door": [848, 384],
		"elements": default_elements
	}
