# -*- coding: utf-8 -*-
extends Control
## Menú de inicio: ranuras de guardado, opciones y créditos.

var _main_col: VBoxContainer
var _slots_col: VBoxContainer
var _credits: VBoxContainer
var _options: OptionsPanel
var _pending_delete := 0


func _ready() -> void:
	# Las capturas de depuracion no pasan por el menu. El juego arranca en
	# menu.tscn, asi que la bandera que mira main.gd nunca se ejecutaba: la
	# herramienta documentada en el README no funcionaba desde que existe el
	# menu. Se acepta en singular y en plural porque el README decia una cosa
	# y el codigo otra.
	var args := OS.get_cmdline_user_args()
	if "--capturas" in args or "--capture" in args:
		call_deferred("_play", 1, false)
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_main_col = _panel()
	var title := UIUtils.label(tr("LA GUARDIA"), 40, UIUtils.FG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_col.add_child(title)
	var sub := UIUtils.label(tr("Estación Cabo Hueso  ---  cinco noches"), 14, UIUtils.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_col.add_child(sub)
	_main_col.add_child(UIUtils.label("", 16, UIUtils.DIM))

	_slots_col = _panel()
	_credits = _panel()
	_options = OptionsPanel.new()
	_options.closed.connect(func(): _show(_main_col))
	var opt_center := CenterContainer.new()
	opt_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(opt_center)
	opt_center.add_child(_options)

	_button(_main_col, "Jugar", func():
		_refresh_slots()
		_show(_slots_col))
	_button(_main_col, "Opciones", func(): _show(_options))
	_button(_main_col, "Créditos", func(): _show(_credits))
	_button(_main_col, "Salir", func(): get_tree().quit())

	_build_credits()
	_refresh_slots()
	_show(_main_col)

	var hint := UIUtils.label(tr("[WASD] moverse   [E] usar   [F] linterna   [TAB] bitácora   [F3] rendimiento"), 12, UIUtils.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -46.0
	hint.offset_bottom = -26.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _panel() -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	center.add_child(col)
	return col


func _show(which: Control) -> void:
	for node in [_main_col, _slots_col, _credits, _options]:
		if node != null:
			node.visible = node == which


func _button(parent: Node, text: String, on_press: Callable, width := 320) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(width, 36)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


func _refresh_slots() -> void:
	for c in _slots_col.get_children():
		c.queue_free()
	var title := UIUtils.label(tr("PARTIDAS"), 20, UIUtils.FG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots_col.add_child(title)

	for i in range(1, GameState.SLOTS + 1):
		var info := GameState.slot_info(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_slots_col.add_child(row)

		var label := "Ranura %d  ---  vacía, empezar de cero" % i
		if info["usado"]:
			var estado := "a mitad de la noche" if info.get("en_curso", false) else "noche terminada"
			label = "Ranura %d  ---  Noche %d, %s   %s" % [i, info["noche"], estado, info["fecha"]]
		var slot_number := i
		_button(row, label, func(): _play(slot_number, info["usado"]), 520)

		if info["usado"]:
			var del := _button(row, "Borrar", func():
				_pending_delete = slot_number
				_refresh_slots(), 100)
			del.add_theme_color_override("font_color", UIUtils.WRONG)

	if _pending_delete > 0:
		var confirm := HBoxContainer.new()
		confirm.add_theme_constant_override("separation", 8)
		_slots_col.add_child(confirm)
		confirm.add_child(UIUtils.label("¿Borrar la ranura %d? No se puede deshacer." % _pending_delete, 14, UIUtils.WRONG))
		_button(confirm, "Sí, borrar", func():
			GameState.delete_slot(_pending_delete)
			_pending_delete = 0
			_refresh_slots(), 120)
		_button(confirm, "No", func():
			_pending_delete = 0
			_refresh_slots(), 80)

	_slots_col.add_child(UIUtils.label("", 10, UIUtils.DIM))
	_button(_slots_col, "Volver", func(): _show(_main_col), 160)


func _play(slot: int, used: bool) -> void:
	GameState.reset()
	GameState.slot = slot
	if used:
		GameState.load_game(slot)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_credits() -> void:
	var title := UIUtils.label(tr("CRÉDITOS"), 20, UIUtils.FG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits.add_child(title)
	_credits.add_child(UIUtils.label("", 10, UIUtils.DIM))
	for line in [
		"Diseño y dirección          ---",
		"Programación                ---",
		"Arte                        ---",
		"Voces de los registros      ---",
		"",
		"Motor                       Godot 4 (renderizador Compatibility)",
		"Audio                       sintetizado en tiempo real",
		"",
		"La estación Cabo Hueso es ficticia.",
		"Cualquier parecido con una base real es casualidad.",
	]:
		_credits.add_child(UIUtils.label(line, 14, UIUtils.FG if line != "" else UIUtils.DIM))
	_credits.add_child(UIUtils.label("", 10, UIUtils.DIM))
	_button(_credits, "Volver", func(): _show(_main_col), 160)
