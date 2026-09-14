extends CanvasLayer
## Pausa: reanudar, opciones o volver al menu.

var is_open := false
var _col: VBoxContainer
var _options: OptionsPanel


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UIUtils.panel_bg(0.9))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	center.add_child(_col)
	var title := UIUtils.label("EN PAUSA", 24, UIUtils.FG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(title)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(func():
		_options.visible = false
		_col.visible = true)
	var opt_center := CenterContainer.new()
	opt_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(opt_center)
	opt_center.add_child(_options)

	_button("Reanudar", func(): close())
	_button("Opciones", func():
		_col.visible = false
		_options.visible = true)
	_button("Guardar y volver al menu", func():
		GameState.save_game()
		close()
		get_tree().change_scene_to_file("res://scenes/menu.tscn"))


func _button(text: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 34)
	b.pressed.connect(on_press)
	_col.add_child(b)


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_col.visible = true
	_options.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toggle() -> void:
	if is_open:
		close()
	else:
		open()
