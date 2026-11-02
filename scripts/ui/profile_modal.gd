extends Control

# ProfileModal - Wrong Way Profile & Identity Customizer
# - Shows & edits username
# - Displays Player Tag with one-click copy
# - Avatar selector (6 stylized avatar icons)
# - Auth status badge

@onready var modal_panel: Panel = get_node_or_null("CenterContainer/Panel")
@onready var name_input: LineEdit = get_node_or_null("CenterContainer/Panel/VBox/NameEdit")
@onready var tag_label: Label = get_node_or_null("CenterContainer/Panel/VBox/TagBox/TagLabel")
@onready var copy_tag_btn: Button = get_node_or_null("CenterContainer/Panel/VBox/TagBox/CopyBtn")
@onready var avatar_preview: TextureRect = get_node_or_null("CenterContainer/Panel/VBox/AvatarPreview")
@onready var avatar_grid: HBoxContainer = get_node_or_null("CenterContainer/Panel/VBox/AvatarGrid")
@onready var save_btn: Button = get_node_or_null("CenterContainer/Panel/VBox/ActionHBox/SaveBtn")
@onready var close_btn: Button = get_node_or_null("CenterContainer/Panel/VBox/ActionHBox/CloseBtn")
@onready var toast_label: Label = get_node_or_null("CenterContainer/Panel/ToastLabel")

var selected_avatar_idx: int = 1

func _ready() -> void:
	visible = false
	if close_btn: close_btn.pressed.connect(close)
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if copy_tag_btn: copy_tag_btn.pressed.connect(_on_copy_tag)
	_setup_avatar_buttons()

func open() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	name_input.text = ProfileManager.username
	tag_label.text = ProfileManager.player_tag
	selected_avatar_idx = ProfileManager.avatar_index
	_update_avatar_preview()
	if toast_label: toast_label.text = ""

func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false

func _setup_avatar_buttons() -> void:
	if not avatar_grid:
		return
	for i in range(1, 7):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.size = Vector2(40, 40)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = str(i)
		btn.pressed.connect(func():
			selected_avatar_idx = i
			_update_avatar_preview()
		)
		avatar_grid.add_child(btn)

func _update_avatar_preview() -> void:
	# Preview avatar doirasini yangilash
	if avatar_preview:
		# Oddiy stilizatsiya yoki IconFactory ikonkalari
		pass

func _on_copy_tag() -> void:
	DisplayServer.clipboard_set(ProfileManager.player_tag)
	_show_toast("ID nusxalandi: " + ProfileManager.player_tag)

func _on_save_pressed() -> void:
	var new_name := name_input.text.strip_edges()
	if new_name.is_empty():
		_show_toast("Ism bo'sh bo'lishi mumkin emas!")
		return
	ProfileManager.update_profile(new_name, selected_avatar_idx)
	_show_toast("Profil saqlandi!")
	await get_tree().create_timer(0.6).timeout
	close()

func _show_toast(msg: String) -> void:
	if toast_label:
		toast_label.text = msg
		toast_label.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(toast_label, "modulate:a", 0.0, 2.0)
