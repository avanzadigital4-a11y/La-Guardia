extends Node
## Medicion de ritmo: camina la Noche 1 como la caminaria un jugador que va
## derecho a cada tarea, y reporta cuanto dura, cuanto se camina y cuanta
## bateria se gasta. Sirve para ajustar el balance con numeros y no a ojo.
##
## Uso:  godot --headless --path . res://tests/pacing.tscn
##
## Corre acelerado con Engine.time_scale, asi que los segundos que imprime son
## de juego, no de reloj.

const SPEED := 2.4          # Player.WALK_SPEED
const DOOR_COST := 1.2      # abrir una puerta
const USE_COST := 2.0       # usar un objeto
const PANEL_COST := 6.0     # leer el panel de sensores

var main: Node
var player: Node3D
var distance := 0.0
var elapsed := 0.0


func _ready() -> void:
	Engine.time_scale = 20.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func _run() -> void:
	await get_tree().create_timer(5.0).timeout
	player = main.player
	var station: StationBuilder = main.station
	var t0 := elapsed

	# Recorrido directo de la Noche 1: dormitorio -> generador -> patio ->
	# sala de control -> dormitorio.
	await _walk([Vector3(-4.0, 0.1, -2.5), Vector3(-1.5, 0.1, -2.5)])
	await _pause(DOOR_COST)
	await _walk([Vector3(0.0, 0.1, -2.5), Vector3(0.0, 0.1, -11.0), Vector3(1.5, 0.1, -11.0)])
	await _pause(DOOR_COST)
	await _walk([Vector3(4.6, 0.1, -11.0)])
	station.points["generador"].interact(player)
	await _pause(USE_COST)
	await _walk([Vector3(7.0, 0.1, -12.6)])
	station.points["generador_b"].interact(player)
	await _pause(USE_COST)

	await _walk([Vector3(0.0, 0.1, -11.0), Vector3(0.0, 0.1, 9.0), Vector3(0.0, 0.1, 10.9)])
	await _pause(DOOR_COST)
	await _walk([Vector3(0.0, 0.1, 13.5), Vector3(8.6, 0.1, 15.0)])
	station.points["ronda"].interact(player)
	await _pause(USE_COST)
	await _walk([Vector3(1.0, 0.1, 24.5)])
	station.points["ronda_2"].interact(player)
	await _pause(USE_COST)
	await _walk([Vector3(-8.0, 0.1, 20.6)])
	station.points["ronda_3"].interact(player)
	await _pause(USE_COST)

	await _walk([Vector3(0.0, 0.1, 13.5), Vector3(0.0, 0.1, -11.0), Vector3(-1.5, 0.1, -11.0)])
	await _pause(DOOR_COST)
	await _walk([Vector3(-7.0, 0.1, -11.0)])
	station.points["sensores"].interact(player)
	await _pause(PANEL_COST)
	main.sensor_ui.close()

	await _walk([Vector3(0.0, 0.1, -11.0), Vector3(0.0, 0.1, -2.5), Vector3(-1.5, 0.1, -2.5)])
	await _pause(DOOR_COST)
	await _walk([Vector3(-6.0, 0.1, -3.4), Vector3(-7.4, 0.1, -3.4)])
	station.points["cama"].interact(player)

	var total := elapsed - t0
	var used := 1.0 - GameState.battery
	print("")
	print("RITMO DE LA NOCHE 1 (recorrido directo, sin explorar)")
	print("  duracion          %5.1f s   (%.1f min)" % [total, total / 60.0])
	print("  distancia         %5.1f m" % distance)
	print("  bateria usada     %5.0f %%   (queda %.0f %%)" % [used * 100.0, GameState.battery * 100.0])
	print("  cargas por noche  %5.2f" % used)
	var charges: float = 1.0 + float(GameState.spare_batteries) + float(main.station.pickups.size())
	print("  cargas disponibles%5.1f  ->  alcanzan para %.1f noches asi" % [charges, charges / maxf(used, 0.001)])
	print("")
	print("Un jugador que explora tarda entre dos y tres veces esto.")
	get_tree().quit(0)


func _walk(points: Array) -> void:
	for p in points:
		var target: Vector3 = p
		while true:
			var delta := await _frame()
			var here := player.global_position
			var step := SPEED * delta
			var flat_target := Vector3(target.x, here.y, target.z)
			var next := here.move_toward(flat_target, step)
			distance += here.distance_to(next)
			player.global_position = next
			if here.distance_to(flat_target) <= step:
				break


func _pause(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		left -= await _frame()


func _frame() -> float:
	await get_tree().process_frame
	var delta := get_process_delta_time()
	elapsed += delta
	return delta
