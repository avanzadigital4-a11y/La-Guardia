extends CanvasLayer
## Fundidos y placas de titulo entre noches.

var _rect: ColorRect
var _title: Label
var _subtitle: Label


func _ready() -> void:
	layer = 30
	add_to_group("screen_fade")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 1)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_rect)

	_title = UIUtils.label("", 30, UIUtils.FG)
	_title.set_anchors_preset(Control.PRESET_CENTER)
	_title.offset_left = -400.0
	_title.offset_right = 400.0
	_title.offset_top = -40.0
	_title.offset_bottom = -4.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title)

	_subtitle = UIUtils.label("", 16, UIUtils.DIM)
	_subtitle.set_anchors_preset(Control.PRESET_CENTER)
	_subtitle.offset_left = -400.0
	_subtitle.offset_right = 400.0
	_subtitle.offset_top = 6.0
	_subtitle.offset_bottom = 34.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_subtitle)


func fade_out(duration := 1.2) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, duration)
	await tw.finished


func fade_in(duration := 1.6) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 0.0, duration)
	await tw.finished


func show_card(title: String, subtitle: String, hold := 2.6) -> void:
	_title.text = tr(title)
	_subtitle.text = tr(subtitle)
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_title, "modulate:a", 1.0, 0.8)
	tw.tween_property(_subtitle, "modulate:a", 1.0, 0.8)
	await get_tree().create_timer(hold).timeout
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_title, "modulate:a", 0.0, 0.8)
	tw2.tween_property(_subtitle, "modulate:a", 0.0, 0.8)
	await tw2.finished
