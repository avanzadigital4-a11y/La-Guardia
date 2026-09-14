class_name NightDirector
extends Node
## Aplica el estado del mundo de cada noche, interpreta los beats guionados y
## arma las anomalias fuera de camara. Toda la "evolucion del loop" pasa por
## aca: la escena no cambia, cambia lo que esta encendido.

signal night_finished(night: int)

var station: StationBuilder
var player: Player
var fade: CanvasLayer
var env: WorldEnvironment

var _armed: Array = []      # anomalias esperando que el jugador salga de una sala
var _busy := false
var anomalies: AnomalyKit
var _door_check := 0.0
var _doors_touched := false


func setup(p_station: StationBuilder, p_player: Player, p_fade: CanvasLayer, p_env: WorldEnvironment) -> void:
	station = p_station
	anomalies = AnomalyKit.new(p_station)
	player = p_player
	fade = p_fade
	env = p_env
	GameState.task_completed.connect(_on_task_completed)
	GameState.all_tasks_done.connect(_on_all_tasks_done)
	for id in station.watchers.keys():
		var w: RoomWatcher = station.watchers[id]
		w.player_exited.connect(_on_room_exited)
	for id in station.routes.keys():
		var r: RouteSwap = station.routes[id]
		r.swapped.connect(_on_route_swapped.bind(id))
		r.exhausted.connect(_on_route_exhausted.bind(id))
	AudioDirector.set_ambient_points(station.ambient_points())


func start_night(night: int) -> void:
	_armed.clear()
	_doors_touched = false
	anomalies.reset_all()
	var data := NightData.get_night(night)
	_apply_world(data["world"], night)

	# Todo vuelve a su lugar: la estacion arranca cada noche "normal".
	for id in station.props.keys():
		(station.props[id] as Prop).set_altered(false)
	for id in station.doors.keys():
		(station.doors[id] as Door).set_open(false, true)
	for id in station.routes.keys():
		var r: RouteSwap = station.routes[id]
		r.active = false
		r.times = 0
	for key in station.points.keys():
		var node: Node = station.points[key]
		if node is TriggerZone:
			(node as TriggerZone).active = true
	for bat in station.pickups:
		bat.restock()
	for key in station.points.keys():
		var pt: Node = station.points[key]
		if pt is TaskPoint:
			(pt as TaskPoint).reset_point()
	station.doors["almacen"].locked = data["world"].get("door_storage_locked", false)
	station.doors["almacen"].locked_text = "Trabada. La llave figura en el inventario del turno anterior."

	# Registros de radio segun la noche.
	for key in station.points.keys():
		if String(key).begins_with("log_"):
			var node: Node3D = station.points[key]
			var from_night: int = int(node.get_meta("from_night", 1))
			node.visible = night >= from_night
			if node is Interactable:
				(node as Interactable).enabled = night >= from_night

	# La senal desconocida de la noche 2 se rastrea escuchandola entera.
	if station.points.has("log_rl_03"):
		(station.points["log_rl_03"] as RadioLog).task_id = "radio_unknown"

	# Lote de anomalias de la noche: cada una espera a que el jugador salga de
	# la sala que le toca.
	for id in data.get("anomalias", []):
		var entry := AnomalyData.get_anomaly(String(id))
		_armed.append({"id": String(id), "room": String(entry.get("sala", ""))})

	GameState.start_night(night)
	player.teleport(StationBuilder.SPAWN, -PI * 0.5)
	AudioDirector.set_dread(clampf((night - 1) / 4.0, 0.0, 1.0))

	if fade.has_method("show_card"):
		await fade.fade_in(1.8)
		await fade.show_card(data["title"], data["subtitle"], 2.4)
	await _run_actions(NightData.beats_for(night, "inicio"))


func _apply_world(world: Dictionary, night: int) -> void:
	var has_south: bool = world.get("corridor_south", false)
	Build.set_active(station.south_section, has_south)
	Build.set_active(station.south_wall, not has_south)
	Build.set_active(station.subnivel_section, has_south and world.get("subnivel_b2", false))

	# Objetos que esta noche no estan (los trajes de la esclusa, por ejemplo).
	var hidden: Array = world.get("hidden", [])
	for id in station.variants.keys():
		Build.set_active(station.variants[id], id not in hidden)

	station.recolor_walls(world.get("wall_tint", Color(0.3, 0.3, 0.32)))
	var energy: float = world.get("light_energy", 1.0)
	for l in station.lights:
		if is_instance_valid(l):
			l.light_energy = energy * 2.6

	if env and env.environment:
		env.environment.fog_density = world.get("fog_density", 0.04)
		var dread := clampf((night - 1) / 4.0, 0.0, 1.0)
		env.environment.fog_light_color = Color(0.10, 0.11, 0.13).lerp(Color(0.05, 0.05, 0.07), dread)


## Tarea por condicion: no se resuelve con [E] sobre nada, se resuelve
## dejando la estacion como tiene que quedar. Y las anomalias abren puertas.
func _process(delta: float) -> void:
	_door_check -= delta
	if _door_check > 0.0:
		return
	_door_check = 0.5
	if not GameState.is_task_active("puertas"):
		return
	var any_open := false
	for id in station.doors.keys():
		if (station.doors[id] as Door).is_open:
			any_open = true
			break
	if any_open:
		# Recien cuenta cuando el jugador efectivamente anduvo abriendo cosas.
		_doors_touched = true
		return
	if not _doors_touched:
		return
	GameState.complete_task("puertas")
	GameState.add_log("", "Todo cerrado. Revisé una por una.", false)


func _on_task_completed(id: String) -> void:
	if id == "subnivel":
		GameState.set_flag("saw_b2", true)
	await _run_actions(NightData.beats_for(GameState.current_night, id))


