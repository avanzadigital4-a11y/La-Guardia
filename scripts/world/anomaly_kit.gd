# -*- coding: utf-8 -*-
class_name AnomalyKit
extends RefCounted
## Aplica y revierte las anomalias del catalogo. Guarda el estado original de
## lo que toca, asi la estacion arranca "normal" cada noche.

var station: StationBuilder
var _applied := {}


func _init(p_station: StationBuilder) -> void:
	station = p_station


func applied_count() -> int:
	return _applied.size()


func applied_ids() -> Array:
	return _applied.keys()


func is_applied(id: String) -> bool:
	return _applied.has(id)


func apply(id: String) -> bool:
	if _applied.has(id):
		return false
	var entry := AnomalyData.get_anomaly(id)
	if entry.is_empty():
		# Compatibilidad con anomalias viejas definidas como props sueltos.
		if station.props.has(id):
			(station.props[id] as Prop).set_altered(true)
			_applied[id] = {"tipo": "prop"}
			return true
		push_warning("Anomalia desconocida: %s" % id)
		return false

	match String(entry.get("tipo", "")):
		"mover":
			var node := _object(entry)
			if node == null:
				return false
			_applied[id] = {"tipo": "mover", "node": node, "transform": node.transform}
			if entry.has("pos") or entry.has("rot"):
				node.position += entry.get("pos", Vector3.ZERO)
				node.rotation.y += deg_to_rad(float(entry.get("rot", 0.0)))
				if node is Prop:
					(node as Prop).altered = true
			elif node is Prop:
				(node as Prop).set_altered(true)
			else:
				node.rotation.y += deg_to_rad(25.0)
		"faltar":
			var node := _object(entry)
			if node == null:
				return false
			_applied[id] = {"tipo": "visible", "node": node, "visible": node.visible}
			Build.set_active(node, false)
		"aparecer":
			var node := _object(entry)
			if node == null:
				return false
			_applied[id] = {"tipo": "visible", "node": node, "visible": node.visible}
			Build.set_active(node, true)
		"puerta":
			var door_id := String(entry.get("puerta", ""))
			if not station.doors.has(door_id):
				return false
			var door: Door = station.doors[door_id]
			_applied[id] = {"tipo": "puerta", "door": door, "open": door.is_open}
			door.set_open(bool(entry.get("abrir", true)), true)
		"luz":
			var room := String(entry.get("sala_luz", ""))
			if not station.room_lights.has(room):
				return false
			var light: OmniLight3D = station.room_lights[room]
			_applied[id] = {"tipo": "luz", "light": light, "energy": light.light_energy}
			light.light_energy = 0.0
		_:
			return false
	return true


func reset_all() -> void:
	for id in _applied.keys():
		var data: Dictionary = _applied[id]
		match String(data.get("tipo", "")):
			"prop":
				if station.props.has(id):
					(station.props[id] as Prop).set_altered(false)
			"mover":
				var node: Node3D = data["node"]
				if is_instance_valid(node):
					node.transform = data["transform"]
					if node is Prop:
						(node as Prop).altered = false
			"visible":
				var node2: Node3D = data["node"]
				if is_instance_valid(node2):
					Build.set_active(node2, data["visible"])
			"puerta":
				var door: Door = data["door"]
				if is_instance_valid(door):
					door.set_open(data["open"], true)
			"luz":
				var light: OmniLight3D = data["light"]
				if is_instance_valid(light):
					light.light_energy = data["energy"]
	_applied.clear()


func _object(entry: Dictionary) -> Node3D:
	var key := String(entry.get("objeto", ""))
	if not station.objects.has(key):
		push_warning("La anomalia apunta a un objeto que no existe: %s" % key)
		return null
	return station.objects[key]
