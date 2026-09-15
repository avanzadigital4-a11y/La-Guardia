# -*- coding: utf-8 -*-
extends Node
## Integridad del contenido: que todo lo que nombran las noches exista de
## verdad en la estacion. Es la red de seguridad para seguir agregando
## anomalias y registros sin romper nada.
##
## Uso:  godot --headless --path . res://tests/content.tscn

var failures: Array[String] = []
var main: Node


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func _run() -> void:
	await get_tree().create_timer(2.0).timeout
	var station: StationBuilder = main.station
	var director: NightDirector = main.director

	# --- Catalogo de anomalias ---
	var broken: Array[String] = []
	for id in AnomalyData.ANOMALIES.keys():
		var a: Dictionary = AnomalyData.ANOMALIES[id]
		if not StationBuilder.ROOMS.has(String(a.get("sala", ""))):
			broken.append("%s: sala '%s'" % [id, a.get("sala", "")])
		match String(a.get("tipo", "")):
			"mover", "faltar", "aparecer":
				if not station.objects.has(String(a.get("objeto", ""))):
					broken.append("%s: objeto '%s'" % [id, a.get("objeto", "")])
			"puerta":
				if not station.doors.has(String(a.get("puerta", ""))):
					broken.append("%s: puerta '%s'" % [id, a.get("puerta", "")])
			"luz":
				if not station.room_lights.has(String(a.get("sala_luz", ""))):
					broken.append("%s: luz '%s'" % [id, a.get("sala_luz", "")])
			_:
				broken.append("%s: tipo desconocido" % id)
	_check(broken.is_empty(), "las %d anomalias apuntan a cosas que existen%s" % [
		AnomalyData.ANOMALIES.size(), "" if broken.is_empty() else ": " + ", ".join(broken)])

	# --- Lo que nombran las noches ---
	var missing: Array[String] = []
	for n in range(1, GameState.MAX_NIGHT + 1):
		var data := NightData.get_night(n)
		for id in data.get("anomalias", []):
			if not AnomalyData.ANOMALIES.has(String(id)):
				missing.append("noche %d: anomalia '%s'" % [n, id])
		for key in data.get("beats", {}).keys():
			for action in data["beats"][key]:
				if action.has("armar") and not AnomalyData.ANOMALIES.has(String(action["armar"])):
					missing.append("noche %d/%s: armar '%s'" % [n, key, action["armar"]])
				if action.has("anomalia") and not AnomalyData.ANOMALIES.has(String(action["anomalia"])):
					missing.append("noche %d/%s: anomalia '%s'" % [n, key, action["anomalia"]])
				if action.has("ruta") and not station.routes.has(String(action["ruta"])):
					missing.append("noche %d/%s: ruta '%s'" % [n, key, action["ruta"]])
				if action.has("puerta") and not station.doors.has(String(action["puerta"])):
					missing.append("noche %d/%s: puerta '%s'" % [n, key, action["puerta"]])
				if action.has("ocultar"):
					for oid in action["ocultar"]:
						if not station.variants.has(String(oid)):
							missing.append("noche %d/%s: ocultar '%s'" % [n, key, oid])
	_check(missing.is_empty(), "las cinco noches nombran cosas que existen%s" % [
		"" if missing.is_empty() else ": " + ", ".join(missing)])

	# --- Tareas: todas se pueden completar con algo del mundo ---
	var resolvable := {
		"sleep": true,          # la cucheta
		"decidir": true,        # los dos puntos de decision
		"logbook_check": true,  # el escritorio
		"puertas": true,        # condicion: todas las puertas cerradas
	}
	for key in station.points.keys():
		var node: Node = station.points[key]
		if node is TaskPoint:
			resolvable[(node as TaskPoint).task_id] = true
		elif node is TriggerZone:
			resolvable[(node as TriggerZone).task_id] = true
		elif node is SensorPanel:
			resolvable[(node as SensorPanel).task_id] = true
		elif node is SuitCounter:
			resolvable[(node as SuitCounter).task_id] = true
		elif node is ReportSheet:
			for tid in (node as ReportSheet).task_ids:
				resolvable[String(tid)] = true
	resolvable["radio_unknown"] = true   # se completa escuchando el registro
	var unreachable: Array[String] = []
	for n in range(1, GameState.MAX_NIGHT + 1):
		for t in NightData.get_night(n)["tasks"]:
			if not resolvable.has(String(t["id"])):
				unreachable.append("noche %d: %s" % [n, t["id"]])
	_check(unreachable.is_empty(), "todas las tareas tienen como resolverse%s" % [
		"" if unreachable.is_empty() else ": " + ", ".join(unreachable)])

	# --- Registros de radio ---
	var logs_ok := true
	var placed := 0
	for id in NightData.RADIO_LOGS.keys():
		var log_data: Dictionary = NightData.RADIO_LOGS[id]
		if not log_data.has("pos") or not log_data.has("night") or log_data.get("lines", []).is_empty():
			logs_ok = false
		if station.points.has("log_%s" % id):
			placed += 1
	_check(logs_ok, "los %d registros tienen lugar, noche y texto" % NightData.RADIO_LOGS.size())
	_check(placed == NightData.RADIO_LOGS.size(), "todos los registros estan colocados en la estacion (%d/%d)" % [
		placed, NightData.RADIO_LOGS.size()])

	# --- Objetos para mirar de cerca ---
	var inspect_ok := true
	for id in NightData.INSPECTABLES.keys():
		var spec: Dictionary = NightData.INSPECTABLES[id]
		if not station.points.has("ver_%s" % id):
			inspect_ok = false
		if not spec.get("textos", {}).has(1):
			inspect_ok = false   # tiene que haber texto desde la noche 1
	_check(inspect_ok, "los %d objetos inspeccionables estan puestos y tienen texto" % NightData.INSPECTABLES.size())
	var placa: Inspectable = station.points["ver_placa"]
	GameState.current_night = 1
	var texto_1 := placa.description()
	GameState.current_night = 5
	var texto_5 := placa.description()
	GameState.current_night = 1
	_check(texto_1 != texto_5 and texto_1 != "" and texto_5 != "",
		"lo que dice un objeto cambia con las noches")

	# --- El parte del turno ---
	var sin_nota: Array[String] = []
	for id in AnomalyData.ANOMALIES.keys():
		if not AnomalyData.NOTES.has(String(id)):
			sin_nota.append(String(id))
	_check(sin_nota.is_empty(), "las %d anomalias tienen su linea para el parte%s" % [
		AnomalyData.ANOMALIES.size(), "" if sin_nota.is_empty() else ": " + ", ".join(sin_nota)])
	var sobran: Array[String] = []
	for id in AnomalyData.NOTES.keys():
		if not AnomalyData.ANOMALIES.has(String(id)):
			sobran.append(String(id))
	_check(sobran.is_empty(), "no hay lineas de parte sin anomalia%s" % [
		"" if sobran.is_empty() else ": " + ", ".join(sobran)])
	_check(station.points.has("parte"), "el parte del turno esta sobre la mesa de control")
	var hoja: ReportSheet = station.points["parte"]

	# Lo que dice la hoja sale de lo que paso en esta partida, no de un guion.
	GameState.anomalies_seen.clear()
	GameState.current_night = 4
	GameState.record_anomaly("gen_puerta")
	GameState.record_anomaly("pasillo_marca")
	var parte := hoja.text_for(4)
	_check(parte.contains(AnomalyData.note("gen_puerta"))
		and parte.contains(AnomalyData.note("pasillo_marca")),
		"el parte de la noche 4 lista lo que de verdad cambio")
	_check(parte.contains("tuya"), "y se lo atribuye al jugador")
	GameState.current_night = 1
	_check(not hoja.text_for(1).contains(AnomalyData.note("gen_puerta")),
		"antes de la noche 4 la hoja esta en blanco")
	GameState.current_night = 5
	GameState.record_anomaly("patio_figura")
	var cierre := hoja.text_for(5)
	_check(cierre.contains(AnomalyData.note("gen_puerta"))
		and cierre.contains(AnomalyData.note("patio_figura")),
		"el inventario de cierre junta las cinco noches")
	GameState.anomalies_seen.clear()
	GameState.current_night = 1

	# --- Aplicar todo y volver atras ---
	for id in AnomalyData.ANOMALIES.keys():
		director.anomalies.apply(String(id))
	_check(director.anomalies.applied_count() == AnomalyData.ANOMALIES.size(),
		"se aplican las %d anomalias juntas" % AnomalyData.ANOMALIES.size())
	var chair: Prop = station.props["dorm_chair"]
	var moved := chair.transform
	director.anomalies.reset_all()
	_check(director.anomalies.applied_count() == 0, "reset_all las revierte todas")
	_check(chair.transform != moved and not chair.altered, "los objetos vuelven a su lugar")

	_report()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  OK    %s" % label)
	else:
		print("  FALLA %s" % label)
		failures.append(label)


func _report() -> void:
	print("")
	if failures.is_empty():
		print("CONTENIDO OK")
	else:
		print("CONTENIDO CON %d FALLAS" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
