class_name NightData
extends RefCounted

## Todo el contenido por noche vive aca: tareas, variaciones del mundo,
## entradas de bitacora y beats guionados. La escena es siempre la misma;
## lo unico que cambia es este diccionario.

const NIGHTS := {
	1: {
		"title": "NOCHE 1",
		"subtitle": "Rutina",
		"clock": "23:04",
		"tasks": [
			{"id": "generator", "text": "Revisar el generador"},
			{"id": "round", "text": "Hacer la ronda exterior"},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
		],
		# Tareas que aparecen recien cuando se completan las anteriores.
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		# Estado del mundo: que objetos existen/estan visibles esta noche.
		"world": {
			"subnivel_b2": false,
			"corridor_south": false,
			"door_storage_locked": true,
			"fog_density": 0.055,
			"light_energy": 1.0,
			"wall_tint": Color(0.30, 0.32, 0.34),
		},
		# Anomalias fuera de camara: id -> se dispara al salir de esta sala.
		"offscreen": [
			{"id": "dorm_chair", "room": "dormitorio", "after_task": "sensors"},
		],
		"logbook": [
			{"time": "23:04", "text": "Cuarto turno solo. Faltan cinco dias para la evacuacion."},
		],
		"logbook_end": [
			{"time": "04:12", "text": "Ronda completa. Sin novedades que valga la pena anotar."},
		],
	},
	2: {
		"title": "NOCHE 2",
		"subtitle": "Primera desviacion",
		"clock": "22:51",
		"tasks": [
			{"id": "generator", "text": "Revisar el generador"},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
			{"id": "radio_unknown", "text": "Rastrear la senal que no figura en el registro"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": false,
			"corridor_south": false,
			"door_storage_locked": false,
			"fog_density": 0.062,
			"light_energy": 0.9,
			"wall_tint": Color(0.29, 0.30, 0.33),
		},
		"offscreen": [
			{"id": "control_chair", "room": "sala de control", "after_task": "generator"},
			{"id": "corridor_door", "room": "almacen", "after_task": "radio_unknown"},
		],
		"logbook": [
			{"time": "22:51", "text": "El almacen esta abierto. Juraria que ayer estaba trabado."},
		],
		"logbook_end": [
			{"time": "03:38", "text": "Segui una senal hasta el almacen."},
			{"time": "03:44", "text": "No debi seguirla."},
		],
	},
	3: {
		"title": "NOCHE 3",
		"subtitle": "El espacio interfiere",
		"clock": "23:19",
		"tasks": [
			{"id": "generator", "text": "Revisar el generador"},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
			{"id": "subnivel", "text": "Confirmar el nivel que aparecio en el mapa"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": true,
			"corridor_south": true,
			"door_storage_locked": false,
			"fog_density": 0.075,
			"light_energy": 0.75,
			"wall_tint": Color(0.27, 0.27, 0.30),
		},
		"offscreen": [
			{"id": "dorm_chair", "room": "dormitorio", "after_task": "generator"},
			{"id": "control_chair", "room": "sala de control", "after_task": "sensors"},
		],
		"logbook": [
			{"time": "23:19", "text": "El pasillo sur es mas largo que ayer. Lo camine dos veces para contarlo."},
		],
		"logbook_end": [
			{"time": "02:56", "text": "Baje al B2."},
			{"time": "03:01", "text": "No hay B2 en los planos."},
			{"time": "03:07", "text": "Igual baje."},
		],
	},
	4: {
		"title": "NOCHE 4",
		"subtitle": "Perdida de confianza",
		"clock": "00:02",
		"tasks": [
			{"id": "logbook_check", "text": "Releer la bitacora de las noches anteriores"},
			{"id": "generator", "text": "Revisar el generador"},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": false,
			"corridor_south": true,
			"door_storage_locked": false,
			"fog_density": 0.085,
			"light_energy": 0.6,
			"wall_tint": Color(0.25, 0.25, 0.27),
		},
		"offscreen": [
			{"id": "dorm_chair", "room": "dormitorio", "after_task": "logbook_check"},
			{"id": "dorm_bed", "room": "dormitorio", "after_task": "sensors"},
		],
		"logbook": [
			{"time": "00:02", "text": "Hoy el B2 no esta. El mapa dice que nunca estuvo."},
		],
		"logbook_end": [
			{"time": "23:41", "text": "Abri la puerta del generador."},
			{"time": "23:43", "text": "No debi abrirla."},
			{"time": "23:47", "text": "El todavia no sabe que fui yo."},
		],
	},
	5: {
		"title": "NOCHE 5",
		"subtitle": "Cierre",
		"clock": "21:40",
		"tasks": [
			{"id": "generator", "text": "Dejar el generador en modo de cierre"},
			{"id": "subnivel", "text": "Bajar al subnivel"},
			{"id": "round", "text": "Esperar el vehiculo en el patio"},
		],
		"final_task": {},
		"world": {
			"subnivel_b2": true,
			"corridor_south": true,
			"door_storage_locked": false,
			"fog_density": 0.10,
			"light_energy": 0.45,
			"wall_tint": Color(0.23, 0.22, 0.24),
		},
		"offscreen": [
			{"id": "dorm_bed", "room": "dormitorio", "after_task": "generator"},
			{"id": "control_chair", "room": "sala de control", "after_task": "subnivel"},
		],
		"logbook": [
			{"time": "21:40", "text": "Ultima guardia. Manana a esta hora esto es hielo vacio."},
		],
		"logbook_end": [
			{"time": "05:50", "text": "Escucho el motor."},
			{"time": "05:58", "text": "No hay personal asignado a esa estacion desde hace 11 meses."},
		],
	},
}

## Registros de radio encontrables en el mundo. Solo texto + ruido: baratos
## de producir, y son el principal vehiculo de historia.
const RADIO_LOGS := {
	"rl_01": {
		"label": "REG-014 / Jefe de base",
		"night": 1,
		"lines": [
			"Registro catorce. El relevo se confirmo para el dia cinco.",
			"Queda una sola persona de guardia hasta entonces.",
			"Si escuchan esto en el inventario final: el generador B pierde presion. No lo fuercen.",
		],
	},
	"rl_02": {
		"label": "REG-021 / Sin firmar",
		"night": 1,
		"lines": [
			"...no se quien dejo esto grabando.",
			"Hay alguien haciendo la ronda. Lo escucho caminar arriba.",
			"Yo soy el unico que hace la ronda.",
		],
	},
	"rl_03": {
		"label": "REG-??? / DESCONOCIDO",
		"night": 2,
		"lines": [
			"[ruido de portadora, doce segundos]",
			"...repetir el recorrido. Repetir el recorrido.",
			"La grabacion figura hecha hoy, a las 23:47.",
			"Son las 23:12.",
		],
	},
}

static func get_night(n: int) -> Dictionary:
	return NIGHTS.get(clampi(n, 1, 5), NIGHTS[1])

static func logs_for_night(n: int) -> Array:
	var out: Array = []
	for id in RADIO_LOGS.keys():
		if int(RADIO_LOGS[id]["night"]) <= n:
			out.append(id)
	return out
