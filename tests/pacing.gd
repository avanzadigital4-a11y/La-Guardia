extends Node
## Medicion de ritmo de las cinco noches: camina cada noche como la caminaria
## alguien que va derecho a cada tarea, y reporta cuanto dura, cuanto se
## camina y cuanta bateria gasta. Sirve para ajustar el balance con numeros y
## para saber si el juego se esta acercando a los 60-90 min del diseno.
##
## Uso:  godot --headless --path . res://tests/pacing.tscn
##
## Corre acelerado con Engine.time_scale, asi que los segundos que imprime son
## de juego, no de reloj.
##
## No hay rutas escritas a mano: cada tarea se resuelve buscando su punto en
## la estacion, y el camino entre dos puntos se arma pasando por el pasillo.
## Asi la medicion sigue valiendo cuando se agreguen tareas nuevas, que es
## justamente para lo que se usa.

const SPEED := 2.4          # Player.WALK_SPEED
const DOOR_COST := 1.2      # abrir una puerta
const USE_COST := 2.0       # usar un objeto
const PANEL_COST := 6.0     # leer el panel de sensores
const READ_COST := 8.0      # leer la bitacora o el parte del turno
const LINE_COST := 3.8      # cada linea de un registro, si no hay audio grabado

## Como se entra a cada sala desde el pasillo. El pasillo es la columna x=0:
## dos caminos cualesquiera se pegan por ahi, asi que no hace falta un
## buscador de caminos, alcanza con concatenar.
const ENTRADAS := {
	"pasillo": [],
	"sala de control": [Vector2(0.0, -11.0), Vector2(-2.5, -11.0)],
	"sala de generador": [Vector2(0.0, -11.0), Vector2(2.5, -11.0)],
	"dormitorio": [Vector2(0.0, -2.5), Vector2(-2.5, -2.5)],
	"almacen": [Vector2(0.0, -2.5), Vector2(2.5, -2.5)],
	"esclusa": [Vector2(0.0, 7.0), Vector2(0.0, 9.0)],
	"patio": [Vector2(0.0, 7.0), Vector2(0.0, 9.0), Vector2(0.0, 13.0)],
	"pasillo sur": [Vector2(0.0, -16.0), Vector2(0.0, -20.0)],
	"subnivel": [Vector2(0.0, -16.0), Vector2(0.0, -20.0), Vector2(0.0, -26.0)],
	"b2 pasillo": [Vector2(0.0, -16.0), Vector2(0.0, -20.0), Vector2(0.0, -26.0), Vector2(0.0, -34.0)],
	"b2 bombas": [Vector2(0.0, -16.0), Vector2(0.0, -20.0), Vector2(0.0, -26.0),
		Vector2(0.0, -38.0), Vector2(-4.0, -38.0)],
	"b2 archivo": [Vector2(0.0, -16.0), Vector2(0.0, -20.0), Vector2(0.0, -26.0),
		Vector2(0.0, -38.0), Vector2(4.0, -38.0)],
	"b2 fondo": [Vector2(0.0, -16.0), Vector2(0.0, -20.0), Vector2(0.0, -26.0),
		Vector2(0.0, -42.0), Vector2(0.0, -46.0)],
}

var main: Node
var player: Node3D
var station: StationBuilder
var director: NightDirector

var distance := 0.0
var elapsed := 0.0
var _room := "dormitorio"
var _rows: Array = []
var _atascos: Array[String] = []


func _ready() -> void:
	Engine.time_scale = 20.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func _run() -> void:
	await get_tree().create_timer(5.0).timeout
	player = main.player
	station = main.station
	director = main.director
	# El recorrido lo maneja esta herramienta: si la fisica del jugador sigue
	# activa, pelea contra las posiciones que le imponemos y nunca llega.
	player.set_physics_process(false)
	player.set_frozen(true)
	# La linterna prendida es el caso normal de una noche a oscuras.
	player.flashlight_on = true

	for night in range(1, GameState.MAX_NIGHT + 1):
		if night > 1:
			await director.start_night(night)
			await get_tree().create_timer(0.4).timeout
		await _measure_night(night)

	_report()


