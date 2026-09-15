class_name StationBuilder
extends Node3D
## Construye la estacion completa por codigo, a partir de una tabla de salas.
## Es UNA sola escena base: las noches no agregan geometria nueva, solo
## encienden o apagan tramos y cambian materiales.

const ROOMS := {
	"pasillo": Rect2(-1.5, -16.0, 3.0, 23.0),
	"sala de control": Rect2(-9.5, -14.0, 8.0, 6.0),
	"sala de generador": Rect2(1.5, -14.0, 8.0, 6.0),
	"dormitorio": Rect2(-9.5, -5.0, 8.0, 5.0),
	"almacen": Rect2(1.5, -5.0, 8.0, 5.0),
	"esclusa": Rect2(-3.0, 7.0, 6.0, 4.0),
	"patio": Rect2(-14.0, 11.0, 28.0, 16.0),
	"pasillo sur": Rect2(-1.5, -24.0, 3.0, 8.0),
	"subnivel": Rect2(-4.0, -31.0, 8.0, 7.0),
	# El B2 de verdad: lo que hay mas abajo de la entrada. Solo existe las
	# noches que la tabla de la noche lo enciende.
	"b2 pasillo": Rect2(-1.5, -44.0, 3.0, 13.0),
	"b2 bombas": Rect2(-10.0, -41.0, 8.5, 6.0),
	"b2 archivo": Rect2(1.5, -41.0, 8.5, 6.0),
	"b2 fondo": Rect2(-5.0, -50.0, 10.0, 6.0),
}

## Altura del piso del subnivel respecto de la estacion.
const B2_Y := -0.6

const SPAWN := Vector3(-6.0, 0.1, -2.5)

var doors := {}
var props := {}
var points := {}
var watchers := {}
var routes := {}
var variants := {}
var pickups: Array[BatteryPickup] = []
var objects := {}        # nodos que una anomalia puede mover u ocultar
var room_lights := {}    # sala -> luz de techo
var lights: Array[OmniLight3D] = []
var wall_meshes: Array[MeshInstance3D] = []
var south_section: Node3D
var south_wall: Node3D
var subnivel_section: Node3D

var _mat_wall: Material
var _mat_floor: Material
var _mat_metal: Material
var _mat_dark: Material
var _mat_snow: Material
var _mat_screen: Material


func build(tint: Color) -> void:
	_mat_wall = Build.surface(tint)
	_mat_floor = Build.surface(tint.darkened(0.45))
	_mat_metal = Build.surface(Color(0.22, 0.24, 0.26))
	_mat_dark = Build.surface(Color(0.08, 0.08, 0.09))
	_mat_snow = Build.surface(Color(0.62, 0.66, 0.70))
	_mat_screen = Build.surface(Color(0.35, 0.72, 0.58), 1.6)

	_build_corridor()
	_build_control()
	_build_generator()
	_build_dorm()
	_build_storage()
	_build_airlock()
	_build_exterior()
	_build_south()
	_build_routes()
	_build_extras()
	_build_radio_logs()
	_build_inspectables()
	_build_recuento()
	_build_watchers()


func _mesh_room(name: String, rect: Rect2, openings: Dictionary, ceiling := true) -> Node3D:
	var holder := Build.room(self, name, rect, _mat_wall, _mat_floor, openings, ceiling)
	for c in holder.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("pared"):
			wall_meshes.append(c)
	return holder


func _build_corridor() -> void:
	var r: Rect2 = ROOMS["pasillo"]
	_mesh_room("Pasillo", r, {
		"w": [Vector2(-11.0, Build.DOOR_W), Vector2(-2.5, Build.DOOR_W)],
		"e": [Vector2(-11.0, Build.DOOR_W), Vector2(-2.5, Build.DOOR_W)],
		"s": [Vector2(0.0, Build.DOOR_W)],
		"n": [Vector2(0.0, Build.DOOR_W)],
	})
	# La pared del fondo del pasillo: existe salvo las noches en que el
	# pasillo sur "aparece".
	# Tapa del hueco del fondo: la pared que "siempre estuvo ahi" hasta que
	# una noche deja de estar.
	south_wall = Node3D.new()
	south_wall.name = "ParedFondo"
	add_child(south_wall)
	Build.box(south_wall, "tapa", Vector3(Build.DOOR_W, Build.DOOR_H, Build.WALL_T),
			Vector3(0.0, Build.DOOR_H * 0.5, r.position.y), _mat_wall)

	Build.light(self, Vector3(0.0, 2.75, -12.0), Color(0.72, 0.78, 0.85), 1.6, 8.0)
	Build.light(self, Vector3(0.0, 2.75, -4.0), Color(0.72, 0.78, 0.85), 1.6, 8.0)
	var corridor_light := Build.light(self, Vector3(0.0, 2.75, 3.0), Color(0.70, 0.74, 0.80), 1.3, 8.0)
	lights.append(corridor_light)
	room_lights["pasillo"] = corridor_light

	# Lockers contra la pared.
	Build.box(self, "Lockers", Vector3(0.45, 1.9, 2.4), Vector3(-1.2, 0.95, -7.0), _mat_metal)
	objects["camilla"] = Build.box(self, "Camilla", Vector3(0.7, 0.7, 2.0), Vector3(1.1, 0.35, 0.5), _mat_metal)
	objects["extintor"] = Build.box(self, "Extintor", Vector3(0.22, 0.6, 0.22), Vector3(1.28, 1.1, -9.0), Build.surface(Color(0.45, 0.16, 0.12)))
	Build.label3d(self, "NIVEL 1  ->  ESCLUSA", Vector3(-1.35, 2.3, -6.0), PI * 0.5, 0.22)
	Build.label3d(self, "<-  B2", Vector3(1.35, 2.3, -14.5), -PI * 0.5, 0.22, Color(0.5, 0.52, 0.55))


