class_name Build
extends RefCounted
## Helpers de construccion en codigo. Toda la estacion se arma con cajas:
## es la geometria mas barata posible y encaja con la estetica low-poly.

const WALL_H := 3.0
const WALL_T := 0.16
const DOOR_W := 1.35
const DOOR_H := 2.2

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_INTERACT := 4

static var _mat_cache := {}
static var _shader: Shader = null

## Repeticiones por metro. Cada superficie pide la suya: el piso necesita
## placas de medio metro, la nieve no puede repetirse tan seguido o se nota
## el patron.
const TEX_SCALE := {
	"chapa": 0.5,
	"piso": 0.5,
	"rejilla": 0.7,
	"metal": 0.9,
	"oxido": 0.35,
	"nieve": 0.18,
	"hormigon": 0.4,
	"crt": 2.5,
}


## `textura`: nombre de una de las texturas generadas por codigo (ver
## textures.gd). El color sigue siendo el que manda: la textura es gris y
## multiplica, asi que `recolor_walls` puede seguir tiniendo la estacion por
## noche sin regenerar nada.
##
## `escala`: repeticiones por metro, si hay que pisar la de TEX_SCALE. Las de
## la tabla estan pensadas para paredes y pisos, que miden metros. Un matafuego
## de 22 cm con la escala de "metal" muestra un quinto de baldosa, o sea un
## manchon plano. Los props piden bastante mas repeticion para que la textura
## se lea como material y no como suciedad al azar.
static func surface(color: Color, emission := 0.0, snap := 0.8, textura := "", escala := 0.0) -> Material:
	var key := "%s|%.2f|%.2f|%s|%.2f" % [color.to_html(false), emission, snap, textura, escala]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat: Material
	if _shader == null:
		_shader = load("res://shaders/ps1_surface.gdshader") as Shader
	if _shader != null:
		var sm := ShaderMaterial.new()
		sm.shader = _shader
		sm.set_shader_parameter("albedo_color", Vector3(color.r, color.g, color.b))
		sm.set_shader_parameter("emission_amount", emission)
		sm.set_shader_parameter("snap_strength", snap)
		if textura != "":
			var tex := Textures.por_nombre(textura)
			if tex != null:
				sm.set_shader_parameter("albedo_tex", tex)
				sm.set_shader_parameter("use_tex", true)
				var rep: float = escala if escala > 0.0 else float(TEX_SCALE.get(textura, 0.5))
				sm.set_shader_parameter("tex_scale", rep)
		mat = sm
	else:
		var std := StandardMaterial3D.new()
		std.albedo_color = color
		std.roughness = 1.0
		std.emission_enabled = emission > 0.0
		std.emission = color
		std.emission_energy_multiplier = emission
		mat = std
	_mat_cache[key] = mat
	return mat


static func clear_cache() -> void:
	_mat_cache.clear()


## `shadow`: si la caja proyecta sombra. Por defecto si. Hasta ahora estaba
## apagado en todas, asi que aunque una luz tuviera sombra no habia nada que
## la proyectara: la estacion entera era geometria transparente a la luz.
## Se apaga en lo que no conviene que la proyecte (carteles, detalle fino que
## solo agregaria ruido al mapa de sombras).
static func box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material, collide := true, shadow := true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.name = "Body"
		body.collision_layer = LAYER_WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.add_child(shape)
		mi.add_child(body)
	return mi


