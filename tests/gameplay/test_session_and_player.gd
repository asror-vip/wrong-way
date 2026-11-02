extends SceneTree

# Wrong Way — Core Gameplay Automated Test Suite
# Tests GameSession, LevelData, and PlayerConfig contracts.

func _init() -> void:
	print("--- Running Wrong Way Core Tests ---")
	
	# Test 1: PlayerConfig instantiation
	var config = PlayerConfig.new()
	assert(config.speed > 0.0, "PlayerConfig speed must be positive")
	assert(config.jump_velocity < 0.0, "PlayerConfig jump_velocity must be negative")
	print("✔ Test 1 Passed: PlayerConfig verified")
	
	# Test 2: LevelData
	var level_data = LevelData.new()
	level_data.level_id = "test_zone"
	level_data.level_version = 1
	assert(level_data.level_id == "test_zone", "LevelData level_id assignment failed")
	print("✔ Test 2 Passed: LevelData verified")
	
	# Test 3: GameSession Lifecycle
	var session = GameSession.new()
	session.start_attempt(level_data)
	assert(session.is_active == true, "Session should be active")
	assert(session.deaths == 0, "Initial deaths must be 0")
	
	session.register_death()
	assert(session.deaths == 1, "Deaths must increment to 1")
	
	# Wait a small slice for time calculation
	var elapsed = session.get_elapsed_ms()
	assert(elapsed >= 0, "Elapsed time should be non-negative")
	
	var result = session.complete_attempt()
	assert(session.is_active == false, "Session should not be active after complete")
	assert(session.is_completed == true, "Session should be marked completed")
	assert(result.has("time_ms"), "Result must contain time_ms")
	assert(result.has("deaths"), "Result must contain deaths")
	print("✔ Test 3 Passed: GameSession lifecycle and verified results output")
	
	# Test 4: TrapConfig
	var trap_cfg = TrapConfig.new()
	assert(trap_cfg.speed > 0.0, "TrapConfig speed must be positive")
	print("✔ Test 4 Passed: TrapConfig verified")
	
	print("--- All Core Architecture Tests Passed Successfully! ---")
	quit(0)
