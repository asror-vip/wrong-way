extends Control
class_name ControlCustomizer

signal closed
signal layout_saved

@onready var backdrop: ColorRect = get_node_or_null("Backdrop")
@onready var top_bar: Control = get_node_or_null("TopBar")
@onready var drag_left: Control = $DragLeft
@onready var drag_right: Control = $DragRight
@onready var drag_jump: Control = $DragJump
@onready var drag_dash: Control = get_node_or_null("DragDash")

@onready var reset_btn: Button = $TopBar/BtnBox/ResetBtn
@onready var save_btn: Button = $TopBar/BtnBox/SaveBtn
@onready var close_btn: Button = $TopBar/BtnBox/CloseBtn
@onready var title_lbl: Label = $TopBar/TitleBox/TitleLbl
@onready var subtitle_lbl: Label = $TopBar/TitleBox/SubtitleLbl

const BASE_SZ_LR := Vector2(82.0, 82.0)
const BASE_SZ_DASH := Vector2(78.0, 78.0)
const BASE_SZ_JUMP := Vector2(88.0, 88.0)

var current_scale: float = 1.0
var size_slider: HSlider = null
var size_val_lbl: Label = null
var size_title_lbl: Label = null
var level_preview: Control = null
var _preview_bg_tex: Texture2D = null

var dragging_node: Control = null
var drag_touch_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg_path := "res://assets/images/chapter_1/twilight_mist_01.png"
	if ResourceLoader.exists(bg_path):
		_preview_bg_tex = load(bg_path)

	_setup_level_preview()
	_setup_size_slider()

	_setup_drag_widget(drag_left, "circle_btn_left", BASE_SZ_LR)
	_setup_drag_widget(drag_right, "circle_btn_right", BASE_SZ_LR)
	_setup_drag_widget(drag_jump, "circle_btn_jump", BASE_SZ_JUMP)
	if not drag_dash:
		var dd := Control.new()
		dd.name = "DragDash"
		dd.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dd)
		drag_dash = dd
	_setup_drag_widget(drag_dash, "circle_btn_dash", BASE_SZ_DASH)

	if reset_btn: reset_btn.pressed.connect(_on_reset_pressed)
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if close_btn: close_btn.pressed.connect(_on_close_pressed)

func _setup_level_preview() -> void:
	if backdrop:
		backdrop.color = Color(0.02, 0.03, 0.05, 0.18)

	level_preview = Control.new()
	level_preview.name = "LevelPreview"
	level_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(level_preview)
	move_child(level_preview, 0)
	level_preview.draw.connect(_on_level_preview_draw)

func _on_level_preview_draw() -> void:
	if not level_preview:
		return
	var cur_scene := get_tree().current_scene
	if cur_scene and cur_scene.name == "Gameplay":
		return

	var vp := get_viewport_rect().size
	var ox := (vp.x - 960.0) * 0.5
	var oy := (vp.y - 540.0) * 0.5

	# 1. Orqa fon (1-bob tumanli o'rmon)
	if _preview_bg_tex:
		level_preview.draw_texture_rect(
			_preview_bg_tex,
			Rect2(0, 0, vp.x, vp.y),
			false,
			Color(0.78, 0.82, 0.90, 1.0)
		)
	else:
		level_preview.draw_rect(Rect2(0, 0, vp.x, vp.y), Color("#121722"), true)

	var sil_col := Color("#0a0a0d")
	var line_col := Color(1.0, 1.0, 1.0, 0.55)

	# 2. Shift va tishlar (Ceiling)
	level_preview.draw_rect(Rect2(0, 0, vp.x, oy + 70.0), sil_col, true)
	var x_tooth := ox
	while x_tooth < ox + 960.0:
		var pts := PackedVector2Array([
			Vector2(x_tooth, oy + 70.0),
			Vector2(x_tooth + 14.0, oy + 70.0),
			Vector2(x_tooth + 7.0, oy + 82.0)
		])
		level_preview.draw_colored_polygon(pts, sil_col)
		x_tooth += 32.0

	# 3. Pol platformalari (1-daraja ko'rinishi)
	var plats := [
		Rect2(0, oy + 380.0, ox + 320.0, vp.y - (oy + 380.0)),
		Rect2(ox + 400.0, oy + 380.0, 180.0, vp.y - (oy + 380.0)),
		Rect2(ox + 680.0, oy + 380.0, vp.x - (ox + 680.0), vp.y - (oy + 380.0))
	]
	for pr in plats:
		level_preview.draw_rect(pr, sil_col, true)
		level_preview.draw_line(
			Vector2(pr.position.x, pr.position.y),
			Vector2(pr.position.x + pr.size.x, pr.position.y),
			line_col,
			1.5
		)

	# 4. Tikanlar (Spikes)
	for s_idx in range(3):
		var sx := ox + 200.0 + float(s_idx) * 16.0
		var sy := oy + 380.0
		var sp_pts := PackedVector2Array([
			Vector2(sx, sy),
			Vector2(sx + 16.0, sy),
			Vector2(sx + 8.0, sy - 28.0)
		])
		level_preview.draw_colored_polygon(sp_pts, sil_col)

	# 5. Chiqish eshigi (ExitDoor)
	var dx := ox + 860.0
	var dy := oy + 380.0
	level_preview.draw_rect(Rect2(dx - 22.0, dy - 58.0, 44.0, 58.0), Color.WHITE, true)
	level_preview.draw_rect(Rect2(dx - 17.0, dy - 52.5, 34.0, 52.5), Color.BLACK, true)

	# 6. Qahramon (Player)
	var px := ox + 90.0
	var py := oy + 380.0
	var p_rect := Rect2(px - 14.0, py - 32.0, 28.0, 32.0)
	level_preview.draw_rect(p_rect, Color("#1c1a20"), true)
	level_preview.draw_rect(p_rect, Color("#342f3a"), false, 1.5)
	level_preview.draw_circle(Vector2(px - 5.0, py - 17.0), 4.0, Color.WHITE)
	level_preview.draw_circle(Vector2(px + 6.0, py - 17.0), 4.0, Color.WHITE)
	level_preview.draw_circle(Vector2(px - 3.5, py - 17.0), 1.8, Color("#111014"))
	level_preview.draw_circle(Vector2(px + 7.5, py - 17.0), 1.8, Color("#111014"))

