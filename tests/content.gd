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
