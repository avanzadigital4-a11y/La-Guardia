extends CanvasLayer
## Subtitulos de los registros de radio.

var _label: Label
var _timer := 0.0


func _ready() -> void:
	layer = 20
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_left = 120.0
	_label.offset_right = -120.0
	_label.offset_top = -150.0
	_label.offset_bottom = -70.0
	_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_outline_size", 6)
	_label.text = ""
	add_child(_label)
	_apply_size()
	Settings.changed.connect(_apply_size)


func _apply_size() -> void:
	_label.add_theme_font_size_override("font_size", Settings.subtitle_size)


func show_line(text: String, duration := 3.0) -> void:
	_label.text = tr(text)
	_timer = duration


func clear() -> void:
	_label.text = ""
	_timer = 0.0


func _process(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_label.text = ""
