extends Resource
class_name PlayerConfig

# Wrong Way — Player Physics & Control Configuration
# Defines all movement, jump, and timing constants to eliminate magic numbers.

@export_group("Movement")
@export var speed: float = 330.0
@export var acceleration: float = 2600.0
@export var friction: float = 2800.0
@export var gravity: float = 1450.0

@export_group("Jumping")
@export var jump_velocity: float = -570.0
@export var min_jump_velocity: float = -280.0
@export var coyote_time: float = 0.16
@export var jump_buffer_time: float = 0.16

@export_group("Lifecycle")
@export var respawn_delay: float = 0.35
@export var death_plane_y: float = 750.0

@export_group("Visuals")
@export var body_color: Color = Color(0.12, 0.11, 0.15, 1.0)
@export var arrow_color: Color = Color(1.0, 0.32, 0.32, 1.0) # Wrong Way signature red/coral glow
@export var eye_color: Color = Color(0.96, 0.95, 0.98, 1.0)
