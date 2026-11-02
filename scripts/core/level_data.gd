extends Resource
class_name LevelData

# Wrong Way — Level Data Resource
# Stores isolated level metadata, versioning, author info, and target goals.

@export var level_id: String = "zone_01"
@export var level_name: String = "First Mistake"
@export var level_version: int = 1
@export var author: String = "Wrong Way Team"
@export var par_time_ms: int = 3500 # 3.50 seconds benchmark
@export var target_deaths: int = 0
@export var checksum: String = ""
@export var scene_path: String = "res://scenes/levels/level_1.tscn"
