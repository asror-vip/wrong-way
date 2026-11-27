extends Control
class_name ControlCustomizer

signal closed
signal layout_saved

@onready var backdrop: ColorRect = get_node_or_null("Backdrop")
@onready var top_bar: Panel = get_node_or_null("TopBar")
@onready var top_margin: MarginContainer = get_node_or_null("TopBar/TopMargin")
@onready var title_box: Control = get_node_or_null("TopBar/TopMargin/TopRow/TitleBox")
@onready var size_box: Control = get_node_or_null("TopBar/TopMargin/TopRow/SizeBox")
@onready var btn_box: Control = get_node_or_null("TopBar/TopMargin/TopRow/BtnBox")

@onready var drag_left: Control = $DragLeft
@onready var drag_right: Control = $DragRight
@onready var drag_jump: Control = $DragJump
@onready var drag_dash: Control = get_node_or_null("DragDash")

@onready var reset_btn: Button = get_node_or_null("TopBar/TopMargin/TopRow/BtnBox/ResetBtn")
@onready var save_btn: Button = get_node_or_null("TopBar/TopMargin/TopRow/BtnBox/SaveBtn")
@onready var close_btn: Button = get_node_or_null("TopBar/TopMargin/TopRow/BtnBox/CloseBtn")
@onready var title_lbl: Label = get_node_or_null("TopBar/TopMargin/TopRow/TitleBox/TitleLbl")
@onready var subtitle_lbl: Label = get_node_or_null("TopBar/TopMargin/TopRow/TitleBox/SubtitleLbl")
@onready var size_title_lbl: Label = get_node_or_null("TopBar/TopMargin/TopRow/SizeBox/SizeTitleLbl")
@onready var size_slider: HSlider = get_node_or_null("TopBar/TopMargin/TopRow/SizeBox/SizeSlider")
@onready var size_val_lbl: Label = get_node_or_null("TopBar/TopMargin/TopRow/SizeBox/SizeValLbl")

const BASE_SZ_LR := Vector2(82.0, 82.0)
const BASE_SZ_DASH := Vector2(78.0, 78.0)
const BASE_SZ_JUMP := Vector2(88.0, 88.0)
const ALIGN_SNAP_PX := 6.0

var current_scale: float = 1.0
var level_preview: Control = null
var guide_overlay: Control = null
var _preview_bg_tex: Texture2D = null

# Global pointer/finger tracking state (zero jitter, zero fast-drag drop-off)
var dragging_node: Control = null
var _drag_finger_index: int = -1
var _drag_is_mouse: bool = false
var _drag_grab_offset: Vector2 = Vector2.ZERO
var _pending_reset: bool = false
var _dirty_after_reset: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg_path := "res://assets/images/chapter_1/twilight_mist_01.png"
	if ResourceLoader.exists(bg_path):
		_preview_bg_tex = load(bg_path)

	_setup_level_preview()
	_setup_guide_overlay()

	if size_slider:
		size_slider.add_theme_icon_override("grabber", IconFactory.get_icon("slider_grabber", 1.0))
		size_slider.add_theme_icon_override("grabber_highlight", IconFactory.get_icon("slider_grabber_hover", 1.0))
		size_slider.value_changed.connect(_on_size_slider_changed)

	_setup_drag_widget(drag_left, "circle_btn_left", BASE_SZ_LR)
	_setup_drag_widget(drag_right, "circle_btn_right", BASE_SZ_LR)
	_setup_drag_widget(drag_jump, "circle_btn_jump", BASE_SZ_JUMP)
	if not drag_dash:
		var dd := Control.new()
		dd.name = "DragDash"
		add_child(dd)
		drag_dash = dd
	_setup_drag_widget(drag_dash, "circle_btn_dash", BASE_SZ_DASH)

	if reset_btn: reset_btn.pressed.connect(_on_reset_pressed)
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if close_btn: close_btn.pressed.connect(_on_close_pressed)

	if LocaleManager and not LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.connect(_on_language_changed)
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)

	_apply_safe_topbar_layout()
	_update_texts()

func _exit_tree() -> void:
	if LocaleManager and LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.disconnect(_on_language_changed)
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.disconnect(_on_viewport_resized)

func _on_language_changed(_lang: String) -> void:
	_update_texts()

