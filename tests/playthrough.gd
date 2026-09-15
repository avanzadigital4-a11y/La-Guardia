extends Node
## Prueba de integracion: juega la Noche 1 de punta a punta sin intervencion
## y verifica que el loop avanza (tareas, anomalia fuera de camara, cierre de
## noche y variacion de la Noche 3).
##
## Uso:  godot --headless --path . res://tests/playthrough.tscn

var failures: Array[String] = []
var main: Node


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func _run() -> void:
	await _wait(5.0)
	var director: NightDirector = main.director
	var station: StationBuilder = main.station
	var player = main.player

	_check(GameState.current_night == 1, "arranca en la noche 1")
	_check(GameState.tasks.size() == 4, "la noche 1 tiene 4 tareas (%d)" % GameState.tasks.size())
	_check(not station.south_section.visible, "el pasillo sur no existe la noche 1")

	# Tareas: se completan usando los propios objetos del mundo.
	station.points["generador"].interact(player)
	await _wait(0.2)
	_check(not GameState.is_task_done("generator"), "un solo generador no alcanza")
	station.points["generador_b"].interact(player)
	await _wait(0.2)
	_check(GameState.is_task_done("generator"), "revisar los dos generadores")

	for key in ["ronda", "ronda_2", "ronda_3"]:
		station.points[key].interact(player)
		await _wait(0.2)
	_check(GameState.is_task_done("round"), "ronda exterior de tres puntos")

	station.points["sensores"].interact(player)
	await _wait(0.3)
	_check(GameState.is_task_done("sensors"), "sensores del nivel 1")
	main.sensor_ui.close()

	station.points["valvula"].interact(player)
	await _wait(0.2)
	_check(GameState.is_task_done("valvula"), "purgar la válvula")

	_check(GameState.has_task("sleep"), "aparece la tarea final de la noche")

	# Anomalia fuera de camara: la silla cambia cuando el jugador sale.
	var chair: Prop = station.props["dorm_chair"]
	_check(not chair.altered, "la silla esta normal mientras el jugador mira")
	director._on_room_exited("dormitorio")
	await _wait(0.2)
	_check(chair.altered, "la silla cambio fuera de camara")

	# Cierre de noche.
	station.points["cama"].interact(player)
	await _wait(9.0)
	_check(GameState.current_night == 2, "paso a la noche 2 (esta en %d)" % GameState.current_night)
	_check(not chair.altered, "la estacion vuelve a su estado normal al empezar la noche")
	_check(GameState.logbook.size() > 0, "la bitacora acumula entradas")
	var wrong := 0
	for e in GameState.logbook:
		if e.get("wrong", false):
			wrong += 1
	_check(wrong > 0, "la bitacora incluye entradas que el jugador no vivio")

	# Variacion de la noche 3: aparece el pasillo que no estaba en los planos.
	await director.start_night(3)
	await _wait(0.5)
	_check(station.south_section.visible, "la noche 3 abre el pasillo sur")
	_check(station.subnivel_section.visible, "la noche 3 abre el subnivel B2")
	_check(not station.south_wall.visible, "la pared del fondo desaparece")

	# El recorrido ya no lleva a donde deberia: el pasillo sur se muerde la cola.
	var loop: RouteSwap = station.routes["pasillo_sur"]
	_check(loop.active, "la noche 3 activa el desvio del pasillo sur")
	player.teleport(Vector3(0.0, 0.1, -20.2), 0.0)
	await _wait(0.8)
	_check(loop.times == 1, "caminar hasta el fondo dispara el desvio")
	_check(player.global_position.z > -16.0, "el jugador reaparece en la entrada del pasillo")

	# Noche 2: la senal desconocida se rastrea escuchandola, no apretando [E].
	await director.start_night(2)
	await _wait(0.5)
	var signal_log: RadioLog = station.points["log_rl_03"]
	_check(signal_log.task_id == "radio_unknown", "la senal de la noche 2 es una tarea de escucha")
	_check(signal_log.visible, "el registro desconocido aparece la noche 2")

	# Noche 4: el parte del turno le devuelve al jugador, en su propia letra,
	# lo que cambio mientras no miraba. El texto sale de esta partida.
	await director.start_night(4)
	await _wait(0.5)
	_check(GameState.has_task("parte"), "la noche 4 pide firmar el parte del turno")
	var antes := GameState.anomalies_of_night(4).size()
	director._on_room_exited("dormitorio")
	await _wait(0.3)
	var pasadas := GameState.anomalies_of_night(4)
	_check(pasadas.size() > antes, "lo que cambia fuera de camara queda anotado (%d)" % pasadas.size())
	var hoja: ReportSheet = station.points["parte"]
	var texto := hoja.description()
	_check(texto.contains(AnomalyData.note(String(pasadas[0]))),
		"el parte lista lo que de verdad paso en esta partida")
	hoja.interact(player)
	await _wait(0.4)
	_check(GameState.is_task_done("parte"), "leer el parte cierra la tarea")
	hoja._drop()
	await _wait(0.2)

	# Noche 5: el cierre corre entero y emite el final.
	var finished := [false]
	director.night_finished.connect(func(_n): finished[0] = true)
	await director.start_night(5)
	await _wait(0.5)
	station.points["generador"].interact(player)
	await _wait(0.2)
	station.points["generador_b"].interact(player)
	await _wait(0.2)
	# El subnivel se completa llegando caminando, no apretando [E].
	player.teleport(Vector3(0.0, -0.4, -28.0), 0.0)
	await _wait(0.6)
	_check(GameState.is_task_done("subnivel"), "bajar al subnivel se resuelve caminando")

	station.points["antena"].interact(player)
	await _wait(0.2)
	_check(GameState.is_task_done("antena"), "orientar la antena")

	# El inventario de cierre junta las cinco noches en una sola hoja.
	var cierre: ReportSheet = station.points["parte"]
	var inventario := cierre.description()
	cierre.interact(player)
	await _wait(0.4)
	_check(GameState.is_task_done("inventario"), "cerrar el inventario del turno")
	_check(inventario.contains("NOCHE 4") and inventario.contains(AnomalyData.note(String(pasadas[0]))),
		"el inventario arrastra lo de las noches anteriores")
	cierre._drop()
	await _wait(0.2)

	# "Dejar todas las puertas cerradas" no se resuelve con [E]: se resuelve
	# dejando la estacion como tiene que quedar.
	var door: Door = station.doors["almacen"]
	door.set_open(true, true)
	await _wait(1.2)
	_check(not GameState.is_task_done("puertas"), "con una puerta abierta la tarea no se cierra")
	door.set_open(false, true)
	await _wait(1.5)
	_check(GameState.is_task_done("puertas"), "cerrar todo completa la tarea por condición")

	_check(GameState.has_task("decidir"), "la noche 5 pide una decision")
	await _wait(6.0)
	station.points["salir"].interact(player)
	await _wait(0.3)
	_check(GameState.pending_tasks() == 0, "las tareas de la noche 5 se completan")
	_check(GameState.get_flag("ending", "") == "salir", "la decision queda registrada")
	await _wait(32.0)
	_check(finished[0], "el final se reproduce hasta el cierre")

	await _wait(0.3)
	_report()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  OK    %s" % label)
	else:
		print("  FALLA %s" % label)
		failures.append(label)


func _report() -> void:
	print("")
	if failures.is_empty():
		print("PLAYTHROUGH OK")
	else:
		print("PLAYTHROUGH CON %d FALLAS" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
