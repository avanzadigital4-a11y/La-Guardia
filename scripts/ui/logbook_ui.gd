extends CanvasLayer
## Bitacora. Muestra las entradas por noche; las que el protagonista escribio
## sin que el jugador las viviera aparecen marcadas en otro color.

var _list: VBoxContainer
var is_open := false


func _ready() -> void:
	layer = 15
	add_to_group("logbook_ui")
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UIUtils.panel_bg(0.93))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)
	col.add_child(UIUtils.label("BITÁCORA DE GUARDIA", 20, UIUtils.FG))
	col.add_child(UIUtils.label("Estación Cabo Hueso  ---  registro personal", 13, UIUtils.DIM))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	col.add_child(UIUtils.label("[TAB] cerrar", 13, UIUtils.DIM))

	GameState.logbook_changed.connect(_refresh)


func _refresh() -> void:
	if not is_inside_tree():
		return
	for c in _list.get_children():
		c.queue_free()
	var last_night := -1
	for e in GameState.logbook:
		var n := int(e["night"])
		if n != last_night:
			last_night = n
			_list.add_child(UIUtils.label("", 8, UIUtils.DIM))
			_list.add_child(UIUtils.label("--- NOCHE %d ---" % n, 14, UIUtils.DIM))
		var time: String = e.get("time", "")
		var prefix := "%s  " % time if time != "" else ""
		var color: Color = UIUtils.WRONG if e.get("wrong", false) else UIUtils.FG
		var entry := UIUtils.label("%s%s" % [prefix, e["text"]], 15, color)
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.custom_minimum_size.x = 900
		_list.add_child(entry)


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_refresh()
	UIUtils.grab_ui(true, get_tree())


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	UIUtils.grab_ui(false, get_tree())


func toggle() -> void:
	if is_open:
		close()
	else:
		open()
