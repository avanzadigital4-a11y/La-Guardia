# -*- coding: utf-8 -*-
extends Node
## Genera docs/lineas_de_voz.md con todas las líneas a grabar, su nombre de
## archivo y una duración objetivo estimada.
##
## Uso:  godot --headless --path . res://tools/exportar_lineas.tscn

const OUT := "res://docs/lineas_de_voz.md"


func _ready() -> void:
	var total := 0
	var seconds := 0.0
	var text := "# Líneas de voz a grabar\n\n"
	text += "Generado con `godot --headless --path . res://tools/exportar_lineas.tscn`.\n"
	text += "No editar a mano: el texto sale de `scripts/data/night_data.gd`.\n\n"
	text += "Cada archivo va en `audio/voz/` con el nombre de la columna. "
	text += "Si falta, esa línea suena con la voz sintetizada.\n\n"

	var ids := NightData.RADIO_LOGS.keys()
	ids.sort()
	for id in ids:
		var data: Dictionary = NightData.RADIO_LOGS[id]
		text += "## %s — %s\n\n" % [id, data["label"]]
		text += "Aparece a partir de la noche %d.\n\n" % int(data["night"])
		text += "| archivo | duración | línea |\n|---|---|---|\n"
		var lines: Array = data["lines"]
		for i in lines.size():
			var line := String(lines[i])
			var estimate := maxf(2.0, line.length() / 14.0)
			total += 1
			seconds += estimate
			text += "| `%s_%d.ogg` | ~%.1f s | %s |\n" % [id, i + 1, estimate, line]
		text += "\n"

	text += "---\n\n"
	text += "**%d líneas en total, alrededor de %d minutos de audio.**\n" % [total, int(seconds / 60.0) + 1]

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f == null:
		print("No pude escribir %s" % OUT)
		get_tree().quit(1)
		return
	f.store_string(text)
	f.close()
	print("Escrito %s: %d líneas, ~%d minutos." % [OUT, total, int(seconds / 60.0) + 1])
	get_tree().quit(0)
