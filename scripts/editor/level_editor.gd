extends Control

const GRID_SIZE: int = 32
const MIN_ROW: int = 2 # y = 64px (TopBar osti)
const MAX_ROW: int = 13 # y = 416..448px (BottomPalette y=460 usti, to'qnashuvsiz)

func _get_canvas_width() -> float:
	return get_viewport_rect().size.x

func _get_cols() -> int:
	return int(_get_canvas_width() / float(GRID_SIZE))


# Asboblar ro'yxati (har birining o'z maxsus SVG belgisi bor)
const TOOLS = [
	{"id": "platform", "icon": "platform", "loc_key": "tool_platform"},
	{"id": "trap_floor", "icon": "trap_floor", "loc_key": "tool_trap_floor"},
	{"id": "spikes", "icon": "spikes", "loc_key": "tool_spikes"},
	{"id": "pop_up_spikes", "icon": "pop_up_spikes", "loc_key": "tool_pop_up_spikes"},
	{"id": "saw", "icon": "saw", "loc_key": "tool_saw"},
	{"id": "circular_saw", "icon": "circular_saw", "loc_key": "tool_circular_saw"},
	{"id": "crusher", "icon": "crusher", "loc_key": "tool_crusher"},
	{"id": "spring", "icon": "spring", "loc_key": "tool_spring"},
	{"id": "falling", "icon": "falling", "loc_key": "tool_falling"},
	{"id": "fake_door", "icon": "fake_door", "loc_key": "tool_fake_door"},
	{"id": "door", "icon": "door", "loc_key": "tool_door"},
	{"id": "player", "icon": "player", "loc_key": "tool_player"},
	{"id": "erase", "icon": "eraser", "loc_key": "btn_erase"}
]

# Prefab sahnalar
const SCENE_PLATFORM = preload("res://scenes/objects/solid_platform.tscn")
const SCENE_TRAP_FLOOR = preload("res://scenes/traps/trap_floor.tscn")
const SCENE_SPIKES = preload("res://scenes/traps/spikes.tscn")
const SCENE_POP_UP_SPIKES = preload("res://scenes/traps/pop_up_spikes.tscn")
const SCENE_SAW = preload("res://scenes/traps/moving_saw.tscn")
const SCENE_CIRCULAR_SAW = preload("res://scenes/traps/circular_saw.tscn")
const SCENE_CRUSHER = preload("res://scenes/traps/crusher.tscn")
const SCENE_SPRING = preload("res://scenes/traps/spring.tscn")
const SCENE_FALLING_SPIKE = preload("res://scenes/traps/falling_spike.tscn")
const SCENE_FAKE_DOOR = preload("res://scenes/traps/fake_door.tscn")
const SCENE_EXIT_DOOR = preload("res://scenes/objects/exit_door.tscn")
const SCENE_PLAYER = preload("res://scenes/player/player.tscn")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

var current_slot: int = 1
var is_save_mode: bool = true
var current_tool: String = "platform"
var player_spawn: Vector2 = Vector2(144, 384)
var exit_door_pos: Vector2 = Vector2(848, 384)

# To'r bo'yicha elementlar: Dictionary[String, Dictionary] (kalit: "gx_gy")
var cell_map: Dictionary = {}

var is_testing: bool = false
var is_pointer_down: bool = false
var last_placed_cell: Vector2i = Vector2i(-1, -1)
var hover_cell: Vector2i = Vector2i(-1, -1)
var _playtest_session_id: int = 0
var _toast_tween: Tween = null

# Palitra kartalari uslubi
var card_norm_style := StyleBoxFlat.new()
var card_hov_style := StyleBoxFlat.new()
var card_act_style := StyleBoxFlat.new()

# Tugmalar va UI nodelar
@onready var top_bar: Control = $TopBar
@onready var bottom_palette: Control = $BottomPalette
@onready var palette_scroll: ScrollContainer = $BottomPalette/Scroll
@onready var canvas: Control = $Canvas
@onready var playtest_world: Node2D = $PlaytestWorld
@onready var playtest_ui: Control = $PlaytestUI
@onready var touch_controls: Control = get_node_or_null("PlaytestUI/TouchControls")
@onready var left_btn: Button = get_node_or_null("PlaytestUI/TouchControls/LeftBtn")
@onready var right_btn: Button = get_node_or_null("PlaytestUI/TouchControls/RightBtn")
@onready var dash_btn: Button = get_node_or_null("PlaytestUI/TouchControls/DashBtn")
@onready var jump_btn: Button = get_node_or_null("PlaytestUI/TouchControls/JumpBtn")
@onready var toast_lbl: Label = $ToastLabel
@onready var slot_btn: OptionButton = $TopBar/LeftGroup/SlotSelect
@onready var palette_container: HBoxContainer = $BottomPalette/Scroll/HBox
@onready var title_lbl: Label = get_node_or_null("TopBar/TitleLabel")
@onready var back_btn: Button = $TopBar/LeftGroup/BackBtn
@onready var save_btn: Button = get_node_or_null("TopBar/RightGroup/SaveBtn")
@onready var load_btn: Button = get_node_or_null("TopBar/RightGroup/LoadBtn")
@onready var clear_btn: Button = get_node_or_null("TopBar/RightGroup/ClearBtn")
@onready var test_btn: Button = get_node_or_null("TopBar/RightGroup/TestBtn")
@onready var stop_test_btn: Button = $PlaytestUI/StopTestBtn

var tool_cards: Dictionary = {}

# Palitrani sensorli surish (Touch/Drag Scroll)
var is_palette_dragging: bool = false
var _palette_touch_index: int = -1
var _palette_drag_moved: bool = false
var palette_drag_start_x: float = 0.0
var palette_scroll_start_x: float = 0.0

# Playtest multi-touch barmoq kuzatuvi (GameHUD bilan bir xil)
var _touch_fingers: Dictionary = {}
var _active_touch_actions: Dictionary = {}

func _ready() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_banner"):
		adm.show_banner()
	if adm and adm.has_signal("banner_visibility_changed") and not adm.banner_visibility_changed.is_connected(_on_banner_visibility_changed):
		adm.banner_visibility_changed.connect(_on_banner_visibility_changed)
	_apply_top_bar_layout()
		
	if not LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.connect(_on_language_changed)
	if not GameManager.custom_player_died.is_connected(_on_custom_player_died):
		GameManager.custom_player_died.connect(_on_custom_player_died)
	if not GameManager.custom_level_completed.is_connected(_on_custom_level_completed):
		GameManager.custom_level_completed.connect(_on_custom_level_completed)
	if not GameManager.player_respawned.is_connected(_on_custom_player_respawned):
		GameManager.player_respawned.connect(_on_custom_player_respawned)
	if SaveManager and not SaveManager.touch_layout_changed.is_connected(_apply_playtest_touch_layout):
		SaveManager.touch_layout_changed.connect(_apply_playtest_touch_layout)
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)
	
	_setup_palette_styles()
	_setup_palette_scroll()
	_build_palette()
	_setup_slots()
	_setup_touch_controls()
	_update_all_texts()
	_load_slot(current_slot)
	
	canvas.draw.connect(_on_canvas_draw)
	canvas.gui_input.connect(_on_canvas_gui_input)
	canvas.mouse_exited.connect(_on_canvas_mouse_exited)

