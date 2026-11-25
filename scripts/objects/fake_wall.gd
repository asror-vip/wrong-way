extends Node2D
class_name FakeWall

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")

# Level Devil / Wrong Way Trick: Fake Wall (Aldovchi Devor)
# Looks completely solid, but the player can walk straight through it
# to find a secret path or escape an impossible forward trap!

@export var wall_size: Vector2 = Vector2(32, 540)
@export var subtle_crack: bool = false
@export var fade_when_inside: bool = true

var _wisp_time: float = 0.0
var _wisp_redraw_accum: float = 0.0
var _cached_chapter: int = 1
var _cached_main_pts: PackedVector2Array = PackedVector2Array()
var _cached_hi_pts: PackedVector2Array = PackedVector2Array()
var _cached_branches: Array[PackedVector2Array] = []
var _cached_branches_hi: Array[PackedVector2Array] = []
var _cached_center_pt: Vector2 = Vector2.ZERO
var _fracture_cached_size: Vector2 = Vector2(-1.0, -1.0)

func _ready() -> void:
	z_index = 2
	_refresh_chapter()
	if subtle_crack:
		_rebuild_fracture_cache()
	queue_redraw()

func _refresh_chapter() -> void:
	_cached_chapter = 1
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_current_chapter"):
		_cached_chapter = int(gm.get_current_chapter())

func _process(delta: float) -> void:
	if subtle_crack:
		_wisp_time += delta
		_wisp_redraw_accum += delta
		# Gentle 20Hz update for the subtle floating dust mote avoids needless 60fps redraw churn on mobile
		if _wisp_redraw_accum >= 0.05:
			_wisp_redraw_accum = 0.0
			queue_redraw()
	if not fade_when_inside or not is_inside_tree():
		return
	var target_a := 1.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player) and not ("is_dead" in player and player.is_dead):
		var px := player.global_position.x
		var py := player.global_position.y - 16.0
		var r := Rect2(global_position - Vector2(8.0, 8.0), wall_size + Vector2(16.0, 16.0))
		if r.has_point(Vector2(px, py)):
			target_a = 0.24
	modulate.a = lerpf(modulate.a, target_a, minf(1.0, delta * 12.0))

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	_cached_chapter = ch
	var is_floor_slab := wall_size.x > wall_size.y and wall_size.y <= 36.0
	# SolidPlatform bilan 100% bir xil biom sirt chizilishi (Ch 1-5 mukammal kamuflyaj!)
	TrapBiomeArt.draw_platform_surface(self, 0.0, wall_size.x, wall_size.y, ch, not is_floor_slab)

	if subtle_crack:
		if _fracture_cached_size != wall_size:
			_rebuild_fracture_cache()
		_draw_realistic_fracture(ch)

func _rebuild_fracture_cache() -> void:
	_fracture_cached_size = wall_size
	var w := wall_size.x
	var h := wall_size.y
	_cached_branches.clear()
	_cached_branches_hi.clear()

	if w > h * 1.2:
		# Horizontal slab crack (e.g. Level 17 FakeHole 55x26)
		var y_mid := h * 0.48
		_cached_main_pts = PackedVector2Array([
			Vector2(w * 0.14, h * 0.15),
			Vector2(w * 0.34, y_mid - 2.0),
			Vector2(w * 0.52, y_mid + 3.5),
			Vector2(w * 0.72, y_mid - 1.5),
			Vector2(w * 0.88, h * 0.82),
		])
		_cached_branches.append(PackedVector2Array([_cached_main_pts[1], Vector2(w * 0.28, h * 0.88)]))
		_cached_branches.append(PackedVector2Array([_cached_main_pts[2], Vector2(w * 0.58, h * 0.12)]))
		_cached_branches.append(PackedVector2Array([_cached_main_pts[3], Vector2(w * 0.84, h * 0.25)]))
	else:
		# Vertical stone wall fracture (e.g. Level 10, 12, 14)
		var cx := w * 0.5
		var amp := minf(w * 0.24, 14.0)
		_cached_main_pts = PackedVector2Array([
			Vector2(cx - amp * 0.35, h * 0.12),
			Vector2(cx + amp * 0.45, h * 0.28),
			Vector2(cx - amp * 0.20, h * 0.44),
			Vector2(cx + amp * 0.55, h * 0.60),
			Vector2(cx - amp * 0.40, h * 0.76),
			Vector2(cx + amp * 0.15, h * 0.88),
		])
		_cached_branches.append(PackedVector2Array([
			_cached_main_pts[1],
			_cached_main_pts[1] + Vector2(amp * 0.75, h * 0.06),
			_cached_main_pts[1] + Vector2(amp * 1.05, h * 0.11),
		]))
		_cached_branches.append(PackedVector2Array([
			_cached_main_pts[2],
			_cached_main_pts[2] + Vector2(-amp * 0.85, h * 0.05),
			_cached_main_pts[2] + Vector2(-amp * 1.10, h * 0.10),
		]))
		_cached_branches.append(PackedVector2Array([
			_cached_main_pts[3],
			_cached_main_pts[3] + Vector2(amp * 0.70, -h * 0.04),
		]))
		_cached_branches.append(PackedVector2Array([
			_cached_main_pts[4],
			_cached_main_pts[4] + Vector2(-amp * 0.65, h * 0.06),
		]))

	_cached_hi_pts = PackedVector2Array()
	for pt in _cached_main_pts:
		_cached_hi_pts.append(pt + Vector2(1.1, 0.8))
	for br in _cached_branches:
		var br_hi := PackedVector2Array()
		for pt in br:
			br_hi.append(pt + Vector2(0.8, 0.6))
		_cached_branches_hi.append(br_hi)
	_cached_center_pt = _cached_main_pts[_cached_main_pts.size() / 2]

func _draw_realistic_fracture(ch: int) -> void:
	var groove_col := Color(0.015, 0.015, 0.025, 0.72)
	var edge_hi := Color(0.84, 0.90, 1.0, 0.22)
	if ch == 4:
		edge_hi = Color(1.0, 0.86, 0.62, 0.22)
	elif ch == 5:
		edge_hi = Color(1.0, 0.52, 0.44, 0.24)

	# Recessed carved dark fracture groove + pale chipped bevel edge (zero per-frame allocations)
	draw_polyline(_cached_hi_pts, edge_hi, 1.0, true)
	draw_polyline(_cached_main_pts, groove_col, 2.3, true)
	draw_polyline(_cached_main_pts, Color(edge_hi.r, edge_hi.g, edge_hi.b, edge_hi.a * 0.65), 0.9, true)

	for i in range(_cached_branches.size()):
		draw_polyline(_cached_branches_hi[i], Color(edge_hi.r, edge_hi.g, edge_hi.b, edge_hi.a * 0.7), 0.8, true)
		draw_polyline(_cached_branches[i], groove_col, 1.4, true)

	# Tiny settled stone chips + faint breathing draft mote hinting the wall is hollow
	draw_circle(_cached_center_pt + Vector2(-2.5, 3.0), 1.1, groove_col)
	draw_circle(_cached_center_pt + Vector2(3.0, -2.0), 0.9, edge_hi)
	var mote_phase := fmod(_wisp_time * 0.45, 1.0)
	var mote_a := sin(mote_phase * PI) * 0.20
	var mote_pos := _cached_center_pt + Vector2(sin(_wisp_time * 1.8) * 4.0, -mote_phase * 14.0)
	draw_circle(mote_pos, 1.3, Color(edge_hi.r, edge_hi.g, edge_hi.b, mote_a))
