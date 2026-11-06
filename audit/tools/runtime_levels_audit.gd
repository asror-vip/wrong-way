extends SceneTree

func _init() -> void:
	print("--- STARTING 60 LEVELS RUNTIME VALIDATION ---")
	var results := []
	var total_levels := 60
	var passed_levels := 0
	var failed_levels := 0
	
	for lvl in range(1, total_levels + 1):
		var path := "res://scenes/levels/level_%02d.tscn" % lvl
		if not ResourceLoader.exists(path):
			print("[FAIL] Level %02d: Scene file missing at %s" % [lvl, path])
			results.append({"level": lvl, "status": "MISSING_FILE", "error": "File does not exist"})
			failed_levels += 1
			continue
			
		var scene_res = load(path)
		if scene_res == null:
			print("[FAIL] Level %02d: Failed to load PackedScene" % lvl)
			results.append({"level": lvl, "status": "LOAD_ERROR", "error": "load() returned null"})
			failed_levels += 1
			continue
			
		var root: Node = scene_res.instantiate()
		if root == null:
			print("[FAIL] Level %02d: Failed to instantiate scene" % lvl)
			results.append({"level": lvl, "status": "INSTANTIATE_ERROR", "error": "instantiate() returned null"})
			failed_levels += 1
			continue
			
		# Add to root to trigger _ready() and node lifecycle
		root_node_add(root)
		
		# Inspect components
		var player = root.get_node_or_null("Player")
		var exit_door = root.get_node_or_null("ExitDoor")
		var traps_container = root.get_node_or_null("Traps")
		var platforms_container = root.get_node_or_null("SolidPlatforms")
		var backdrop = root.get_node_or_null("AtmosphericBackdrop")
		
		var level_info := {
			"level": lvl,
			"path": path,
			"root_class": root.get_class(),
			"has_player": player != null,
			"player_pos": str(player.position) if player else "N/A",
			"has_exit": exit_door != null,
			"exit_pos": str(exit_door.position) if exit_door else "N/A",
			"has_traps": traps_container != null,
			"trap_count": traps_container.get_child_count() if traps_container else 0,
			"has_platforms": platforms_container != null,
			"platform_count": platforms_container.get_child_count() if platforms_container else 0,
			"has_backdrop": backdrop != null,
			"status": "PASS"
		}
		
		var issues := []
		if player == null:
			issues.append("Missing Player node")
		if exit_door == null:
			issues.append("Missing ExitDoor node")
		if platforms_container == null and root.get_node_or_null("Platforms") == null:
			issues.append("Missing SolidPlatforms container")
			
		if issues.size() > 0:
			level_info["status"] = "FAIL"
			level_info["issues"] = issues
			failed_levels += 1
			print("[WARN] Level %02d: Issues found: %s" % [lvl, ", ".join(issues)])
		else:
			passed_levels += 1
			print("[PASS] Level %02d: Instantiated OK | Player: %s | Exit: %s | Traps: %d | Platforms: %d" % [
				lvl, level_info["player_pos"], level_info["exit_pos"], level_info["trap_count"], level_info["platform_count"]
			])
			
		results.append(level_info)
		root.queue_free()
		
	print("--- AUDIT SUMMARY: %d PASSED, %d FAILED / %d TOTAL ---" % [passed_levels, failed_levels, total_levels])
	
	# Save results to json
	var f := FileAccess.open("res://audit/levels_runtime_verification.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"total_levels": total_levels,
			"passed_levels": passed_levels,
			"failed_levels": failed_levels,
			"levels": results
		}, "\t"))
		f.close()
		print("Saved verification to audit/levels_runtime_verification.json")
		
	quit(0)

func root_node_add(node: Node) -> void:
	root.add_child(node)