func _exit_tree() -> void:
	_playtest_session_id += 1
	is_testing = false
	_release_all_touch_actions()
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	if GameManager:
		GameManager.is_custom_editor_mode = false
		if GameManager.custom_player_died.is_connected(_on_custom_player_died):
			GameManager.custom_player_died.disconnect(_on_custom_player_died)
		if GameManager.custom_level_completed.is_connected(_on_custom_level_completed):
			GameManager.custom_level_completed.disconnect(_on_custom_level_completed)
		if GameManager.player_respawned.is_connected(_on_custom_player_respawned):
			GameManager.player_respawned.disconnect(_on_custom_player_respawned)
	if SoundManager:
		SoundManager.set_gameplay_mode(false)
	if LocaleManager and LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.disconnect(_on_language_changed)
	if SaveManager and SaveManager.touch_layout_changed.is_connected(_apply_playtest_touch_layout):
		SaveManager.touch_layout_changed.disconnect(_apply_playtest_touch_layout)
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.disconnect(_on_viewport_size_changed)
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_signal("banner_visibility_changed") and adm.banner_visibility_changed.is_connected(_on_banner_visibility_changed):
		adm.banner_visibility_changed.disconnect(_on_banner_visibility_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_action()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_handle_back_action()
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()

func _handle_back_action() -> void:
	if is_testing:
		_on_stop_test_pressed()
	else:
		_on_back_pressed()

func _on_banner_visibility_changed(_is_visible: bool) -> void:
	_apply_top_bar_layout()
	_apply_playtest_touch_layout()

func _on_viewport_size_changed() -> void:
	_apply_top_bar_layout()
	_apply_playtest_touch_layout()
	if canvas:
		canvas.queue_redraw()

func _apply_top_bar_layout() -> void:
	var adm = get_node_or_null("/root/AdManager")
	var banner_h: float = adm.get_top_banner_height() \
		if adm and adm.has_method("get_top_banner_height") else 0.0
	if top_bar:
		top_bar.offset_top = banner_h
		top_bar.offset_bottom = banner_h + 56.0

func _on_canvas_mouse_exited() -> void:
	if hover_cell != Vector2i(-1, -1):
		hover_cell = Vector2i(-1, -1)
		if canvas:
			canvas.queue_redraw()

func _setup_palette_styles() -> void:
	card_norm_style.bg_color = Color("#0d111a")
	card_norm_style.border_color = Color("#222c3e")
	card_norm_style.border_width_left = 1
	card_norm_style.border_width_top = 1
	card_norm_style.border_width_right = 1
	card_norm_style.border_width_bottom = 1
	card_norm_style.corner_radius_top_left = 8
	card_norm_style.corner_radius_top_right = 8
	card_norm_style.corner_radius_bottom_right = 8
	card_norm_style.corner_radius_bottom_left = 8
	
	card_hov_style.bg_color = Color("#141b28")
	card_hov_style.border_color = Color("#384764")
	card_hov_style.border_width_left = 1
	card_hov_style.border_width_top = 1
	card_hov_style.border_width_right = 1
	card_hov_style.border_width_bottom = 1
	card_hov_style.corner_radius_top_left = 8
	card_hov_style.corner_radius_top_right = 8
	card_hov_style.corner_radius_bottom_right = 8
	card_hov_style.corner_radius_bottom_left = 8
	
	card_act_style.bg_color = Color("#182234")
	card_act_style.border_color = Color("#f8fafc") # Oq nurli faol hoshiya
	card_act_style.border_width_left = 2
	card_act_style.border_width_top = 2
	card_act_style.border_width_right = 2
	card_act_style.border_width_bottom = 2
	card_act_style.corner_radius_top_left = 8
	card_act_style.corner_radius_top_right = 8
	card_act_style.corner_radius_bottom_right = 8
	card_act_style.corner_radius_bottom_left = 8

func _setup_palette_scroll() -> void:
	if palette_scroll:
		palette_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		palette_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		palette_scroll.gui_input.connect(_on_palette_gui_input)

func _get_palette_max_scroll() -> int:
	if not palette_scroll or not palette_container:
		return 0
	var content_w: float = maxf(palette_container.size.x, palette_container.get_combined_minimum_size().x)
	return maxi(0, int(ceil(content_w - palette_scroll.size.x)))

func _on_palette_gui_input(event: InputEvent) -> void:
	if not palette_scroll:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _palette_touch_index == -1:
				_palette_touch_index = st.index
				is_palette_dragging = true
				_palette_drag_moved = false
				palette_drag_start_x = st.position.x
				palette_scroll_start_x = float(palette_scroll.scroll_horizontal)
		elif st.index == _palette_touch_index:
			_palette_touch_index = -1
			is_palette_dragging = false
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _palette_touch_index == -1:
			_palette_touch_index = sd.index
			is_palette_dragging = true
			_palette_drag_moved = false
			palette_drag_start_x = sd.position.x - sd.relative.x
			palette_scroll_start_x = float(palette_scroll.scroll_horizontal)
		if sd.index == _palette_touch_index:
			var diff: float = palette_drag_start_x - sd.position.x
			if absf(diff) > 10.0:
				_palette_drag_moved = true
			var max_sx := _get_palette_max_scroll()
			palette_scroll.scroll_horizontal = clampi(int(round(palette_scroll_start_x + diff)), 0, max_sx)
			palette_scroll.accept_event()
		return

	if _palette_touch_index != -1 or event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_palette_dragging = true
				_palette_drag_moved = false
				palette_drag_start_x = mb.global_position.x
				palette_scroll_start_x = float(palette_scroll.scroll_horizontal)
			else:
				is_palette_dragging = false
	elif event is InputEventMouseMotion and is_palette_dragging:
		var mm := event as InputEventMouseMotion
		var diff := palette_drag_start_x - mm.global_position.x
		if absf(diff) > 10.0:
			_palette_drag_moved = true
		var max_sx := _get_palette_max_scroll()
		palette_scroll.scroll_horizontal = clampi(int(round(palette_scroll_start_x + diff)), 0, max_sx)

func _setup_slots() -> void:
	if not slot_btn: return
	
	# 1. OptionButton o'zining zamonaviy dizayni
	slot_btn.custom_minimum_size = Vector2(115, 36)
	var btn_norm := StyleBoxFlat.new()
	btn_norm.bg_color = Color("#171524")
	btn_norm.border_color = Color("#3d3652")
	btn_norm.border_width_left = 1
	btn_norm.border_width_top = 1
	btn_norm.border_width_right = 1
	btn_norm.border_width_bottom = 1
	btn_norm.corner_radius_top_left = 8
	btn_norm.corner_radius_top_right = 8
	btn_norm.corner_radius_bottom_right = 8
	btn_norm.corner_radius_bottom_left = 8
	btn_norm.content_margin_left = 12.0
	btn_norm.content_margin_right = 12.0
	slot_btn.add_theme_stylebox_override("normal", btn_norm)
	
	var btn_hov := btn_norm.duplicate() as StyleBoxFlat
	btn_hov.border_color = Color("#8b5cf6") # Neon binafsha hoshiya
	btn_hov.bg_color = Color("#221d33")
	slot_btn.add_theme_stylebox_override("hover", btn_hov)
	
	var btn_press := btn_norm.duplicate() as StyleBoxFlat
	btn_press.border_color = Color("#a78bfa")
	btn_press.bg_color = Color("#2b2440")
	slot_btn.add_theme_stylebox_override("pressed", btn_press)
	
	slot_btn.add_theme_color_override("font_color", Color("#f1f5f9"))
	slot_btn.add_theme_font_size_override("font_size", 12)

	# 2. Ochiladigan PopupMenu (Dropdown) dizayni
	var popup: PopupMenu = slot_btn.get_popup()
	if popup:
		var pop_style := StyleBoxFlat.new()
		pop_style.bg_color = Color(0.10, 0.09, 0.15, 0.98) # Dark obsidian slate
		pop_style.border_color = Color(0.38, 0.32, 0.52, 0.95) # Chiroyli binafsharang hoshiya
		pop_style.border_width_left = 1
		pop_style.border_width_top = 1
		pop_style.border_width_right = 1
		pop_style.border_width_bottom = 1
		pop_style.corner_radius_top_left = 10
		pop_style.corner_radius_top_right = 10
		pop_style.corner_radius_bottom_right = 10
		pop_style.corner_radius_bottom_left = 10
		pop_style.content_margin_left = 8.0
		pop_style.content_margin_right = 8.0
		pop_style.content_margin_top = 8.0
		pop_style.content_margin_bottom = 8.0
		pop_style.shadow_color = Color(0, 0, 0, 0.65)
		pop_style.shadow_size = 14
		popup.add_theme_stylebox_override("panel", pop_style)
		
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.22, 0.18, 0.32, 0.95)
		hover_style.border_color = Color(0.22, 0.85, 0.45, 1.0) # Chap tomondagi neon yashil chiziq
		hover_style.border_width_left = 3
		hover_style.corner_radius_top_left = 6
		hover_style.corner_radius_top_right = 6
		hover_style.corner_radius_bottom_right = 6
		hover_style.corner_radius_bottom_left = 6
		hover_style.content_margin_left = 12.0
		hover_style.content_margin_right = 12.0
		hover_style.content_margin_top = 6.0
		hover_style.content_margin_bottom = 6.0
		popup.add_theme_stylebox_override("hover", hover_style)
		
		popup.add_theme_color_override("font_color", Color(0.92, 0.90, 0.96))
		popup.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		popup.add_theme_font_size_override("font_size", 13)
		popup.add_theme_constant_override("v_separation", 6)
		popup.add_theme_constant_override("item_start_padding", 10)
		popup.add_theme_constant_override("item_end_padding", 10)
		popup.add_theme_constant_override("icon_max_width", 20)

	# 3. Elementlarni to'ldirish
	slot_btn.fit_to_longest_item = false
	slot_btn.clear()
	for i in range(1, 6):
		var file_path := CustomLevelManager.get_slot_path(i)
		var is_saved := FileAccess.file_exists(file_path)
		var status_str := LocaleManager.t("slot_saved") if is_saved else LocaleManager.t("slot_empty")
		var item_text := "%s  •  %s" % [LocaleManager.t("slot_label", [i]), status_str]
		var item_icon := IconFactory.get_icon("slot_saved" if is_saved else "slot_empty", 0.8)
		
		slot_btn.add_icon_item(item_icon, item_text, i)
		
	slot_btn.add_separator()
	slot_btn.add_icon_item(IconFactory.get_icon("restart", 0.75), " " + LocaleManager.t("btn_reload_current"), 99)
	
	_select_current_slot_in_dropdown()
	if not slot_btn.item_selected.is_connected(_on_slot_selected):
		slot_btn.item_selected.connect(_on_slot_selected)

