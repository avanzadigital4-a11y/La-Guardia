extends CanvasLayer
## HUD: lista de tareas, prompt de interaccion, bateria, reloj y avisos.

var _tasks_box: VBoxContainer
var _prompt: Label
var _notice: Label
var _clock: Label
var _battery_fill: ColorRect
var _notice_time := 0.0


func _ready() -> void:
	layer = 10
	add_to_group("hud")

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Lista de tareas.
	var tasks_panel := VBoxContainer.new()
	tasks_panel.position = Vector2(28, 24)
	tasks_panel.add_theme_constant_override("separation", 2)
	root.add_child(tasks_panel)
	var header := UIUtils.label(tr("TAREAS DE LA NOCHE"), 13, UIUtils.DIM)
	tasks_panel.add_child(header)
	_tasks_box = VBoxContainer.new()
	_tasks_box.add_theme_constant_override("separation", 2)
	tasks_panel.add_child(_tasks_box)

	# Reloj.
	_clock = UIUtils.label("", 14, UIUtils.DIM)
	_clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock.offset_left = -180.0
	_clock.offset_top = 24.0
	_clock.offset_right = -28.0
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_clock)

	# Mira.
	var dot := ColorRect.new()
	dot.color = Color(0.8, 0.85, 0.82, 0.5)
	dot.size = Vector2(3, 3)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.offset_left = -1.5
	dot.offset_top = -1.5
	dot.offset_right = 1.5
	dot.offset_bottom = 1.5
	root.add_child(dot)

	# Prompt de interaccion.
	_prompt = UIUtils.label("", 15, UIUtils.FG)
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -190.0
	_prompt.offset_bottom = -160.0
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt)

	# Aviso puntual.
	_notice = UIUtils.label("", 15, UIUtils.WARN)
	_notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice.offset_left = -400.0
	_notice.offset_right = 400.0
	_notice.offset_top = 96.0
	_notice.offset_bottom = 126.0
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.modulate.a = 0.0
	root.add_child(_notice)

	# Bateria.
	var bat_label := UIUtils.label(tr("LINTERNA"), 12, UIUtils.DIM)
	bat_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bat_label.offset_left = 28.0
	bat_label.offset_top = -66.0
	bat_label.offset_right = 160.0
	bat_label.offset_bottom = -50.0
	root.add_child(bat_label)

	var bat_bg := ColorRect.new()
	bat_bg.color = Color(0.12, 0.13, 0.13, 0.8)
	bat_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bat_bg.offset_left = 28.0
	bat_bg.offset_top = -46.0
	bat_bg.offset_right = 148.0
	bat_bg.offset_bottom = -36.0
	root.add_child(bat_bg)

	_battery_fill = ColorRect.new()
	_battery_fill.color = Color(0.6, 0.78, 0.6, 0.9)
	_battery_fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_battery_fill.size = Vector2(120, 10)
	bat_bg.add_child(_battery_fill)

	var hint := UIUtils.label(tr("[E] usar   [F] linterna   [TAB] bitácora"), 12, UIUtils.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -360.0
	hint.offset_top = -46.0
	hint.offset_right = -28.0
	hint.offset_bottom = -26.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)

	GameState.tasks_changed.connect(_refresh_tasks)
	GameState.notice.connect(show_notice)
	GameState.battery_changed.connect(_on_battery)
	GameState.night_started.connect(_on_night_started)
	GameState.clock_changed.connect(_on_clock_changed)
	_refresh_tasks()
	_on_battery(GameState.battery)


func _on_night_started(night: int) -> void:
	_on_clock_changed(GameState.clock_override)


## El reloj muestra la hora de la noche, salvo que una anomalia la haya
## corrido. No avisa nada ni cambia de color: si el jugador no venia mirando
## la hora, no se entera, y esa es la idea.
func _on_clock_changed(override: String) -> void:
	var data := NightData.get_night(GameState.current_night)
	var hora: String = override if override != "" else String(data["clock"])
	_clock.text = "%s   %s" % [data["title"], hora]


func _refresh_tasks() -> void:
	for c in _tasks_box.get_children():
		c.queue_free()
	for t in GameState.tasks:
		var mark := "[x]" if t["done"] else "[ ]"
		var color: Color = UIUtils.DIM if t["done"] else UIUtils.FG
		var progress := ""
		if int(t.get("steps", 1)) > 1 and not t["done"]:
			progress = " (%d/%d)" % [t["done_steps"], t["steps"]]
		_tasks_box.add_child(UIUtils.label("%s %s%s" % [mark, tr(t["text"]), progress], 14, color))


func set_prompt(text: String) -> void:
	_prompt.text = "" if text == "" else "[E]  %s" % tr(text)


func show_notice(text: String) -> void:
	_notice.text = tr(text)
	_notice.modulate.a = 1.0
	_notice_time = 4.0


func _on_battery(value: float) -> void:
	_battery_fill.size = Vector2(120.0 * value, 10)
	_battery_fill.color = Color(0.6, 0.78, 0.6, 0.9) if value > 0.25 else Color(0.8, 0.45, 0.35, 0.9)


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time < 1.0:
			_notice.modulate.a = clampf(_notice_time, 0.0, 1.0)