func _measure_night(night: int) -> void:
	var t0 := elapsed
	var d0 := distance
	var b0 := GameState.battery
	_room = "dormitorio"
	player.global_position = StationBuilder.SPAWN

	var puntos := _task_points()
	var data := NightData.get_night(night)
	var hechas := 0
	var sin_resolver: Array[String] = []

	for t in data["tasks"]:
		var id := String(t["id"])
		if not puntos.has(id):
			sin_resolver.append(id)
			continue
		for paso in puntos[id]:
			await _go(paso["pos"])
			await _pause(float(paso["costo"]))
		hechas += 1

	# La tarea final aparece recien al terminar las otras: se camina hasta
	# ella pero no se resuelve, asi la noche no se cierra sola en el medio de
	# la medicion.
	var final: Dictionary = data.get("final_task", {})
	if not final.is_empty() and puntos.has(String(final["id"])):
		for paso in puntos[String(final["id"])]:
			await _go(paso["pos"])

	_rows.append({
		"noche": night,
		"duracion": elapsed - t0,
		"distancia": distance - d0,
		"tareas": hechas,
		"bateria": b0 - GameState.battery,
		"sin_resolver": sin_resolver,
		"registros": _logs_available(night),
		"anomalias": data.get("anomalias", []).size() + int(data.get("anomalias_extra", 0)),
	})


## Cada tarea a la lista de paradas que exige, con lo que cuesta cada una.
## Sale de la estacion misma, no de una tabla escrita al lado.
func _task_points() -> Dictionary:
	var out := {}
	for key in station.points.keys():
		var node: Node = station.points[key]
		var ids: Array[String] = []
		var costo := USE_COST
		if node is TaskPoint:
			ids.append((node as TaskPoint).task_id)
		elif node is TriggerZone:
			ids.append((node as TriggerZone).task_id)
			costo = 0.0            # se resuelve llegando, no apretando
		elif node is SensorPanel:
			ids.append((node as SensorPanel).task_id)
			costo = PANEL_COST
		elif node is SuitCounter:
			ids.append((node as SuitCounter).task_id)
		elif node is ReportSheet:
			for tid in (node as ReportSheet).task_ids:
				ids.append(String(tid))
			costo = READ_COST
		elif node is RadioLog and (node as RadioLog).task_id != "":
			var rl := node as RadioLog
			ids.append(rl.task_id)
			costo = NightData.RADIO_LOGS.get(rl.log_id, {}).get("lines", []).size() * LINE_COST
		for id in ids:
			if id == "":
				continue
			if not out.has(id):
				out[id] = []
			out[id].append({"pos": (node as Node3D).global_position, "costo": costo})

	# Las que no son un punto con `task_id`.
	if station.points.has("cama"):
		out["sleep"] = [{"pos": station.points["cama"].global_position, "costo": USE_COST}]
	if station.points.has("bitacora"):
		out["logbook_check"] = [{"pos": station.points["bitacora"].global_position, "costo": READ_COST}]
	if station.points.has("salir"):
		out["decidir"] = [{"pos": station.points["salir"].global_position, "costo": USE_COST}]
	# "Dejar todas las puertas cerradas" no se aprieta en ningun lado: hay que
	# pasar por cada puerta.
	var puertas: Array = []
	for id in station.doors.keys():
		puertas.append({"pos": (station.doors[id] as Node3D).global_position, "costo": DOOR_COST})
	if not puertas.is_empty():
		out["puertas"] = puertas
	return out


func _logs_available(night: int) -> Dictionary:
	var n := 0
	var segundos := 0.0
	for id in NightData.RADIO_LOGS.keys():
		if int(NightData.RADIO_LOGS[id]["night"]) <= night:
			n += 1
			segundos += _log_seconds(String(id))
	return {"cuantos": n, "segundos": segundos}


## Cuanto dura escuchar un registro entero. Si hay audio de verdad en
## audio/voz/, se mide; si no, se estima. Importa: el audio generado resulto
## un 38 % mas largo que la estimacion, y con 35 registros eso no es un
## detalle.
func _log_seconds(log_id: String) -> float:
	var lines: Array = NightData.RADIO_LOGS.get(log_id, {}).get("lines", [])
	var total := 0.0
	for i in lines.size():
		var clip := AudioDirector.voice_clip(log_id, i)
		total += clip.get_length() if clip != null else LINE_COST
	return total


