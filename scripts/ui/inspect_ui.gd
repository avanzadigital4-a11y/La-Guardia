# -*- coding: utf-8 -*-
extends CanvasLayer
## Texto que acompaña a un objeto mientras se lo mira de cerca.
##
## Dos disposiciones, porque hay dos cosas distintas que mostrar:
##
## - "pie de foto": el objeto ocupa la pantalla y el texto es una linea al
##   pie (la chapa, la foto, la taza).
## - "documento": el texto ES el objeto (el parte del turno). Se arma con
##   contenedores, igual que la bitacora, en vez de posicionar a mano: el
##   alto de linea depende de la fuente de cada maquina, asi que una hoja
##   larga tiene que acomodarse sola y poder scrollearse si no entra.

const HINT := "mové el mouse para girarlo   ---   [E] dejarlo"

var _caption: Control
var _title: Label
var _desc: Label

var _document: Control
var _doc_title: Label
var _doc_text: Label
var _doc_scroll: ScrollContainer


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

	root.add_child(_build_caption())
	root.add_child(_build_document())


## Pie de foto: el texto no compite con el objeto, se queda abajo.
func _build_caption() -> Control:
	_caption = Control.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_title = UIUtils.label("", 18, UIUtils.FG)
	_title.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_title.offset_left = 140.0
	_title.offset_right = -140.0
	_title.offset_top = -190.0
	_title.offset_bottom = -160.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_child(_title)

	_desc = UIUtils.label("", 15, UIUtils.DIM)
	_desc.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_desc.offset_left = 180.0
	_desc.offset_right = -180.0
	_desc.offset_top = -156.0
	_desc.offset_bottom = -60.0
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_child(_desc)

	var hint := UIUtils.label(HINT, 12, UIUtils.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -48.0
	hint.offset_bottom = -28.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_child(hint)
	return _caption


## Documento: la hoja se lee entera, con los mismos margenes que la bitacora.
##
## Y se ve como una hoja. Antes era texto verde flotando sobre el fondo oscuro,
## igual que el HUD y que el menu, asi que el parte del turno no se distinguia
## de cualquier otro cartel del juego. Es el objeto que sostiene el giro del
## final: tiene que leerse como papel que alguien escribio a maquina, no como
## una pantalla mas.
func _build_document() -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 150)
	margin.add_theme_constant_override("margin_right", 150)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	_document = margin

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var hoja := PanelContainer.new()
	hoja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoja.add_theme_stylebox_override("panel", UIUtils.paper_box())
	col.add_child(hoja)

	var adentro := MarginContainer.new()
	adentro.add_theme_constant_override("margin_left", 30)
	adentro.add_theme_constant_override("margin_right", 30)
	adentro.add_theme_constant_override("margin_top", 24)
	adentro.add_theme_constant_override("margin_bottom", 24)
	hoja.add_child(adentro)

	var hoja_col := VBoxContainer.new()
	hoja_col.add_theme_constant_override("separation", 10)
	adentro.add_child(hoja_col)

	_doc_title = UIUtils.to_paper(UIUtils.label("", 18, UIUtils.FG), true)
	hoja_col.add_child(_doc_title)

	hoja_col.add_child(UIUtils.paper_rule())

	_doc_scroll = ScrollContainer.new()
	_doc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hoja_col.add_child(_doc_scroll)

	_doc_text = UIUtils.to_paper(UIUtils.label("", 15, UIUtils.FG))
	_doc_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_doc_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_doc_scroll.add_child(_doc_text)

	# La ayuda no va impresa en la hoja: es del juego, no del documento.
	var hint := UIUtils.label(HINT, 12, UIUtils.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	return margin


func open(title: String, description: String) -> void:
	var as_document := description.count("\n") >= 2
	if as_document:
		_doc_title.text = tr(title)
		_doc_text.text = tr(description)
		_doc_scroll.scroll_vertical = 0
	else:
		_title.text = tr(title)
		_desc.text = tr(description)
	_caption.visible = not as_document
	_document.visible = as_document
	visible = true


func close() -> void:
	visible = false


## Para la suite de UI: donde quedo cada cosa de la hoja, en coordenadas de
## pantalla. Sirve para verificar que el titulo no se monte sobre el texto y
## que nada se derrame fuera del viewport, sea cual sea la fuente.
func document_rects() -> Dictionary:
	return {
		"titulo": _doc_title.get_global_rect(),
		"texto": _doc_scroll.get_global_rect(),
		"pedido": _doc_text.get_combined_minimum_size(),
		"pantalla": get_viewport().get_visible_rect(),
	}
