class_name UIUtils
extends RefCounted
## Estetica compartida de la interfaz: monoespaciada, verde fosforo, sin adornos.
##
## Tipografia. Hasta ahora el comentario de arriba decia "monoespaciada" y era
## mentira: no se seteaba ninguna fuente, asi que todo el juego salia con la
## sans por defecto de Godot. Es limpia, moderna y neutra, o sea exactamente lo
## contrario de lo que pide una estacion antartica noventosa. Era lo que mas
## delataba al proyecto.
##
## Ahora hay dos cortes de la misma superfamilia, que es la forma barata de que
## combinen sin tener que elegir bien:
##
##   MONO  IBM Plex Mono            documentos, bitacora, parte, subtitulos
##   COND  IBM Plex Sans Condensed  titulos, menu, HUD
##
## La mono lee como maquina de escribir y terminal, que es lo que son los
## papeles de la estacion y las transcripciones de radio. La condensada aprieta
## los titulos y deja aire al costado.
##
## Las dos son IBM Plex, licencia SIL OFL 1.1: uso comercial permitido, que es
## la regla del proyecto (ver LICENSE). Los archivos estan en fuentes/.
##
## Se importan sin suavizado (`antialiasing=0`, `subpixel_positioning=0`,
## hinting completo) a proposito: el mundo se filtra con NEAREST y corre a 55 %
## de resolucion interna, asi que un texto suavizado al borde flotaria por
## encima de todo lo demas como si fuera de otro juego.

const MONO := preload("res://fuentes/IBMPlexMono-Regular.ttf")
const MONO_BOLD := preload("res://fuentes/IBMPlexMono-SemiBold.ttf")
const COND := preload("res://fuentes/IBMPlexSansCondensed-Regular.ttf")
const COND_BOLD := preload("res://fuentes/IBMPlexSansCondensed-SemiBold.ttf")

const FG := Color(0.78, 0.84, 0.80)
const DIM := Color(0.45, 0.50, 0.48)
const WARN := Color(0.85, 0.55, 0.35)
const WRONG := Color(0.78, 0.36, 0.36)

## Papel: el parte del turno y la bitacora no son pantallas, son hojas. Todo
## el resto de la interfaz es verde fosforo sobre negro, asi que un documento
## en papel se separa solo, sin necesidad de decir "esto es un papel".
const PAPEL := Color(0.80, 0.78, 0.71)
const PAPEL_TINTA := Color(0.13, 0.12, 0.11)
const PAPEL_DIM := Color(0.38, 0.36, 0.32)
## Lapicera roja. La usa la bitacora para las entradas que el protagonista
## escribio sin que el jugador las viviera.
const PAPEL_ROJO := Color(0.52, 0.16, 0.13)


## Deja la mono como fuente de todo Control que nadie configure a mano. Sin
## esto quedarian con la de Godot los nodos que no pasan por `label()`:
## botones, campos, tooltips, y cualquier cosa que se agregue despues.
static func install_theme() -> void:
	ThemeDB.fallback_font = MONO
	ThemeDB.fallback_font_size = 15


static func label(text: String, size: int, color: Color) -> Label:
	return _label(text, size, color, MONO)


## Titulos y HUD: condensada, que a cuerpo grande no se come el ancho.
static func title(text: String, size: int, color: Color) -> Label:
	return _label(text, size, color, COND_BOLD)


static func _label(text: String, size: int, color: Color, fuente: Font) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


## Un Label ya construido que tiene que pasarse a tinta sobre papel: sin sombra
## negra, que sobre fondo claro se lee como suciedad.
static func to_paper(l: Label, bold := false, tinta := PAPEL_TINTA) -> Label:
	l.add_theme_font_override("font", MONO_BOLD if bold else MONO)
	l.add_theme_color_override("font_color", tinta)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return l


## La hoja: color plano, borde duro, sin esquinas redondeadas. Redondear seria
## de otra decada y de otro genero.
static func paper_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPEL
	sb.border_color = Color(PAPEL_TINTA, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	return sb


## Un renglon impreso, como el de un formulario.
static func paper_rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(PAPEL_TINTA, 0.35)
	r.custom_minimum_size = Vector2(0.0, 1.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


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