## Camina hasta un punto pasando por el pasillo, y cobra el costo de cruzar
## cada puerta que haya en el medio.
func _go(target: Vector3) -> void:
	var destino := _room_of(target)
	var ruta: Array[Vector2] = []
	if destino != _room:
		var salida: Array = ENTRADAS.get(_room, [])
		for i in range(salida.size() - 1, -1, -1):
			ruta.append(salida[i])
		for p in ENTRADAS.get(destino, []):
			ruta.append(p)
		await _pause(DOOR_COST * _doors_between(_room, destino))
	for p in ruta:
		await _walk_to(Vector3(p.x, 0.1, p.y))
	await _walk_to(target)
	_room = destino


func _doors_between(a: String, b: String) -> int:
	var n := 0
	if a != "pasillo":
		n += 1
	if b != "pasillo":
		n += 1
	return n


func _room_of(p: Vector3) -> String:
	for id in StationBuilder.ROOMS.keys():
		var r: Rect2 = StationBuilder.ROOMS[id]
		if r.has_point(Vector2(p.x, p.z)):
			return String(id)
	return "pasillo"


## `ATASCO`: si un tramo no se completa en este tiempo de juego, se corta. Sin
## esto un destino mal puesto cuelga la medicion entera en silencio.
const ATASCO := 30.0


func _walk_to(target: Vector3) -> void:
	var gastado := 0.0
	while true:
		var delta := await _frame()
		gastado += delta
		if gastado > ATASCO:
			_atascos.append("%.1f,%.1f" % [target.x, target.z])
			player.global_position = Vector3(target.x, player.global_position.y, target.z)
			break
		var here := player.global_position
		var step := SPEED * delta
		var flat := Vector3(target.x, here.y, target.z)
		var next := here.move_toward(flat, step)
		distance += here.distance_to(next)
		player.global_position = next
		if here.distance_to(flat) <= step:
			break


func _pause(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		left -= await _frame()


func _frame() -> float:
	await get_tree().process_frame
	var delta := get_process_delta_time()
	elapsed += delta
	# Con la fisica del jugador apagada nadie descuenta la linterna: se cobra
	# aca, con la misma constante que usa el jugador.
	if player.flashlight_on:
		GameState.drain_battery(Player.BATTERY_DRAIN * delta)
	return delta


func _report() -> void:
	var total := 0.0
	var dist := 0.0
	var faltan: Array[String] = []
	print("")
	print("RITMO DE LAS CINCO NOCHES (recorrido directo, sin explorar)")
	print("")
	print("  noche   duracion   distancia   bateria   tareas   registros   anomalias")
	for r in _rows:
		total += float(r["duracion"])
		dist += float(r["distancia"])
		for id in r["sin_resolver"]:
			faltan.append("noche %d: %s" % [r["noche"], id])
		print("  %5d   %6.1f s   %7.1f m   %6.0f %%   %6d   %9d   %9d" % [
			r["noche"], r["duracion"], r["distancia"], float(r["bateria"]) * 100.0,
			r["tareas"], r["registros"]["cuantos"], r["anomalias"]])
	print("")
	print("  total directo      %6.1f s   (%.1f min)" % [total, total / 60.0])
	print("  distancia total    %6.1f m" % dist)
	var peor := 0.0
	for r in _rows:
		peor = maxf(peor, float(r["bateria"]))
	var cargas: float = 1.0 + float(GameState.spare_batteries) + float(station.pickups.size())
	var margen: float = cargas / maxf(peor, 0.001)
	print("  bateria: la peor noche gasta %.0f %% de una carga; hay %.0f cargas" % [
		peor * 100.0, cargas])
	print("           alcanzan para %.1f noches asi -> %s" % [margen,
		"sobra demasiado, rebalancear" if margen > 4.0 else "razonable"])
	# Un jugador que explora tarda entre dos y tres veces el recorrido directo,
	# mas lo que escuche de radio.
	var audio: float = _logs_available(GameState.MAX_NIGHT)["segundos"]
	print("  explorando (x2-x3) %6.1f a %.1f min, mas %.1f min de audio" % [
		total * 2.0 / 60.0, total * 3.0 / 60.0, audio / 60.0])
	print("  objetivo del diseno   60 a 90 min")
	if not _atascos.is_empty():
		print("")
		print("  OJO: %d tramos se cortaron por atasco -> %s" % [
			_atascos.size(), ", ".join(_atascos)])
	if not faltan.is_empty():
		print("")
		print("  OJO: tareas sin punto en la estacion -> %s" % ", ".join(faltan))
	print("")
	get_tree().quit(0)
