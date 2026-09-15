# -*- coding: utf-8 -*-
class_name AnomalyData
extends RefCounted

## Catalogo de anomalias. Cada entrada es un cambio de estado chiquito que se
## aplica mientras el jugador no esta en la sala. La regla del diseño: nada de
## secuencias animadas ni sustos: cuando volves, algo es distinto y no sabes
## desde cuando.
##
## Tipos:
##   mover     -> el objeto cambia de lugar o de orientacion
##   faltar    -> el objeto ya no esta
##   aparecer  -> aparece algo que no estaba (definido en EXTRAS)
##   puerta    -> una puerta queda abierta o cerrada
##   luz       -> una sala se queda a oscuras
##
## "sala" es donde tiene que dejar de estar el jugador para que pase.

const ANOMALIES := {
	# --- Dormitorio ---
	"dorm_chair": {"sala": "dormitorio", "tipo": "mover", "objeto": "dorm_chair"},
	"dorm_bed": {"sala": "dormitorio", "tipo": "mover", "objeto": "dorm_bed"},
	"dorm_silla_mira_cama": {"sala": "dormitorio", "tipo": "mover", "objeto": "dorm_chair",
		"pos": Vector3(-2.6, 0.0, -2.2), "rot": 195.0},
	"dorm_silla_falta": {"sala": "dormitorio", "tipo": "faltar", "objeto": "dorm_chair"},
	"dorm_silla_doble": {"sala": "dormitorio", "tipo": "aparecer", "objeto": "extra_silla_dorm"},
	"dorm_bulto": {"sala": "dormitorio", "tipo": "aparecer", "objeto": "extra_bulto_cama"},
	"dorm_marca": {"sala": "dormitorio", "tipo": "aparecer", "objeto": "extra_marca_dorm"},
	"dorm_oscuro": {"sala": "dormitorio", "tipo": "luz", "sala_luz": "dormitorio"},

	# --- Sala de control ---
	"control_chair": {"sala": "sala de control", "tipo": "mover", "objeto": "control_chair"},
	"control_silla_al_pasillo": {"sala": "sala de control", "tipo": "mover", "objeto": "control_chair",
		"pos": Vector3(4.4, 0.0, 0.0), "rot": 90.0},
	"control_silla_falta": {"sala": "sala de control", "tipo": "faltar", "objeto": "control_chair"},
	"control_pizarra": {"sala": "sala de control", "tipo": "aparecer", "objeto": "extra_pizarra_cero"},
	"control_taza": {"sala": "sala de control", "tipo": "aparecer", "objeto": "extra_taza"},
	"control_oscuro": {"sala": "sala de control", "tipo": "luz", "sala_luz": "sala de control"},

	# --- Sala de generador ---
	"gen_puerta": {"sala": "sala de generador", "tipo": "puerta", "puerta": "generador", "abrir": true},
	"gen_herramienta": {"sala": "sala de generador", "tipo": "aparecer", "objeto": "extra_llave_inglesa"},
	"gen_banco_vacio": {"sala": "sala de generador", "tipo": "faltar", "objeto": "banco_taller"},
	"gen_marca": {"sala": "sala de generador", "tipo": "aparecer", "objeto": "extra_marca_gen"},
	"gen_oscuro": {"sala": "sala de generador", "tipo": "luz", "sala_luz": "sala de generador"},

	# --- Almacen ---
	"corridor_door": {"sala": "almacen", "tipo": "puerta", "puerta": "almacen", "abrir": true},
	"almacen_cajas": {"sala": "almacen", "tipo": "mover", "objeto": "cajas",
		"pos": Vector3(-2.0, 0.0, -1.6), "rot": 35.0},
	"almacen_cajas_faltan": {"sala": "almacen", "tipo": "faltar", "objeto": "cajas"},
	"almacen_pila_extra": {"sala": "almacen", "tipo": "aparecer", "objeto": "extra_cajas_apiladas"},
	"almacen_oscuro": {"sala": "almacen", "tipo": "luz", "sala_luz": "almacen"},

	# --- Pasillo y esclusa ---
	"pasillo_camilla": {"sala": "pasillo", "tipo": "mover", "objeto": "camilla",
		"pos": Vector3(-1.4, 0.0, -6.0), "rot": 90.0},
	"pasillo_marca": {"sala": "pasillo", "tipo": "aparecer", "objeto": "extra_marca_pasillo"},
	"pasillo_locker_abierto": {"sala": "pasillo", "tipo": "aparecer", "objeto": "extra_locker_abierto"},
	"esclusa_traje_falta": {"sala": "esclusa", "tipo": "faltar", "objeto": "traje_2"},
	"esclusa_traje_extra": {"sala": "esclusa", "tipo": "aparecer", "objeto": "extra_traje_mojado"},
	"esclusa_puerta": {"sala": "esclusa", "tipo": "puerta", "puerta": "esclusa", "abrir": true},

	# --- Patio ---
	"patio_huellas": {"sala": "patio", "tipo": "aparecer", "objeto": "extra_huellas"},
	"patio_tambor": {"sala": "patio", "tipo": "mover", "objeto": "tambores",
		"pos": Vector3(-6.0, 0.0, 4.0), "rot": 0.0},
	"patio_figura": {"sala": "patio", "tipo": "aparecer", "objeto": "extra_figura"},

	# --- Segunda tanda: variaciones sobre los mismos objetos ---
	"dorm_cama_hecha": {"sala": "dormitorio", "tipo": "mover", "objeto": "dorm_bed",
		"pos": Vector3(0.0, 0.0, 1.1), "rot": 0.0},
	"dorm_silla_puerta": {"sala": "dormitorio", "tipo": "mover", "objeto": "dorm_chair",
		"pos": Vector3(2.3, 0.0, -1.2), "rot": 90.0},
	"dorm_pisadas": {"sala": "dormitorio", "tipo": "aparecer", "objeto": "extra_pisadas_dorm"},
	"dorm_linterna": {"sala": "dormitorio", "tipo": "aparecer", "objeto": "extra_linterna"},
	"control_reloj": {"sala": "sala de control", "tipo": "aparecer", "objeto": "extra_reloj"},
	"control_bandeja": {"sala": "sala de control", "tipo": "aparecer", "objeto": "extra_bandeja"},
	"control_marca": {"sala": "sala de control", "tipo": "aparecer", "objeto": "extra_marca_control"},
	"control_silla_girada": {"sala": "sala de control", "tipo": "mover", "objeto": "control_chair",
		"pos": Vector3(0.0, 0.0, 0.0), "rot": 180.0},
	"gen_traba_falta": {"sala": "sala de generador", "tipo": "faltar", "objeto": "traba"},
	"gen_puerta_cerrada": {"sala": "sala de generador", "tipo": "puerta", "puerta": "generador", "abrir": false},
	"gen_silla": {"sala": "sala de generador", "tipo": "aparecer", "objeto": "extra_silla_gen"},
	"almacen_bolsa": {"sala": "almacen", "tipo": "aparecer", "objeto": "extra_bolsa"},
	"almacen_estante_vacio": {"sala": "almacen", "tipo": "faltar", "objeto": "estante_2"},
	"almacen_puerta_cerrada": {"sala": "almacen", "tipo": "puerta", "puerta": "almacen", "abrir": false},
	"almacen_pila_falta": {"sala": "almacen", "tipo": "faltar", "objeto": "cajas"},
	"pasillo_silla": {"sala": "pasillo", "tipo": "aparecer", "objeto": "extra_silla_pasillo"},
	"pasillo_linterna": {"sala": "pasillo", "tipo": "aparecer", "objeto": "extra_linterna_pasillo"},
	"pasillo_camilla_falta": {"sala": "pasillo", "tipo": "faltar", "objeto": "camilla"},
	"pasillo_extintor": {"sala": "pasillo", "tipo": "faltar", "objeto": "extintor"},
	"pasillo_oscuro": {"sala": "pasillo", "tipo": "luz", "sala_luz": "pasillo"},
	"esclusa_traje_suelo": {"sala": "esclusa", "tipo": "aparecer", "objeto": "extra_traje_suelo"},
	"esclusa_marca": {"sala": "esclusa", "tipo": "aparecer", "objeto": "extra_marca_esclusa"},
	"esclusa_traje_1_falta": {"sala": "esclusa", "tipo": "faltar", "objeto": "traje_1"},
	"esclusa_oscuro": {"sala": "esclusa", "tipo": "luz", "sala_luz": "esclusa"},
	"patio_huellas_entran": {"sala": "patio", "tipo": "aparecer", "objeto": "extra_huellas_2"},
	"patio_tambor_falta": {"sala": "patio", "tipo": "faltar", "objeto": "tambores"},
	"patio_oscuro": {"sala": "patio", "tipo": "luz", "sala_luz": "patio"},
	"patio_bandera": {"sala": "patio", "tipo": "aparecer", "objeto": "extra_bandera"},

	# --- Subnivel B2 ---
	"b2_tanque_corrido": {"sala": "b2 bombas", "tipo": "mover", "objeto": "b2_tanque",
		"pos": Vector3(1.8, 0.0, 1.4), "rot": 40.0},
	"b2_banco_falta": {"sala": "b2 bombas", "tipo": "faltar", "objeto": "b2_banco"},
	"b2_bombas_oscuro": {"sala": "b2 bombas", "tipo": "luz", "sala_luz": "b2 bombas"},
	"b2_fichero_abierto": {"sala": "b2 archivo", "tipo": "mover", "objeto": "b2_fichero",
		"pos": Vector3(-0.9, 0.0, 0.5), "rot": 65.0},
	"b2_estante_falta": {"sala": "b2 archivo", "tipo": "faltar", "objeto": "b2_estante_b"},
	"b2_archivo_oscuro": {"sala": "b2 archivo", "tipo": "luz", "sala_luz": "b2 archivo"},
	"b2_camastro_corrido": {"sala": "b2 fondo", "tipo": "mover", "objeto": "b2_camastro",
		"pos": Vector3(2.2, 0.0, -0.8), "rot": 90.0},
	"b2_lata_falta": {"sala": "b2 fondo", "tipo": "faltar", "objeto": "b2_lata"},
	"b2_fondo_oscuro": {"sala": "b2 fondo", "tipo": "luz", "sala_luz": "b2 fondo"},
	"b2_pasillo_oscuro": {"sala": "subnivel", "tipo": "luz", "sala_luz": "b2 pasillo"},
}

