# -*- coding: utf-8 -*-
class_name Modelos
extends RefCounted
## Props armados con primitivas compuestas, en vez de una caja por objeto.
##
## Por que existe. La estacion entera se construye con cajas, que es lo mas
## barato posible y encaja con la estetica low-poly. Pero para la arquitectura
## una caja ES la forma correcta: una pared es una caja. Para los objetos no.
## Un matafuego caja es un cubo rojo, una valvula caja es un cubo verde, y por
## buena que sea la textura el jugador ve cubos de colores.
##
## Lo que los hace legibles no es la cantidad de poligonos: es la SILUETA. Un
## cilindro vertical con un pico arriba se lee como matafuego a diez metros y
## con la linterna apagada. Eso es lo que falta y es lo que hace esto.
##
## Presupuesto. La PS1 movia props de 50 a 200 triangulos, asi que los
## cilindros van con 6 u 8 lados y los toros con 8 anillos. No es una
## limitacion que haya que disimular: el facetado es parte del look, igual que
## el temblor de vertices.
##
## Colision. Ninguna de estas piezas colisiona. El prop entero sigue teniendo
## UNA caja de colision, puesta por `setup_box` o por quien lo arma. Nadie
## necesita chocar contra el volante de una valvula con precision de volante,
## y trece formas de colision por sala serian caras y no cambiarian nada de lo
## que el jugador siente.
##
## Todas las funciones cuelgan las piezas de `p` en coordenadas locales, con
## el piso en y=0. Quien las llama decide donde va el prop y como rota.

## Lados de los cilindros. Seis es el limite de abajo: con cinco se lee como
## prisma y deja de parecer un tubo.
const LADOS := 8


static func _cil(radio: float, alto: float, lados := LADOS) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radio
	m.bottom_radius = radio
	m.height = alto
	m.radial_segments = lados
	m.rings = 0
	return m


static func _cono(r_arriba: float, r_abajo: float, alto: float) -> CylinderMesh:
	var m := _cil(r_abajo, alto)
	m.top_radius = r_arriba
	return m