func _select_current_slot_in_dropdown() -> void:
	for i in range(slot_btn.item_count):
		if slot_btn.get_item_id(i) == current_slot:
			slot_btn.select(i)
			slot_btn.text = LocaleManager.t("slot_label", [current_slot])
			break

func _build_palette() -> void:
	for child in palette_container.get_children():
		palette_container.remove_child(child)
		child.queue_free()
	tool_cards.clear()
	
	for item in TOOLS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(78, 62)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.flat = false
		btn.add_theme_stylebox_override("normal", card_norm_style)
		btn.add_theme_stylebox_override("hover", card_hov_style)
		btn.add_theme_stylebox_override("pressed", card_act_style)
		
		# Ichki karta tartibi: Ikona yuqorida, Yozuv pastda
		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 4.0
		vbox.offset_right = -4.0
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 3)
		
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(26, 26)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.texture = IconFactory.get_icon(item.icon, 1.0)
		vbox.add_child(icon_rect)
		
		var lbl := Label.new()
		lbl.text = LocaleManager.t(item.loc_key)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.clip_text = true
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color("#cbd5e1"))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)
		
		btn.add_child(vbox)
		btn.pressed.connect(func():
			if _palette_drag_moved:
				return
			_select_tool(item.id)
		)
		palette_container.add_child(btn)
		
		tool_cards[item.id] = {
			"btn": btn,
			"lbl": lbl,
			"loc_key": item.loc_key
		}
		
	_select_tool("platform")

func _select_tool(tool_id: String) -> void:
	current_tool = tool_id
	SoundManager.play("click")
	
	for id in tool_cards:
		var data = tool_cards[id]
		var btn: Button = data["btn"]
		var lbl: Label = data["lbl"]
		if id == current_tool:
			btn.add_theme_stylebox_override("normal", card_act_style)
			btn.add_theme_stylebox_override("hover", card_act_style)
			lbl.add_theme_color_override("font_color", Color("#4ade80"))
		else:
			btn.add_theme_stylebox_override("normal", card_norm_style)
			btn.add_theme_stylebox_override("hover", card_hov_style)
			lbl.add_theme_color_override("font_color", Color("#94a3b8"))

func _on_language_changed(_lang: String) -> void:
	_update_all_texts()

func _update_all_texts() -> void:
	if title_lbl: title_lbl.text = LocaleManager.t("editor_title")
	_setup_slots()
	if back_btn:
		back_btn.icon = IconFactory.get_icon("arrow_left", 0.8)
		back_btn.text = " " + LocaleManager.t("btn_back")
	_set_save_mode(is_save_mode)
	if clear_btn:
		clear_btn.icon = IconFactory.get_icon("trash", 0.8)
		clear_btn.text = " " + LocaleManager.t("btn_clear")
	if test_btn:
		test_btn.icon = IconFactory.get_icon("play", 0.85)
		test_btn.text = " " + LocaleManager.t("btn_test")
	if stop_test_btn:
		stop_test_btn.icon = IconFactory.get_icon("stop", 0.85)
		stop_test_btn.text = " " + LocaleManager.t("btn_stop_test")
	if jump_btn:
		jump_btn.text = LocaleManager.t("btn_jump")
	if dash_btn:
		dash_btn.text = LocaleManager.t("btn_dash")
		
	for id in tool_cards:
		var data = tool_cards[id]
		var lbl: Label = data["lbl"]
		lbl.text = LocaleManager.t(data["loc_key"])

func _snap_to_cell(pos: Vector2) -> Vector2i:
	var gx: int = clampi(int(pos.x / float(GRID_SIZE)), 0, maxi(0, _get_cols() - 1))
	var gy: int = clampi(int(pos.y / float(GRID_SIZE)), MIN_ROW, MAX_ROW)
	return Vector2i(gx, gy)

