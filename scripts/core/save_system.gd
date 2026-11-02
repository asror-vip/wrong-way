extends Node

# Wrong Way — Persistent Save System
# Stores unlocked levels, stars earned (0-3), best times, and overall best record in user://save_data.json

signal progress_updated

const SAVE_PATH: String = "user://save_data.json"

var unlocked_levels: Array = [1]
var ad_unlocked_levels: Array = []
var attempted_levels: Array = []
var level_stars: Dictionary = {} # level_num (int/string) -> stars (int)
var level_best_times: Dictionary = {} # level_num -> time_ms (int)
var overall_best_time_ms: int = 999999999
var overall_best_text: String = "Mavjud emas"

# Navigation context (transient in-memory state)
var navigation_source: String = "home_menu" # "home_menu" or "result_modal"
var return_level_num: int = 1
var should_restore_result_modal: bool = false
var pending_result_data: Dictionary = {}

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		unlocked_levels = [1]
		level_stars = {}
		level_best_times = {}
		overall_best_text = "Mavjud emas"
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.new()
		var err = json.parse(text)
		if err == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			unlocked_levels = data.get("unlocked_levels", [1])
			var has_lvl_1 = false
			for lvl in unlocked_levels:
				if int(lvl) == 1:
					has_lvl_1 = true
					break
			if not has_lvl_1:
				unlocked_levels.append(1)
			ad_unlocked_levels = data.get("ad_unlocked_levels", [])
			attempted_levels = data.get("attempted_levels", [])
			level_stars = data.get("level_stars", {})
			level_best_times = data.get("level_best_times", {})
			overall_best_text = data.get("overall_best_text", "Mavjud emas")
			overall_best_time_ms = data.get("overall_best_time_ms", 999999999)

func save_progress() -> void:
	var data: Dictionary = {
		"unlocked_levels": unlocked_levels,
		"ad_unlocked_levels": ad_unlocked_levels,
		"attempted_levels": attempted_levels,
		"level_stars": level_stars,
		"level_best_times": level_best_times,
		"overall_best_text": overall_best_text,
		"overall_best_time_ms": overall_best_time_ms
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func record_level_result(level_num: int, time_ms: int, deaths: int) -> int:
	# Calculate stars:
	# 3 Stars: 0 deaths
	# 2 Stars: 1-2 deaths
	# 1 Star: 3+ deaths
	var stars: int = 1
	if deaths == 0:
		stars = 3
	elif deaths <= 2:
		stars = 2
	else:
		stars = 1
	
	var key = str(level_num)
	var prev_stars: int = int(level_stars.get(key, 0))
	if stars > prev_stars:
		level_stars[key] = stars
	
	var prev_time = level_best_times.get(key, 999999999)
	if time_ms < prev_time:
		level_best_times[key] = time_ms
	
	# Overall best update
	if time_ms < overall_best_time_ms:
		overall_best_time_ms = time_ms
		var sec = float(time_ms) / 1000.0
		overall_best_text = "%0.2f soniya (%d-lvl)" % [sec, level_num]
	
	# Unlock next level if got at least 2 stars
	if stars >= 2:
		var next_lvl = level_num + 1
		if not unlocked_levels.has(next_lvl):
			unlocked_levels.append(next_lvl)
	
	save_progress()
	progress_updated.emit()
	return stars

func is_level_unlocked(level_num: int) -> bool:
	if level_num == 1:
		return true
	for lvl in unlocked_levels:
		if int(lvl) == level_num:
			return true
	return false

func record_level_attempt(level_num: int) -> void:
	if not attempted_levels.has(level_num):
		attempted_levels.append(level_num)
		save_progress()

func is_level_ad_unlockable(level_num: int) -> bool:
	if level_num <= 1:
		return false
	if is_level_unlocked(level_num):
		return false
	var prev_lvl = level_num - 1
	# Eligible if player attempted or played the previous level, but current level is still locked
	if attempted_levels.has(prev_lvl) or get_level_stars(prev_lvl) > 0:
		return true
	return false

func unlock_level_via_ad(level_num: int) -> void:
	if not unlocked_levels.has(level_num):
		unlocked_levels.append(level_num)
	if not ad_unlocked_levels.has(level_num):
		ad_unlocked_levels.append(level_num)
	save_progress()
	progress_updated.emit()

func get_level_stars(level_num: int) -> int:
	return int(level_stars.get(str(level_num), 0))

func get_overall_best_text() -> String:
	return overall_best_text

func get_total_stars() -> int:
	var total: int = 0
	for k in level_stars.keys():
		total += int(level_stars[k])
	return total

func get_unlocked_count() -> int:
	return unlocked_levels.size()
