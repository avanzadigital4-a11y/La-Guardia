class_name NightDirector
extends Node
## Aplica el estado del mundo de cada noche, arma las anomalias fuera de
## camara y dispara los beats guionados. Toda la "evolucion del loop" pasa
## por aca: la escena no cambia, cambia lo que esta encendido.

signal night_finished(night: int)

var station: StationBuilder
var player: Player
var fade: CanvasLayer
var env: WorldEnvironment

var _armed: Array = []          # anomalias esperando que el jugador salga
var _pending: Array = []        # definiciones de la noche actual
var _busy := false


func setup(p_station: StationBuilder, p_player: Player, p_fade: CanvasLayer, p_env: WorldEnvironment) -> void:
	station = p_station
	player = p_player
	fade = p_fade
	env = p_env
	GameState.task_completed.connect(_on_task_completed)
	GameState.all_tasks_done.connect(_on_all_tasks_done)
	for id in station.watchers.keys():
		var w: RoomWatcher = station.watchers[id]
		w.player_exited.connect(_on_room_exited)


func start_night(night: int) -> void:
	_armed.clear()
	_pending.clear()
	var data := NightData.get_night(night)
	_apply_world(data["world"], night)
	_pending = data["offscreen"].duplicate(true)

	# Todo vuelve a su lugar: la estacion arranca cada noche "normal".
	for id in station.props.keys():
		(station.props[id] as Prop).set_altered(false)
	for id in station.doors.keys():
		(station.doors[id] as Door).set_open(false, true)
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

	GameState.start_night(night)
	player.teleport(StationBuilder.SPAWN, -PI * 0.5)
	AudioDirector.set_dread(clampf((night - 1) / 4.0, 0.0, 1.0))

	if fade.has_method("show_card"):
		await fade.fade_in(1.8)
		await fade.show_card(data["title"], data["subtitle"], 2.4)


func _apply_world(world: Dictionary, night: int) -> void:
	var has_south: bool = world.get("corridor_south", false)
	Build.set_active(station.south_section, has_south)
	Build.set_active(station.south_wall, not has_south)
	Build.set_active(station.subnivel_section, has_south and world.get("subnivel_b2", false))

	station.recolor_walls(world.get("wall_tint", Color(0.3, 0.3, 0.32)))
	var energy: float = world.get("light_energy", 1.0)
	for l in station.lights:
		if is_instance_valid(l):
			l.light_energy = energy * 2.6

	if env and env.environment:
		env.environment.fog_density = world.get("fog_density", 0.055)
		var dread := clampf((night - 1) / 4.0, 0.0, 1.0)
		env.environment.fog_light_color = Color(0.10, 0.11, 0.13).lerp(Color(0.05, 0.05, 0.07), dread)


func _on_task_completed(id: String) -> void:
	# Arma las anomalias que esperaban esta tarea.
	for a in _pending:
		if String(a.get("after_task", "")) == id:
			_armed.append(a)
	if id == "subnivel":
		GameState.set_flag("saw_b2", true)
	_beat(id)


func _beat(task_id: String) -> void:
	match task_id:
		"generator":
			await get_tree().create_timer(4.0).timeout
			AudioDirector.play_cue("creak", player.global_position + Vector3(0, 2.5, -6), -8.0)
		"round":
			await get_tree().create_timer(2.0).timeout
			_flicker_lights(2.4)
			Subtitles.show_line("(el viento se corta un segundo y vuelve)", 2.6)
		"sensors":
			GameState.notice.emit("El panel marco una lectura de mas y la borro solo.")
		"radio_unknown":
			Subtitles.show_line("(la portadora sigue sonando despues de apagar el equipo)", 3.2)
		"subnivel":
			_flicker_lights(3.0)


func _on_all_tasks_done() -> void:
	if _busy:
		return
	if GameState.is_task_done("sleep") or not GameState.has_task("sleep"):
		_finish_night()
	else:
		GameState.notice.emit("Volve al dormitorio.")


func _on_room_exited(room_id: String) -> void:
	# El jugador salio de la sala: si habia algo armado para este cuarto, se
	# aplica ahora, sin que haya transicion que ver.
	var still: Array = []
	for a in _armed:
		if String(a.get("room", "")) == room_id:
			_apply_anomaly(String(a["id"]))
			_pending.erase(a)
		else:
			still.append(a)
	_armed = still


func _apply_anomaly(id: String) -> void:
	if station.props.has(id):
		(station.props[id] as Prop).set_altered(true)
		return
	match id:
		"corridor_door":
			if station.doors.has("almacen"):
				(station.doors["almacen"] as Door).set_open(true, true)
		_:
			push_warning("Anomalia desconocida: %s" % id)


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
	await fade.show_card("FIN DE LA NOCHE %d" % night, "Dormis con la ropa puesta.", 2.4)
	GameState.save_game()
	player.set_frozen(false)
	_busy = false
	await start_night(night + 1)


func _ending() -> void:
	# Final principal: la radio cierra sin explicar nada.
	await fade.show_card("AMANECE", "Se escucha un motor sobre el hielo.", 3.0)
	var lines := [
		"Base movil a Cabo Hueso. Estamos a dos kilometros.",
		"Confirmen personal en superficie para el retiro.",
		"...",
		"No hay personal asignado a esa estacion desde hace once meses.",
	]
	for line in lines:
		Subtitles.show_line(line, 3.6)
		await get_tree().create_timer(3.8).timeout
	Subtitles.clear()
	await fade.show_card("LA GUARDIA", "fin", 5.0)
