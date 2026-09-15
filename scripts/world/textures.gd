# -*- coding: utf-8 -*-
class_name Textures
extends RefCounted
## Texturas generadas por codigo. Ningun archivo, ninguna licencia que revisar.
##
## Por que generadas y no pintadas: el proyecto se construye entero por codigo
## y no tiene presupuesto para arte. Una caja con textura de chapa sucia se lee
## como una pared de estacion; una caja gris se lee como una caja gris. Esto es
## lo mas barato que cambia esa lectura.
##
## Por que 64 pixeles: la estetica PS1 pide poca resolucion de textura, y el
## objetivo de hardware es gama baja. Ademas, a 64 px una textura procedural
## parece intencional; a 512 px parece ruido.
##
## Todas se filtran con NEAREST y sin mipmaps: el aliasing y el temblor al
## moverse son parte del look, no un defecto a corregir.
##
## Las texturas van en escala de grises alrededor de 1.0, y el color lo pone
## el material que las usa. Asi `recolor_walls` sigue tinendo la estacion por
## noche sin que haya que regenerar nada.

const SIZE := 64

static var _cache := {}


## Chapa de pared: juntas horizontales, remaches, y manchas verticales de
## humedad que bajan desde las juntas.
static func chapa() -> Texture2D:
	return _crear("chapa", func(img: Image) -> void:
		_fill(img, 1.0)
		_grain(img, 0.055, 11)
		# Dos juntas horizontales, con su sombra abajo y su brillo arriba.
		for y in [16, 48]:
			_line_h(img, y, 0.72)
			_line_h(img, y + 1, 1.12)
		# Remaches a los costados de cada junta.
		for y in [16, 48]:
			for x in range(6, SIZE, 13):
				_dot(img, x, y - 4, 1.18)
		_streaks(img, 0.88, 7, 23)
	)


## Piso interior: placas cuadradas con la junta marcada y el centro gastado.
static func piso() -> Texture2D:
	return _crear("piso", func(img: Image) -> void:
		_fill(img, 0.96)
		_grain(img, 0.045, 3)
		_line_h(img, 0, 0.7)
		_line_h(img, 32, 0.7)
		_line_v(img, 0, 0.7)
		_line_v(img, 32, 0.7)
		# El centro de cada placa esta mas pisado, o sea mas claro.
		for cx in [16, 48]:
			for cy in [16, 48]:
				_blob(img, cx, cy, 9, 1.07)
	)


## Rejilla del subnivel: ranuras oscuras, se ve el vacio entre medio.
static func rejilla() -> Texture2D:
	return _crear("rejilla", func(img: Image) -> void:
		_fill(img, 0.92)
		_grain(img, 0.04, 17)
		for x in range(0, SIZE, 8):
			for dx in 5:
				_line_v(img, x + dx, 0.34)
		for y in range(0, SIZE, 32):
			_line_h(img, y, 1.0)
			_line_h(img, y + 1, 1.0)
	)


## Metal de equipos: mas liso, con rayones finos.
static func metal() -> Texture2D:
	return _crear("metal", func(img: Image) -> void:
		_fill(img, 1.0)
		_grain(img, 0.03, 29)
		_scratches(img, 14, 1.16, 31)
	)


## Oxido: manchas irregulares, para lo que lleva tiempo abandonado.
static func oxido() -> Texture2D:
	return _crear("oxido", func(img: Image) -> void:
		_fill(img, 0.95)
		_grain(img, 0.07, 5)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 22:
			_blob(img, rng.randi_range(0, SIZE), rng.randi_range(0, SIZE),
				rng.randi_range(3, 9), rng.randf_range(0.62, 0.84))
	)


## Nieve del patio: casi plana, apenas ondulada. Si tiene mucho detalle deja
## de leerse como nieve y pasa a parecer arena.
static func nieve() -> Texture2D:
	return _crear("nieve", func(img: Image) -> void:
		_fill(img, 1.0)
		_grain(img, 0.025, 13)
		var rng := RandomNumberGenerator.new()
		rng.seed = 13
		for i in 10:
			_blob(img, rng.randi_range(0, SIZE), rng.randi_range(0, SIZE),
				rng.randi_range(8, 18), rng.randf_range(0.96, 1.05))
	)


