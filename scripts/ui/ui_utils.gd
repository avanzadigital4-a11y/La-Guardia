class_name UIUtils
extends RefCounted
## Estetica compartida de la interfaz: monoespaciada, verde fosforo, sin adornos.

const FG := Color(0.78, 0.84, 0.80)
const DIM := Color(0.45, 0.50, 0.48)
const WARN := Color(0.85, 0.55, 0.35)
const WRONG := Color(0.78, 0.36, 0.36)


static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


static func panel_bg(alpha := 0.86) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.03, 0.035, 0.04, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func grab_ui(open: bool, tree: SceneTree) -> void:
	var player := tree.get_first_node_in_group("player")
	if player and player.has_method("set_frozen"):
		player.set_frozen(open)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
