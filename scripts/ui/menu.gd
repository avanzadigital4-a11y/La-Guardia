extends Control
## Menu de inicio.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var title := UIUtils.label("LA GUARDIA", 40, UIUtils.FG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UIUtils.label("Estacion Cabo Hueso  ---  cinco noches", 14, UIUtils.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(UIUtils.label("", 16, UIUtils.DIM))

	var options := OptionsPanel.new()
	options.visible = false
	options.closed.connect(func():
		options.visible = false
		col.visible = true)

	_button(col, "Nueva partida", func():
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/main.tscn"))

	var cont := _button(col, "Continuar", func():
		GameState.load_game()
		get_tree().change_scene_to_file("res://scenes/main.tscn"))
	cont.disabled = not FileAccess.file_exists(GameState.SAVE_PATH)
	if cont.disabled:
		cont.tooltip_text = "Todavia no hay ninguna noche guardada."

	_button(col, "Opciones", func():
		col.visible = false
		options.visible = true)

	_button(col, "Salir", func():
		get_tree().quit())

	var opt_center := CenterContainer.new()
	opt_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(opt_center)
	opt_center.add_child(options)

	var hint := UIUtils.label("[WASD] moverse   [E] usar   [F] linterna   [TAB] bitacora", 12, UIUtils.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -46.0
	hint.offset_bottom = -26.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _button(parent: Node, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 38)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
