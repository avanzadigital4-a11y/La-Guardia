extends CanvasLayer
## Bitacora. Muestra las entradas por noche; las que el protagonista escribio
## sin que el jugador las viviera aparecen marcadas en otro color.
##
## Es un cuaderno, no una pantalla, asi que se dibuja en papel igual que el
## parte del turno. El resto de la interfaz es verde fosforo sobre negro; al
## abrir la bitacora el jugador tiene que sentir que agarro un objeto, no que
## abrio un menu. Y las entradas que el protagonista escribio sin que el
## jugador las viviera pasan a lapicera roja, que sobre papel dice bastante
## mas que el mismo texto en verde.

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

	var hoja := PanelContainer.new()
	hoja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hoja.add_theme_stylebox_override("panel", UIUtils.paper_box())
	col.add_child(hoja)

	var adentro := MarginContainer.new()
	adentro.add_theme_constant_override("margin_left", 30)
	adentro.add_theme_constant_override("margin_right", 30)
	adentro.add_theme_constant_override("margin_top", 24)
	adentro.add_theme_constant_override("margin_bottom", 24)
	hoja.add_child(adentro)

	var hoja_col := VBoxContainer.new()
	hoja_col.add_theme_constant_override("separation", 8)
	adentro.add_child(hoja_col)

	hoja_col.add_child(UIUtils.to_paper(
		UIUtils.label(tr("BITÁCORA DE GUARDIA"), 20, UIUtils.FG), true))
	hoja_col.add_child(UIUtils.to_paper(
		UIUtils.label(tr("Estación Cabo Hueso  ---  registro personal"), 13, UIUtils.FG),
		false, UIUtils.PAPEL_DIM))
	hoja_col.add_child(UIUtils.paper_rule())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hoja_col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	# La ayuda es del juego, no del cuaderno: va afuera de la hoja.
	var hint := UIUtils.label(tr("[TAB] cerrar"), 13, UIUtils.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)

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
			_list.add_child(UIUtils.to_paper(
				UIUtils.label("--- NOCHE %d ---" % n, 14, UIUtils.FG),
				true, UIUtils.PAPEL_DIM))
		var time: String = e.get("time", "")
		var prefix := "%s  " % time if time != "" else ""
		var tinta: Color = UIUtils.PAPEL_ROJO if e.get("wrong", false) else UIUtils.PAPEL_TINTA
		var entry := UIUtils.to_paper(
			UIUtils.label("%s%s" % [prefix, tr(e["text"])], 15, UIUtils.FG), false, tinta)
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