## Interprete de beats. El contenido esta en night_data.gd; aca solo se
## ejecuta, para que agregar una noche no implique tocar codigo.
func _run_actions(actions: Array) -> void:
	for a in actions:
		var action: Dictionary = a
		if action.has("esperar"):
			await get_tree().create_timer(float(action["esperar"])).timeout
		if action.has("subtitulo"):
			Subtitles.show_line(String(action["subtitulo"]), float(action.get("tiempo", 3.0)))
			await get_tree().create_timer(float(action.get("tiempo", 3.0)) + 0.2).timeout
		if action.has("aviso"):
			GameState.notice.emit(String(action["aviso"]))
		if action.has("parpadeo"):
			await _flicker_lights(float(action["parpadeo"]))
		if action.has("sonido"):
			AudioDirector.play_cue(String(action["sonido"]), player.global_position, float(action.get("db", -8.0)))
		if action.has("bitacora"):
			GameState.add_log(String(action.get("hora", "")), String(action["bitacora"]), bool(action.get("falsa", false)))
		if action.has("anomalia"):
			_apply_anomaly(String(action["anomalia"]))
		if action.has("armar"):
			var aid := String(action["armar"])
			var room := String(action.get("sala", AnomalyData.get_anomaly(aid).get("sala", "")))
			_armed.append({"id": aid, "room": room})
		if action.has("ruta") and station.routes.has(action["ruta"]):
			var r: RouteSwap = station.routes[action["ruta"]]
			r.active = bool(action.get("activa", true))
		if action.has("puerta") and station.doors.has(action["puerta"]):
			(station.doors[action["puerta"]] as Door).set_open(bool(action.get("abrir", true)), true)
		if action.has("ocultar"):
			for id in action["ocultar"]:
				if station.variants.has(id):
					Build.set_active(station.variants[id], false)


func _on_all_tasks_done() -> void:
	if _busy:
		return
	if GameState.pending_tasks() == 0:
		_finish_night()


func _on_room_exited(room_id: String) -> void:
	# El jugador salio de la sala: si habia algo armado para este cuarto, se
	# aplica ahora, sin que haya transicion que ver.
	var still: Array = []
	for a in _armed:
		if String(a.get("room", "")) == room_id:
			_apply_anomaly(String(a["id"]))
		else:
			still.append(a)
	_armed = still


func _apply_anomaly(id: String) -> void:
	anomalies.apply(id)


func _on_route_swapped(times: int, route_id: String) -> void:
	if route_id == "pasillo_sur":
		Subtitles.show_line("(estás de nuevo en la entrada del pasillo)", 2.8)
		if times == 1:
			GameState.add_log("", "Caminé el pasillo sur hasta el fondo y salí de nuevo por la entrada.", true)
	elif route_id == "puerta_dormitorio":
		Subtitles.show_line("(esta no es tu pieza)", 3.0)
		GameState.notice.emit("Entraste al dormitorio y saliste en el almacén.")


func _on_route_exhausted(route_id: String) -> void:
	if route_id == "pasillo_sur":
		Subtitles.show_line("(esta vez el pasillo termina donde debería)", 3.0)


func _flicker_lights(duration: float) -> void:
	var lights := station.lights.duplicate()
	var t := 0.0
	while t < duration:
		var dt: float = randf_range(0.04, 0.16)
		await get_tree().create_timer(dt).timeout
		t += dt
		for l in lights:
			if is_instance_valid(l):
				l.light_energy = randf_range(0.1, 1.6)
	var world: Dictionary = NightData.get_night(GameState.current_night)["world"]
	for l in lights:
		if is_instance_valid(l):
			l.light_energy = float(world.get("light_energy", 1.0)) * 2.6


func _finish_night() -> void:
	if _busy:
		return
	_busy = true
	player.set_frozen(true)
	await fade.fade_out(1.6)
	GameState.end_night()
	var night := GameState.current_night
	if night >= GameState.MAX_NIGHT:
		await _ending()
		night_finished.emit(night)
		_busy = false
		return
	await fade.show_card("FIN DE LA NOCHE %d" % night, "Dormís con la ropa puesta.", 2.4)
	GameState.save_game()
	player.set_frozen(false)
	_busy = false
	await start_night(night + 1)


func _ending() -> void:
	var choice := String(GameState.get_flag("ending", "salir"))
	if choice == "quedarse":
		await _ending_stay()
	else:
		await _ending_leave()
	await fade.show_card("LA GUARDIA", "fin", 5.0)


## Final principal: la radio cierra sin explicar nada.
func _ending_leave() -> void:
	await fade.show_card("AMANECE", "Se escucha un motor sobre el hielo.", 3.0)
	var lines := [
		"Base móvil a Cabo Hueso. Estamos a dos kilómetros.",
		"Confirmen personal en superficie para el retiro.",
		"...",
		"No hay personal asignado a esa estación desde hace once meses.",
	]
	if GameState.radio_logs_found.size() >= NightData.RADIO_LOGS.size():
		lines.append("Y las grabaciones que dejaron ahí son todas de la misma voz.")
	await _speak(lines)


## Variante menor: el jugador decide no salir.
func _ending_stay() -> void:
	await fade.show_card("ABAJO", "La escotilla cierra desde adentro.", 3.0)
	await _speak([
		"Base móvil a Cabo Hueso. Estamos en el patio.",
		"No hay nadie en superficie. Repetimos: no hay nadie.",
		"Dejen la puerta como está.",
	])


func _speak(lines: Array) -> void:
	for line in lines:
		Subtitles.show_line(String(line), 3.6)
		await get_tree().create_timer(3.8).timeout
	Subtitles.clear()
