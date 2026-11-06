extends Control
class_name ControlCustomizer

signal closed
signal layout_saved

@onready var drag_left: Control = $DragLeft
@onready var drag_right: Control = $DragRight
@onready var drag_jump: Control = $DragJump
@onready var drag_dash: Control = get_node_or_null("DragDash")

@onready var reset_btn: Button = $TopBar/BtnBox/ResetBtn
@onready var save_btn: Button = $TopBar/BtnBox/SaveBtn
@onready var close_btn: Button = $TopBar/BtnBox/CloseBtn
@onready var title_lbl: Label = $TopBar/TitleBox/TitleLbl
@onready var subtitle_lbl: Label = $TopBar/TitleBox/SubtitleLbl

func _get_default_positions() -> Dictionary:
	return UIResponsive.get_default_touch_positions(self)

func _load_current_positions() -> void:
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

func _setup_drag_widget(node: Control, icon_name: String, sz: Vector2) -> void:
	if not node: return
	node.custom_minimum_size = sz
	node.size = sz
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var icon_rect = TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.texture = IconFactory.get_icon(icon_name, 1.0)
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
			node.position = Vector2(clampf(new_pos.x, 10.0, max_x), clampf(new_pos.y, 64.0, max_y))
	)
	
	# Drag paytida nozik neon hoshiya chizish
	node.draw.connect(func():
		var is_act = (dragging_node == node)
		var c = Color(0.3, 0.8, 1.0, 0.95) if is_act else Color(0.5, 0.65, 0.9, 0.5)
		var r = Rect2(Vector2.ZERO, node.size)
		node.draw_rect(r, Color(0.1, 0.2, 0.4, 0.25 if is_act else 0.0), true)
		node.draw_rect(r, c, false, 1.5 if is_act else 1.0)
	)

var dragging_node: Control = null
var drag_touch_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_drag_widget(drag_left, "circle_btn_left", Vector2(64, 64))
	_setup_drag_widget(drag_right, "circle_btn_right", Vector2(64, 64))
	_setup_drag_widget(drag_jump, "circle_btn_jump", Vector2(68, 68))
	if not drag_dash:
		var dd := Control.new()
		dd.name = "DragDash"
		dd.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dd)
		drag_dash = dd
	_setup_drag_widget(drag_dash, "circle_btn_dash", Vector2(64, 64))
	
	if reset_btn: reset_btn.pressed.connect(_on_reset_pressed)
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if close_btn: close_btn.pressed.connect(_on_close_pressed)

func open() -> void:
	_load_current_positions()
	_update_texts()
	visible = true
	SoundManager.play("click")

func close() -> void:
	visible = false
	closed.emit()

func _on_reset_pressed() -> void:
	SoundManager.play("click")
	var defs := _get_default_positions()
	if drag_left: drag_left.position = defs["left"]
	if drag_right: drag_right.position = defs["right"]
	if drag_jump: drag_jump.position = defs["jump"]
	if drag_dash: drag_dash.position = defs["dash"]
	SaveManager.reset_touch_layout()

func _on_save_pressed() -> void:
	SoundManager.play("click")
	if drag_left: SaveManager.set_touch_pos("left", drag_left.position)
	if drag_right: SaveManager.set_touch_pos("right", drag_right.position)
	if drag_jump: SaveManager.set_touch_pos("jump", drag_jump.position)
	if drag_dash: SaveManager.set_touch_pos("dash", drag_dash.position)
	layout_saved.emit()
	close()

func _on_close_pressed() -> void:
	SoundManager.play("click")
	close()