func _build_control() -> void:
	var r: Rect2 = ROOMS["sala de control"]
	_mesh_room("SalaDeControl", r, {"e": [Vector2(-11.0, Build.DOOR_W)]})
	room_lights["sala de control"] = Build.light(self, Vector3(-5.5, 2.7, -11.0), Color(0.62, 0.72, 0.82), 1.5, 8.0)
	lights.append(room_lights["sala de control"])

	_add_door("control", Vector3(-1.5, 0.0, -11.0 + Build.DOOR_W * 0.5), PI * 0.5, Build.DOOR_W)

	# Consola de sensores contra la pared oeste.
	var console := SensorPanel.new()
	console.name = "ConsolaSensores"
	add_child(console)
	console.position = Vector3(-8.4, 0.0, -11.0)
	console.setup_box(Vector3(1.2, 1.1, 2.6), _mat_metal, Vector3(0.0, 0.55, 0.0))
	Build.box(console, "Pantalla", Vector3(0.08, 0.7, 1.6), Vector3(0.5, 1.5, 0.0), _mat_screen, false)
	Build.light(console, Vector3(0.9, 1.5, 0.0), Color(0.35, 0.8, 0.6), 0.8, 3.5)
	points["sensores"] = console

	Build.box(self, "Pizarra", Vector3(2.0, 1.2, 0.06), Vector3(-5.5, 1.7, -13.9), Build.surface(Color(0.18, 0.20, 0.19)))
	Build.label3d(self, "DÍAS PARA EL CIERRE", Vector3(-5.5, 2.05, -13.85), 0.0, 0.18, Color(0.7, 0.72, 0.68))
	Build.label3d(self, "|||||", Vector3(-5.5, 1.55, -13.85), 0.0, 0.32, Color(0.75, 0.7, 0.55))

	var chair := _add_prop("control_chair", Vector3(-6.4, 0.0, -11.0), 0.0, Vector3(0.55, 0.9, 0.55))
	chair.register("control_chair", Vector3(0.6, 0.0, 0.8), 145.0)

	Build.box(self, "MesaControl", Vector3(1.6, 0.85, 0.7), Vector3(-3.2, 0.42, -13.2), _mat_metal)

	# El parte del turno: en blanco hasta la Noche 4, cuando resulta que ya
	# estaba escrito.
	var parte := ReportSheet.new()
	parte.name = "ParteDelTurno"
	add_child(parte)
	parte.position = Vector3(-3.55, 0.90, -12.95)
	parte.inspect_id = "parte"
	parte.titulo = "Parte del turno"
	parte.setup_box(Vector3(0.20, 0.008, 0.28), Build.surface(Color(0.72, 0.70, 0.64)))
	points["parte"] = parte
	objects["parte"] = parte


func _build_generator() -> void:
	var r: Rect2 = ROOMS["sala de generador"]
	_mesh_room("SalaDeGenerador", r, {"w": [Vector2(-11.0, Build.DOOR_W)]})
	room_lights["sala de generador"] = Build.light(self, Vector3(5.5, 2.7, -11.0), Color(0.85, 0.62, 0.42), 1.5, 8.0)
	lights.append(room_lights["sala de generador"])

	_add_door("generador", Vector3(1.5, 0.0, -11.0 - Build.DOOR_W * 0.5), -PI * 0.5, Build.DOOR_W)

	var gen := TaskPoint.new()
	gen.name = "Generador"
	add_child(gen)
	gen.position = Vector3(6.0, 0.0, -11.0)
	gen.setup_box(Vector3(2.4, 1.8, 3.2), _mat_metal, Vector3(0.0, 0.9, 0.0))
	gen.task_id = "generator"
	gen.multi_step = true
	gen.active_prompt = "Revisar GEN-A"
	gen.done_prompt = "GEN-A estable"
	gen.log_time = ""
	points["generador"] = gen

	var gen_b := TaskPoint.new()
	gen_b.name = "GeneradorB"
	add_child(gen_b)
	gen_b.position = Vector3(8.4, 0.0, -12.6)
	gen_b.setup_box(Vector3(1.6, 1.6, 2.0), _mat_metal, Vector3(0.0, 0.8, 0.0))
	gen_b.task_id = "generator"
	gen_b.multi_step = true
	gen_b.active_prompt = "Revisar GEN-B"
	gen_b.done_prompt = "GEN-B revisado"
	gen_b.notice_on_done = "Presión en verde. El B sigue perdiendo."
	gen_b.log_text = "Generadores revisados. El B pierde presión, como siempre."
	points["generador_b"] = gen_b
	Build.label3d(self, "GEN-B", Vector3(8.4, 1.8, -13.65), 0.0, 0.2, Color(0.8, 0.6, 0.4))
	Build.light(gen, Vector3(0.0, 2.0, 0.0), Color(0.9, 0.5, 0.25), 0.7, 4.0)
	Build.label3d(self, "GEN-A", Vector3(4.7, 1.9, -11.0), -PI * 0.5, 0.2, Color(0.8, 0.6, 0.4))

	_add_battery("PilaGenerador", Vector3(2.6, 0.9, -9.0))
	objects["banco_taller"] = Build.box(self, "BancoTaller", Vector3(1.4, 0.85, 1.0), Vector3(2.6, 0.42, -9.0), _mat_metal)


