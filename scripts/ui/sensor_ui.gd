extends CanvasLayer
## Panel de sensores. Los valores son una tabla en codigo: facil de tocar,
## y el mapa de niveles es donde aparece (y desaparece) el SUBNIVEL B2.

var _readouts: VBoxContainer
var _map: VBoxContainer
var _t := 0.0
var is_open := false


func _ready() -> void:
	layer = 15
	add_to_group("sensor_ui")
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UIUtils.panel_bg(0.95))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 110)
	margin.add_theme_constant_override("margin_right", 110)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 70)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)
	col.add_child(UIUtils.label("PANEL DE SENSORES  ---  NIVEL 1", 20, UIUtils.FG))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 70)
	col.add_child(cols)
	_readouts = VBoxContainer.new()
	_readouts.add_theme_constant_override("separation", 6)
	cols.add_child(_readouts)
	_map = VBoxContainer.new()
	_map.add_theme_constant_override("separation", 6)
	cols.add_child(_map)

	col.add_child(UIUtils.label("[E] o [ESC] cerrar", 13, UIUtils.DIM))


func open() -> void:
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


func _process(delta: float) -> void:
	if not is_open:
		return
	_t += delta
	if _t > 1.0:
		_t = 0.0
		_refresh()


func _refresh() -> void:
	for c in _readouts.get_children():
		c.queue_free()
	for c in _map.get_children():
		c.queue_free()

	var night := GameState.current_night
	var rows := [
		["TEMPERATURA EXT.", "%.1f C" % (-41.0 - night * 1.3 + randf_range(-0.4, 0.4)), false],
		["VIENTO", "%.0f nudos" % (38.0 + night * 2.0 + randf_range(-3.0, 3.0)), false],
		["PRESIÓN", "%.1f hPa" % (978.0 - night * 2.0 + randf_range(-0.6, 0.6)), false],
		["RADIACIÓN", "%.2f uSv/h" % (0.11 + randf_range(-0.01, 0.01)), false],
		["OCUPACIÓN REGISTRADA", "1 persona", night >= 3],
	]
	if night >= 4:
		rows[4][1] = "0 personas"
	_readouts.add_child(UIUtils.label("LECTURAS", 14, UIUtils.DIM))
	for r in rows:
		var color: Color = UIUtils.WARN if r[2] else UIUtils.FG
		_readouts.add_child(UIUtils.label("%-22s %s" % [r[0], r[1]], 15, color))

	_map.add_child(UIUtils.label("MAPA DE NIVELES", 14, UIUtils.DIM))
	_map.add_child(UIUtils.label("NIVEL 1   habitable      OK", 15, UIUtils.FG))
	_map.add_child(UIUtils.label("NIVEL 0   esclusa/patio  OK", 15, UIUtils.FG))
	_map.add_child(UIUtils.label("SUBNIVEL B1  clausurado  --", 15, UIUtils.DIM))
	var world: Dictionary = NightData.get_night(night)["world"]
	if world.get("subnivel_b2", false):
		_map.add_child(UIUtils.label("SUBNIVEL B2  ?           ??", 15, UIUtils.WRONG))
	elif GameState.get_flag("saw_b2", false):
		_map.add_child(UIUtils.label("SUBNIVEL B2  sin registro", 15, UIUtils.DIM))