## Hormigon del B2: sucio, manchado, sin juntas regulares. Abajo no hay chapa.
static func hormigon() -> Texture2D:
	return _crear("hormigon", func(img: Image) -> void:
		_fill(img, 0.98)
		_grain(img, 0.06, 23)
		var rng := RandomNumberGenerator.new()
		rng.seed = 23
		for i in 16:
			_blob(img, rng.randi_range(0, SIZE), rng.randi_range(0, SIZE),
				rng.randi_range(5, 14), rng.randf_range(0.80, 0.94))
		_streaks(img, 0.9, 4, 41)
	)


## Despacha por nombre, para que quien pide una textura no tenga que conocer
## la funcion. Si el nombre no existe devuelve null y el material queda sin
## textura, que es un color plano: se degrada, no rompe.
static func por_nombre(nombre: String) -> Texture2D:
	match nombre:
		"chapa": return chapa()
		"piso": return piso()
		"rejilla": return rejilla()
		"metal": return metal()
		"oxido": return oxido()
		"nieve": return nieve()
		"hormigon": return hormigon()
	return null


# --- Fabrica y cache -------------------------------------------------------

static func _crear(key: String, pintar: Callable) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	pintar.call(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


# --- Pinceles --------------------------------------------------------------
#
# Todo trabaja sobre el canal de gris. Se multiplica en vez de asignar, para
# que las capas se acumulen (una mancha sobre una junta oscurece las dos).

static func _fill(img: Image, v: float) -> void:
	img.fill(Color(v, v, v))


static func _mul(img: Image, x: int, y: int, f: float) -> void:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return
	var c := img.get_pixel(x, y)
	var v := clampf(c.r * f, 0.0, 1.0)
	img.set_pixel(x, y, Color(v, v, v))


static func _grain(img: Image, amount: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in SIZE:
		for x in SIZE:
			_mul(img, x, y, 1.0 + rng.randf_range(-amount, amount))


static func _line_h(img: Image, y: int, f: float) -> void:
	for x in SIZE:
		_mul(img, x, y % SIZE, f)


static func _line_v(img: Image, x: int, f: float) -> void:
	for y in SIZE:
		_mul(img, x % SIZE, y, f)


static func _dot(img: Image, x: int, y: int, f: float) -> void:
	_mul(img, x, y, f)
	_mul(img, x + 1, y, f)
	_mul(img, x, y + 1, f)
	_mul(img, x + 1, y + 1, f)


## Mancha redonda con borde suave.
static func _blob(img: Image, cx: int, cy: int, r: int, f: float) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d := sqrt(float(dx * dx + dy * dy))
			if d > float(r):
				continue
			var borde := 1.0 - (d / float(r))
			_mul(img, cx + dx, cy + dy, lerpf(1.0, f, borde * borde))


## Chorreaduras verticales, como humedad bajando por una pared.
static func _streaks(img: Image, f: float, cuantas: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in cuantas:
		var x := rng.randi_range(0, SIZE - 1)
		var y0 := rng.randi_range(0, SIZE - 1)
		var largo := rng.randi_range(8, 28)
		for dy in largo:
			var desvanece := 1.0 - float(dy) / float(largo)
			_mul(img, x, (y0 + dy) % SIZE, lerpf(1.0, f, desvanece))


## Rayones finos en diagonal.
static func _scratches(img: Image, cuantos: int, f: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in cuantos:
		var x := rng.randi_range(0, SIZE - 1)
		var y := rng.randi_range(0, SIZE - 1)
		var largo := rng.randi_range(4, 16)
		var paso := 1 if rng.randf() > 0.5 else -1
		for d in largo:
			_mul(img, (x + d) % SIZE, (y + d * paso + SIZE) % SIZE, f)
