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
	_check(GameState.tasks.size() == 3, "la noche 1 tiene 3 tareas (%d)" % GameState.tasks.size())
	_check(not station.south_section.visible, "el pasillo sur no existe la noche 1")

	# Tareas: se completan usando los propios objetos del mundo.
	station.points["generador"].interact(player)
	await _wait(0.3)
	_check(GameState.is_task_done("generator"), "revisar el generador")

	station.points["ronda"].interact(player)
	await _wait(0.3)
	_check(GameState.is_task_done("round"), "ronda exterior")

	station.points["sensores"].interact(player)
	await _wait(0.3)
	_check(GameState.is_task_done("sensors"), "sensores del nivel 1")
	main.sensor_ui.close()

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

	# Noche 5: el cierre corre entero y emite el final.
	var finished := [false]
	director.night_finished.connect(func(_n): finished[0] = true)
	await director.start_night(5)
	await _wait(0.5)
	for id in ["generador", "subnivel", "ronda"]:
		station.points[id].interact(player)
		await _wait(0.3)
	_check(GameState.pending_tasks() == 0, "las tareas de la noche 5 se completan")
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