## Como lo anota el parte del turno: cada anomalia en primera persona y en
## pasado, porque el que la escribio fue el protagonista. Es el material con
## el que la Noche 4 y la Noche 5 le muestran al jugador lo que hizo sin
## acordarse. Toda anomalia tiene que tener su linea (lo verifica content.gd).
const NOTES := {
	"dorm_chair": "Corrí la silla del dormitorio.",
	"dorm_bed": "Moví la cucheta de lugar.",
	"dorm_silla_mira_cama": "Puse la silla mirando la cama.",
	"dorm_silla_falta": "Saqué la silla del dormitorio.",
	"dorm_silla_doble": "Subí una segunda silla al dormitorio.",
	"dorm_bulto": "Dejé algo armado arriba de la cama.",
	"dorm_marca": "Escribí NO DUERMAS en la pared del dormitorio.",
	"dorm_oscuro": "Apagué la luz del dormitorio.",
	"dorm_cama_hecha": "Hice la cama.",
	"dorm_silla_puerta": "Trabé la puerta del dormitorio con la silla.",
	"dorm_pisadas": "Entré al dormitorio con las botas sucias.",
	"dorm_linterna": "Dejé una linterna prendida en el piso del dormitorio.",
	"control_chair": "Giré la silla de la sala de control.",
	"control_silla_al_pasillo": "Saqué la silla de control hasta la puerta.",
	"control_silla_falta": "Me llevé la silla de la sala de control.",
	"control_silla_girada": "Di vuelta la silla de control hacia la puerta.",
	"control_pizarra": "Escribí un 0 en la pizarra del cierre.",
	"control_taza": "Dejé una taza servida en el escritorio.",
	"control_reloj": "Colgué un reloj en la sala de control.",
	"control_bandeja": "Dejé una bandeja servida en control.",
	"control_marca": "Escribí NO CUENTES en la pared de control.",
	"control_oscuro": "Apagué la luz de la sala de control.",
	"gen_puerta": "Abrí la puerta del generador.",
	"gen_puerta_cerrada": "Cerré la puerta del generador.",
	"gen_herramienta": "Dejé la llave inglesa tirada junto al generador.",
	"gen_banco_vacio": "Vacié el banco de taller.",
	"gen_marca": "Marqué once rayas en la pared del generador.",
	"gen_traba_falta": "Saqué la traba del generador.",
	"gen_silla": "Arrimé una silla al generador.",
	"gen_oscuro": "Apagué la luz de la sala de generador.",
	"corridor_door": "Dejé abierta la puerta del almacén.",
	"almacen_puerta_cerrada": "Cerré la puerta del almacén.",
	"almacen_cajas": "Corrí las cajas del almacén.",
	"almacen_cajas_faltan": "Saqué las cajas del almacén.",
	"almacen_pila_extra": "Apilé cajas nuevas contra la pared del almacén.",
	"almacen_pila_falta": "Bajé la pila de cajas del almacén.",
	"almacen_bolsa": "Dejé una bolsa cargada en el almacén.",
	"almacen_estante_vacio": "Vacié el segundo estante del almacén.",
	"almacen_oscuro": "Apagué la luz del almacén.",
	"pasillo_camilla": "Crucé la camilla en el pasillo.",
	"pasillo_camilla_falta": "Me llevé la camilla del pasillo.",
	"pasillo_marca": "Escribí VOLVE en la pared del pasillo.",
	"pasillo_locker_abierto": "Dejé el locker del pasillo abierto.",
	"pasillo_silla": "Puse una silla en la mitad del pasillo.",
	"pasillo_linterna": "Dejé una linterna tirada en el pasillo.",
	"pasillo_extintor": "Descolgué el extintor del pasillo.",
	"pasillo_oscuro": "Apagué la luz del pasillo.",
	"esclusa_traje_falta": "Descolgué el segundo traje de la esclusa.",
	"esclusa_traje_1_falta": "Descolgué el primer traje de la esclusa.",
	"esclusa_traje_extra": "Colgué un traje mojado en la esclusa.",
	"esclusa_traje_suelo": "Dejé un traje tirado en el piso de la esclusa.",
	"esclusa_marca": "Escribí un 3 en la puerta de la esclusa.",
	"esclusa_puerta": "Dejé abierta la puerta de la esclusa.",
	"esclusa_oscuro": "Apagué la luz de la esclusa.",
	"patio_huellas": "Dejé una hilera de huellas saliendo al patio.",
	"patio_huellas_entran": "Volví al patio y entre por el costado.",
	"patio_tambor": "Rodé un tambor hasta el medio del patio.",
	"patio_tambor_falta": "Saqué el tambor del patio.",
	"patio_figura": "Paré algo del tamaño de una persona en el fondo del patio.",
	"patio_bandera": "Clavé una baliza en el patio.",
	"patio_oscuro": "Apagué la luz del patio.",
	"b2_tanque_corrido": "Corrí el tanque de la sala de bombas.",
	"b2_banco_falta": "Saqué el banco de la sala de bombas.",
	"b2_bombas_oscuro": "Apagué la luz de las bombas del B2.",
	"b2_fichero_abierto": "Dejé el fichero del archivo abierto.",
	"b2_estante_falta": "Vacié un estante del archivo del B2.",
	"b2_archivo_oscuro": "Apagué la luz del archivo del B2.",
	"b2_camastro_corrido": "Corrí el camastro del fondo del B2.",
	"b2_lata_falta": "Me llevé la lata del fondo del B2.",
	"b2_fondo_oscuro": "Apagué la luz del fondo del B2.",
	"b2_pasillo_oscuro": "Apagué la luz del pasillo del B2.",
}