func _build_dorm() -> void:
	var r: Rect2 = ROOMS["dormitorio"]
	_mesh_room("Dormitorio", r, {"e": [Vector2(-2.5, Build.DOOR_W)]})
	room_lights["dormitorio"] = Build.light(self, Vector3(-5.5, 2.7, -2.5), Color(0.75, 0.66, 0.55), 1.2, 7.0)
	lights.append(room_lights["dormitorio"])

	_add_door("dormitorio", Vector3(-1.5, 0.0, -2.5 + Build.DOOR_W * 0.5), PI * 0.5, Build.DOOR_W)

	var bed_prop := Prop.new()
	bed_prop.name = "CamaProp"
	add_child(bed_prop)
	bed_prop.position = Vector3(-8.2, 0.0, -3.4)
	bed_prop.register("dorm_bed", Vector3(0.35, 0.0, 0.15), 4.0)
	props["dorm_bed"] = bed_prop
	objects["dorm_bed"] = bed_prop

	var bed := Bed.new()
	bed.name = "Cucheta"
	bed_prop.add_child(bed)
	bed.setup_box(Vector3(1.0, 0.55, 2.1), Build.surface(Color(0.30, 0.28, 0.26)), Vector3(0.0, 0.28, 0.0))
	points["cama"] = bed

	var chair := _add_prop("dorm_chair", Vector3(-4.0, 0.0, -1.2), 0.0, Vector3(0.55, 0.9, 0.55))
	chair.register("dorm_chair", Vector3(-0.5, 0.0, -0.9), 160.0)

	var desk := LogbookDesk.new()
	desk.name = "Escritorio"
	add_child(desk)
	desk.position = Vector3(-4.2, 0.0, -0.6)
	desk.setup_box(Vector3(1.6, 0.85, 0.7), _mat_metal, Vector3(0.0, 0.42, 0.0))
	Build.box(desk, "Cuaderno", Vector3(0.3, 0.04, 0.22), Vector3(0.0, 0.88, 0.0), Build.surface(Color(0.65, 0.62, 0.5)), false)
	points["bitacora"] = desk



func _build_storage() -> void:
	var r: Rect2 = ROOMS["almacen"]
	_mesh_room("Almacen", r, {"w": [Vector2(-2.5, Build.DOOR_W)]})
	room_lights["almacen"] = Build.light(self, Vector3(5.5, 2.7, -2.5), Color(0.6, 0.62, 0.66), 0.9, 7.0)
	lights.append(room_lights["almacen"])

	_add_door("almacen", Vector3(1.5, 0.0, -2.5 - Build.DOOR_W * 0.5), -PI * 0.5, Build.DOOR_W)

	Build.box(self, "Estante1", Vector3(0.6, 2.2, 3.0), Vector3(8.8, 1.1, -3.0), _mat_metal)
	objects["estante_2"] = Build.box(self, "Estante2", Vector3(2.6, 2.0, 0.5), Vector3(5.0, 1.0, -4.6), _mat_metal)
	objects["cajas"] = Build.box(self, "Cajas", Vector3(1.2, 1.2, 1.2), Vector3(6.5, 0.6, -1.4), Build.surface(Color(0.35, 0.30, 0.22)))
	_add_battery("PilaAlmacen", Vector3(5.0, 2.1, -4.6))

	var valve := TaskPoint.new()
	valve.name = "Valvula"
	add_child(valve)
	valve.position = Vector3(8.7, 0.0, -0.6)
	valve.setup_box(Vector3(0.5, 0.7, 0.7), Build.surface(Color(0.40, 0.42, 0.30)), Vector3(0.0, 1.0, 0.0))
	valve.task_id = "valvula"
	valve.active_prompt = "Purgar la válvula"
	valve.done_prompt = "Válvula purgada"
	valve.notice_on_done = "Sale agua marrón un rato y después clara."
	valve.log_text = "Válvula purgada. El agua salió marrón otra vez."
	points["valvula"] = valve
	Build.box(self, "Canio", Vector3(0.2, 2.2, 0.2), Vector3(8.7, 1.1, -0.6), _mat_metal)