func _clamp_cell_for_tool(cell: Vector2i, tool_id: String) -> Vector2i:
	var cols := _get_cols()
	var max_col := maxi(0, cols - 1)
	var min_inner_col := 1 if cols >= 3 else 0
	var max_inner_col := maxi(min_inner_col, cols - 2)
	match tool_id:
		"player":
			return Vector2i(clampi(cell.x, min_inner_col, max_inner_col), clampi(cell.y, MIN_ROW, MAX_ROW))
		"door", "fake_door":
			return Vector2i(clampi(cell.x, min_inner_col, max_inner_col), clampi(cell.y, maxi(3, MIN_ROW + 1), MAX_ROW))
		"crusher":
			var max_crusher_x := maxi(min_inner_col, cols - 3)
			return Vector2i(clampi(cell.x, min_inner_col, max_crusher_x), clampi(cell.y, MIN_ROW, maxi(MIN_ROW, MAX_ROW - 1)))
		_:
			return Vector2i(clampi(cell.x, 0, max_col), clampi(cell.y, MIN_ROW, MAX_ROW))

func _compute_crusher_target_y(gx: int, gy: int) -> float:
	var start_y: float = float(gy * GRID_SIZE)
	for scan_gy in range(gy + 2, MAX_ROW + 1):
		for col_offset in [0, 1]:
			var k := "%d_%d" % [gx + col_offset, scan_gy]
			if cell_map.has(k):
				var ct: String = str(cell_map[k].get("type", ""))
				if ct == "platform" or ct == "trap_floor":
					return maxf(start_y, float(scan_gy * GRID_SIZE) - 64.0)
	return maxf(start_y, float((MAX_ROW + 1) * GRID_SIZE) - 64.0)

func _on_canvas_gui_input(event: InputEvent) -> void:
	if is_testing:
		return
		
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			is_pointer_down = mb.pressed
			if is_pointer_down:
				last_placed_cell = Vector2i(-1, -1)
				_apply_tool_at_pos(mb.position)
			else:
				last_placed_cell = Vector2i(-1, -1)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		hover_cell = _snap_to_cell(mm.position)
		if is_pointer_down:
			_apply_tool_at_pos(mm.position)
		canvas.queue_redraw()

func _apply_tool_at_pos(pos: Vector2) -> void:
	var cell := _clamp_cell_for_tool(_snap_to_cell(pos), current_tool)
	if cell == last_placed_cell:
		return
	last_placed_cell = cell
	
	if not is_save_mode:
		_set_save_mode(true)
	
	var key := "%d_%d" % [cell.x, cell.y]
	
	if current_tool == "erase":
		if cell_map.has(key):
			cell_map.erase(key)
			SoundManager.play("click")
			canvas.queue_redraw()
		return
		
	if current_tool == "player":
		player_spawn = Vector2(cell.x * GRID_SIZE + 16, cell.y * GRID_SIZE + 32)
		SoundManager.play("click")
		canvas.queue_redraw()
		return
		
	if current_tool == "door":
		exit_door_pos = Vector2(cell.x * GRID_SIZE + 16, cell.y * GRID_SIZE + 32)
		SoundManager.play("click")
		canvas.queue_redraw()
		return
		
	# Boshqa katakli element joylashtirish
	var elem := {
		"type": current_tool,
		"gx": cell.x,
		"gy": cell.y,
		"x": cell.x * GRID_SIZE,
		"y": cell.y * GRID_SIZE
	}
	
	match current_tool:
		"platform", "trap_floor":
			pass
		"spikes", "pop_up_spikes":
			pass
		"saw":
			elem["move_distance"] = 64.0
			elem["radius"] = 16.0
		"circular_saw":
			elem["orbit_radius"] = 64.0
			elem["saw_radius"] = 16.0
		"crusher":
			pass
		"spring":
			elem["bounce_force"] = 580.0
		"falling":
			elem["trigger_distance"] = 340.0
		"fake_door":
			pass
			
	cell_map[key] = elem
	SoundManager.play("click")
	canvas.queue_redraw()

func _on_canvas_draw() -> void:
	var cw := _get_canvas_width()
	# 1. 32px to'r koordinata nuqtalari (qorong'i atmosfera nuqtalari)
	for x in range(0, int(cw) + GRID_SIZE, GRID_SIZE):
		for y in range(MIN_ROW * GRID_SIZE, (MAX_ROW + 1) * GRID_SIZE, GRID_SIZE):
			canvas.draw_circle(Vector2(x, y), 1.2, Color(0.20, 0.26, 0.38, 0.45))
			
	# Asosiy standart pol yo'naltiruvchi chiziq (Row 12, y=384)
	canvas.draw_dashed_line(Vector2(0, 12 * GRID_SIZE), Vector2(cw, 12 * GRID_SIZE), Color(0.35, 0.45, 0.65, 0.35), 1.2, 8.0)
	
	# Maydon chegaralari
	canvas.draw_line(Vector2(0, MIN_ROW * GRID_SIZE), Vector2(cw, MIN_ROW * GRID_SIZE), Color(0.18, 0.24, 0.35, 0.8), 1.5)
	canvas.draw_line(Vector2(0, (MAX_ROW + 1) * GRID_SIZE), Vector2(cw, (MAX_ROW + 1) * GRID_SIZE), Color(0.18, 0.24, 0.35, 0.8), 1.5)
	
	# 2. Joylashtirilgan elementlarni chizish
	for key in cell_map:
		_draw_cell_element(cell_map[key])
		
	# 3. Chiqish darvozasi va O'yinchi
	_draw_door(exit_door_pos)
	_draw_player(player_spawn)
	
	# 4. Kursor indikatori (Hover)
	if not is_testing and hover_cell.x >= 0 and hover_cell.y >= MIN_ROW:
		var hc := _clamp_cell_for_tool(hover_cell, current_tool)
		var hx: float = float(hc.x * GRID_SIZE)
		var hy: float = float(hc.y * GRID_SIZE)
		if current_tool == "crusher":
			# 2x2 katak (64x64px)
			canvas.draw_rect(Rect2(hx, hy, 64.0, 64.0), Color(0.85, 0.92, 1.0, 0.8), false, 2.0)
		elif current_tool == "door" or current_tool == "fake_door":
			# 1x2 katak (32x64px)
			canvas.draw_rect(Rect2(hx, hy - 32.0, 32.0, 64.0), Color(0.85, 0.92, 1.0, 0.8), false, 2.0)
		else:
			# Standart 1x1 katak (32x32px)
			canvas.draw_rect(Rect2(hx, hy, float(GRID_SIZE), float(GRID_SIZE)), Color(0.85, 0.92, 1.0, 0.8), false, 2.0)

