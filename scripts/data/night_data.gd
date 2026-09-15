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
			{"id": "valvula", "text": "Purgar la válvula del almacén"},
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
		"anomalias": [
			"control_taza",
			"pasillo_extintor",
		],
		"anomalias_extra": 0,
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
			"valvula": [
				{"esperar": 2.0},
				{"subtitulo": "(el agua sigue corriendo un rato después de cerrar)", "tiempo": 3.0},
			],
		},
		"logbook": [
			{"time": "23:04", "text": "Cuarto turno solo. Faltan cinco días para la evacuación."},
			{"time": "23:20", "text": "Rutina de siempre: generadores, ronda, sensores, válvula."},
		],
		"logbook_end": [
			{"time": "04:12", "text": "Ronda completa. Sin novedades que valga la pena anotar."},
			{"time": "04:30", "text": "Dormí bien. Anoto esto porque las próximas noches no."},
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
			{"id": "antena", "text": "Realinear la antena"},
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
		"anomalias": [
			"almacen_cajas",
			"gen_herramienta",
			"pasillo_locker_abierto",
			"control_reloj",
			"dorm_cama_hecha",
		],
		"anomalias_extra": 2,
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
			"antena": [
				{"esperar": 1.5},
				{"subtitulo": "(la portadora se escucha desde el patio, sin equipo)", "tiempo": 3.2},
				{"armar": "gen_herramienta", "sala": "sala de generador"},
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
			{"time": "23:05", "text": "La banda 4 tendría que estar muerta y hay algo transmitiendo."},
		],
		"logbook_end": [
			{"time": "03:38", "text": "Seguí una señal hasta el almacén."},
			{"time": "03:44", "text": "No debí seguirla."},
			{"time": "03:51", "text": "Dejé la grabadora andando por las dudas."},
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
			{"id": "trajes", "text": "Contar los trajes de la esclusa"},
			{"id": "puertas", "text": "Dejar todas las puertas cerradas"},
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
		"anomalias": [
			"dorm_silla_mira_cama",
			"control_silla_al_pasillo",
			"gen_marca",
			"esclusa_traje_falta",
			"patio_huellas",
			"pasillo_silla",
			"control_bandeja",
			"almacen_bolsa",
		],
		"anomalias_extra": 3,
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
			"trajes": [
				{"esperar": 1.0},
				{"subtitulo": "(ayer eran tres)", "tiempo": 2.6},
			],
			"puertas": [
				{"esperar": 3.0},
				{"sonido": "door", "db": -9.0},
				{"anomalia": "gen_puerta"},
				{"subtitulo": "(una acaba de abrirse de nuevo)", "tiempo": 3.0},
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
			{"time": "23:40", "text": "Conté los trajes: dos. Ayer había tres y no salió nadie."},
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
			{"id": "parte", "text": "Firmar el parte del turno"},
			{"id": "generator", "text": "Revisar los generadores", "steps": 2},
			{"id": "sensors", "text": "Verificar sensores del nivel 1"},
			{"id": "trajes", "text": "Contar los trajes de la esclusa"},
			{"id": "puertas", "text": "Dejar todas las puertas cerradas"},
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
		"anomalias": [
			"dorm_bulto",
			"dorm_marca",
			"control_pizarra",
			"control_silla_falta",
			"gen_puerta",
			"almacen_cajas_faltan",
			"pasillo_marca",
			"dorm_pisadas",
			"esclusa_marca",
			"pasillo_camilla_falta",
			"gen_traba_falta",
		],
		"anomalias_extra": 3,
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
			"trajes": [
				{"esperar": 1.0},
				{"bitacora": "Conté los trajes otra vez. El número no coincide con ayer.", "hora": "02:14", "falsa": true},
			],
			"parte": [
				{"esperar": 0.8},
				{"subtitulo": "El parte ya está completo.", "tiempo": 2.6},
				{"subtitulo": "Es tu letra, y la hora del pie es de antes de que pasara nada.", "tiempo": 3.8},
				{"bitacora": "Firmé el parte al entrar. Todo lo que anoté ahí pasó después.", "hora": "04:12", "falsa": true},
				{"parpadeo": 1.6},
				{"armar": "control_marca", "sala": "sala de control"},
			],
			"sensors": [
				{"aviso": "OCUPACIÓN REGISTRADA: 0 personas."},
				{"parpadeo": 2.0},
				{"armar": "control_chair", "sala": "sala de control"},
			],
		},
		"logbook": [
			{"time": "00:02", "text": "Hoy el B2 no está. El mapa dice que nunca estuvo."},
			{"time": "00:25", "text": "Comparé mi letra con la de las entradas viejas. Es la misma."},
		],
		"logbook_end": [
			{"time": "04:30", "text": "Revisé las tres firmas de la bitácora."},
			{"time": "04:31", "text": "Las tres son mías."},
			{"time": "04:48", "text": "Voy a dejar de anotar la hora. No me está sirviendo."},
		],
	},
	5: {
		"title": "NOCHE 5",
		"subtitle": "Cierre",
		"clock": "21:40",
		"tasks": [
			{"id": "generator", "text": "Dejar los generadores en modo de cierre", "steps": 2},
			{"id": "subnivel", "text": "Bajar al subnivel por última vez"},
			{"id": "antena", "text": "Orientar la antena para el retiro"},
			{"id": "inventario", "text": "Cerrar el inventario del turno"},
			{"id": "puertas", "text": "Dejar todas las puertas cerradas"},
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
		"anomalias": [
			"dorm_silla_doble",
			"dorm_oscuro",
			"control_oscuro",
			"gen_banco_vacio",
			"almacen_pila_extra",
			"esclusa_traje_extra",
			"patio_figura",
			"patio_tambor",
			"control_marca",
			"esclusa_traje_suelo",
			"patio_huellas_entran",
			"dorm_linterna",
			"pasillo_oscuro",
			"patio_bandera",
		],
		"anomalias_extra": 4,
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
			"antena": [
				{"esperar": 1.0},
				{"subtitulo": "La antena engancha al vehículo. Está a dos horas.", "tiempo": 3.4},
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
			{"time": "22:10", "text": "Dejé el inventario final sobre la mesa de control. Faltan cosas que no saqué yo."},
		],
		"logbook_end": [
			{"time": "05:50", "text": "Escucho el motor."},
			{"time": "05:54", "text": "Voy a salir igual. Sea lo que sea que salga conmigo."},
		],
	},
}

## Registros de radio encontrables en el mundo. Solo texto + ruido: baratos
## de producir, y son el principal vehiculo de historia.
const RADIO_LOGS := {
	# --- Lo que dejo el personal antes del cierre ---
	"rl_01": {
		"label": "REG-014 / Jefe de base",
		"night": 1,
		"pos": Vector3(-3.2, 0.9, -13.2),
		"lines": [
			"Registro catorce. El relevo se confirmó para el día cinco.",
			"Queda una sola persona de guardia hasta entonces.",
			"Si escuchan esto en el inventario final: el generador B pierde presión. No lo fuercen.",
		],
	},
	"rl_02": {
		"label": "REG-021 / Sin firmar",
		"night": 1,
		"pos": Vector3(-4.2, 0.9, -1.0),
		"lines": [
			"...no sé quién dejó esto grabando.",
			"Hay alguien haciendo la ronda. Lo escucho caminar arriba.",
			"Yo soy el único que hace la ronda.",
		],
	},
	"rl_06": {
		"label": "REG-009 / Enfermería",
		"night": 1,
		"pos": Vector3(1.1, 0.75, 0.5),
		"lines": [
			"Control de sueño, semana treinta y uno.",
			"Tres de los cinco reportan haber despertado de pie en el pasillo.",
			"Ninguno recuerda haberse levantado. Lo anotamos como falta de luz solar.",
		],
	},
	"rl_07": {
		"label": "REG-016 / Cocina",
		"night": 1,
		"pos": Vector3(6.5, 1.3, -1.4),
		"lines": [
			"Inventario de víveres para el último turno.",
			"Raciones para una persona por sesenta días.",
			"Lo raro es que el consumo del mes pasado da para dos.",
		],
	},
	# --- Noche 2: la señal ---
	"rl_03": {
		"label": "REG-??? / DESCONOCIDO",
		"night": 2,
		"pos": Vector3(5.6, 2.1, -4.6),
		"lines": [
			"[ruido de portadora, doce segundos]",
			"...repetir el recorrido. Repetir el recorrido.",
			"La grabación figura hecha hoy, a las 23:47.",
			"Son las 23:12.",
		],
	},
	"rl_08": {
		"label": "REG-023 / Radiooperador",
		"night": 2,
		"pos": Vector3(-8.4, 1.2, -12.2),
		"lines": [
			"La banda cuatro tendría que estar muerta desde que se fue el equipo.",
			"Hay una portadora ahí todas las noches, siempre a la misma hora.",
			"Cuando transmito encima, se calla. Cuando dejo de transmitir, vuelve.",
		],
	},
	"rl_09": {
		"label": "REG-025 / Mantenimiento",
		"night": 2,
		"pos": Vector3(3.0, 0.9, -9.4),
		"lines": [
			"El consumo eléctrico de la estación no cierra.",
			"Hay ocho kilovatios que se van a algún lado que no figura en el plano.",
			"Pedí el plano original a continente. Me mandaron el mismo que tenemos.",
		],
	},
	"rl_10": {
		"label": "REG-027 / Sin firmar",
		"night": 2,
		"pos": Vector3(1.6, 0.5, 9.6),
		"lines": [
			"Dejé los trajes contados antes de dormir. Eran cuatro.",
			"A la mañana había tres y uno estaba mojado por dentro.",
			"Afuera no salió nadie. El registro de la esclusa está en cero.",
		],
	},
	# --- Noche 3: el subnivel ---
	"rl_04": {
		"label": "REG-030 / Nivel B2",
		"night": 3,
		"pos": Vector3(2.2, -0.1, -27.0),
		"lines": [
			"Prueba de eco en el subnivel. Día doscientos once.",
			"El pasillo mide catorce metros de ida y diecinueve de vuelta.",
			"Lo medimos cuatro veces. Dejamos de medirlo.",
		],
	},
	"rl_11": {
		"label": "REG-031 / Nivel B2",
		"night": 3,
		"pos": Vector3(-2.4, -0.5, -29.5),
		"lines": [
			"Segunda prueba. Entramos dos, salimos dos.",
			"El conteo está bien. El problema es que entramos a las cuatro y salimos a las cuatro.",
			"No pasó tiempo acá abajo. Arriba pasaron seis horas.",
		],
	},
	"rl_12": {
		"label": "REG-033 / Sin firmar",
		"night": 3,
		"pos": Vector3(-1.2, 0.05, -19.0),
		"lines": [
			"El pasillo sur no está en los planos porque lo hicimos nosotros.",
			"Lo que no sabemos es contra qué lo hicimos.",
			"Tapialo si podés. Nosotros no pudimos.",
		],
	},
	"rl_13": {
		"label": "REG-034 / Glaciología",
		"night": 3,
		"pos": Vector3(8.0, 2.5, 18.0),
		"lines": [
			"Perforación a ciento veinte metros bajo la estación.",
			"El hielo de ahí abajo tiene once mil años y una cavidad de aire.",
			"La cavidad tiene la forma del pasillo que estamos parados.",
		],
	},
	# --- Noche 4: la voz propia ---
	"rl_05": {
		"label": "REG-041 / Tu voz",
		"night": 4,
		"pos": Vector3(-8.2, 0.6, -2.2),
		"lines": [
			"Registro cuarenta y uno. Estación Cabo Hueso.",
			"Si estás escuchando esto, ya hiciste la ronda tres veces esta noche.",
			"No la hagas de nuevo.",
			"[la grabación tiene tu voz y no la reconoces]",
		],
	},
	"rl_14": {
		"label": "REG-042 / Tu voz",
		"night": 4,
		"pos": Vector3(-6.4, 0.05, -9.0),
		"lines": [
			"Anoté todo lo que hice hoy, minuto por minuto.",
			"Después comparé con la bitácora.",
			"Hay cuarenta minutos que escribí yo y no viví yo.",
		],
	},
	"rl_15": {
		"label": "REG-044 / Tu voz",
		"night": 4,
		"pos": Vector3(5.0, 0.05, -8.6),
		"lines": [
			"Probé dejar la puerta del generador trabada desde afuera.",
			"A la noche siguiente estaba abierta y la traba en mi bolsillo.",
			"Dejé de trabarla. Prefiero verla abierta que encontrarla así.",
		],
	},
	"rl_16": {
		"label": "REG-045 / Sin firmar",
		"night": 4,
		"pos": Vector3(8.8, 1.6, -3.0),
		"lines": [
			"Al que venga después: la estación no te hace nada.",
			"Vos hacés cosas y después no te acordás. Es distinto y es peor.",
			"Contá los trajes. Es lo único que te va a avisar.",
		],
	},
	# --- Noche 5: el cierre ---
	"rl_17": {
		"label": "REG-048 / Continente",
		"night": 5,
		"pos": Vector3(-8.0, 0.05, 20.6),
		"lines": [
			"Cabo Hueso, confirmamos retiro para mañana al amanecer.",
			"Preparen el inventario final y dejen el generador en mínimo.",
			"No hace falta que confirmen por voz. Sabemos cómo está la estación.",
		],
	},
	"rl_18": {
		"label": "REG-050 / Nivel B2",
		"night": 5,
		"pos": Vector3(0.0, -0.5, -25.0),
		"lines": [
			"Última entrada del subnivel.",
			"Las marcas de la pared no son días. Son turnos.",
			"Uno por cada vez que alguien se quedó a cerrar la estación.",
		],
	},
	"rl_19": {
		"label": "REG-051 / Tu voz",
		"night": 5,
		"pos": Vector3(-4.6, 0.05, -4.2),
		"lines": [
			"Si estás escuchando esto es porque llegaste a la última noche.",
			"Yo también llegué.",
			"Fijate la fecha de esta grabación antes de subir al vehículo.",
		],
	},
	"rl_20": {
		"label": "REG-052 / Sin firmar",
		"night": 5,
		"pos": Vector3(0.0, 0.05, 8.2),
		"lines": [
			"[la cinta está en blanco los primeros treinta segundos]",
			"...está bien. Si te quedás, cerrá desde adentro.",
			"Si te vas, no mires el patio por la ventanilla.",
		],
	},
	"rl_21": {
		"label": "REG-011 / Meteorología",
		"night": 1,
		"pos": Vector3(-8.4, 1.2, -10.0),
		"lines": [
			"Parte de las veintidós. Viento del sudeste, treinta y ocho nudos.",
			"La estación está dentro de parámetros. Todo normal.",
			"Anoto igual que el anemómetro marcó cero durante once minutos y nadie lo tocó.",
		],
	},
	"rl_22": {
		"label": "REG-013 / Sin firmar",
		"night": 1,
		"pos": Vector3(8.8, 1.9, -3.0),
		"lines": [
			"Prueba de grabadora. Uno, dos.",
			"Si esto quedó grabando toda la noche, borrenlo sin escucharlo.",
			"En serio.",
		],
	},
	"rl_23": {
		"label": "REG-018 / Jefe de base",
		"night": 2,
		"pos": Vector3(-5.5, 1.0, -13.5),
		"lines": [
			"Decisión tomada: la estación cierra al final de la temporada.",
			"El personal sale en dos tandas. Queda una guardia hasta el retiro.",
			"Se ofrecieron cuatro. Elegí al que menos preguntas hizo.",
		],
	},
	"rl_24": {
		"label": "REG-024 / Cocina",
		"night": 2,
		"pos": Vector3(4.0, 0.9, -1.0),
		"lines": [
			"Segunda semana cocinando para uno.",
			"Sigo poniendo dos platos. Es costumbre, supongo.",
			"El segundo plato aparece usado. Eso no es costumbre.",
		],
	},
	"rl_25": {
		"label": "REG-026 / Mantenimiento",
		"night": 2,
		"pos": Vector3(1.28, 1.5, -9.0),
		"lines": [
			"La puerta del generador no cierra sola. Alguien la abre.",
			"Puse una traba nueva el lunes.",
			"El martes la traba estaba puesta y la puerta abierta igual.",
		],
	},
	"rl_26": {
		"label": "REG-029 / Radiooperador",
		"night": 3,
		"pos": Vector3(-1.2, 0.5, -17.5),
		"lines": [
			"Grabé la portadora de la banda cuatro y la pasé lenta.",
			"Adentro hay una voz repitiendo el parte meteorológico.",
			"Es el parte de mañana.",
		],
	},
	"rl_27": {
		"label": "REG-032 / Nivel B2",
		"night": 3,
		"pos": Vector3(-3.0, -0.5, -26.5),
		"lines": [
			"Tercera prueba. Bajamos tres y subimos tres.",
			"Nadie discute el número mientras estamos abajo.",
			"Arriba, cada uno se acuerda de una persona distinta que no vino.",
		],
	},
	"rl_28": {
		"label": "REG-036 / Sin firmar",
		"night": 3,
		"pos": Vector3(10.0, 1.2, 14.0),
		"lines": [
			"El perímetro está bien. Los tres puntos marcados.",
			"Hay un cuarto juego de huellas que da la vuelta completa.",
			"Yo marqué tres puntos. Las huellas pasan por cuatro.",
		],
	},
	"rl_29": {
		"label": "REG-043 / Tu voz",
		"night": 4,
		"pos": Vector3(-1.4, 1.2, -6.5),
		"lines": [
			"Dejé la grabadora en el pasillo toda la noche, apuntando a mi pieza.",
			"Se escuchan mis pasos saliendo a las dos y cuarto.",
			"No se escuchan volviendo.",
		],
	},
	"rl_30": {
		"label": "REG-046 / Enfermería",
		"night": 4,
		"pos": Vector3(1.1, 0.9, 0.9),
		"lines": [
			"Al que esté de guardia: si te despertás en un lugar que no elegiste, no corras.",
			"Sentate donde estás y esperá a que amanezca.",
			"Los que corrieron tardaron más en volver.",
		],
	},
	"rl_31": {
		"label": "REG-049 / Jefe de base",
		"night": 5,
		"pos": Vector3(-9.6, 0.9, 22.6),
		"lines": [
			"Última entrada antes de salir con la primera tanda.",
			"Dejamos la estación en condiciones y la guardia cubierta.",
			"Que conste que el nombre de la guardia lo completé yo, y estaba en blanco.",
		],
	},
	"rl_32": {
		"label": "REG-053 / Sin firmar",
		"night": 5,
		"pos": Vector3(8.0, 0.9, 18.0),
		"lines": [
			"El vehículo llega con luz. Van a preguntar por el personal.",
			"Decí que sos el de la guardia y mostrá la chapa.",
			"Si la chapa dice otro número, no la muestres.",
		],
	},
}

## Objetos que se pueden levantar y mirar de cerca. El texto cambia con las
## noches: el objeto es el mismo, lo que dice no.
const INSPECTABLES := {
	"placa": {
		"titulo": "Chapa de identificación",
		"pos": Vector3(-3.7, 0.92, -0.6),
		"size": Vector3(0.10, 0.02, 0.06),
		"color": Color(0.55, 0.56, 0.52),
		"textos": {
			1: "Tu nombre y el número de turno: 14. La cadena está gastada de darle vueltas.",
			3: "Tu nombre está bien. El número de turno ahora dice 15.",
			5: "El nombre está frotado hasta casi borrarse. El número dice 16.",
		},
	},
	"foto": {
		"titulo": "Foto del equipo",
		"pos": Vector3(-2.8, 0.92, -13.2),
		"size": Vector3(0.16, 0.006, 0.12),
		"color": Color(0.62, 0.60, 0.54),
		"textos": {
			1: "Cinco personas frente a la esclusa, con los ojos cerrados por el viento.",
			2: "Cuatro personas. Alguien recortó el borde derecho con tijera.",
			4: "Tres. El recorte es más nuevo que la foto.",
			5: "Una sola persona, de espaldas. Lo demás es hielo.",
		},
	},
	"taza": {
		"titulo": "Taza",
		"pos": Vector3(-3.9, 0.94, -13.2),
		"size": Vector3(0.09, 0.11, 0.09),
		"color": Color(0.70, 0.68, 0.62),
		"textos": {
			1: "Café frío de hace horas. Es tuya.",
			3: "Café tibio. Hoy no hiciste café.",
			5: "Vacía y limpia, como recién lavada.",
		},
	},
	"traba": {
		"titulo": "Traba del generador",
		"pos": Vector3(2.1, 0.94, -8.7),
		"size": Vector3(0.06, 0.03, 0.22),
		"color": Color(0.48, 0.50, 0.54),
		"textos": {
			1: "La traba de la puerta del generador. Pesa más de lo que parece.",
			4: "Está en tu mano otra vez. En la bitácora figura que la dejaste puesta.",
		},
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