func _build_airlock() -> void:
	var r: Rect2 = ROOMS["esclusa"]
	_mesh_room("Esclusa", r, {"n": [Vector2(0.0, Build.DOOR_W)], "s": [Vector2(0.0, Build.DOOR_W)]})
	room_lights["esclusa"] = Build.light(self, Vector3(0.0, 2.7, 9.0), Color(0.55, 0.65, 0.75), 1.0, 6.0)
	lights.append(room_lights["esclusa"])
	_add_door("esclusa", Vector3(-Build.DOOR_W * 0.5, 0.0, 11.0), 0.0, Build.DOOR_W)
	Build.label3d(self, "SALIDA / PATIO", Vector3(0.0, 2.35, 10.88), 0.0, 0.2, Color(0.8, 0.75, 0.6))

	# Tres trajes colgados. Las ultimas noches falta alguno.
	Build.box(self, "Perchero", Vector3(4.0, 0.08, 0.08), Vector3(0.0, 2.05, 7.5), _mat_metal)
	var suit_mat := Build.surface(Color(0.55, 0.38, 0.14))
	for i in 3:
		var suit := Node3D.new()
		suit.name = "Traje%d" % (i + 1)
		add_child(suit)
		suit.position = Vector3(-1.2 + i * 1.2, 0.0, 7.5)
		Build.box(suit, "Tela", Vector3(0.5, 1.3, 0.22), Vector3(0.0, 1.3, 0.0), suit_mat)
		variants["traje_%d" % (i + 1)] = suit
		objects["traje_%d" % (i + 1)] = suit
	Build.box(self, "BancoEsclusa", Vector3(2.2, 0.45, 0.6), Vector3(1.6, 0.22, 9.6), _mat_metal)
	_add_battery("PilaEsclusa", Vector3(0.9, 0.5, 9.6))

	var counter := SuitCounter.new()
	counter.name = "Perchero"
	add_child(counter)
	counter.position = Vector3(0.0, 0.0, 7.9)
	counter.setup_box(Vector3(4.2, 0.4, 0.5), _mat_metal, Vector3(0.0, 2.1, 0.0))
	points["trajes"] = counter


func _build_exterior() -> void:
	var r: Rect2 = ROOMS["patio"]
	Build.floor_slab(self, r, 0.0, _mat_snow, "Nieve")
	# Cerco perimetral: limita el patio sin techarlo.
	Build.wall(self, "cerco_n", 0, r.position.y, r.position.x, -3.0, _mat_metal, [], 2.4)
	Build.wall(self, "cerco_n2", 0, r.position.y, 3.0, r.end.x, _mat_metal, [], 2.4)
	Build.wall(self, "cerco_s", 0, r.end.y, r.position.x, r.end.x, _mat_metal, [], 2.4)
	Build.wall(self, "cerco_o", 2, r.position.x, r.position.y, r.end.y, _mat_metal, [], 2.4)
	Build.wall(self, "cerco_e", 2, r.end.x, r.position.y, r.end.y, _mat_metal, [], 2.4)

	Build.box(self, "Mastil", Vector3(0.3, 7.0, 0.3), Vector3(-8.0, 3.5, 20.0), _mat_metal)
	Build.box(self, "Antena", Vector3(3.0, 0.2, 0.2), Vector3(-8.0, 6.6, 20.0), _mat_metal)
	Build.box(self, "Contenedor", Vector3(5.0, 2.4, 2.4), Vector3(8.0, 1.2, 18.0), Build.surface(Color(0.32, 0.26, 0.24)))
	room_lights["patio"] = Build.light(self, Vector3(0.0, 4.0, 13.0), Color(0.55, 0.62, 0.75), 1.1, 12.0)
	lights.append(room_lights["patio"])

	# Tres puntos de control: la ronda es un recorrido, no un boton.
	var spots := [
		{"key": "ronda", "label": "PTO. 1", "pos": Vector3(9.5, 0.0, 15.0)},
		{"key": "ronda_2", "label": "PTO. 2", "pos": Vector3(1.0, 0.0, 25.5)},
		{"key": "ronda_3", "label": "PTO. 3", "pos": Vector3(-8.0, 0.0, 20.0)},
	]
	for spot in spots:
		var marker := TaskPoint.new()
		marker.name = "Marca_%s" % spot["key"]
		add_child(marker)
		marker.position = spot["pos"]
		marker.setup_box(Vector3(0.7, 1.2, 0.7), Build.surface(Color(0.75, 0.55, 0.15)), Vector3(0.0, 0.6, 0.0))
		marker.task_id = "round"
		marker.multi_step = true
		marker.active_prompt = "Marcar %s" % spot["label"]
		marker.done_prompt = "%s marcado" % spot["label"]
		points[spot["key"]] = marker
		Build.label3d(self, spot["label"], spot["pos"] + Vector3(0.0, 1.4, -0.4), PI, 0.18, Color(0.85, 0.7, 0.3))
	(points["ronda_3"] as TaskPoint).notice_on_done = "Viento 41 nudos. Sin novedad en el perímetro."
	(points["ronda_3"] as TaskPoint).log_text = "Ronda exterior hecha. Cuarenta y un nudos de viento."

	objects["tambores"] = Build.box(self, "Tambores", Vector3(0.8, 1.1, 0.8), Vector3(10.0, 0.55, 14.0), _mat_metal)
	Build.box(self, "Tambores2", Vector3(0.8, 1.1, 0.8), Vector3(10.9, 0.55, 14.6), _mat_metal)

	var antenna := TaskPoint.new()
	antenna.name = "ControlAntena"
	add_child(antenna)
	antenna.position = Vector3(-9.6, 0.0, 22.0)
	antenna.setup_box(Vector3(0.6, 1.3, 0.5), Build.surface(Color(0.35, 0.38, 0.40)), Vector3(0.0, 0.65, 0.0))
	antenna.task_id = "antena"
	antenna.active_prompt = "Realinear la antena"
	antenna.done_prompt = "Antena alineada"
	antenna.notice_on_done = "Alineada al norte. La portadora de la banda 4 sube."
	antenna.log_text = "Realineé la antena. La banda 4 se escucha más fuerte."
	points["antena"] = antenna
	Build.label3d(self, "ANT-1", Vector3(-9.6, 1.5, 21.7), PI, 0.18, Color(0.7, 0.72, 0.68))

	# Decision de la ultima noche: esperar el vehiculo.
	var leave := ChoicePoint.new()
	leave.name = "EsperarVehiculo"
	add_child(leave)
	leave.position = Vector3(0.0, 0.0, 25.0)
	leave.ending_id = "salir"
	leave.choice_prompt = "Esperar el vehículo acá"
	leave.setup_box(Vector3(1.2, 1.0, 1.2), Build.surface(Color(0.5, 0.45, 0.2)), Vector3(0.0, 0.5, 0.0))
	points["salir"] = leave
	Build.label3d(self, "PUNTO DE RETIRO", Vector3(0.0, 1.5, 24.4), PI, 0.2, Color(0.8, 0.7, 0.4))