func _on_viewport_resized() -> void:
	_apply_safe_topbar_layout()
	if visible:
		_clamp_all_widgets()
		if level_preview: level_preview.queue_redraw()
		if guide_overlay: guide_overlay.queue_redraw()

func _apply_safe_topbar_layout() -> void:
	var insets := UIResponsive.get_safe_insets(self)
	var top_inset: float = float(insets.get("top", 0.0))
	var left_inset: float = float(insets.get("left", 0.0))
	var right_inset: float = float(insets.get("right", 0.0))
	if top_bar:
		top_bar.offset_top = 0.0
		top_bar.offset_bottom = 56.0 + top_inset
	if top_margin:
		top_margin.add_theme_constant_override("margin_left", int(round(16.0 + left_inset)))
		top_margin.add_theme_constant_override("margin_right", int(round(16.0 + right_inset)))
		top_margin.add_theme_constant_override("margin_top", int(round(6.0 + top_inset)))
		top_margin.add_theme_constant_override("margin_bottom", 6)

func _get_drag_widgets() -> Array[Control]:
	var res: Array[Control] = []
	for w in [drag_left, drag_right, drag_dash, drag_jump]:
		if w != null:
			res.append(w)
	return res

func _get_safe_bounds(node_sz: Vector2) -> Rect2:
	var vp := UIResponsive.get_viewport_size(self)
	var insets := UIResponsive.get_safe_insets(self)
	var min_x: float = maxf(10.0, float(insets.get("left", 0.0)) + 8.0)
	var right_pad: float = maxf(10.0, float(insets.get("right", 0.0)) + 8.0)
	var max_x: float = maxf(min_x, vp.x - node_sz.x - right_pad)
	var top_bar_bottom: float = (top_bar.position.y + top_bar.size.y) if (top_bar and top_bar.size.y > 0.0) else (56.0 + float(insets.get("top", 0.0)))
	var min_y: float = maxf(64.0, top_bar_bottom + 8.0)
	var bot_pad: float = maxf(10.0, float(insets.get("bottom", 0.0)) + 8.0)
	var max_y: float = maxf(min_y, vp.y - node_sz.y - bot_pad)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func _clamp_widget_pos(node: Control, pos: Vector2) -> Vector2:
	var b := _get_safe_bounds(node.size)
	return Vector2(
		clampf(pos.x, b.position.x, b.position.x + b.size.x),
		clampf(pos.y, b.position.y, b.position.y + b.size.y)
	)

func _clamp_all_widgets() -> void:
	for w in _get_drag_widgets():
		w.position = _clamp_widget_pos(w, w.position)
		w.queue_redraw()

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

func _setup_guide_overlay() -> void:
	guide_overlay = Control.new()
	guide_overlay.name = "GuideOverlay"
	guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guide_overlay)
	# Place right after Backdrop so guides render behind buttons & TopBar
	move_child(guide_overlay, 2)
	guide_overlay.draw.connect(_on_guide_overlay_draw)

func _on_guide_overlay_draw() -> void:
	if not guide_overlay or dragging_node == null:
		return
	var vp := UIResponsive.get_viewport_size(self)
	var top_y: float = (top_bar.position.y + top_bar.size.y) if top_bar else 56.0
	var dc := dragging_node.position + dragging_node.size * 0.5

	# Subtle crosshair through dragged button center
	var soft_col := Color(0.38, 0.80, 1.0, 0.20)
	guide_overlay.draw_line(Vector2(0.0, dc.y), Vector2(vp.x, dc.y), soft_col, 1.0)
	guide_overlay.draw_line(Vector2(dc.x, top_y), Vector2(dc.x, vp.y), soft_col, 1.0)

	# Bright cyan snap highlight when aligned horizontally or vertically with another button
	var snap_col := Color(0.22, 0.86, 1.0, 0.72)
	for other in _get_drag_widgets():
		if other == dragging_node:
			continue
		var oc := other.position + other.size * 0.5
		if absf(dc.y - oc.y) <= ALIGN_SNAP_PX:
			guide_overlay.draw_line(Vector2(minf(dc.x, oc.x) - 36.0, oc.y), Vector2(maxf(dc.x, oc.x) + 36.0, oc.y), snap_col, 1.8)
		if absf(dc.x - oc.x) <= ALIGN_SNAP_PX:
			guide_overlay.draw_line(Vector2(oc.x, minf(dc.y, oc.y) - 36.0), Vector2(oc.x, maxf(dc.y, oc.y) + 36.0), snap_col, 1.8)

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

