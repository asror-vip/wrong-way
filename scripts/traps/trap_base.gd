extends Node2D
class_name TrapBase

# Wrong Way — Universal Trap Base Class
# Enforces the standard lifecycle (IDLE -> ARMED -> ACTIVE -> RESET)
# Decouples audio/visual feedback from state logic.

enum State {
	IDLE,
	ARMED,
	ACTIVE,
	RESET
}

signal trap_state_changed(new_state: State)

@export var config: TrapConfig = null
@export var trap_id: String = "trap_base"

var current_state: State = State.IDLE
var arm_timer: float = 0.0

func _ready() -> void:
	add_to_group("traps")
	_setup_trap()

func _setup_trap() -> void:
	# Subclasses initialize shapes or initial positions
	pass

func trigger_trap() -> void:
	if current_state != State.IDLE:
		return
	
	current_state = State.ARMED
	trap_state_changed.emit(current_state)
	
	var delay = config.trigger_delay if config else 0.04
	arm_timer = delay
	_on_trap_armed()

func activate_trap() -> void:
	current_state = State.ACTIVE
	trap_state_changed.emit(current_state)
	_on_trap_activated()

func reset_trap() -> void:
	current_state = State.IDLE
	arm_timer = 0.0
	trap_state_changed.emit(current_state)
	_on_trap_reset()

func _process(delta: float) -> void:
	if current_state == State.ARMED:
		arm_timer -= delta
		_on_arm_tick(delta)
		if arm_timer <= 0.0:
			activate_trap()
	elif current_state == State.ACTIVE:
		_on_active_tick(delta)

# Virtual lifecycle hooks for concrete traps to override:
func _on_trap_armed() -> void:
	pass

func _on_arm_tick(_delta: float) -> void:
	pass

func _on_trap_activated() -> void:
	pass

func _on_active_tick(_delta: float) -> void:
	pass

func _on_trap_reset() -> void:
	pass