func _build_south() -> void:
	# Tramo que solo existe algunas noches: el pasillo que no esta en los planos.
	south_section = Node3D.new()
	south_section.name = "PasilloSur"
	add_child(south_section)

	var r: Rect2 = ROOMS["pasillo sur"]
	Build.floor_slab(south_section, r, 0.0, _mat_floor)
	Build.ceiling_slab(south_section, r, 0.0, _mat_wall)
	Build.wall(south_section, "sur_o", 2, r.position.x, r.position.y, r.end.y, _mat_wall)
	Build.wall(south_section, "sur_e", 2, r.end.x, r.position.y, r.end.y, _mat_wall)
	Build.wall(south_section, "sur_n", 0, r.position.y, r.position.x, r.end.x, _mat_wall, [Vector2(0.0, Build.DOOR_W)])
	Build.light(south_section, Vector3(0.0, 2.75, -20.0), Color(0.45, 0.5, 0.58), 0.9, 8.0)
	Build.label3d(south_section, "SUBNIVEL B2", Vector3(-1.35, 2.2, -19.0), PI * 0.5, 0.2, Color(0.5, 0.55, 0.6))

	subnivel_section = Node3D.new()
	subnivel_section.name = "SubnivelB2"
	south_section.add_child(subnivel_section)
	_build_b2()


