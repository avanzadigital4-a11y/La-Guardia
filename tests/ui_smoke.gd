extends Node
## Prueba de humo de la interfaz: menu de inicio, opciones y pausa.
##
## Uso:  godot --headless --path . res://tests/ui_smoke.tscn
## Con  -- --capture  ademas guarda una captura del menu en user://.

var failures: Array[String] = []


func _ready() -> void:
	_run()


func _run() -> void:
	# --- Menu de inicio ---
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var buttons := _find_buttons(menu)
	_check(buttons.size() >= 4, "el menu tiene sus cuatro opciones (%d)" % buttons.size())
	var names: Array[String] = []
	for b in buttons:
		names.append(b.text)
	_check("Nueva partida" in names and "Continuar" in names, "estan nueva partida y continuar")
	var cont: Button = buttons[names.find("Continuar")]
	_check(cont.disabled == not FileAccess.file_exists(GameState.SAVE_PATH),
		"continuar solo esta disponible si hay partida guardada")

	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.6).timeout
		for i in 3:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shot_menu.png")

	# --- Opciones: se aplican y persisten ---
	var previous := Settings.mouse_sensitivity
	Settings.mouse_sensitivity = 1.7
	Settings.master_volume = 0.42
	Settings.apply()
	Settings.save_settings()
	Settings.mouse_sensitivity = 0.0
	Settings.load_settings()
	_check(is_equal_approx(Settings.mouse_sensitivity, 1.7), "las opciones se guardan y se releen")
	_check(AudioServer.get_bus_volume_db(0) < 0.0, "el volumen se aplica al bus maestro")
	Settings.mouse_sensitivity = previous
	Settings.save_settings()
	menu.queue_free()

	# --- Pausa dentro del juego ---
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var pause = main.pause_menu
	_check(pause != null, "el juego tiene menu de pausa")
	pause.open()
	_check(get_tree().paused, "la pausa detiene el juego")
	pause.close()
	_check(not get_tree().paused, "reanudar lo devuelve")

	# --- La linterna alcanza para una noche con las pilas de la estacion ---
	var station: StationBuilder = main.station
	_check(station.pickups.size() >= 3, "hay pilas repartidas por la estacion (%d)" % station.pickups.size())
	var autonomy := (1.0 / Player.BATTERY_DRAIN) * (1 + GameState.spare_batteries + station.pickups.size())
	_check(autonomy > 900.0, "la linterna da para mas de 15 minutos con todo (%d s)" % int(autonomy))

	# --- Guardado a mitad de noche ---
	var director: NightDirector = main.director
	await get_tree().create_timer(4.0).timeout
	station.points["valvula"].interact(main.player)
	station.doors["almacen"].set_open(true, true)
	director.anomalies.apply("control_taza")
	GameState.drain_battery(0.3)
	main.player.teleport(Vector3(4.0, 0.1, -11.0), 1.0)
	main.save_now()

	var saved_battery := GameState.battery
	GameState.reset()
	_check(GameState.load_game(), "el guardado se relee")
	_check(not GameState.pending_world.is_empty(), "el guardado incluye el estado del mundo")
	await director.start_night(GameState.current_night)
	await get_tree().create_timer(0.5).timeout
	_check(GameState.is_task_done("valvula"), "las tareas hechas siguen hechas al continuar")
	# Tolerancia: la linterna sigue consumiendo mientras corre la restauracion.
	_check(absf(GameState.battery - saved_battery) < 0.02,
		"la bateria se retoma donde iba (%.3f vs %.3f)" % [GameState.battery, saved_battery])
	_check(station.doors["almacen"].is_open, "las puertas quedan como estaban")
	_check(director.anomalies.is_applied("control_taza"), "las anomalias aplicadas siguen aplicadas")
	_check(main.player.global_position.distance_to(Vector3(4.0, 0.1, -11.0)) < 1.5,
		"el jugador vuelve donde estaba")

	_report()


func _find_buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	if node is Button:
		out.append(node)
	for c in node.get_children():
		out.append_array(_find_buttons(c))
	return out


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  OK    %s" % label)
	else:
		print("  FALLA %s" % label)
		failures.append(label)


func _report() -> void:
	print("")
	if failures.is_empty():
		print("UI SMOKE OK")
	else:
		print("UI SMOKE CON %d FALLAS" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
