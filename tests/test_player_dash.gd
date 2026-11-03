extends SceneTree

func _init():
	print("========================================")
	print("TESTING GENSHIN IMPACT STYLE DASH BURST")
	print("========================================")
	
	var player_scene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate()
	root.add_child(player)
	
	assert(player.DASH_SPEED > player.SPEED, "Dash speed must be significantly faster than normal speed")
	print("Player normal speed: ", player.SPEED, " | Dash speed: ", player.DASH_SPEED)
	print("Dash duration: ", player.DASH_DURATION, "s | Cooldown: ", player.DASH_COOLDOWN, "s")
	
	# 1. Simulating initial standing still: facing right (1)
	player.facing = 1
	player.dash_cooldown_timer = 0.0
	player.is_dashing = false
	
	# Simulate action just pressed:
	Input.action_press("dash")
	
	# Simulate physics process
	player._physics_process(0.016)
	
	print("Is dashing after press: ", player.is_dashing)
	print("Player velocity.x during dash: ", player.velocity.x)
	assert(player.is_dashing == true, "Player should be dashing after Shift press")
	assert(abs(player.velocity.x - player.DASH_SPEED) < 0.1, "Velocity should equal DASH_SPEED")
	
	# 2. Advance time past dash duration while HOLDING dash down
	# In Godot, holding the action keeps action_press active, so is_action_just_pressed is FALSE!
	for i in range(15): # 15 * 0.016 = 0.24s > 0.16s
		player._physics_process(0.016)
	
	print("Is dashing after duration elapsed (with key held): ", player.is_dashing)
	print("Player velocity.x after dash expired: ", player.velocity.x)
	assert(player.is_dashing == false, "Dash MUST expire and not continue even if held!")
	assert(player.velocity.x == 0.0 or abs(player.velocity.x) <= player.SPEED, "Speed must return to normal, not dash speed!")
	
	# Release action
	Input.action_release("dash")
	
	print("\nALL DASH TESTS PASSED SUCCESSFULLY!")
	print("========================================")
	quit(0)