## El B2: cinco espacios encadenados hacia abajo. Todo cuelga de
## `subnivel_section`, asi que existe o no existe segun la noche, sin agregar
## una escena nueva.
##
##        entrada (rampa desde el pasillo sur)
##           |
##        pasillo ---- bombas (oeste)  /  archivo (este)
##           |
##        fondo (las marcas, y la decision de la ultima noche)
func _build_b2() -> void:
	var entrada: Rect2 = ROOMS["subnivel"]
	var pasillo: Rect2 = ROOMS["b2 pasillo"]
	var bombas: Rect2 = ROOMS["b2 bombas"]
	var archivo: Rect2 = ROOMS["b2 archivo"]
	var fondo: Rect2 = ROOMS["b2 fondo"]

	# --- Entrada: la sala que ya existia, ahora con salida al fondo ---
	_b2_slabs(entrada)
	Build.wall(subnivel_section, "b2_o", 2, entrada.position.x, entrada.position.y, entrada.end.y, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2_e", 2, entrada.end.x, entrada.position.y, entrada.end.y, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2_n", 0, entrada.end.y, entrada.position.x, entrada.end.x, _mat_dark, [Vector2(0.0, Build.DOOR_W)], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2_s", 0, entrada.position.y, entrada.position.x, entrada.end.x, _mat_dark, [Vector2(0.0, Build.DOOR_W)], Build.WALL_H, B2_Y)
	# Rampa corta desde el pasillo sur hasta el B2.
	Build.box(subnivel_section, "Rampa", Vector3(3.0, 0.2, 2.0), Vector3(0.0, -0.3, -23.2), _mat_dark)
	_b2_light("subnivel", Vector3(0.0, 1.0, -28.0), Color(0.35, 0.40, 0.45), 0.9, 6.0)
	Build.label3d(subnivel_section, "B2  ---  ACCESO", Vector3(-3.9, 1.2, -28.0), PI * 0.5, 0.18, Color(0.5, 0.52, 0.5))

	# La tarea de bajar se completa llegando, no apretando un boton.
	var zone := TriggerZone.new()
	zone.name = "ZonaSubnivel"
	subnivel_section.add_child(zone)
	zone.position = Vector3(0.0, B2_Y, -28.0)
	zone.task_id = "subnivel"
	zone.notice = "El aire de abajo está quieto."
	zone.configure(Vector3(6.0, 2.4, 4.0))
	points["subnivel"] = zone

	# --- Pasillo: la columna que baja, con las dos salas a los costados ---
	_b2_slabs(pasillo)
	Build.wall(subnivel_section, "b2p_o", 2, pasillo.position.x, pasillo.position.y, pasillo.end.y, _mat_dark, [Vector2(-38.0, Build.DOOR_W)], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2p_e", 2, pasillo.end.x, pasillo.position.y, pasillo.end.y, _mat_dark, [Vector2(-38.0, Build.DOOR_W)], Build.WALL_H, B2_Y)
	_b2_light("b2 pasillo", Vector3(0.0, 1.0, -37.5), Color(0.30, 0.34, 0.38), 0.7, 9.0)
	Build.label3d(subnivel_section, "BOMBAS", Vector3(-1.4, 1.3, -36.4), PI * 0.5, 0.16, Color(0.48, 0.5, 0.48))
	Build.label3d(subnivel_section, "ARCHIVO", Vector3(1.4, 1.3, -36.4), -PI * 0.5, 0.16, Color(0.48, 0.5, 0.48))

	# --- Sala de bombas ---
	_b2_slabs(bombas)
	Build.wall(subnivel_section, "b2b_o", 2, bombas.position.x, bombas.position.y, bombas.end.y, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2b_n", 0, bombas.end.y, bombas.position.x, bombas.end.x, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2b_s", 0, bombas.position.y, bombas.position.x, bombas.end.x, _mat_dark, [], Build.WALL_H, B2_Y)
	_b2_light("b2 bombas", Vector3(-6.0, 1.0, -38.0), Color(0.42, 0.34, 0.28), 0.8, 7.0)
	_b2_task("bomba_a", "bombas", Vector3(-8.6, B2_Y, -36.6), Vector3(0.9, 1.4, 0.9),
		"Purgar la bomba A", "La bomba A ya está purgada", true)
	_b2_task("bomba_b", "bombas", Vector3(-8.6, B2_Y, -39.6), Vector3(0.9, 1.4, 0.9),
		"Purgar la bomba B", "La bomba B ya está purgada", true)
	_b2_prop("b2_tanque", Vector3(-4.0, B2_Y, -39.8), 0.0, Vector3(1.6, 1.8, 1.2))
	_b2_prop("b2_banco", Vector3(-3.6, B2_Y, -36.2), 0.0, Vector3(1.8, 0.85, 0.7))
	_b2_task("llave_bombas", "cerrar_b2", Vector3(-6.2, B2_Y, -40.4), Vector3(0.7, 1.0, 0.5),
		"Cerrar la llave de las bombas", "Esta llave ya está cerrada", true)

	# --- Archivo ---
	_b2_slabs(archivo)
	Build.wall(subnivel_section, "b2a_e", 2, archivo.end.x, archivo.position.y, archivo.end.y, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2a_n", 0, archivo.end.y, archivo.position.x, archivo.end.x, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2a_s", 0, archivo.position.y, archivo.position.x, archivo.end.x, _mat_dark, [], Build.WALL_H, B2_Y)
	_b2_light("b2 archivo", Vector3(6.0, 1.0, -38.0), Color(0.36, 0.40, 0.36), 0.7, 7.0)
	_b2_prop("b2_estante_a", Vector3(9.3, B2_Y, -36.6), 0.0, Vector3(0.5, 2.0, 2.4))
	_b2_prop("b2_estante_b", Vector3(9.3, B2_Y, -39.6), 0.0, Vector3(0.5, 2.0, 2.4))
	_b2_prop("b2_fichero", Vector3(4.0, B2_Y, -40.2), 0.0, Vector3(1.0, 1.3, 0.6))
	_b2_task("llave_archivo", "cerrar_b2", Vector3(7.4, B2_Y, -40.4), Vector3(0.7, 1.0, 0.5),
		"Cerrar la llave del archivo", "Esta llave ya está cerrada", true)
	_b2_task("legajo", "legajo", Vector3(4.2, B2_Y, -36.4), Vector3(1.1, 0.9, 0.8),
		"Buscar tu legajo", "Ya lo buscaste", false,
		"Tu legajo figura archivado. Con fecha de cierre.")

	# --- Fondo: las marcas y la decision ---
	_b2_slabs(fondo)
	Build.wall(subnivel_section, "b2f_o", 2, fondo.position.x, fondo.position.y, fondo.end.y, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2f_e", 2, fondo.end.x, fondo.position.y, fondo.end.y, _mat_dark, [], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2f_n", 0, fondo.end.y, fondo.position.x, fondo.end.x, _mat_dark, [Vector2(0.0, Build.DOOR_W)], Build.WALL_H, B2_Y)
	Build.wall(subnivel_section, "b2f_s", 0, fondo.position.y, fondo.position.x, fondo.end.x, _mat_dark, [], Build.WALL_H, B2_Y)
	_b2_light("b2 fondo", Vector3(0.0, 1.0, -47.0), Color(0.30, 0.32, 0.38), 0.6, 8.0)

	Build.box(subnivel_section, "Marcas", Vector3(3.2, 1.2, 0.06),
		Vector3(0.0, B2_Y + 1.4, -49.9), Build.surface(Color(0.22, 0.20, 0.20)))
	Build.label3d(subnivel_section, "|||| |||| |||| ||",
		Vector3(0.0, B2_Y + 1.5, -49.84), 0.0, 0.22, Color(0.55, 0.5, 0.45))
	_b2_prop("b2_camastro", Vector3(-3.4, B2_Y, -47.4), 0.0, Vector3(0.9, 0.45, 2.0))
	_b2_prop("b2_lata", Vector3(3.2, B2_Y, -46.0), 0.0, Vector3(0.35, 0.4, 0.35))
	_b2_task("llave_fondo", "cerrar_b2", Vector3(0.0, B2_Y, -45.4), Vector3(1.2, 1.0, 0.7),
		"Cerrar la llave del fondo", "Esta llave ya está cerrada", true,
		"Las tres llaves del B2 cerradas. El subnivel queda muerto.")

	# Decision de la ultima noche: quedarse abajo.
	var stay := ChoicePoint.new()
	stay.name = "QuedarseAbajo"
	subnivel_section.add_child(stay)
	stay.position = Vector3(0.0, B2_Y, -48.6)
	stay.ending_id = "quedarse"
	stay.choice_prompt = "Cerrar la escotilla desde adentro"
	stay.setup_box(Vector3(1.4, 0.9, 0.6), _mat_dark, Vector3(0.0, 0.45, 0.0))
	points["quedarse"] = stay

	for id in ["subnivel", "b2 bombas", "b2 archivo", "b2 fondo"]:
		var w := RoomWatcher.new()
		w.name = "Watcher_%s" % id
		subnivel_section.add_child(w)
		w.configure(id, ROOMS[id], Build.WALL_H, B2_Y)
		watchers[id] = w


func _b2_slabs(rect: Rect2) -> void:
	Build.floor_slab(subnivel_section, rect, B2_Y, _mat_dark)
	Build.ceiling_slab(subnivel_section, rect, B2_Y, _mat_dark)


func _b2_light(room: String, pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var l := Build.light(subnivel_section, pos, color, energy, range_m)
	room_lights[room] = l
	lights.append(l)


## Un punto de tarea del B2. `multi` marca los que son un paso de una tarea de
## varios (las dos bombas, los tres cierres).
func _b2_task(name: String, task_id: String, pos: Vector3, size: Vector3,
		prompt: String, done: String, multi: bool, log_text := "") -> TaskPoint:
	var t := TaskPoint.new()
	t.name = "Punto_%s" % name
	subnivel_section.add_child(t)
	t.position = pos
	t.task_id = task_id
	t.active_prompt = prompt
	t.done_prompt = done
	t.multi_step = multi
	t.log_text = log_text
	t.setup_box(size, _mat_metal, Vector3(0.0, size.y * 0.5, 0.0))
	points[name] = t
	return t


func _b2_prop(id: String, pos: Vector3, rot_y: float, size: Vector3) -> Prop:
	var p := Prop.new()
	p.name = "Prop_%s" % id
	subnivel_section.add_child(p)
	p.position = pos
	p.rotation.y = rot_y
	Build.box(p, "Cuerpo", size, Vector3(0.0, size.y * 0.5, 0.0), _mat_metal)
	# Pose alterada por defecto: corrido y girado apenas. Las anomalias que
	# traen `pos`/`rot` propios igual pisan esto.
	p.register(id, Vector3(0.45, 0.0, 0.35), 28.0)
	props[id] = p
	objects[id] = p
	return p


func _build_routes() -> void:
	# El pasillo sur se muerde la cola: caminar hacia el fondo devuelve al
	# principio del pasillo, hasta que deja de hacerlo.
	var loop_dest := Node3D.new()
	loop_dest.name = "DestinoPasilloSur"
	add_child(loop_dest)
	loop_dest.position = Vector3(0.0, 0.0, -14.6)

	var loop := RouteSwap.new()
	loop.name = "RutaPasilloSur"
	south_section.add_child(loop)
	loop.position = Vector3(0.0, 0.0, -20.5)
	loop.loop_limit = 2
	loop.configure(loop_dest, Vector3(3.0, 2.6, 0.5))
	routes["pasillo_sur"] = loop

	# La puerta del dormitorio deja de dar al dormitorio.
	var swap_dest := Node3D.new()
	swap_dest.name = "DestinoAlmacen"
	add_child(swap_dest)
	swap_dest.position = Vector3(1.5, 0.0, -2.5)
	swap_dest.rotation.y = -PI * 0.5

	var swap := RouteSwap.new()
	swap.name = "RutaPuertaDormitorio"
	add_child(swap)
	swap.position = Vector3(-1.5, 0.0, -2.5)
	swap.rotation.y = PI * 0.5
	swap.loop_limit = 1
	swap.configure(swap_dest, Vector3(Build.DOOR_W, 2.4, 0.5))
	routes["puerta_dormitorio"] = swap


## Los objetos que solo aparecen cuando una anomalia los enciende. Se arman
## una sola vez, apagados: la estacion ya los tiene adentro.
func _build_extras() -> void:
	for id in AnomalyData.EXTRAS.keys():
		var spec: Dictionary = AnomalyData.EXTRAS[id]
		var holder := Node3D.new()
		holder.name = "Extra_%s" % id
		add_child(holder)
		holder.position = spec.get("pos", Vector3.ZERO)
		holder.rotation.y = deg_to_rad(float(spec.get("rot", 0.0)))
		match String(spec.get("tipo", "caja")):
			"silla":
				Build.box(holder, "Asiento", Vector3(0.55, 0.08, 0.55), Vector3(0.0, 0.45, 0.0), _mat_metal)
				Build.box(holder, "Respaldo", Vector3(0.55, 0.5, 0.08), Vector3(0.0, 0.7, -0.25), _mat_metal)
				Build.box(holder, "Pata", Vector3(0.08, 0.45, 0.08), Vector3(0.0, 0.22, 0.0), _mat_metal)
			"marca":
				Build.label3d(holder, String(spec.get("texto", "")), Vector3.ZERO, 0.0,
					float(spec.get("size", 0.24)), Color(0.72, 0.66, 0.60))
			_:
				Build.box(holder, "Cuerpo", spec.get("size", Vector3.ONE),
					Vector3.ZERO, Build.surface(spec.get("color", Color(0.3, 0.3, 0.3))))
		Build.set_active(holder, false)
		objects[id] = holder


## Tarea de la Noche 4: recorrer la estacion anotando que cambio. Son cuatro
## paradas, una por sala, sobre la superficie.
func _build_recuento() -> void:
	var donde := {
		"recuento_dorm": Vector3(-8.8, 0.0, -1.2),
		"recuento_control": Vector3(-8.8, 0.0, -9.2),
		"recuento_gen": Vector3(8.8, 0.0, -9.2),
		"recuento_almacen": Vector3(8.8, 0.0, -1.2),
	}
	for id in donde.keys():
		var t := TaskPoint.new()
		t.name = "Punto_%s" % id
		add_child(t)
		t.position = donde[id]
		t.task_id = "recuento"
		t.active_prompt = "Anotar lo que cambió acá"
		t.done_prompt = "Ya lo anotaste"
		t.multi_step = true
		t.setup_box(Vector3(0.5, 1.1, 0.5), _mat_metal, Vector3(0.0, 0.55, 0.0))
		points[id] = t
	(points["recuento_almacen"] as TaskPoint).log_text = "Recorrí las cuatro salas anotando. La lista no me cierra."

	# La Noche 4 apaga el B2: bajar y encontrar pared es la tarea.
	var vacio := TriggerZone.new()
	vacio.name = "ZonaSinB2"
	south_section.add_child(vacio)
	vacio.position = Vector3(0.0, 0.0, -22.0)
	vacio.task_id = "sin_b2"
	vacio.notice = "Acá bajaba la rampa. Ahora es pared."
	vacio.configure(Vector3(3.0, 2.6, 3.0))
	points["sin_b2"] = vacio


func _build_watchers() -> void:
	for id in ["dormitorio", "sala de control", "sala de generador", "almacen", "patio"]:
		var w := RoomWatcher.new()
		w.name = "Watcher_%s" % id
		add_child(w)
		w.configure(id, ROOMS[id])
		watchers[id] = w


func _add_door(id: String, hinge: Vector3, rot_y: float, width: float) -> Door:
	var d := Door.new()
	d.name = "Puerta_%s" % id
	add_child(d)
	d.position = hinge
	d.rotation.y = rot_y
	d.configure(width, _mat_metal)
	doors[id] = d
	return d


func _add_prop(id: String, pos: Vector3, rot_y: float, size: Vector3) -> Prop:
	var p := Prop.new()
	p.name = "Prop_%s" % id
	add_child(p)
	p.position = pos
	p.rotation.y = rot_y
	# Silla: asiento + respaldo, dos cajas y listo.
	Build.box(p, "Asiento", Vector3(size.x, 0.08, size.z), Vector3(0.0, size.y * 0.5, 0.0), _mat_metal)
	Build.box(p, "Respaldo", Vector3(size.x, size.y * 0.55, 0.08), Vector3(0.0, size.y * 0.78, -size.z * 0.45), _mat_metal)
	Build.box(p, "Pata", Vector3(0.08, size.y * 0.5, 0.08), Vector3(0.0, size.y * 0.25, 0.0), _mat_metal)
	props[id] = p
	objects[id] = p
	return p


## Los registros se colocan desde la tabla de contenido: agregar uno es
## escribirlo en night_data.gd, no tocar la estacion.
func _build_radio_logs() -> void:
	for id in NightData.RADIO_LOGS.keys():
		var data: Dictionary = NightData.RADIO_LOGS[id]
		var pos: Vector3 = data.get("pos", Vector3.ZERO)
		var parent: Node3D = self
		if pos.z <= -24.0:
			parent = subnivel_section
		elif pos.z <= -16.0:
			parent = south_section
		_add_radio_log(id, pos, int(data.get("night", 1)), parent)


## Objetos para mirar de cerca: van de la tabla de contenido al mundo.
func _build_inspectables() -> void:
	for id in NightData.INSPECTABLES.keys():
		var spec: Dictionary = NightData.INSPECTABLES[id]
		var item := Inspectable.new()
		item.name = "Inspeccionable_%s" % id
		add_child(item)
		item.position = spec.get("pos", Vector3.ZERO)
		item.inspect_id = String(id)
		item.titulo = String(spec.get("titulo", "Objeto"))
		item.setup_box(spec.get("size", Vector3(0.1, 0.1, 0.1)),
			Build.surface(spec.get("color", Color(0.5, 0.5, 0.5))))
		points["ver_%s" % id] = item
		objects[String(id)] = item


func _add_battery(name: String, pos: Vector3) -> BatteryPickup:
	var bat := BatteryPickup.new()
	bat.name = name
	add_child(bat)
	bat.position = pos
	bat.setup_box(Vector3(0.18, 0.3, 0.18), Build.surface(Color(0.7, 0.66, 0.2)))
	pickups.append(bat)
	return bat


func _add_radio_log(id: String, pos: Vector3, from_night: int, parent: Node3D = null) -> RadioLog:
	var rl := RadioLog.new()
	rl.name = "Registro_%s" % id
	(parent if parent != null else self).add_child(rl)
	rl.position = pos
	rl.log_id = id
	rl.setup_box(Vector3(0.28, 0.1, 0.18), Build.surface(Color(0.45, 0.42, 0.38)))
	rl.set_meta("from_night", from_night)
	points["log_%s" % id] = rl
	return rl


## Centros de las salas: de ahi salen los crujidos y los golpes ambiente.
func ambient_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for id in ROOMS.keys():
		var r: Rect2 = ROOMS[id]
		var c := r.get_center()
		out.append(Vector3(c.x, 1.6, c.y))
	return out


func recolor_walls(tint: Color) -> void:
	var mat := Build.surface(tint)
	for m in wall_meshes:
		if is_instance_valid(m):
			m.material_override = mat