static func _aro(radio: float, grosor: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = radio - grosor
	m.outer_radius = radio
	m.rings = 10
	m.ring_segments = 6
	return m


# --- Props -----------------------------------------------------------------

## Silla de oficina: columna, base de cinco patas, asiento y respaldo. Antes
## era asiento + respaldo + una pata central, o sea un hongo cuadrado.
static func silla(p: Node, metal: Material, tela: Material, alto := 0.9, ancho := 0.55) -> void:
	var r := ancho * 0.45
	# Base de estrella: cinco brazos y una rueda en la punta de cada uno.
	for i in 5:
		var a := TAU * float(i) / 5.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		Build.detalle(p, "Brazo%d" % i, Vector3(r * 1.5, 0.04, 0.06),
			dir * r * 0.75 + Vector3(0.0, 0.05, 0.0), metal, Vector3(0.0, -a, 0.0), false)
		Build.pieza(p, "Rueda%d" % i, _cil(0.035, 0.03, 6),
			dir * r * 1.4 + Vector3(0.0, 0.035, 0.0), metal, Vector3(PI * 0.5, -a, 0.0), false)
	Build.pieza(p, "Columna", _cil(0.045, alto * 0.45), Vector3(0.0, alto * 0.28, 0.0), metal)
	Build.detalle(p, "Asiento", Vector3(ancho, 0.09, ancho), Vector3(0.0, alto * 0.52, 0.0), tela)
	Build.detalle(p, "Respaldo", Vector3(ancho, alto * 0.5, 0.08),
		Vector3(0.0, alto * 0.8, -ancho * 0.45), tela)


## Matafuego: cuerpo cilindrico, cuello, valvula, manguera y soporte de pared.
## La silueta la dan el cuello y la manguera, no el cuerpo.
static func matafuego(p: Node, rojo: Material, metal: Material) -> void:
	Build.pieza(p, "Cuerpo", _cil(0.105, 0.44), Vector3(0.0, 0.22, 0.0), rojo)
	Build.pieza(p, "Hombro", _cono(0.05, 0.105, 0.09), Vector3(0.0, 0.485, 0.0), rojo)
	Build.pieza(p, "Cuello", _cil(0.028, 0.07, 6), Vector3(0.0, 0.56, 0.0), metal)
	Build.detalle(p, "Gatillo", Vector3(0.05, 0.03, 0.16), Vector3(0.0, 0.60, 0.02), metal, Vector3.ZERO, false)
	# Manguera: tres tramos que bajan por el costado.
	Build.pieza(p, "Manguera1", _cil(0.018, 0.14, 6), Vector3(0.09, 0.55, 0.05), metal, Vector3(0.0, 0.0, -0.9), false)
	Build.pieza(p, "Manguera2", _cil(0.018, 0.22, 6), Vector3(0.14, 0.40, 0.05), metal, Vector3.ZERO, false)
	Build.pieza(p, "Boquilla", _cono(0.045, 0.02, 0.09), Vector3(0.14, 0.26, 0.05), metal, Vector3(PI, 0.0, 0.0), false)
	Build.detalle(p, "Soporte", Vector3(0.05, 0.10, 0.22), Vector3(-0.11, 0.30, 0.0), metal, Vector3.ZERO, false)


## Valvula de paso: el cano sube del piso, la valvula lo corta, y el volante
## queda a la altura de la mano. Los canos corren sobre Z, o sea paralelos a
## la pared contra la que va montada: un cano apuntando al jugador no se lee
## como canieria, se lee como un error.
static func valvula(p: Node, cuerpo: Material, metal: Material, alto := 1.0) -> void:
	# Montante desde el piso hasta el cuerpo.
	Build.pieza(p, "Montante", _cil(0.09, alto - 0.12), Vector3(0.0, (alto - 0.12) * 0.5, 0.0), metal)
	Build.detalle(p, "Anclaje", Vector3(0.26, 0.05, 0.26), Vector3(0.0, 0.03, 0.0), metal, Vector3.ZERO, false)
	# Tramos horizontales, sobre Z.
	for sz in [-1.0, 1.0]:
		Build.pieza(p, "Cano%d" % int(sz), _cil(0.09, 0.42),
			Vector3(0.0, alto, sz * 0.33), metal, Vector3(PI * 0.5, 0.0, 0.0))
		Build.pieza(p, "Brida%d" % int(sz), _cil(0.14, 0.04),
			Vector3(0.0, alto, sz * 0.16), metal, Vector3(PI * 0.5, 0.0, 0.0), false)
	Build.detalle(p, "Cuerpo", Vector3(0.26, 0.30, 0.26), Vector3(0.0, alto, 0.0), cuerpo)
	Build.pieza(p, "Vastago", _cil(0.035, 0.22, 6), Vector3(0.0, alto + 0.24, 0.0), metal, Vector3.ZERO, false)
	Build.pieza(p, "Volante", _aro(0.26, 0.035), Vector3(0.0, alto + 0.36, 0.0), cuerpo)
	# Los cuatro rayos del volante.
	for k in 2:
		var a := PI * 0.5 * float(k)
		Build.detalle(p, "Rayo%d" % k, Vector3(0.50, 0.028, 0.035),
			Vector3(0.0, alto + 0.36, 0.0), cuerpo, Vector3(0.0, a, 0.0), false)
	Build.pieza(p, "Cubo", _cil(0.055, 0.05, 6), Vector3(0.0, alto + 0.36, 0.0), metal, Vector3.ZERO, false)


## Antena exterior: tripode, mastil y cuatro brazos. Contra el cielo, la
## silueta de un mastil con brazos dice "antena" sin cartel.
static func antena(p: Node, metal: Material, alto := 1.3) -> void:
	for i in 3:
		var a := TAU * float(i) / 3.0
		Build.pieza(p, "Pata%d" % i, _cil(0.03, 0.55, 6),
			Vector3(cos(a) * 0.16, 0.26, sin(a) * 0.16), metal, Vector3(cos(a) * 0.30, 0.0, -sin(a) * 0.30))
	Build.detalle(p, "Caja", Vector3(0.26, 0.30, 0.20), Vector3(0.0, 0.62, 0.0), metal)
	Build.pieza(p, "Mastil", _cil(0.035, alto), Vector3(0.0, 0.77 + alto * 0.5, 0.0), metal)
	for i in 4:
		var y := 0.95 + float(i) * 0.26
		var largo := 0.55 - float(i) * 0.09
		Build.detalle(p, "Brazo%d" % i, Vector3(largo, 0.022, 0.022), Vector3(0.0, y, 0.0), metal, Vector3.ZERO, false)
	Build.pieza(p, "Punta", _cono(0.005, 0.035, 0.14), Vector3(0.0, 0.77 + alto + 0.07, 0.0), metal, Vector3.ZERO, false)


## Baliza del patio: poste, jaula y cabeza. Marca el recorrido exterior.
static func baliza(p: Node, cuerpo: Material, metal: Material, alto := 1.2) -> void:
	Build.detalle(p, "Base", Vector3(0.24, 0.08, 0.24), Vector3(0.0, 0.04, 0.0), metal)
	Build.pieza(p, "Poste", _cil(0.045, alto * 0.72), Vector3(0.0, alto * 0.40, 0.0), metal)
	Build.pieza(p, "Cabeza", _cil(0.12, 0.22, 6), Vector3(0.0, alto * 0.86, 0.0), cuerpo)
	Build.pieza(p, "Tapa", _cono(0.03, 0.13, 0.08), Vector3(0.0, alto * 0.86 + 0.15, 0.0), metal, Vector3.ZERO, false)
	# Jaula: tres barras verticales alrededor de la cabeza.
	for i in 3:
		var a := TAU * float(i) / 3.0
		Build.pieza(p, "Barra%d" % i, _cil(0.012, 0.24, 6),
			Vector3(cos(a) * 0.13, alto * 0.86, sin(a) * 0.13), metal, Vector3.ZERO, false)


## Generador diesel: bloque, escape, radiador y tablero. Es el objeto mas
## grande que el jugador visita todas las noches, asi que aguanta detalle.
static func generador(p: Node, cuerpo: Material, metal: Material, size := Vector3(2.4, 1.8, 3.2)) -> void:
	var h := size.y
	Build.detalle(p, "Bancada", Vector3(size.x, 0.18, size.z), Vector3(0.0, 0.09, 0.0), metal)
	Build.detalle(p, "Bloque", Vector3(size.x * 0.88, h - 0.5, size.z * 0.82), Vector3(0.0, (h - 0.5) * 0.5 + 0.18, 0.0), cuerpo)
	# Escape: sube y dobla contra el techo.
	Build.pieza(p, "Escape", _cil(0.10, h * 0.75), Vector3(size.x * 0.3, h * 0.72, -size.z * 0.3), metal)
	Build.pieza(p, "Silenciador", _cil(0.15, 0.5), Vector3(size.x * 0.3, h * 0.55, -size.z * 0.3), metal, Vector3.ZERO, false)
	# Radiador al frente, con sus aletas.
	Build.detalle(p, "Radiador", Vector3(size.x * 0.7, h * 0.5, 0.1), Vector3(0.0, h * 0.55, size.z * 0.45), metal)
	for i in 7:
		Build.detalle(p, "Aleta%d" % i, Vector3(size.x * 0.66, 0.03, 0.04),
			Vector3(0.0, h * 0.35 + float(i) * 0.07, size.z * 0.5), cuerpo, Vector3.ZERO, false)
	# Tablero al costado.
	Build.detalle(p, "Tablero", Vector3(0.08, 0.45, 0.6), Vector3(size.x * 0.46, h * 0.62, size.z * 0.1), metal)
	Build.pieza(p, "Manometro", _cil(0.07, 0.03, 6), Vector3(size.x * 0.51, h * 0.72, size.z * 0.1), cuerpo, Vector3(0.0, 0.0, PI * 0.5), false)
	# Volante de arranque en el lateral.
	Build.pieza(p, "Volante", _aro(0.22, 0.03), Vector3(-size.x * 0.46, h * 0.55, 0.0), metal, Vector3(0.0, 0.0, PI * 0.5))


## Consola de sensores: mesa inclinada, monitor sobre un pie, y teclado. La
## pantalla la pone quien llama, que tiene el material emisivo.
static func consola(p: Node, metal: Material, size := Vector3(1.2, 1.1, 2.6)) -> void:
	Build.detalle(p, "Gabinete", Vector3(size.x * 0.9, size.y * 0.75, size.z), Vector3(0.0, size.y * 0.375, 0.0), metal)
	Build.detalle(p, "Tapa", Vector3(size.x, 0.06, size.z), Vector3(0.0, size.y * 0.78, 0.0), metal)
	# Teclado inclinado sobre la tapa.
	Build.detalle(p, "Teclado", Vector3(0.36, 0.04, 1.0), Vector3(0.18, size.y * 0.84, 0.0), metal, Vector3(0.0, 0.0, -0.18))
	# Pie del monitor.
	Build.pieza(p, "PieMonitor", _cil(0.07, 0.22, 6), Vector3(0.0, size.y * 0.9, 0.0), metal, Vector3.ZERO, false)
	# Carcasa: el marco alrededor de donde va la pantalla.
	Build.detalle(p, "Carcasa", Vector3(0.28, 0.82, 1.72), Vector3(-0.06, size.y + 0.36, 0.0), metal)
	# Rejillas de ventilacion del gabinete.
	for i in 5:
		Build.detalle(p, "Rejilla%d" % i, Vector3(0.02, 0.03, size.z * 0.5),
			Vector3(size.x * 0.46, 0.25 + float(i) * 0.06, 0.0), metal, Vector3.ZERO, false)


## Cucheta: marco de caños, somier y colchon. Antes era una caja.
static func cucheta(p: Node, metal: Material, tela: Material, size := Vector3(1.0, 0.55, 2.1)) -> void:
	var w := size.x * 0.5
	var l := size.z * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.pieza(p, "Poste%d%d" % [int(sx), int(sz)], _cil(0.035, size.y, 6),
				Vector3(sx * (w - 0.05), size.y * 0.5, sz * (l - 0.05)), metal, Vector3.ZERO, false)
	Build.detalle(p, "Somier", Vector3(size.x, 0.06, size.z), Vector3(0.0, size.y * 0.72, 0.0), metal)
	Build.detalle(p, "Colchon", Vector3(size.x * 0.94, 0.16, size.z * 0.96), Vector3(0.0, size.y * 0.85, 0.0), tela)
	Build.detalle(p, "Almohada", Vector3(size.x * 0.6, 0.10, 0.34), Vector3(0.0, size.y * 0.98, -l + 0.26), tela, Vector3.ZERO, false)
	# Cabecera y pie: dos barras horizontales entre los postes.
	for sz in [-1.0, 1.0]:
		Build.pieza(p, "Barra%d" % int(sz), _cil(0.03, size.x - 0.1, 6),
			Vector3(0.0, size.y + 0.12, sz * (l - 0.05)), metal, Vector3(0.0, 0.0, PI * 0.5), false)


## Fila de lockers: el cuerpo, las juntas entre puertas y las manijas.
static func lockers(p: Node, metal: Material, size := Vector3(0.45, 1.9, 2.4)) -> void:
	Build.detalle(p, "Cuerpo", size, Vector3(0.0, 0.0, 0.0), metal)
	var puertas := 4
	for i in puertas:
		var z := -size.z * 0.5 + size.z * (float(i) + 0.5) / float(puertas)
		# Junta: un surco fino entre puerta y puerta.
		if i > 0:
			Build.detalle(p, "Junta%d" % i, Vector3(0.02, size.y * 0.95, 0.03),
				Vector3(size.x * 0.5, 0.0, z - size.z / float(puertas) * 0.5), metal, Vector3.ZERO, false)
		Build.detalle(p, "Manija%d" % i, Vector3(0.04, 0.16, 0.03),
			Vector3(size.x * 0.52, -0.05, z + 0.16), metal, Vector3.ZERO, false)
		# Rejilla de ventilacion arriba de cada puerta.
		for j in 3:
			Build.detalle(p, "Vent%d_%d" % [i, j], Vector3(0.015, 0.02, size.z / float(puertas) * 0.5),
				Vector3(size.x * 0.5, size.y * 0.38 + float(j) * 0.05, z), metal, Vector3.ZERO, false)


## Pila de cajas: tres cajones de distinto tamaño, apilados torcidos. Una sola
## caja se lee como una caja; tres apiladas se leen como un deposito.
static func cajas(p: Node, carton: Material, lado := 1.2) -> void:
	Build.detalle(p, "Caja1", Vector3(lado, lado * 0.55, lado * 0.9), Vector3(0.0, lado * 0.275, 0.0), carton)
	Build.detalle(p, "Caja2", Vector3(lado * 0.8, lado * 0.45, lado * 0.75),
		Vector3(0.06, lado * 0.775, -0.05), carton, Vector3(0.0, 0.22, 0.0))
	Build.detalle(p, "Caja3", Vector3(lado * 0.5, lado * 0.3, lado * 0.5),
		Vector3(-0.12, lado * 1.15, 0.08), carton, Vector3(0.0, -0.4, 0.0))
	# El precinto cruzado de la caja de abajo.
	Build.detalle(p, "Precinto", Vector3(0.08, 0.004, lado * 0.92),
		Vector3(0.0, lado * 0.552, 0.0), carton, Vector3.ZERO, false)
