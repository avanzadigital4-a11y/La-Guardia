# -*- coding: utf-8 -*-
class_name OptionsPanel
extends VBoxContainer
## Controles de opciones, compartidos por el menu de inicio y la pausa.

signal closed()

var _listening_action := ""
var _listening_button: Button = null


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UIUtils.label(tr("OPCIONES"), 20, UIUtils.FG))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 60)
	add_child(cols)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)

	_slider(left, "Sensibilidad del mouse", 0.2, 3.0, Settings.mouse_sensitivity, 0.05,
		func(v): Settings.mouse_sensitivity = v)
	_slider(left, "Volumen", 0.0, 1.0, Settings.master_volume, 0.05,
		func(v): Settings.master_volume = v)
	_slider(left, "Pixelado (resolución interna)", 0.25, 1.0, Settings.pixelation, 0.05,
		func(v): Settings.pixelation = v)
	_check(left, "Efectos PS1 (grano, scanlines, viñeta)", Settings.ps1_effects,
		func(v): Settings.ps1_effects = v)
	_check(left, "Sombras (lo más caro: apagalas si va lento)", Settings.shadows,
		func(v): Settings.shadows = v)
	_check(left, "Pantalla completa", Settings.fullscreen,
		func(v): Settings.fullscreen = v)
	_check(left, "Invertir eje Y", Settings.invert_y,
		func(v): Settings.invert_y = v)
	_check(left, "Cabeceo al caminar", Settings.head_bob,
		func(v): Settings.head_bob = v)
	_slider(left, "Campo de visión", 60.0, 100.0, Settings.fov, 1.0,
		func(v): Settings.fov = v)
	_slider(left, "Tamaño de subtítulos", 12.0, 28.0, float(Settings.subtitle_size), 1.0,
		func(v): Settings.subtitle_size = int(v))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	cols.add_child(right)
	right.add_child(UIUtils.label(tr("TECLAS"), 14, UIUtils.DIM))
	for entry in Settings.REBINDABLE:
		_rebind_row(right, String(entry[0]), String(entry[1]))
	right.add_child(UIUtils.label(tr("[ESC] cancela la reasignación"), 12, UIUtils.DIM))

	var back := Button.new()
	back.text = tr("Volver")
	back.custom_minimum_size = Vector2(160, 34)
	back.pressed.connect(func():
		Settings.save_settings()
		closed.emit())
	add_child(back)


func _slider(parent: Node, text: String, min_v: float, max_v: float, value: float, step: float, on_change: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var label := UIUtils.label("%s   %.2f" % [text, value], 14, UIUtils.FG)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(320, 18)
	slider.value_changed.connect(func(v: float):
		label.text = "%s   %.2f" % [text, v]
		on_change.call(v)
		Settings.apply())
	row.add_child(slider)
	parent.add_child(row)


func _check(parent: Node, text: String, value: bool, on_change: Callable) -> void:
	var box := CheckBox.new()
	box.text = tr(text)
	box.button_pressed = value
	box.add_theme_color_override("font_color", UIUtils.FG)
	box.toggled.connect(func(v: bool):
		on_change.call(v)
		Settings.apply())
	parent.add_child(box)


func _rebind_row(parent: Node, action: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := UIUtils.label(label_text, 14, UIUtils.FG)
	label.custom_minimum_size.x = 150
	row.add_child(label)
	var button := Button.new()
	button.text = Settings.key_name(action)
	button.custom_minimum_size = Vector2(130, 26)
	button.pressed.connect(func():
		_listening_action = action
		_listening_button = button
		button.text = "esperando...")
	row.add_child(button)
	parent.add_child(row)


func _input(event: InputEvent) -> void:
	if _listening_action == "" or not (event is InputEventKey) or not event.is_pressed():
		return
	var key := event as InputEventKey
	get_viewport().set_input_as_handled()
	if key.keycode != KEY_ESCAPE:
		Settings.rebind(_listening_action, key.physical_keycode)
	if is_instance_valid(_listening_button):
		_listening_button.text = Settings.key_name(_listening_action)
	_listening_action = ""
	_listening_button = null
