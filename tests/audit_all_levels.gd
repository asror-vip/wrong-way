extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("========================================")
	print("AUDITING ALL LEVELS (1 to 20)")
	print("========================================")
	
	for lvl in range(1, 21):
		var path := "res://scenes/levels/level_%02d.tscn" % lvl
		if not ResourceLoader.exists(path):
			print("Level %02d: FILE NOT FOUND!" % lvl)
			continue
			
		var res := load(path) as PackedScene
		if not res:
			print("Level %02d: FAILED TO LOAD RESOURCE!" % lvl)
			continue
			
		var inst := res.instantiate() as Node2D
		if not inst:
			print("Level %02d: FAILED TO INSTANTIATE!" % lvl)
			continue
			
		var player = inst.get_node_or_null("Player")
		var door = inst.get_node_or_null("ExitDoor")
		var platforms_node = inst.get_node_or_null("Platforms")
		var traps_node = inst.get_node_or_null("Traps")
		
		var p_pos = player.position if player else Vector2.ZERO
		var d_pos = door.position if door else Vector2.ZERO
		
		var trap_info := []
		if traps_node:
			for t in traps_node.get_children():
				var t_type = t.name
				var t_pos = t.position
				var extra = ""
				if t is Crusher:
					extra = "trigger_dist=%.1f, state=%d" % [t.trigger_distance, t.current_state]
				elif t is TrapFloor:
					extra = "shake_timer=%.2fs" % [t.shake_timer]
				trap_info.append("%s@%s(%s)" % [t_type, str(t_pos), extra])
				
		var plat_info := []
		if platforms_node:
			for p in platforms_node.get_children():
				var sz = p.platform_size if "platform_size" in p else Vector2.ZERO
				plat_info.append("%s: pos=%s sz=%s" % [p.name, str(p.position), str(sz)])
				
		print("\n--- LEVEL %02d ---" % lvl)
		print("Player: %s | Door: %s" % [str(p_pos), str(d_pos)])
		print("Platforms (%d): %s" % [plat_info.size(), ", ".join(plat_info)])
		print("Traps (%d): %s" % [trap_info.size(), ", ".join(trap_info)])
		
		inst.queue_free()
		
	print("\n========================================")
	print("AUDIT COMPLETE")
	print("========================================")
	quit()

