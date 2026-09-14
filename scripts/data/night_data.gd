class_name NightData
extends RefCounted

## Todo el contenido por noche vive aca: tareas, variaciones del mundo,
## entradas de bitacora y beats guionados. La escena es siempre la misma;
## lo unico que cambia es este diccionario.
##
## Los beats son listas de acciones que el NightDirector interpreta. Las
## claves son "inicio", "final" o el id de la tarea que los dispara.
## Acciones disponibles:
##   {"esperar": 3.0}                                  pausa
##   {"subtitulo": "...", "tiempo": 3.2}               linea en pantalla
##   {"aviso": "..."}                                  aviso del HUD
##   {"parpadeo": 2.4}                                 las luces fallan
##   {"sonido": "creak", "db": -8.0}                   senal sonora
##   {"bitacora": "...", "hora": "01:12", "falsa": true}
##   {"anomalia": "dorm_chair"}                        cambio inmediato
##   {"armar": "dorm_chair", "sala": "dormitorio"}     cambio fuera de camara
##   {"ruta": "pasillo_sur", "activa": true}           el recorrido se desvia
##   {"puerta": "almacen", "abrir": true}
##   {"ocultar": ["traje_3"]}                          objetos que ya no estan

const NIGHTS := {
	1: {
		"title": "NOCHE 1",
		"subtitle": "Rutina",
		"clock": "23:04",
		"tasks": [
			{"id": "generator", "text": "Revisar los generadores", "steps": 2},
			{"id": "round", "text": "Hacer la ronda exterior", "steps": 3},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": false,
			"corridor_south": false,
			"door_storage_locked": true,
			"fog_density": 0.040,
			"light_energy": 1.0,
			"wall_tint": Color(0.30, 0.32, 0.34),
			"hidden": [],
		},
		"beats": {
			"inicio": [
				{"subtitulo": "Cuarto turno solo. Faltan cinco días.", "tiempo": 3.0},
			],
			"generator": [
				{"esperar": 4.0},
				{"sonido": "creak", "db": -8.0},
				{"subtitulo": "(algo se acomoda en el techo del pasillo)", "tiempo": 2.8},
			],
			"round": [
				{"esperar": 2.0},
				{"parpadeo": 2.2},
				{"subtitulo": "(el viento se corta un segundo y vuelve)", "tiempo": 2.6},
			],
			"sensors": [
				{"aviso": "El panel marcó una lectura de más y la borró solo."},
				{"armar": "dorm_chair", "sala": "dormitorio"},
			],
		},
		"logbook": [
			{"time": "23:04", "text": "Cuarto turno solo. Faltan cinco días para la evacuación."},
		],
		"logbook_end": [
			{"time": "04:12", "text": "Ronda completa. Sin novedades que valga la pena anotar."},
		],
	},
	2: {
		"title": "NOCHE 2",
		"subtitle": "Primera desviación",
		"clock": "22:51",
		"tasks": [
			{"id": "generator", "text": "Revisar los generadores", "steps": 2},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
			{"id": "radio_unknown", "text": "Rastrear la señal que no figura en el registro"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": false,
			"corridor_south": false,
			"door_storage_locked": false,
			"fog_density": 0.048,
			"light_energy": 0.9,
			"wall_tint": Color(0.29, 0.30, 0.33),
			"hidden": [],
		},
		"beats": {
			"inicio": [
				{"subtitulo": "El almacén está abierto. Juraría que ayer estaba trabado.", "tiempo": 3.4},
				{"aviso": "Hay una portadora en la banda 4. No figura en el registro."},
			],
			"generator": [
				{"esperar": 3.0},
				{"armar": "control_chair", "sala": "sala de control"},
				{"sonido": "door", "db": -10.0},
				{"esperar": 1.2},
				{"puerta": "almacen", "abrir": true},
				{"sonido": "creak", "db": -9.0},
			],
			"sensors": [
				{"aviso": "Ocupación registrada: 1. El sensor tardó en decidirlo."},
			],
			"radio_unknown": [
				{"esperar": 1.0},
				{"parpadeo": 2.2},
				{"subtitulo": "(la portadora sigue sonando con el equipo apagado)", "tiempo": 3.2},
				{"armar": "corridor_door", "sala": "almacen"},
				{"armar": "dorm_chair", "sala": "dormitorio"},
				{"bitacora": "La señal estaba grabada hoy, a una hora que todavía no pasó.", "hora": "01:58"},
			],
		},
		"logbook": [
			{"time": "22:51", "text": "El almacén está abierto. Juraría que ayer estaba trabado."},
		],
		"logbook_end": [
			{"time": "03:38", "text": "Seguí una señal hasta el almacén."},
			{"time": "03:44", "text": "No debí seguirla."},
		],
	},
	3: {
		"title": "NOCHE 3",
		"subtitle": "El espacio interfiere",
		"clock": "23:19",
		"tasks": [
			{"id": "generator", "text": "Revisar los generadores", "steps": 2},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
			{"id": "subnivel", "text": "Bajar al nivel que apareció en el mapa"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": true,
			"corridor_south": true,
			"door_storage_locked": false,
			"fog_density": 0.058,
			"light_energy": 0.75,
			"wall_tint": Color(0.27, 0.27, 0.30),
			"hidden": ["traje_3"],
		},
		"beats": {
			"inicio": [
				{"subtitulo": "El pasillo sigue más allá de donde terminaba.", "tiempo": 3.2},
				{"ruta": "pasillo_sur", "activa": true},
			],
			"generator": [
				{"esperar": 2.5},
				{"armar": "dorm_chair", "sala": "dormitorio"},
				{"sonido": "creak", "db": -6.0},
			],
			"sensors": [
				{"aviso": "El mapa suma un SUBNIVEL B2 que no está en los planos."},
				{"armar": "control_chair", "sala": "sala de control"},
			],
			"subnivel": [
				{"parpadeo": 3.0},
				{"subtitulo": "Hay marcas en la pared. Son de esta semana.", "tiempo": 3.6},
				{"subtitulo": "Es tu letra.", "tiempo": 3.0},
				{"bitacora": "Las marcas del B2 son mías. No me acuerdo de haberlas hecho.", "hora": "03:07", "falsa": true},
			],
		},
		"logbook": [
			{"time": "23:19", "text": "El pasillo sur es más largo que ayer. Lo caminé dos veces para contarlo."},
		],
		"logbook_end": [
			{"time": "02:56", "text": "Bajé al B2."},
			{"time": "03:01", "text": "No hay B2 en los planos."},
			{"time": "03:07", "text": "Igual bajé."},
		],
	},
	4: {
		"title": "NOCHE 4",
		"subtitle": "Pérdida de confianza",
		"clock": "00:02",
		"tasks": [
			{"id": "logbook_check", "text": "Releer la bitácora de las noches anteriores"},
			{"id": "generator", "text": "Revisar los generadores", "steps": 2},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
		],
		"final_task": {"id": "sleep", "text": "Volver al dormitorio y descansar"},
		"world": {
			"subnivel_b2": false,
			"corridor_south": true,
			"door_storage_locked": false,
			"fog_density": 0.068,
			"light_energy": 0.6,
			"wall_tint": Color(0.25, 0.25, 0.27),
			"hidden": ["traje_2", "traje_3"],
		},
		"beats": {
			"inicio": [
				{"subtitulo": "Hoy el B2 no está. El mapa dice que nunca estuvo.", "tiempo": 3.4},
				{"ocultar": ["traje_2", "traje_3"]},
			],
			"logbook_check": [
				{"esperar": 0.8},
				{"sonido": "click", "db": -10.0},
				{"bitacora": "Abrí la puerta del generador.", "hora": "23:41", "falsa": true},
				{"esperar": 1.2},
				{"bitacora": "No debí abrirla.", "hora": "23:43", "falsa": true},
				{"esperar": 1.2},
				{"bitacora": "Él todavía no sabe que fui yo.", "hora": "23:47", "falsa": true},
				{"aviso": "Tres entradas nuevas. Con tu letra. De hace una hora."},
				{"parpadeo": 1.8},
				{"anomalia": "dorm_chair"},
				{"sonido": "creak", "db": -8.0},
				{"ruta": "puerta_dormitorio", "activa": true},
			],
			"generator": [
				{"puerta": "generador", "abrir": true},
				{"esperar": 2.0},
				{"armar": "dorm_bed", "sala": "dormitorio"},
				{"sonido": "door", "db": -8.0},
			],
			"sensors": [
				{"aviso": "OCUPACIÓN REGISTRADA: 0 personas."},
				{"parpadeo": 2.0},
				{"armar": "control_chair", "sala": "sala de control"},
			],
		},
		"logbook": [
			{"time": "00:02", "text": "Hoy el B2 no está. El mapa dice que nunca estuvo."},
		],
		"logbook_end": [
			{"time": "04:30", "text": "Revisé las tres firmas de la bitácora."},
			{"time": "04:31", "text": "Las tres son mías."},
		],
	},
	5: {
		"title": "NOCHE 5",
		"subtitle": "Cierre",
		"clock": "21:40",
		"tasks": [
			{"id": "generator", "text": "Dejar los generadores en modo de cierre", "steps": 2},
			{"id": "subnivel", "text": "Bajar al subnivel por última vez"},
		],
		"final_task": {"id": "decidir", "text": "Decidir: esperar el vehículo en el patio o quedarte abajo"},
		"world": {
			"subnivel_b2": true,
			"corridor_south": true,
			"door_storage_locked": false,
			"fog_density": 0.080,
			"light_energy": 0.45,
			"wall_tint": Color(0.23, 0.22, 0.24),
			"hidden": ["traje_1", "traje_2", "traje_3"],
		},
		"beats": {
			"inicio": [
				{"subtitulo": "Última guardia. Mañana a esta hora esto es hielo vacío.", "tiempo": 3.4},
				{"ocultar": ["traje_1", "traje_2", "traje_3"]},
			],
			"generator": [
				{"esperar": 2.0},
				{"subtitulo": "El generador queda en mínimo. La estación se enfría rápido.", "tiempo": 3.2},
				{"armar": "dorm_bed", "sala": "dormitorio"},
			],
			"subnivel": [
				{"parpadeo": 2.6},
				{"subtitulo": "Las marcas de la pared ahora son una lista de fechas.", "tiempo": 3.6},
				{"subtitulo": "La última es la de mañana.", "tiempo": 3.0},
				{"aviso": "El vehículo llega al amanecer. Hay que decidir."},
			],
		},
		"logbook": [
			{"time": "21:40", "text": "Última guardia. Mañana a esta hora esto es hielo vacío."},
		],
		"logbook_end": [
			{"time": "05:50", "text": "Escucho el motor."},
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
			"Registro catorce. El relevo se confirmó para el día cinco.",
			"Queda una sola persona de guardia hasta entonces.",
			"Si escuchan esto en el inventario final: el generador B pierde presión. No lo fuercen.",
		],
	},
	"rl_02": {
		"label": "REG-021 / Sin firmar",
		"night": 1,
		"lines": [
			"...no sé quién dejó esto grabando.",
			"Hay alguien haciendo la ronda. Lo escucho caminar arriba.",
			"Yo soy el único que hace la ronda.",
		],
	},
	"rl_03": {
		"label": "REG-??? / DESCONOCIDO",
		"night": 2,
		"lines": [
			"[ruido de portadora, doce segundos]",
			"...repetir el recorrido. Repetir el recorrido.",
			"La grabación figura hecha hoy, a las 23:47.",
			"Son las 23:12.",
		],
	},
	"rl_04": {
		"label": "REG-030 / Nivel B2",
		"night": 3,
		"lines": [
			"Prueba de eco en el subnivel. Día doscientos once.",
			"El pasillo mide catorce metros de ida y diecinueve de vuelta.",
			"Lo medimos cuatro veces. Dejamos de medirlo.",
		],
	},
	"rl_05": {
		"label": "REG-041 / Tu voz",
		"night": 4,
		"lines": [
			"Registro cuarenta y uno. Estación Cabo Hueso.",
			"Si estás escuchando esto, ya hiciste la ronda tres veces esta noche.",
			"No la hagas de nuevo.",
			"[la grabación tiene tu voz y no la reconoces]",
		],
	},
}

static func get_night(n: int) -> Dictionary:
	return NIGHTS.get(clampi(n, 1, 5), NIGHTS[1])


static func beats_for(n: int, key: String) -> Array:
	return get_night(n).get("beats", {}).get(key, [])


static func logs_for_night(n: int) -> Array:
	var out: Array = []
	for id in RADIO_LOGS.keys():
		if int(RADIO_LOGS[id]["night"]) <= n:
			out.append(id)
	return out
