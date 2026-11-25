extends Node2D

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")

# Wrong Way - Trap Floor Visual Renderer
# Ensures falling trap floors render with 100% fidelity to the current chapter biome.

func _draw() -> void:
	var target = get_parent()
	var w: float = 140.0
	var h: float = 160.0
	if target and "platform_size" in target:
		w = target.platform_size.x
		h = target.platform_size.y

	var ch := TrapBiomeArt.get_chapter(self)
	# SolidPlatform bilan 100% bir xil sirt chizilishi (idle holatda mukammal kamuflyaj)
	TrapBiomeArt.draw_platform_surface(self, 0.0, w, h, ch, false)

	# Kutilmagan yoriqlar (bosilganda tez tarqaladi)
	if target and "crack_progress" in target and target.crack_progress > 0.05:
		TrapBiomeArt.draw_fracture_cracks(self, w, h, float(target.crack_progress), ch)
