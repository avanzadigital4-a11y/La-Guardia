class_name OptionsPanel
extends VBoxContainer
## Controles de opciones, compartidos por el menu de inicio y la pausa.

signal closed()


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	add_child(UIUtils.label("OPCIONES", 20, UIUtils.FG))

	_slider("Sensibilidad del mouse", 0.2, 3.0, Settings.mouse_sensitivity, 0.05,
		func(v): Settings.mouse_sensitivity = v)
	_slider("Volumen", 0.0, 1.0, Settings.master_volume, 0.05,
		func(v): Settings.master_volume = v)
	_slider("Pixelado (resolucion interna)", 0.25, 1.0, Settings.pixelation, 0.05,
		func(v): Settings.pixelation = v)
	_check("Efectos PS1 (grano, scanlines, vineta)", Settings.ps1_effects,
		func(v): Settings.ps1_effects = v)

	var back := Button.new()
	back.text = "Volver"
	back.custom_minimum_size = Vector2(160, 34)
	back.pressed.connect(func():
		Settings.save_settings()
		closed.emit())
	add_child(back)


func _slider(text: String, min_v: float, max_v: float, value: float, step: float, on_change: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var label := UIUtils.label("%s   %.2f" % [text, value], 14, UIUtils.FG)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(340, 18)
	slider.value_changed.connect(func(v: float):
		label.text = "%s   %.2f" % [text, v]
		on_change.call(v)
		Settings.apply())
	row.add_child(slider)
	add_child(row)


func _check(text: String, value: bool, on_change: Callable) -> void:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = value
	box.add_theme_color_override("font_color", UIUtils.FG)
	box.toggled.connect(func(v: bool):
		on_change.call(v)
		Settings.apply())
	add_child(box)