func _draw_cell_element(elem: Dictionary) -> void:
	var t: String = elem.get("type", "platform")
	var gx: int = int(elem.get("gx", 0))
	var gy: int = int(elem.get("gy", 0))
	var x: float = float(gx * GRID_SIZE)
	var y: float = float(gy * GRID_SIZE)
	var sz := float(GRID_SIZE)
	
	match t:
		"platform":
			canvas.draw_rect(Rect2(x, y, sz, sz), Color("#0a0b10"), true)
			var above_key := "%d_%d" % [gx, gy - 1]
			if not cell_map.has(above_key) or cell_map[above_key].get("type") != "platform":
				canvas.draw_rect(Rect2(x, y, sz, 2.0), Color("#262e3e"), true)
		"trap_floor":
			canvas.draw_rect(Rect2(x, y, sz, sz), Color("#1e1218"), true)
			canvas.draw_line(Vector2(x, y), Vector2(x + sz, y + sz), Color("#ef4444", 0.4), 1.5)
			canvas.draw_rect(Rect2(x, y, sz, 2.0), Color("#f87171"), true)
		"spikes":
			var pts1 := PackedVector2Array([
				Vector2(x + 2.0, y + sz),
				Vector2(x + 8.0, y + 8.0),
				Vector2(x + 14.0, y + sz)
			])
			var pts2 := PackedVector2Array([
				Vector2(x + 18.0, y + sz),
				Vector2(x + 24.0, y + 8.0),
				Vector2(x + 30.0, y + sz)
			])
			canvas.draw_colored_polygon(pts1, Color("#0c0e14"))
			canvas.draw_colored_polygon(pts2, Color("#0c0e14"))
			canvas.draw_line(pts1[0], pts1[1], Color("#3a455a"), 1.0)
			canvas.draw_line(pts2[0], pts2[1], Color("#3a455a"), 1.0)
			canvas.draw_rect(Rect2(x, y + sz - 2.0, sz, 2.0), Color("#181e28"), true)
		"pop_up_spikes":
			canvas.draw_rect(Rect2(x, y + sz - 4.0, sz, 4.0), Color("#141822"), true)
			canvas.draw_line(Vector2(x + 8, y + sz - 4), Vector2(x + 16, y + 14), Color("#ef4444"), 2.0)
			canvas.draw_line(Vector2(x + 24, y + sz - 4), Vector2(x + 16, y + 14), Color("#ef4444"), 2.0)
		"saw":
			var c := Vector2(x + 16, y + 16)
			var srad_m: float = float(elem.get("radius", 16.0))
			var move_dist: float = float(elem.get("move_distance", 64.0))
			var end_c := c + Vector2(move_dist, 0.0)
			canvas.draw_dashed_line(c, end_c, Color(0.95, 0.45, 0.25, 0.55), 1.5, 4.0)
			canvas.draw_circle(end_c, 3.0, Color(0.95, 0.45, 0.25, 0.65))
			canvas.draw_circle(c, srad_m, Color("#3f3f46"))
			canvas.draw_circle(c, srad_m * 0.44, Color("#dc2626"))
			canvas.draw_circle(c, 2.5, Color("#f8fafc"))
		"circular_saw":
			var center := Vector2(x + 16, y + 16)
			var orad: float = float(elem.get("orbit_radius", 64.0))
			var srad: float = float(elem.get("saw_radius", 16.0))
			canvas.draw_arc(center, orad, 0, TAU, 32, Color(0.9, 0.4, 0.4, 0.25), 1.0)
			canvas.draw_circle(center, 4.0, Color("#334155"))
			var bpos := center + Vector2(orad, 0)
			canvas.draw_line(center, bpos, Color("#475569"), 2.0)
			canvas.draw_circle(bpos, srad, Color("#94a3b8"))
			canvas.draw_circle(bpos, srad * 0.65, Color("#dc2626"))
			canvas.draw_circle(bpos, 2.5, Color("#f8fafc"))
		"crusher":
			# Pastga tushish yo'li preview chizig'i
			var drop_target_y: float = _compute_crusher_target_y(gx, gy)
			var drop_bottom_y: float = drop_target_y + 64.0
			if drop_bottom_y > y + 66.0:
				canvas.draw_dashed_line(
					Vector2(x + 32.0, y + 64.0),
					Vector2(x + 32.0, drop_bottom_y),
					Color(0.95, 0.40, 0.40, 0.45),
					1.5,
					5.0
				)
				canvas.draw_line(
					Vector2(x + 12.0, drop_bottom_y),
					Vector2(x + 52.0, drop_bottom_y),
					Color(0.95, 0.40, 0.40, 0.55),
					1.5
				)
			# 2x standart: 64x64px siluet blok
			canvas.draw_rect(Rect2(x, y, 64, 64), Color("#0c0e14"), true)
			canvas.draw_line(Vector2(x, y + 1), Vector2(x + 64, y + 1), Color("#2a3548"), 2.0)
			for i in range(4):
				var p1 := Vector2(x + float(i) * 16.0, y + 64.0)
				var p2 := Vector2(x + (float(i) + 0.5) * 16.0, y + 74.0)
				var p3 := Vector2(x + float(i + 1) * 16.0, y + 64.0)
				canvas.draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color("#0c0e14"))
				canvas.draw_line(p1, p2, Color("#2a3548"), 1.0)
		"spring":
			canvas.draw_rect(Rect2(x + 2, y + sz - 6.0, sz - 4.0, 6.0), Color("#181e28"), true)
			canvas.draw_rect(Rect2(x + 4, y + 10.0, sz - 8.0, 4.0), Color("#f59e0b"), true)
			canvas.draw_line(Vector2(x + 8, y + sz - 6), Vector2(x + sz - 8, y + 20), Color("#94a3b8"), 2.5)
			canvas.draw_line(Vector2(x + sz - 8, y + 20), Vector2(x + 8, y + 14), Color("#cbd5e1"), 2.5)
			canvas.draw_line(Vector2(x + 8, y + 14), Vector2(x + 16, y + 10), Color("#94a3b8"), 2.5)
			canvas.draw_rect(Rect2(x + 2, y + 6.0, sz - 4.0, 4.0), Color("#475569"), true)
		"falling":
			var f_pts := PackedVector2Array([
				Vector2(x, y),
				Vector2(x + sz, y),
				Vector2(x + 16.0, y + sz)
			])
			canvas.draw_colored_polygon(f_pts, Color("#e11d48"))
			canvas.draw_line(Vector2(x, y), Vector2(x + 16.0, y + sz), Color("#fb7185"), 1.2)
			canvas.draw_line(Vector2(x + 16.0, y + sz), Vector2(x + sz, y), Color("#881337"), 1.2)
		"fake_door":
			var fdw: float = 32.0
			var fdh: float = 56.0
			var fx: float = x
			var fy: float = y + sz - fdh
			canvas.draw_rect(Rect2(fx, fy, fdw, fdh), Color("#241433"), true)
			canvas.draw_rect(Rect2(fx, fy, fdw, 3.0), Color("#a855f7"), true)
			canvas.draw_circle(Vector2(fx + 10, fy + 32.0), 2.5, Color("#ef4444"))
			canvas.draw_circle(Vector2(fx + 22, fy + 32.0), 2.5, Color("#ef4444"))