func _setup_size_slider() -> void:
	if not top_bar:
		return
	var box := HBoxContainer.new()
	box.name = "SizeBox"
	box.anchors_preset = Control.PRESET_CENTER
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -130.0
	box.offset_right = 110.0
	box.offset_top = -16.0
	box.offset_bottom = 16.0
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(box)

	size_title_lbl = Label.new()
	size_title_lbl.text = "Hajmi:"
	size_title_lbl.add_theme_font_size_override("font_size", 12)
	size_title_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	box.add_child(size_title_lbl)

	size_slider = HSlider.new()
	size_slider.custom_minimum_size = Vector2(120, 24)
	size_slider.min_value = 65.0
	size_slider.max_value = 145.0
	size_slider.step = 5.0
	size_slider.value = 100.0
	size_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(size_slider)

	size_val_lbl = Label.new()
	size_val_lbl.custom_minimum_size = Vector2(42, 0)
	size_val_lbl.text = "100%"
	size_val_lbl.add_theme_font_size_override("font_size", 12)
	size_val_lbl.add_theme_color_override("font_color", Color(0.38, 0.82, 1.0))
	box.add_child(size_val_lbl)

	size_slider.value_changed.connect(_on_size_slider_changed)

func _on_size_slider_changed(val: float) -> void:
	current_scale = clampf(val / 100.0, 0.65, 1.45)
	if size_val_lbl:
		size_val_lbl.text = "%d%%" % int(round(current_scale * 100.0))
	_apply_scale_to_widgets(true)

func _apply_scale_to_widgets(keep_center: bool) -> void:
	_resize_widget(drag_left, BASE_SZ_LR * current_scale, keep_center)
	_resize_widget(drag_right, BASE_SZ_LR * current_scale, keep_center)
	_resize_widget(drag_dash, BASE_SZ_DASH * current_scale, keep_center)
	_resize_widget(drag_jump, BASE_SZ_JUMP * current_scale, keep_center)

func _resize_widget(node: Control, new_sz: Vector2, keep_center: bool) -> void:
	if not node:
		return
	var old_center := node.position + node.size * 0.5
	node.custom_minimum_size = new_sz
	node.size = new_sz
	if keep_center:
		var vp := get_viewport_rect().size
		var np := old_center - new_sz * 0.5
		var max_x := maxf(10.0, vp.x - new_sz.x - 10.0)
		var max_y := maxf(64.0, vp.y - new_sz.y - 10.0)
		node.position = Vector2(clampf(np.x, 10.0, max_x), clampf(np.y, 64.0, max_y))
	node.queue_redraw()

func _get_default_positions() -> Dictionary:
	return UIResponsive.get_default_touch_positions(self)

func _load_current_positions() -> void:
	current_scale = SaveManager.touch_button_scale
	if size_slider:
		size_slider.set_value_no_signal(round(current_scale * 100.0))
	if size_val_lbl:
		size_val_lbl.text = "%d%%" % int(round(current_scale * 100.0))
	_apply_scale_to_widgets(false)

	var defs := _get_default_positions()
	if drag_left: drag_left.position = SaveManager.get_touch_pos("left", defs["left"])
	if drag_right: drag_right.position = SaveManager.get_touch_pos("right", defs["right"])
	if drag_jump: drag_jump.position = SaveManager.get_touch_pos("jump", defs["jump"])
	if drag_dash: drag_dash.position = SaveManager.get_touch_pos("dash", defs["dash"])