## Una pieza de malla cualquiera, sin colision. La usan los modelos de
## modelos.gd: un prop se arma con diez o quince de estas, y la colision la
## pone una sola caja en el nodo padre. Nadie necesita chocar contra el
## volante de una valvula con precision de volante.
static func pieza(parent: Node, name: String, mesh: Mesh, pos: Vector3, mat: Material,
		rot := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Caja sin colision, para el detalle de un prop.
static func detalle(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material,
		rot := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return pieza(parent, name, mesh, pos, mat, rot, shadow)


static func floor_slab(parent: Node, rect: Rect2, y: float, mat: Material, name := "Piso") -> void:
	var c := rect.get_center()
	box(parent, name, Vector3(rect.size.x, 0.2, rect.size.y), Vector3(c.x, y - 0.1, c.y), mat)


static func ceiling_slab(parent: Node, rect: Rect2, y: float, mat: Material, name := "Techo") -> void:
	var c := rect.get_center()
	box(parent, name, Vector3(rect.size.x, 0.2, rect.size.y), Vector3(c.x, y + WALL_H + 0.1, c.y), mat)


## Pared alineada a un eje, con huecos para puertas.
## axis 0 = corre sobre X (Z fijo); axis 2 = corre sobre Z (X fijo).
## openings: Array[Vector2] -> (centro sobre el eje, ancho del hueco).
static func wall(parent: Node, name: String, axis: int, fixed: float, a: float, b: float,
		mat: Material, openings: Array = [], height := WALL_H, base_y := 0.0) -> void:
	var lo := minf(a, b)
	var hi := maxf(a, b)
	var cuts: Array = []
	for o in openings:
		var op: Vector2 = o
		var s := clampf(op.x - op.y * 0.5, lo, hi)
		var e := clampf(op.x + op.y * 0.5, lo, hi)
		if e > s:
			cuts.append(Vector2(s, e))
	cuts.sort_custom(func(x, y): return x.x < y.x)

	var cursor := lo
	var idx := 0
	for cut in cuts:
		if cut.x > cursor:
			_wall_piece(parent, "%s_%d" % [name, idx], axis, fixed, cursor, cut.x, base_y, height, mat)
			idx += 1
		# Dintel sobre el hueco.
		if height > DOOR_H:
			_wall_piece(parent, "%s_dintel_%d" % [name, idx], axis, fixed, cut.x, cut.y,
					base_y + DOOR_H, height - DOOR_H, mat)
			idx += 1
		cursor = maxf(cursor, cut.y)
	if cursor < hi:
		_wall_piece(parent, "%s_%d" % [name, idx], axis, fixed, cursor, hi, base_y, height, mat)


static func _wall_piece(parent: Node, name: String, axis: int, fixed: float, a: float, b: float,
		base_y: float, height: float, mat: Material) -> void:
	var length := b - a
	if length <= 0.001 or height <= 0.001:
		return
	var mid := (a + b) * 0.5
	var size: Vector3
	var pos: Vector3
	if axis == 0:
		size = Vector3(length, height, WALL_T)
		pos = Vector3(mid, base_y + height * 0.5, fixed)
	else:
		size = Vector3(WALL_T, height, length)
		pos = Vector3(fixed, base_y + height * 0.5, mid)
	box(parent, name, size, pos, mat)


## Habitacion cerrada: piso, techo y cuatro paredes con sus huecos.
## openings: {"n": [Vector2...], "s": [...], "e": [...], "w": [...]}
static func room(parent: Node, name: String, rect: Rect2, mat_wall: Material, mat_floor: Material,
		openings := {}, with_ceiling := true) -> Node3D:
	var holder := Node3D.new()
	holder.name = name
	parent.add_child(holder)
	floor_slab(holder, rect, 0.0, mat_floor)
	if with_ceiling:
		ceiling_slab(holder, rect, 0.0, mat_wall)
	var x0 := rect.position.x
	var x1 := rect.end.x
	var z0 := rect.position.y
	var z1 := rect.end.y
	# n = Z minimo (norte del plano), s = Z maximo.
	wall(holder, "pared_n", 0, z0, x0, x1, mat_wall, openings.get("n", []))
	wall(holder, "pared_s", 0, z1, x0, x1, mat_wall, openings.get("s", []))
	wall(holder, "pared_o", 2, x0, z0, z1, mat_wall, openings.get("w", []))
	wall(holder, "pared_e", 2, x1, z0, z1, mat_wall, openings.get("e", []))
	return holder


## Todas las luces creadas al armar la estacion, para que el presupuesto de
## sombras las conozca a todas y no solo a las de sala.
static var created: Array[OmniLight3D] = []


static func light(parent: Node, pos: Vector3, color: Color, energy: float, range_m := 9.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	# Atenuacion mas marcada: la luz cae rapido y se forma un charco en vez de
	# banar la sala entera. Es la mitad de lo que hace que haya oscuridad.
	l.omni_attenuation = 1.6
	# La sombra la enciende el presupuesto, segun donde este el jugador.
	l.shadow_enabled = false
	l.shadow_bias = 0.04
	l.shadow_normal_bias = 1.4
	# Sombra de baja resolucion a proposito: dura, con el borde escalonado.
	# Es la estetica, y ademas es lo barato.
	l.shadow_blur = 0.0
	l.distance_fade_enabled = true
	l.distance_fade_begin = 22.0
	l.distance_fade_length = 6.0
	parent.add_child(l)
	created.append(l)
	return l


static func label3d(parent: Node, text: String, pos: Vector3, rot_y := 0.0, size := 0.25, color := Color(0.75, 0.78, 0.8)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation.y = rot_y
	l.pixel_size = size * 0.01
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.shaded = false
	l.double_sided = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	parent.add_child(l)
	return l


## Activa o desactiva un tramo de estacion (visibilidad + colisiones).
static func set_active(node: Node, active: bool) -> void:
	if node is Node3D:
		(node as Node3D).visible = active
	_set_collisions(node, active)


## Las anomalias se aplican desde la senal de un Area3D, o sea en mitad del
## paso de fisica, y ahi Godot rechaza el cambio y lo ignora en silencio: el
## objeto desaparecia pero se le seguia chocando. Por eso va diferido.
static func _set_collisions(node: Node, active: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", not active)
		_set_collisions(child, active)