func _draw_door(pos: Vector2) -> void:
	# Monumental glowing white portal arch (Exit Door)
	var dw: float = 44.0
	var dh: float = 58.0
	var half_w := dw / 2.0
	var post_w := 5.0
	var lintel_h := 5.5
	var dx := pos.x
	var dy := pos.y
	
	# Tashqi aura
	canvas.draw_rect(Rect2(dx - half_w - 3.0, dy - dh - 3.0, dw + 6.0, dh + 3.0), Color(0.95, 0.98, 1.0, 0.20), true)
	
	# Qora ichki bo'shliq
	canvas.draw_rect(Rect2(dx - half_w + post_w, dy - dh + lintel_h, dw - post_w * 2.0, dh - lintel_h), Color("#05070c"), true)
	
	# Nur ustuni
	canvas.draw_rect(Rect2(dx - 7.0, dy - dh + lintel_h + 1.0, 14.0, dh - lintel_h - 1.0), Color(0.85, 0.95, 1.0, 0.45), true)
	canvas.draw_rect(Rect2(dx - 2.5, dy - dh + lintel_h + 1.0, 5.0, dh - lintel_h - 1.0), Color(1.0, 1.0, 1.0, 0.85), true)
	
	# Oq ramka
	var frame_col := Color(1.0, 1.0, 1.0)
	canvas.draw_rect(Rect2(dx - half_w, dy - dh, post_w, dh), frame_col, true)
	canvas.draw_rect(Rect2(dx + half_w - post_w, dy - dh, post_w, dh), frame_col, true)
	canvas.draw_rect(Rect2(dx - half_w, dy - dh, dw, lintel_h), frame_col, true)
	canvas.draw_rect(Rect2(dx - half_w - 2.0, dy - dh, dw + 4.0, 2.5), frame_col, true)
	
	# Poydevor
	canvas.draw_line(Vector2(dx - half_w - 2.5, dy), Vector2(dx + half_w + 2.5, dy), frame_col, 2.0)
	
	# Ustidagi ▼ indikator
	var tri_pts := PackedVector2Array([
		Vector2(dx - 6.0, dy - dh - 10.0),
		Vector2(dx + 6.0, dy - dh - 10.0),
		Vector2(dx, dy - dh - 2.0)
	])
	canvas.draw_colored_polygon(tri_pts, frame_col)

func _draw_player(pos: Vector2) -> void:
	var pw: float = 28.0
	var ph: float = 32.0
	var r := Rect2(pos.x - pw / 2.0, pos.y - ph, pw, ph)
	canvas.draw_rect(r, Color("#181520"), true)
	canvas.draw_rect(r, Color("#342f3a"), false, 1.2)
	# Ko'zlar
	canvas.draw_circle(Vector2(pos.x - 5, pos.y - 18), 3.0, Color(1, 1, 1, 1))
	canvas.draw_circle(Vector2(pos.x + 5, pos.y - 18), 3.0, Color(1, 1, 1, 1))
	canvas.draw_circle(Vector2(pos.x - 4, pos.y - 18), 1.5, Color(0, 0, 0, 1))
	canvas.draw_circle(Vector2(pos.x + 6, pos.y - 18), 1.5, Color(0, 0, 0, 1))

# --- Playtest rejimi ---
func _on_test_pressed() -> void:
	SoundManager.play("click")
	_playtest_session_id += 1
	is_testing = true
	is_pointer_down = false
	hover_cell = Vector2i(-1, -1)
	top_bar.visible = false
	bottom_palette.visible = false
	canvas.visible = false
	playtest_ui.visible = true
	_update_playtest_touch_visibility()
	_apply_playtest_touch_layout()
	
	GameManager.is_custom_editor_mode = true
	SoundManager.set_gameplay_mode(true)
	_spawn_test_world()

func _on_stop_test_pressed() -> void:
	SoundManager.play("click")
	_playtest_session_id += 1
	_release_all_touch_actions()
	_clear_test_world()
	GameManager.is_custom_editor_mode = false
	SoundManager.set_gameplay_mode(false)
	is_testing = false
	
	playtest_ui.visible = false
	_update_playtest_touch_visibility()
	top_bar.visible = true
	bottom_palette.visible = true
	canvas.visible = true
	canvas.queue_redraw()

func _spawn_test_world() -> void:
	_clear_test_world()
	
	# 1. Platformalarni (gy, gx) bo'yicha tartiblab gorizontal birlashtiramiz (o'ngdan-chapga dublikatlarsiz!)
	var platform_cells: Array[Dictionary] = []
	for key in cell_map:
		var elem: Dictionary = cell_map[key]
		if str(elem.get("type", "")) == "platform":
			platform_cells.append(elem)
	platform_cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ay := int(a.get("gy", 0))
		var by := int(b.get("gy", 0))
		if ay != by:
			return ay < by
		return int(a.get("gx", 0)) < int(b.get("gx", 0))
	)
	
	var processed_platforms: Dictionary = {}
	for pe in platform_cells:
		var gx: int = int(pe.get("gx", 0))
		var gy: int = int(pe.get("gy", 0))
		var pkey := "%d_%d" % [gx, gy]
		if processed_platforms.has(pkey):
			continue
		var has_above: bool = cell_map.has("%d_%d" % [gx, gy - 1]) \
			and str(cell_map["%d_%d" % [gx, gy - 1]].get("type", "")) == "platform"
		processed_platforms[pkey] = true
		var span: int = 1
		while true:
			var nkey := "%d_%d" % [gx + span, gy]
			if processed_platforms.has(nkey) or not cell_map.has(nkey):
				break
			if str(cell_map[nkey].get("type", "")) != "platform":
				break
			var n_has_above: bool = cell_map.has("%d_%d" % [gx + span, gy - 1]) \
				and str(cell_map["%d_%d" % [gx + span, gy - 1]].get("type", "")) == "platform"
			if n_has_above != has_above:
				break
			processed_platforms[nkey] = true
			span += 1
		
		var plat = SCENE_PLATFORM.instantiate()
		plat.set("platform_size", Vector2(span * GRID_SIZE, GRID_SIZE))
		plat.set("is_extension_or_wall", has_above)
		plat.position = Vector2(float(gx * GRID_SIZE), float(gy * GRID_SIZE))
		playtest_world.add_child(plat)
	
	# 2. Qolgan barcha tuzoqlar va obyektlarni yaratish
	for key in cell_map:
		var elem: Dictionary = cell_map[key]
		var t: String = str(elem.get("type", "platform"))
		if t == "platform":
			continue
		var gx: int = int(elem.get("gx", 0))
		var gy: int = int(elem.get("gy", 0))
		var x: float = float(gx * GRID_SIZE)
		var y: float = float(gy * GRID_SIZE)
			
		var node: Node2D = null
		match t:
			"trap_floor":
				node = SCENE_TRAP_FLOOR.instantiate()
				node.set("auto_extend_to_bottom", false)
				node.set("platform_size", Vector2(GRID_SIZE, GRID_SIZE))
				node.position = Vector2(x, y)
			"spikes":
				node = SCENE_SPIKES.instantiate()
				node.set("spike_size", Vector2(GRID_SIZE, GRID_SIZE))
				node.position = Vector2(x, y)
			"pop_up_spikes":
				node = SCENE_POP_UP_SPIKES.instantiate()
				node.set("spike_width", float(GRID_SIZE))
				node.set("max_spike_height", float(GRID_SIZE))
				node.position = Vector2(x, y + GRID_SIZE)
			"saw":
				node = SCENE_SAW.instantiate()
				node.position = Vector2(x + 16, y + 16)
				node.set("patrol_distance", float(elem.get("move_distance", 64.0)))
				node.set("radius", float(elem.get("radius", 16.0)))
			"circular_saw":
				node = SCENE_CIRCULAR_SAW.instantiate()
				node.position = Vector2(x + 16, y + 16)
				node.set("orbit_radius", float(elem.get("orbit_radius", 64.0)))
				node.set("saw_radius", float(elem.get("saw_radius", 16.0)))
			"crusher":
				node = SCENE_CRUSHER.instantiate()
				node.position = Vector2(x, y)
				node.set("crusher_size", Vector2(64, 64))
				node.set("target_y", _compute_crusher_target_y(gx, gy))
			"spring":
				node = SCENE_SPRING.instantiate()
				node.position = Vector2(x, y + GRID_SIZE)
				node.set("spring_size", Vector2(GRID_SIZE, GRID_SIZE))
				node.set("bounce_force", absf(float(elem.get("bounce_force", 580.0))))
				node.set("visible_when_idle", true)
			"falling":
				node = SCENE_FALLING_SPIKE.instantiate()
				node.position = Vector2(x + 16, y)
				node.set("trigger_distance", float(elem.get("trigger_distance", elem.get("trigger_dist", 340.0))))
			"fake_door":
				node = SCENE_FAKE_DOOR.instantiate()
				node.position = Vector2(x + 16, y + 32)
				
		if node:
			playtest_world.add_child(node)
			
	# Chiqish darvozasi
	var door = SCENE_EXIT_DOOR.instantiate()
	door.position = exit_door_pos
	playtest_world.add_child(door)

	# Chegaraviy devorlar va shift
	var cw := _get_canvas_width()
	var left_w = SCENE_PLATFORM.instantiate()
	left_w.name = "LeftWall"
	left_w.position = Vector2(0, 0)
	left_w.set("platform_size", Vector2(32, 540))
	left_w.set("is_extension_or_wall", true)
	playtest_world.add_child(left_w)
	
	var right_w = SCENE_PLATFORM.instantiate()
	right_w.name = "RightWall"
	right_w.position = Vector2(cw - 32, 0)
	right_w.set("platform_size", Vector2(32, 540))
	right_w.set("is_extension_or_wall", true)
	playtest_world.add_child(right_w)
	
	var ceiling = SCENE_PLATFORM.instantiate()
	ceiling.name = "Ceiling"
	ceiling.position = Vector2(0, 0)
	ceiling.set("platform_size", Vector2(cw, 60))
	playtest_world.add_child(ceiling)
	
	# O'yinchi (faqat bitta marta yaratiladi!)
	_spawn_test_player_once()

