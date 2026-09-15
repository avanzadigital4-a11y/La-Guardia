# -*- coding: utf-8 -*-
extends Node
## Genera localizacion/la-guardia.pot con todo el texto que ve el jugador:
## el de las tablas de contenido (tareas, beats, registros, objetos) y el de
## la interfaz (las llamadas a tr() en el código).
##
## Uso:  godot --headless --path . res://tools/exportar_traduccion.tscn
##
## Para traducir: copiar el .pot a localizacion/en.po, completar los msgstr y
## agregarlo en Proyecto > Configuración > Localización.

const OUT := "res://localizacion/la-guardia.pot"
const CODE_DIRS := ["res://scripts"]

var _strings := {}   # texto -> [de donde salio]


func _ready() -> void:
	_from_nights()
	_from_radio_logs()
	_from_inspectables()
	_from_anomalies()
	_from_code()
	_write()
	get_tree().quit(0)


func _add(text: String, source: String) -> void:
	var clean := text.strip_edges()
	if clean == "" or clean.length() < 2:
		return
	if not _strings.has(clean):
		_strings[clean] = []
	if source not in _strings[clean]:
		_strings[clean].append(source)


func _from_nights() -> void:
	for n in NightData.NIGHTS.keys():
		var data: Dictionary = NightData.NIGHTS[n]
		var origin := "noche %s" % n
		_add(String(data.get("title", "")), origin)
		_add(String(data.get("subtitle", "")), origin)
		for t in data.get("tasks", []):
			_add(String(t.get("text", "")), origin + " / tarea")
		var final: Dictionary = data.get("final_task", {})
		if final.has("text"):
			_add(String(final["text"]), origin + " / tarea final")
		for e in data.get("logbook", []) + data.get("logbook_end", []):
			_add(String(e.get("text", "")), origin + " / bitácora")
		for key in data.get("beats", {}).keys():
			for action in data["beats"][key]:
				for field in ["subtitulo", "aviso", "bitacora"]:
					if action.has(field):
						_add(String(action[field]), "%s / beat %s" % [origin, key])


func _from_radio_logs() -> void:
	for id in NightData.RADIO_LOGS.keys():
		var data: Dictionary = NightData.RADIO_LOGS[id]
		_add(String(data.get("label", "")), "registro %s" % id)
		for line in data.get("lines", []):
			_add(String(line), "registro %s" % id)


func _from_inspectables() -> void:
	for id in NightData.INSPECTABLES.keys():
		var data: Dictionary = NightData.INSPECTABLES[id]
		_add(String(data.get("titulo", "")), "objeto %s" % id)
		for night in data.get("textos", {}).keys():
			_add(String(data["textos"][night]), "objeto %s" % id)


## Las lineas del parte del turno: una por anomalia.
func _from_anomalies() -> void:
	for id in AnomalyData.NOTES.keys():
		_add(String(AnomalyData.NOTES[id]), "parte / %s" % id)


## Todo lo que el código pasa por tr("...").
func _from_code() -> void:
	var regex := RegEx.new()
	regex.compile('tr\\("([^"]+)"\\)')
	for dir_path in CODE_DIRS:
		for path in _gd_files(dir_path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f == null:
				continue
			var text := f.get_as_text()
			f.close()
			for m in regex.search_all(text):
				_add(m.get_string(1), path.replace("res://", ""))


func _gd_files(path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := "%s/%s" % [path, name]
		if dir.current_is_dir():
			out.append_array(_gd_files(full))
		elif name.ends_with(".gd"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
	return out


func _write() -> void:
	var lines := PackedStringArray([
		'# La Guardia — plantilla de traducción.',
		'# Generado con tools/exportar_traduccion.tscn. No editar a mano.',
		'msgid ""',
		'msgstr ""',
		'"Content-Type: text/plain; charset=UTF-8\\n"',
		'"Language: es\\n"',
		'',
	])
	var keys := _strings.keys()
	keys.sort()
	for key in keys:
		lines.append("#. %s" % ", ".join(_strings[key]))
		lines.append('msgid "%s"' % String(key).replace('\\', '\\\\').replace('"', '\\"'))
		lines.append('msgstr ""')
		lines.append("")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f == null:
		print("No pude escribir %s" % OUT)
		get_tree().quit(1)
		return
	f.store_string("\n".join(lines))
	f.close()
	print("Escrito %s con %d textos." % [OUT, keys.size()])