func _on_size_slider_changed(val: float) -> void:
	current_scale = clampf(val / 100.0, 0.65, 1.45)
	_dirty_after_reset = true
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
		var np := old_center - new_sz * 0.5
		node.position = _clamp_widget_pos(node, np)
	node.queue_redraw()

func _get_default_positions(scale_override: float = -1.0) -> Dictionary:
	return UIResponsive.get_default_touch_positions(self, scale_override)

func _load_current_positions() -> void:
	_pending_reset = false
	_dirty_after_reset = false
	_clear_drag_state()
	current_scale = SaveManager.touch_button_scale
	if size_slider:
		size_slider.set_value_no_signal(round(current_scale * 100.0))
	if size_val_lbl:
		size_val_lbl.text = "%d%%" % int(round(current_scale * 100.0))
	_apply_scale_to_widgets(false)

	var defs := _get_default_positions(current_scale)
	if drag_left: drag_left.position = _clamp_widget_pos(drag_left, SaveManager.get_touch_pos("left", defs["left"]))
	if drag_right: drag_right.position = _clamp_widget_pos(drag_right, SaveManager.get_touch_pos("right", defs["right"]))
	if drag_jump: drag_jump.position = _clamp_widget_pos(drag_jump, SaveManager.get_touch_pos("jump", defs["jump"]))
	if drag_dash: drag_dash.position = _clamp_widget_pos(drag_dash, SaveManager.get_touch_pos("dash", defs["dash"]))

func _update_texts() -> void:
	if title_lbl:
		title_lbl.text = LocaleManager.t("controls_customizer_title")
	if subtitle_lbl:
		subtitle_lbl.text = LocaleManager.t("controls_customizer_hint")
	if reset_btn:
		reset_btn.text = " " + LocaleManager.t("btn_reset_default")
		reset_btn.icon = IconFactory.get_icon("restart", 0.72)
	if save_btn:
		save_btn.text = " " + LocaleManager.t("btn_save")
		save_btn.icon = IconFactory.get_icon("check", 0.72)
	if size_title_lbl:
		size_title_lbl.text = LocaleManager.t("customizer_size")

func _setup_drag_widget(node: Control, icon_name: String, sz: Vector2) -> void:
	if not node:
		return
	node.custom_minimum_size = sz
	node.size = sz
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_rect := TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.texture = IconFactory.get_icon(icon_name, 1.3)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.add_child(icon_rect)

	node.draw.connect(func():
		var is_act := (dragging_node == node)
		var center := node.size * 0.5
		var radius := minf(node.size.x, node.size.y) * 0.5
		if is_act:
			# Soft cyan active halo + crisp ring
			node.draw_circle(center, radius + 6.0, Color(0.22, 0.74, 0.97, 0.22))
			node.draw_arc(center, radius + 2.0, 0.0, TAU, 40, Color(0.35, 0.88, 1.0, 0.95), 2.2, true)
		else:
			node.draw_arc(center, radius + 1.0, 0.0, TAU, 36, Color(0.60, 0.75, 0.95, 0.35), 1.2, true)
	)

