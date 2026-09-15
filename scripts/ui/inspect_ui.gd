# -*- coding: utf-8 -*-
extends CanvasLayer
## Texto que acompaña a un objeto mientras se lo mira de cerca.

var _title: Label
var _desc: Label


func _ready() -> void:
	layer = 12
	add_to_group("inspect_ui")
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var vig := ColorRect.new()
	vig.color = Color(0.02, 0.02, 0.03, 0.55)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vig)

	_title = UIUtils.label("", 18, UIUtils.FG)
	_title.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_title.offset_left = 140.0
	_title.offset_right = -140.0
	_title.offset_top = -190.0
	_title.offset_bottom = -160.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title)

	_desc = UIUtils.label("", 15, UIUtils.DIM)
	_desc.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_desc.offset_left = 180.0
	_desc.offset_right = -180.0
	_desc.offset_top = -156.0
	_desc.offset_bottom = -60.0
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_desc)

	var hint := UIUtils.label("mové el mouse para girarlo   ---   [E] dejarlo", 12, UIUtils.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -48.0
	hint.offset_bottom = -28.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


## `document`: el texto es una hoja escrita, no un pie de foto. Se alinea a la
## izquierda y ocupa el centro de la pantalla, que es como se lee un parte.
func open(title: String, description: String) -> void:
	_title.text = tr(title)
	_desc.text = tr(description)
	var document := description.count("\n") >= 2
	if document:
		_desc.offset_left = 210.0
		_desc.offset_right = -210.0
		_desc.offset_top = -420.0
		_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_desc.autowrap_mode = TextServer.AUTOWRAP_OFF
	else:
		_desc.offset_left = 180.0
		_desc.offset_right = -180.0
		_desc.offset_top = -156.0
		_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	visible = true


func close() -> void:
	visible = false
