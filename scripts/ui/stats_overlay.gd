# -*- coding: utf-8 -*-
extends CanvasLayer
## Estadísticas de rendimiento, con [F3]. Están para poder medir en la máquina
## objetivo (gama baja) en vez de estimar.

var _label: Label
var _samples: Array[float] = []
var _timer := 0.0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("stats_overlay")
	_label = UIUtils.label("", 13, Color(0.7, 0.85, 0.7))
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -320.0
	_label.offset_top = 56.0
	_label.offset_right = -20.0
	_label.offset_bottom = 200.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_label)
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if (event as InputEventKey).physical_keycode == KEY_F3:
			visible = not visible
			_samples.clear()


func _process(delta: float) -> void:
	if not visible:
		return
	var fps := Engine.get_frames_per_second()
	_samples.append(float(fps))
	if _samples.size() > 240:
		_samples.pop_front()
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.25

	var avg := 0.0
	var low := 9999.0
	for v in _samples:
		avg += v
		low = minf(low, v)
	avg /= maxf(_samples.size(), 1)

	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var vram := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)

	_label.text = "\n".join([
		"FPS  %d   (prom %d, min %d)" % [fps, int(avg), int(low)],
		"frame  %.1f ms" % (delta * 1000.0),
		"draw calls  %d" % draw_calls,
		"primitivas  %d" % primitives,
		"VRAM  %.1f MB" % (float(vram) / 1048576.0),
		"escala 3D  %.2f" % Settings.pixelation,
		"objetos  %d" % Performance.get_monitor(Performance.OBJECT_COUNT),
	])