func _update_texts() -> void:
	if title_lbl:
		title_lbl.text = LocaleManager.t("controls_customizer_title")
	if subtitle_lbl:
		subtitle_lbl.text = LocaleManager.t("controls_customizer_hint")
	if reset_btn:
		reset_btn.text = "  " + LocaleManager.t("btn_reset_default")
		reset_btn.icon = IconFactory.get_icon("restart", 0.75)
	if save_btn:
		save_btn.text = "  " + LocaleManager.t("btn_save")
		save_btn.icon = IconFactory.get_icon("check", 0.75)
	if size_title_lbl:
		var lang := LocaleManager.current_language
		if lang == "ru":
			size_title_lbl.text = "Размер:"
		elif lang == "en":
			size_title_lbl.text = "Size:"
		elif lang == "tr":
			size_title_lbl.text = "Boyut:"
		else:
			size_title_lbl.text = "Hajmi:"

func _setup_drag_widget(node: Control, icon_name: String, sz: Vector2) -> void:
	if not node:
		return
	node.custom_minimum_size = sz
	node.size = sz
	node.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon_rect := TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.texture = IconFactory.get_icon(icon_name, 1.3)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.add_child(icon_rect)

	node.gui_input.connect(func(event: InputEvent):
		var is_press := false
		var is_release := false
		var is_drag := false
		var local_pos := Vector2.ZERO
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				is_press = mb.pressed
				is_release = not mb.pressed
				local_pos = mb.position
		elif event is InputEventMouseMotion:
			if dragging_node == node:
				is_drag = true
				local_pos = (event as InputEventMouseMotion).position
		elif event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			is_press = st.pressed
			is_release = not st.pressed
			local_pos = st.position
		elif event is InputEventScreenDrag:
			if dragging_node == node:
				is_drag = true
				local_pos = (event as InputEventScreenDrag).position

		if is_press:
			dragging_node = node
			drag_touch_offset = local_pos
			node.queue_redraw()
		elif is_release and dragging_node == node:
			dragging_node = null
			node.queue_redraw()
		elif is_drag:
			var new_pos := node.position + local_pos - drag_touch_offset
			var vp := get_viewport_rect().size
			var max_x := maxf(10.0, vp.x - node.size.x - 10.0)
			var max_y := maxf(64.0, vp.y - node.size.y - 10.0)
			node.position = Vector2(
				clampf(new_pos.x, 10.0, max_x),
				clampf(new_pos.y, 64.0, max_y)
			)
	)

	node.draw.connect(func():
		var is_act := (dragging_node == node)
		var c := Color(0.3, 0.8, 1.0, 0.95) if is_act else Color(0.5, 0.65, 0.9, 0.5)
		var r := Rect2(Vector2.ZERO, node.size)
		node.draw_rect(r, Color(0.1, 0.2, 0.4, 0.25 if is_act else 0.0), true)
		node.draw_rect(r, c, false, 1.5 if is_act else 1.0)
	)

func _set_pause_backdrop_hidden(hidden: bool) -> void:
	var p := get_parent()
	while p != null:
		if p is PauseModal:
			var p_card = p.get_node_or_null("Card")
			var p_bg = p.get_node_or_null("Backdrop")
			if p_card: p_card.visible = not hidden
			if p_bg: p_bg.visible = not hidden
			break
		p = p.get_parent()

func open() -> void:
	_set_pause_backdrop_hidden(true)
	_load_current_positions()
	_update_texts()
	visible = true
	if level_preview:
		level_preview.queue_redraw()
	SoundManager.play("click")

func close() -> void:
	_set_pause_backdrop_hidden(false)
	visible = false
	closed.emit()

func _on_reset_pressed() -> void:
	SoundManager.play("click")
	current_scale = 1.0
	if size_slider:
		size_slider.set_value_no_signal(100.0)
	if size_val_lbl:
		size_val_lbl.text = "100%"
	_apply_scale_to_widgets(false)
	SaveManager.reset_touch_layout()
	var defs := _get_default_positions()
	if drag_left: drag_left.position = defs["left"]
	if drag_right: drag_right.position = defs["right"]
	if drag_jump: drag_jump.position = defs["jump"]
	if drag_dash: drag_dash.position = defs["dash"]

func _on_save_pressed() -> void:
	SoundManager.play("click")
	SaveManager.set_touch_scale(current_scale)
	if drag_left: SaveManager.set_touch_pos("left", drag_left.position)
	if drag_right: SaveManager.set_touch_pos("right", drag_right.position)
	if drag_jump: SaveManager.set_touch_pos("jump", drag_jump.position)
	if drag_dash: SaveManager.set_touch_pos("dash", drag_dash.position)
	layout_saved.emit()
	close()

func _on_close_pressed() -> void:
	SoundManager.play("click")
	close()
