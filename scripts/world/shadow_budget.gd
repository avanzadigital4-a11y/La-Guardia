# -*- coding: utf-8 -*-
class_name ShadowBudget
extends Node
## Presupuesto de sombras: solo las luces mas cercanas al jugador proyectan.
##
## Por que existe. Hasta ahora ninguna luz de la estacion tenia sombra
## (`shadow_enabled = false` en las catorce), asi que cada sala quedaba banada
## de luz pareja, sin oclusion. En terror eso es el problema entero: no habia
## oscuridad, habia penumbra uniforme. Ninguna textura arregla eso.
##
## Pero prender sombra en catorce luces omni no se puede: cada una es un mapa
## cubico, seis caras, y el objetivo es hardware de gama baja. La salida es que
## la sombra sea un recurso escaso: la proyectan las dos o tres luces mas
## cercanas, que son las unicas cuya sombra el jugador puede ver de todos
## modos, y el resto solo ilumina.
##
## Esto es distinto del presupuesto de luces que se probo y se descarto antes.
## Aquel apagaba luces enteras buscando FPS y no daba ninguna mejora medible.
## Este no apaga nada: reparte sombras, y el motivo es estetico. Que ademas
## acota el costo es una consecuencia, no la razon.

## Cuantas luces proyectan sombra al mismo tiempo.
const MAXIMO := 3
## Mas alla de esta distancia no vale la pena: la sombra no se distingue.
const ALCANCE := 14.0
const INTERVALO := 0.25

var lights: Array[OmniLight3D] = []
var player: Node3D
var enabled := true

var _t := 0.0


func setup(p_lights: Array[OmniLight3D], p_player: Node3D) -> void:
	lights = p_lights
	player = p_player
	Settings.changed.connect(_on_settings)
	_on_settings()


## Las sombras son lo mas caro del cuadro, y el objetivo es hardware de gama
## baja: tienen que poder apagarse sin tocar nada mas.
func _on_settings() -> void:
	set_enabled(Settings.shadows)


func _process(delta: float) -> void:
	if not enabled or player == null:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = INTERVALO
	_apply()


func _apply() -> void:
	if player == null or not is_instance_valid(player):
		return
	var pos := player.global_position
	var cerca: Array = []
	for l in lights:
		if not is_instance_valid(l):
			continue
		# Una luz apagada (por una anomalia, o por la noche) no tiene por que
		# gastar un mapa de sombras.
		if not l.visible or l.light_energy <= 0.01:
			l.shadow_enabled = false
			continue
		var d := l.global_position.distance_to(pos)
		if d > ALCANCE:
			l.shadow_enabled = false
		else:
			cerca.append({"luz": l, "d": d})
	cerca.sort_custom(func(a, b): return a["d"] < b["d"])
	for i in cerca.size():
		cerca[i]["luz"].shadow_enabled = i < MAXIMO


## Para medir el A/B: apaga todas las sombras, como estaba antes.
func set_enabled(on: bool) -> void:
	enabled = on
	if on:
		_apply()
		return
	for l in lights:
		if is_instance_valid(l):
			l.shadow_enabled = false


func casting_count() -> int:
	var n := 0
	for l in lights:
		if is_instance_valid(l) and l.shadow_enabled:
			n += 1
	return n
