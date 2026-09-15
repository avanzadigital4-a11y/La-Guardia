# -*- coding: utf-8 -*-
class_name ReportSheet
extends Inspectable
## El parte del turno: la hoja donde el protagonista anota lo que hizo.
##
## Es el unico lugar donde el juego le muestra al jugador, en limpio, que las
## anomalias las causo el. Y no lo hace con texto guionado: lee lo que
## realmente paso en esta partida (`GameState.anomalies_seen`) y lo devuelve
## en primera persona y en pasado, con una hora anterior a la que el jugador
## lo esta leyendo. Dos partidas no leen el mismo parte.
##
## Noches 1 a 3: la hoja esta en blanco, para que el objeto ya sea parte del
## escritorio cuando la Noche 4 lo use.

const MAX_ENTRADAS := 5        # cuantas entradas muestra el parte de una noche
const MAX_ENTRADAS_CIERRE := 12   # cuantas muestra el inventario de la Noche 5

## La Noche 4 lo firma y la Noche 5 lo cierra: es la misma hoja.
@export var task_ids: PackedStringArray = ["parte", "inventario"]


func get_prompt() -> String:
	if GameState.current_night >= 4:
		return "Leer el parte del turno"
	return "Mirar el parte del turno"


func description() -> String:
	return text_for(GameState.current_night)


func _on_interact(who: Node) -> void:
	super._on_interact(who)
	for id in task_ids:
		if GameState.is_task_active(id):
			GameState.complete_task(id)
			return


## El texto entero de la hoja para una noche. No es static porque cada linea
## pasa por tr(), y tr() es un metodo del objeto.
func text_for(night: int) -> String:
	if night >= GameState.MAX_NIGHT:
		return _closing_text()
	if night >= 4:
		return _night_text(night)
	return tr("Hoja del parte del turno. En blanco.") + "\n" + tr("Se firma al final de los cinco días.")


## Parte de una noche: lo que cambio esta noche, con hora y en primera
## persona. Si el jugador lo lee antes de que haya pasado gran cosa, se
## completa con lo de las noches anteriores para que la hoja nunca este vacia.
func _night_text(night: int) -> String:
	var ids := GameState.anomalies_of_night(night)
	var out := PackedStringArray()
	out.append(tr("PARTE DEL TURNO — NOCHE %d") % night)
	out.append(tr("Ya está completo. La letra es tuya."))
	out.append("")

	var clock := _clock_of(night)
	var shown := 0
	for id in ids:
		if shown >= MAX_ENTRADAS:
			break
		out.append("%s   %s" % [_stamp(clock, shown), tr(AnomalyData.note(String(id)))])
		shown += 1

	if shown < 2:
		# Todavia no paso casi nada esta noche: la hoja arrastra lo de antes.
		for n in range(night - 1, 0, -1):
			for id in GameState.anomalies_of_night(n):
				if shown >= MAX_ENTRADAS:
					break
				out.append("%s   %s" % [_stamp(_clock_of(n), shown), tr(AnomalyData.note(String(id)))])
				shown += 1
			if shown >= MAX_ENTRADAS:
				break

	if shown == 0:
		out.append(tr("No hay anotaciones todavía. La firma sí está."))
	out.append("")
	out.append(tr("Firmado a las %s. Antes de que pasara nada de esto.") % clock)
	return "\n".join(out)


## Inventario de cierre: las cinco noches juntas. Es la ultima vez que el
## juego le pone numero a lo que hizo el jugador.
func _closing_text() -> String:
	var out := PackedStringArray()
	out.append(tr("INVENTARIO DE CIERRE — CINCO NOCHES"))
	out.append("")
	var total := 0
	var shown := 0
	for n in range(1, GameState.MAX_NIGHT + 1):
		var ids := GameState.anomalies_of_night(n)
		total += ids.size()
		if ids.is_empty() or shown >= MAX_ENTRADAS_CIERRE:
			continue
		out.append(tr("NOCHE %d") % n)
		var i := 0
		for id in ids:
			if shown >= MAX_ENTRADAS_CIERRE:
				break
			out.append("  %s   %s" % [_stamp(_clock_of(n), i), tr(AnomalyData.note(String(id)))])
			i += 1
			shown += 1
	out.append("")
	if total == 0:
		out.append(tr("La hoja está firmada y no dice nada más."))
	elif total > shown:
		out.append(tr("Y %d más. Las %d con la misma letra.") % [total - shown, total])
	else:
		out.append(tr("%d anotaciones. Las %d con la misma letra.") % [total, total])
	return "\n".join(out)


func _clock_of(night: int) -> String:
	return String(NightData.get_night(night).get("clock", "23:00"))


## Una hora plausible para la entrada numero `index`, contando desde el
## arranque de la noche. Siempre queda antes del momento en que el jugador
## lee la hoja: el parte se escribio primero.
func _stamp(clock: String, index: int) -> String:
	var parts := clock.split(":")
	var minutes := 0
	if parts.size() == 2:
		minutes = int(parts[0]) * 60 + int(parts[1])
	minutes = (minutes + (index + 1) * 13) % (24 * 60)
	return "%02d:%02d" % [minutes / 60, minutes % 60]
