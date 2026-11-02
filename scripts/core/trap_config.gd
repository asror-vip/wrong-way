extends Resource
class_name TrapConfig

# Wrong Way — Universal Trap Configuration Resource
# Parameterizes trap behavior without hardcoding magic numbers in scripts.

@export var trap_id: String = "generic_trap"
@export var trigger_delay: float = 0.04
@export var cooldown: float = 0.0
@export var speed: float = 3500.0
@export var damage: int = 1
@export var editor_category: String = "Hazards"
@export var editor_icon: String = "res://icon.svg"