func _spawn_test_player_once() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.get_parent():
			p.get_parent().remove_child(p)
		p.queue_free()
		
	var player = SCENE_PLAYER.instantiate()
	player.name = "Player"
	player.position = player_spawn
	player.spawn_position = player_spawn
	playtest_world.add_child(player)

func _clear_test_world() -> void:
	if not playtest_world:
		return
	TrapBiomeVFX.clear_level(playtest_world)
	for c in playtest_world.get_children():
		playtest_world.remove_child(c)
		c.queue_free()

func _on_custom_player_died() -> void:
	# PlayerController.kill() allaqachon "die" SFX chaladi; tuzoqlar respawn'da tozalanadi.
	pass

func _on_custom_player_respawned() -> void:
	if not is_testing or not is_instance_valid(playtest_world):
		return
	TrapBiomeVFX.clear_level(playtest_world)
	for c in playtest_world.get_children():
		if c.has_method("reset_trap"):
			c.reset_trap()
		elif c.has_method("reset_door"):
			c.reset_door()

func _on_custom_level_completed() -> void:
	# ExitDoor._on_body_entered() allaqachon "win" SFX chaladi.
	var session := _playtest_session_id
	_show_toast(LocaleManager.t("test_won_notice"))
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree() and is_testing and _playtest_session_id == session:
		_on_stop_test_pressed()

# --- Saqlash va Yuklash ---
func _on_slot_selected(idx: int) -> void:
	var id := slot_btn.get_item_id(idx)
	if id == 99:
		# Qayta yuklash (Revert) — bo'sh slot bo'lsa Save rejimi saqlanadi
		SoundManager.play("click")
		_load_slot(current_slot)
		_show_toast(LocaleManager.t("reloaded_notice", [current_slot]))
		_select_current_slot_in_dropdown()
		return
		
	if id >= 1 and id <= 5:
		current_slot = id
		SoundManager.play("click")
		_load_slot(current_slot)
		_show_toast(LocaleManager.t("loaded_notice", [current_slot]))
		_select_current_slot_in_dropdown()

func _snap_door_pos(raw: Vector2) -> Vector2:
	var cols := _get_cols()
	var min_x := 1 if cols >= 3 else 0
	var max_x := maxi(min_x, cols - 2)
	var gx: int = clampi(int(floor(raw.x / float(GRID_SIZE))), min_x, max_x)
	var gy: int = clampi(int(round(raw.y / float(GRID_SIZE))), maxi(4, MIN_ROW + 2), MAX_ROW + 1)
	return Vector2(float(gx * GRID_SIZE + 16), float(gy * GRID_SIZE))

func _snap_player_pos(raw: Vector2) -> Vector2:
	var cols := _get_cols()
	var min_x := 1 if cols >= 3 else 0
	var max_x := maxi(min_x, cols - 2)
	var gx: int = clampi(int(floor(raw.x / float(GRID_SIZE))), min_x, max_x)
	var gy: int = clampi(int(round(raw.y / float(GRID_SIZE))), MIN_ROW + 1, MAX_ROW + 1)
	return Vector2(float(gx * GRID_SIZE + 16), float(gy * GRID_SIZE))

func _load_slot(slot: int) -> void:
	cell_map.clear()
	var data: Dictionary = CustomLevelManager.load_custom_level(slot)
	var raw_p = data.get("player_spawn", [144, 384])
	if raw_p is Array and raw_p.size() >= 2:
		player_spawn = _snap_player_pos(Vector2(float(raw_p[0]), float(raw_p[1])))
	else:
		player_spawn = _snap_player_pos(Vector2(144.0, 384.0))
	
	var raw_d = data.get("exit_door", [848, 384])
	if raw_d is Array and raw_d.size() >= 2:
		exit_door_pos = _snap_door_pos(Vector2(float(raw_d[0]), float(raw_d[1])))
	else:
		exit_door_pos = _snap_door_pos(Vector2(848.0, 384.0))
	
	var raw_elements = data.get("elements", [])
	if raw_elements is Array:
		for elem in raw_elements:
			if not (elem is Dictionary):
				continue
			var t: String = str(elem.get("type", "platform"))
			var gx: int = int(elem.get("gx", int(elem.get("x", 0) / float(GRID_SIZE))))
			var gy: int = int(elem.get("gy", int(elem.get("y", 0) / float(GRID_SIZE))))
			var clamped := _clamp_cell_for_tool(Vector2i(gx, gy), t)
			var key := "%d_%d" % [clamped.x, clamped.y]
			var clean_elem: Dictionary = elem.duplicate()
			clean_elem["gx"] = clamped.x
			clean_elem["gy"] = clamped.y
			clean_elem["x"] = clamped.x * GRID_SIZE
			clean_elem["y"] = clamped.y * GRID_SIZE
			cell_map[key] = clean_elem
		
	canvas.queue_redraw()
	
	var file_path := CustomLevelManager.get_slot_path(slot)
	_set_save_mode(not FileAccess.file_exists(file_path))