## Objetos que solo existen cuando una anomalia los enciende. Se construyen
## apagados al armar la estacion: no cuesta nada tenerlos ahi.
const EXTRAS := {
	"extra_silla_dorm": {"tipo": "silla", "pos": Vector3(-5.4, 0.0, -1.2), "rot": 20.0},
	"extra_bulto_cama": {"tipo": "caja", "size": Vector3(0.8, 0.35, 1.7),
		"pos": Vector3(-8.2, 0.75, -3.4), "color": Color(0.26, 0.24, 0.23)},
	"extra_marca_dorm": {"tipo": "marca", "texto": "NO DUERMAS",
		"pos": Vector3(-9.4, 1.8, -2.6), "rot": -90.0},
	"extra_pizarra_cero": {"tipo": "marca", "texto": "0",
		"pos": Vector3(-5.5, 1.55, -13.84), "rot": 0.0, "size": 0.34},
	"extra_taza": {"tipo": "caja", "size": Vector3(0.12, 0.14, 0.12),
		"pos": Vector3(-3.2, 0.92, -13.2), "color": Color(0.7, 0.68, 0.62)},
	"extra_llave_inglesa": {"tipo": "caja", "size": Vector3(0.09, 0.05, 0.5),
		"pos": Vector3(4.2, 0.05, -9.6), "color": Color(0.5, 0.5, 0.55)},
	"extra_marca_gen": {"tipo": "marca", "texto": "|||| |||| ||",
		"pos": Vector3(9.4, 1.6, -11.0), "rot": -90.0},
	"extra_cajas_apiladas": {"tipo": "caja", "size": Vector3(1.0, 2.0, 1.0),
		"pos": Vector3(3.2, 1.0, -3.6), "color": Color(0.33, 0.28, 0.21)},
	"extra_marca_pasillo": {"tipo": "marca", "texto": "VOLVE",
		"pos": Vector3(-1.4, 1.7, -4.5), "rot": 90.0},
	"extra_locker_abierto": {"tipo": "caja", "size": Vector3(0.5, 1.9, 0.06),
		"pos": Vector3(-0.85, 0.95, -6.0), "color": Color(0.20, 0.22, 0.24)},
	"extra_traje_mojado": {"tipo": "caja", "size": Vector3(0.5, 1.3, 0.22),
		"pos": Vector3(2.4, 1.3, 7.5), "color": Color(0.30, 0.24, 0.12)},
	"extra_huellas": {"tipo": "caja", "size": Vector3(0.6, 0.02, 9.0),
		"pos": Vector3(3.0, 0.02, 18.0), "color": Color(0.45, 0.48, 0.52)},
	"extra_figura": {"tipo": "caja", "size": Vector3(0.5, 1.75, 0.3),
		"pos": Vector3(-12.0, 0.88, 25.0), "color": Color(0.10, 0.10, 0.12)},
	"extra_pisadas_dorm": {"tipo": "caja", "size": Vector3(0.5, 0.02, 2.2),
		"pos": Vector3(-7.2, 0.02, -3.0), "color": Color(0.20, 0.19, 0.18)},
	"extra_linterna": {"tipo": "caja", "size": Vector3(0.09, 0.09, 0.26),
		"pos": Vector3(-6.0, 0.06, -4.2), "color": Color(0.75, 0.72, 0.45)},
	"extra_linterna_pasillo": {"tipo": "caja", "size": Vector3(0.09, 0.09, 0.26),
		"pos": Vector3(0.4, 0.06, -9.0), "color": Color(0.75, 0.72, 0.45)},
	"extra_reloj": {"tipo": "caja", "size": Vector3(0.26, 0.26, 0.05),
		"pos": Vector3(-7.0, 2.1, -13.85), "color": Color(0.55, 0.54, 0.50)},
	"extra_bandeja": {"tipo": "caja", "size": Vector3(0.4, 0.05, 0.3),
		"pos": Vector3(-3.2, 0.9, -12.9), "color": Color(0.45, 0.46, 0.44)},
	"extra_marca_control": {"tipo": "marca", "texto": "NO CUENTES",
		"pos": Vector3(-9.4, 1.9, -11.6), "rot": -90.0},
	"extra_silla_gen": {"tipo": "silla", "pos": Vector3(3.4, 0.0, -12.6), "rot": 200.0},
	"extra_bolsa": {"tipo": "caja", "size": Vector3(0.6, 0.9, 0.6),
		"pos": Vector3(4.0, 0.45, -1.0), "color": Color(0.28, 0.26, 0.24)},
	"extra_silla_pasillo": {"tipo": "silla", "pos": Vector3(0.0, 0.0, -8.0), "rot": 180.0},
	"extra_traje_suelo": {"tipo": "caja", "size": Vector3(1.4, 0.18, 0.5),
		"pos": Vector3(-1.6, 0.09, 9.2), "color": Color(0.50, 0.34, 0.12)},
	"extra_marca_esclusa": {"tipo": "marca", "texto": "3",
		"pos": Vector3(0.0, 1.9, 6.95), "rot": 180.0, "size": 0.4},
	"extra_huellas_2": {"tipo": "caja", "size": Vector3(0.6, 0.02, 7.0),
		"pos": Vector3(-4.0, 0.02, 16.0), "color": Color(0.45, 0.48, 0.52)},
	"extra_bandera": {"tipo": "caja", "size": Vector3(0.05, 1.9, 0.05),
		"pos": Vector3(6.0, 0.95, 22.0), "color": Color(0.35, 0.33, 0.30)},
}


static func get_anomaly(id: String) -> Dictionary:
	return ANOMALIES.get(id, {})


static func ids_for_room(room: String) -> Array:
	var out: Array = []
	for id in ANOMALIES.keys():
		if String(ANOMALIES[id].get("sala", "")) == room:
			out.append(id)
	return out
## La linea del parte para una anomalia. Si alguna se agrega sin nota, se
## arma una generica con el tipo, para que el parte nunca quede vacio.
static func note(id: String) -> String:
	if NOTES.has(id):
		return String(NOTES[id])
	var entry: Dictionary = ANOMALIES.get(id, {})
	var room := String(entry.get("sala", "la estacion"))
	match String(entry.get("tipo", "")):
		"mover":
			return "Movi algo en %s." % room
		"faltar":
			return "Saque algo de %s." % room
		"aparecer":
			return "Deje algo en %s." % room
		"puerta":
			return "Toque la puerta de %s." % room
		"luz":
			return "Apague la luz de %s." % room
	return "Anduve en %s." % room
