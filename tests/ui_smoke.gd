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
	var names: Array[String] = []
	for b in buttons:
		names.append(b.text)
	_check("Jugar" in names and "Opciones" in names and "Créditos" in names and "Salir" in names,
		"el menu tiene jugar, opciones, creditos y salir")
	var slot_rows := 0
	for name in names:
		if name.begins_with("Ranura "):
			slot_rows += 1
	_check(slot_rows == GameState.SLOTS, "el menu lista las %d ranuras de guardado (%d)" % [GameState.SLOTS, slot_rows])

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
	var director: NightDirector = main.director
	_check(station.pickups.size() >= 3, "hay pilas repartidas por la estacion (%d)" % station.pickups.size())
	var autonomy := (1.0 / Player.BATTERY_DRAIN) * (1 + GameState.spare_batteries + station.pickups.size())
	_check(autonomy > 900.0, "la linterna da para mas de 15 minutos con todo (%d s)" % int(autonomy))

	# --- Mirar un objeto de cerca ---
	var placa: Inspectable = station.points["ver_placa"]
	var padre_original := placa.get_parent()
	var pose_original := placa.transform
	placa.interact(main.player)
	await get_tree().process_frame
	_check(placa.get_parent() == main.player.camera, "el objeto queda en la mano, frente a la camara")
	_check(not main.player.can_move and not main.player.look_enabled,
		"mientras se mira un objeto no se camina ni se gira la camara")
	var inspect_ui := get_tree().get_first_node_in_group("inspect_ui")
	_check(inspect_ui != null and inspect_ui.visible, "se muestra el texto del objeto")
	placa._drop()
	await get_tree().process_frame
	_check(placa.get_parent() == padre_original and placa.transform == pose_original,
		"al soltarlo vuelve exactamente a donde estaba")
	_check(main.player.can_move and main.player.look_enabled, "y devuelve el control al jugador")

	# --- El apagon ---
	# Quedarse sin luz no mata ni corta la partida: te pierde. Y lo que pasa
	# mientras no viste queda anotado a tu nombre, que es el punto.
	var apagon: Blackout = main.blackout
	_check(apagon != null, "el juego tiene apagon")
	main.player.teleport(Vector3(-5.5, 0.1, -2.5), 0.0)   # dormitorio
	main.player.set_flashlight(false)
	station.room_lights["dormitorio"].light_energy = 0.0
	await get_tree().process_frame
	_check(apagon.is_dark(), "sin linterna y con la sala apagada, esta a oscuras")
	station.room_lights["dormitorio"].light_energy = 1.2
	await get_tree().process_frame
	_check(not apagon.is_dark(), "bajo una luz encendida no cuenta como a oscuras")
	station.room_lights["dormitorio"].light_energy = 0.0
	main.player.teleport(Vector3(4.0, 0.1, -11.0), 0.0)

	GameState.battery = 0.0
	GameState.spare_batteries = 2
	var antes_anom := GameState.anomalies_seen.size()
	var antes_log := GameState.logbook.size()
	apagon.trigger()
	await get_tree().create_timer(11.0).timeout
	_check(GameState.spare_batteries == 0, "el apagon se lleva las pilas de repuesto")
	# Tolerancia: vuelve prendida, asi que ya consumio algo mientras corria el
	# fundido y la placa.
	_check(GameState.battery > 0.0 and GameState.battery <= Blackout.CARGA_AL_VOLVER
		and Blackout.CARGA_AL_VOLVER - GameState.battery < 0.06,
		"la linterna vuelve con poca carga (%.2f de %.2f)" % [
			GameState.battery, Blackout.CARGA_AL_VOLVER])
	_check(main.player.global_position.distance_to(StationBuilder.SPAWN) < 1.5,
		"despertas en el dormitorio")
	_check(main.player.can_move, "y podes seguir jugando: no es un game over")
	_check(GameState.logbook.size() > antes_log, "queda escrito en la bitacora")
	_check(int(GameState.get_flag("apagones", 0)) == 1, "el apagon queda contado")
	_check(int(GameState.get_flag("horas_perdidas", 0)) > 0, "y las horas perdidas tambien")
	# Lo importante: lo que paso a oscuras aparece despues en el parte, con tu
	# letra, sin que lo hayas visto.
	_check(GameState.anomalies_seen.size() > antes_anom,
		"lo que paso a oscuras queda anotado a tu nombre (%d nuevas)" % [
			GameState.anomalies_seen.size() - antes_anom])
	station.room_lights["dormitorio"].light_energy = 1.2

	# --- El parte del turno se lee sin romper la pantalla ---
	# El inventario de cierre es el texto mas largo del juego y se arma en
	# runtime. No se mide contra un alto de linea fijo (depende de la fuente
	# de cada maquina): se verifica lo que tiene que valer siempre, que el
	# titulo no se monte sobre el texto y que la hoja no se derrame fuera.
	GameState.anomalies_seen.clear()
	var largas := _longest_notes(3 * GameState.MAX_NIGHT)
	var k := 0
	for n in range(1, GameState.MAX_NIGHT + 1):
		GameState.current_night = n
		for i in 3:
			GameState.record_anomaly(largas[k])
			k += 1
	GameState.current_night = GameState.MAX_NIGHT
	var hoja: ReportSheet = station.points["parte"]
	var peor := hoja.text_for(GameState.MAX_NIGHT)
	_check(peor.split("\n").size() >= 15, "el peor caso del parte es largo de verdad (%d lineas)" % peor.split("\n").size())
	inspect_ui.open("Parte del turno", peor)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: Dictionary = inspect_ui.document_rects()
	var titulo: Rect2 = r["titulo"]
	var texto: Rect2 = r["texto"]
	var pantalla: Rect2 = r["pantalla"]
	_check(not titulo.intersects(texto), "el titulo de la hoja no se monta sobre el texto")
	_check(pantalla.encloses(texto), "el bloque de la hoja entra en la pantalla (%s en %s)" % [texto, pantalla])
	_check(texto.size.y > 0.0 and texto.size.x > 0.0, "y tiene lugar para mostrar algo")
	# Si el texto no entra, el scroll tiene que poder llegar al final.
	var pedido: Vector2 = r["pedido"]
	if pedido.y > texto.size.y:
		_check(inspect_ui._doc_scroll.get_v_scroll_bar().max_value >= pedido.y - 1.0,
			"la hoja larga se puede scrollear hasta el final")
	else:
		_check(true, "la hoja entra entera sin scrollear")
	inspect_ui.close()
	GameState.anomalies_seen.clear()
	GameState.current_night = 1

	# --- Guardado a mitad de noche ---
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


## Las notas mas largas del catalogo: el peor caso para el ancho de la hoja.
func _longest_notes(cuantas: int) -> Array[String]:
	var ids: Array[String] = []
	for id in AnomalyData.NOTES.keys():
		ids.append(String(id))
	ids.sort_custom(func(a, b): return AnomalyData.note(a).length() > AnomalyData.note(b).length())
	return ids.slice(0, cuantas)


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