func _to_local_canvas(screen_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_pos

func _is_over_top_bar(local_pos: Vector2) -> bool:
	if not top_bar:
		return false
	return Rect2(top_bar.position, top_bar.size).has_point(local_pos)

func _pick_widget_at(local_pos: Vector2) -> Control:
	if _is_over_top_bar(local_pos):
		return null
	var widgets := _get_drag_widgets()
	widgets.sort_custom(func(a: Control, b: Control) -> bool: return a.get_index() < b.get_index())
	# Check visually top-most drawn widget first
	for i in range(widgets.size() - 1, -1, -1):
		var w := widgets[i]
		if Rect2(w.position, w.size).grow(8.0).has_point(local_pos):
			return w
	return null

func _begin_drag(w: Control, local_pos: Vector2, finger_idx: int, is_mouse: bool) -> void:
	dragging_node = w
	_drag_finger_index = finger_idx
	_drag_is_mouse = is_mouse
	_drag_grab_offset = local_pos - w.position
	move_child(w, get_child_count() - 1)
	if top_bar:
		move_child(top_bar, get_child_count() - 1)
	w.queue_redraw()
	if guide_overlay:
		guide_overlay.queue_redraw()

func _update_drag(local_pos: Vector2) -> void:
	if dragging_node == null:
		return
	_dirty_after_reset = true
	var desired := _clamp_widget_pos(dragging_node, local_pos - _drag_grab_offset)
	# Soft magnetic alignment snap when within ALIGN_SNAP_PX of another widget's center
	var half_sz := dragging_node.size * 0.5
	var dc := desired + half_sz
	for other in _get_drag_widgets():
		if other == dragging_node:
			continue
		var oc := other.position + other.size * 0.5
		if absf(dc.y - oc.y) <= ALIGN_SNAP_PX:
			desired.y = oc.y - half_sz.y
		if absf(dc.x - oc.x) <= ALIGN_SNAP_PX:
			desired.x = oc.x - half_sz.x
	dragging_node.position = _clamp_widget_pos(dragging_node, desired)
	dragging_node.queue_redraw()
	if guide_overlay:
		guide_overlay.queue_redraw()

func _clear_drag_state() -> void:
	var prev := dragging_node
	dragging_node = null
	_drag_finger_index = -1
	_drag_is_mouse = false
	_drag_grab_offset = Vector2.ZERO
	if prev:
		prev.queue_redraw()
	if guide_overlay:
		guide_overlay.queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var lp := _to_local_canvas(st.position)
		if st.pressed:
			if dragging_node == null:
				var picked := _pick_widget_at(lp)
				if picked != null:
					_begin_drag(picked, lp, st.index, false)
					get_viewport().set_input_as_handled()
		elif st.index == _drag_finger_index:
			_clear_drag_state()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if dragging_node != null and not _drag_is_mouse and sd.index == _drag_finger_index:
			var lp := _to_local_canvas(sd.position)
			_update_drag(lp)
			get_viewport().set_input_as_handled()
		return

	# Prevent Android touch-emulated mouse events from causing double-event jitter
	if _drag_finger_index != -1 or event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var lp := _to_local_canvas(mb.position)
			if mb.pressed:
				if dragging_node == null:
					var picked := _pick_widget_at(lp)
					if picked != null:
						_begin_drag(picked, lp, -1, true)
						get_viewport().set_input_as_handled()
			elif _drag_is_mouse:
				_clear_drag_state()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if dragging_node != null and _drag_is_mouse:
			var mm := event as InputEventMouseMotion
			var lp := _to_local_canvas(mm.position)
			_update_drag(lp)
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		_on_close_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

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
	_apply_safe_topbar_layout()
	_load_current_positions()
	_update_texts()
	visible = true
	if level_preview:
		level_preview.queue_redraw()
	if guide_overlay:
		guide_overlay.queue_redraw()
	SoundManager.play("click")

func close() -> void:
	_clear_drag_state()
	_pending_reset = false
	_dirty_after_reset = false
	_set_pause_backdrop_hidden(false)
	visible = false
	closed.emit()

func _on_reset_pressed() -> void:
	SoundManager.play("click")
	_clear_drag_state()
	# Preview defaults WITHOUT writing to SaveManager until Save is explicitly pressed!
	_pending_reset = true
	_dirty_after_reset = false
	current_scale = 1.0
	if size_slider:
		size_slider.set_value_no_signal(100.0)
	if size_val_lbl:
		size_val_lbl.text = "100%"
	_apply_scale_to_widgets(false)
	var defs := _get_default_positions(1.0)
	if drag_left: drag_left.position = _clamp_widget_pos(drag_left, defs["left"])
	if drag_right: drag_right.position = _clamp_widget_pos(drag_right, defs["right"])
	if drag_jump: drag_jump.position = _clamp_widget_pos(drag_jump, defs["jump"])
	if drag_dash: drag_dash.position = _clamp_widget_pos(drag_dash, defs["dash"])

func _on_save_pressed() -> void:
	SoundManager.play("click")
	if _pending_reset and not _dirty_after_reset:
		SaveManager.reset_touch_layout()
	else:
		var positions := {}
		if drag_left: positions["left"] = drag_left.position
		if drag_right: positions["right"] = drag_right.position
		if drag_jump: positions["jump"] = drag_jump.position
		if drag_dash: positions["dash"] = drag_dash.position
		SaveManager.save_touch_layout(positions, current_scale)
	layout_saved.emit()
	close()

func _on_close_pressed() -> void:
	SoundManager.play("click")
	close()