func _set_save_mode(save_mode: bool) -> void:
	is_save_mode = save_mode
	if not save_btn: return
	if is_save_mode:
		save_btn.icon = IconFactory.get_icon("save", 0.8)
		save_btn.text = " " + LocaleManager.t("btn_save")
		save_btn.add_theme_color_override("font_color", Color(0.9, 0.88, 0.92, 1))
	else:
		save_btn.icon = IconFactory.get_icon("load", 0.8)
		save_btn.text = " " + LocaleManager.t("btn_load")
		save_btn.add_theme_color_override("font_color", Color(0.38, 0.85, 1.0, 1))

func _on_save_pressed() -> void:
	SoundManager.play("click")
	if is_save_mode:
		var elements_list: Array = []
		for key in cell_map:
			elements_list.append(cell_map[key])
			
		var data := {
			"name": "Slot %d Zonasi" % current_slot,
			"player_spawn": [player_spawn.x, player_spawn.y],
			"exit_door": [exit_door_pos.x, exit_door_pos.y],
			"elements": elements_list
		}
		var ok: bool = CustomLevelManager.save_custom_level(current_slot, data)
		if ok:
			_show_toast(LocaleManager.t("saved_notice"))
			_setup_slots()
			_set_save_mode(false)
	else:
		# Yuklash holatida bosilsa - oxirgi saqlangan holat yuklanadi
		_load_slot(current_slot)
		_show_toast(LocaleManager.t("reloaded_notice", [current_slot]))

func _on_load_pressed() -> void:
	SoundManager.play("click")
	_load_slot(current_slot)

func _on_clear_pressed() -> void:
	SoundManager.play("click")
	cell_map.clear()
	player_spawn = Vector2(144, 384)
	exit_door_pos = Vector2(848, 384)
	canvas.queue_redraw()
	_show_toast(LocaleManager.t("cleared_notice"))
	_set_save_mode(true)

func _on_back_pressed() -> void:
	SoundManager.play("click")
	_playtest_session_id += 1
	_release_all_touch_actions()
	GameManager.is_custom_editor_mode = false
	SoundManager.set_gameplay_mode(false)
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_banner"):
		adm.show_banner()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _show_toast(msg: String) -> void:
	if not toast_lbl: return
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_lbl.text = msg
	toast_lbl.visible = true
	toast_lbl.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(toast_lbl, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): toast_lbl.visible = false)

func _is_mobile_touch_platform() -> bool:
	return (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)

func _setup_touch_controls() -> void:
	for btn in [left_btn, right_btn, dash_btn, jump_btn]:
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.focus_mode = Control.FOCUS_NONE
	_apply_playtest_touch_layout()
	_update_playtest_touch_visibility()

func _update_playtest_touch_visibility() -> void:
	var show_touch := is_testing and _is_mobile_touch_platform()
	if touch_controls:
		touch_controls.visible = show_touch
	if not show_touch:
		_release_all_touch_actions()

func _apply_playtest_touch_layout() -> void:
	var def_positions := UIResponsive.get_default_touch_positions(self)
	var insets := UIResponsive.get_safe_insets(self)
	var adm = get_node_or_null("/root/AdManager")
	var banner_h: float = adm.get_top_banner_height() \
		if adm and adm.has_method("get_top_banner_height") else 0.0

	if stop_test_btn:
		stop_test_btn.position = Vector2(18.0 + float(insets["left"]), banner_h + 16.0 + float(insets["top"]))

	var sm = get_node_or_null("/root/SaveManager")
	var btn_sc: float = float(sm.touch_button_scale) if sm else 1.0
	var sz_lr := Vector2(82.0, 82.0) * btn_sc
	var sz_dash := Vector2(78.0, 78.0) * btn_sc
	var sz_jump := Vector2(88.0, 88.0) * btn_sc

	if left_btn:
		left_btn.custom_minimum_size = sz_lr
		left_btn.size = sz_lr
	if right_btn:
		right_btn.custom_minimum_size = sz_lr
		right_btn.size = sz_lr
	if dash_btn:
		dash_btn.custom_minimum_size = sz_dash
		dash_btn.size = sz_dash
	if jump_btn:
		jump_btn.custom_minimum_size = sz_jump
		jump_btn.size = sz_jump

	if sm and not sm.custom_touch_layout.is_empty():
		if left_btn: left_btn.position = sm.get_touch_pos("left", def_positions["left"])
		if right_btn: right_btn.position = sm.get_touch_pos("right", def_positions["right"])
		if dash_btn: dash_btn.position = sm.get_touch_pos("dash", def_positions["dash"])
		if jump_btn: jump_btn.position = sm.get_touch_pos("jump", def_positions["jump"])
	else:
		if left_btn: left_btn.position = def_positions["left"]
		if right_btn: right_btn.position = def_positions["right"]
		if dash_btn: dash_btn.position = def_positions["dash"]
		if jump_btn: jump_btn.position = def_positions["jump"]

func _input(event: InputEvent) -> void:
	if not is_testing or not touch_controls or not touch_controls.visible or get_tree().paused:
		if not _active_touch_actions.is_empty():
			_release_all_touch_actions()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var act := _get_touch_action_at(st.position)
			if not act.is_empty():
				_touch_fingers[st.index] = act
				_sync_touch_actions()
		elif _touch_fingers.has(st.index):
			_touch_fingers.erase(st.index)
			_sync_touch_actions()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touch_fingers.has(sd.index):
			var cur_act := str(_touch_fingers[sd.index])
			if cur_act == "move_left" or cur_act == "move_right":
				var new_act := _get_touch_action_at(sd.position)
				if (new_act == "move_left" or new_act == "move_right") \
						and new_act != cur_act:
					_touch_fingers[sd.index] = new_act
					_sync_touch_actions()

func _get_touch_action_at(screen_pos: Vector2) -> String:
	var local_pos := get_global_transform_with_canvas().affine_inverse() * screen_pos
	var pad := 16.0
	if jump_btn and Rect2(jump_btn.position, jump_btn.size).grow(pad).has_point(local_pos):
		return "jump"
	if dash_btn and Rect2(dash_btn.position, dash_btn.size).grow(pad).has_point(local_pos):
		return "dash"
	if left_btn and Rect2(left_btn.position, left_btn.size).grow(pad).has_point(local_pos):
		return "move_left"
	if right_btn and Rect2(right_btn.position, right_btn.size).grow(pad).has_point(local_pos):
		return "move_right"
	return ""

func _sync_touch_actions() -> void:
	var next_actions: Dictionary = {}
	for act in _touch_fingers.values():
		next_actions[str(act)] = true

	for act in _active_touch_actions.keys():
		if not next_actions.has(act):
			Input.action_release(str(act))

	for act in next_actions.keys():
		if not _active_touch_actions.has(act):
			Input.action_press(str(act))

	_active_touch_actions = next_actions

func _release_all_touch_actions() -> void:
	_touch_fingers.clear()
	for act in _active_touch_actions.keys():
		Input.action_release(str(act))
	_active_touch_actions.clear()
