# -*- coding: utf-8 -*-
class_name Blackout
extends Node
## El apagon: que pasa cuando te quedas sin luz.
##
## El diseno dice "sin combate, el peligro es ambiental y psicologico, nunca
## una amenaza fisica directa". Asi que quedarse a oscuras no mata ni termina
## la partida: te pierde. Fundido a negro, y despertas en el dormitorio sin
## acordarte de haber vuelto, con horas de menos.
##
## Lo que cuesta de verdad:
##   - las pilas de repuesto que tenias encima ya no estan;
##   - la linterna vuelve con poca carga, no llena;
##   - mientras estuviste a oscuras "pasaron cosas", y quedan anotadas a tu
##     nombre: van a aparecer en el parte del turno, con tu letra.
##
## Eso ultimo es el punto. El apagon no es un castigo pegado al costado: es
## la forma mas directa que tiene el juego de convertirte en el autor de las
## anomalias sin que lo recuerdes, que es el giro central del diseno.

## Cuanto aguanta el jugador a oscuras antes de perder el conocimiento.
const AGUANTE := 12.0
## Con cuanta carga vuelve la linterna despues de un apagon.
const CARGA_AL_VOLVER := 0.35
## Cuantas anomalias se aplican durante el apagon.
const ANOMALIAS := 2
## Por debajo de esta energia, una sala cuenta como a oscuras.
const OSCURA := 0.06

signal blacked_out(night: int)

var station: StationBuilder
var player: Player
var fade: CanvasLayer
var director: NightDirector

var enabled := true
var in_the_dark := 0.0
var _busy := false


func setup(p_station: StationBuilder, p_player: Player, p_fade: CanvasLayer, p_director: NightDirector) -> void:
	station = p_station
	player = p_player
	fade = p_fade
	director = p_director


## A oscuras de verdad: sin linterna y en una sala cuya luz esta apagada.
## Quedarse sin bateria parado bajo una luz encendida no cuenta.
func is_dark() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if player.flashlight_on:
		return false
	var room := _room_of(player.global_position)
	if not station.room_lights.has(room):
		return true   # el pasillo sur y el subnivel no tienen luz de sala
	var light: OmniLight3D = station.room_lights[room]
	if not is_instance_valid(light) or not light.visible:
		return true
	return light.light_energy <= OSCURA


func _process(delta: float) -> void:
	if not enabled or _busy or not GameState.night_active:
		return
	if not is_dark():
		in_the_dark = 0.0
		return
	# Si todavia queda con que prender la linterna, no es un apagon: es no
	# haberla prendido.
	if GameState.battery > 0.0 or GameState.spare_batteries > 0:
		in_the_dark = 0.0
		return
	in_the_dark += delta
	if in_the_dark >= AGUANTE:
		trigger()


func trigger() -> void:
	if _busy:
		return
	_busy = true
	in_the_dark = 0.0
	_run()


func _run() -> void:
	player.set_frozen(true)
	await fade.fade_out(2.2)

	var perdidas := randi_range(2, 4)
	GameState.set_flag("apagones", int(GameState.get_flag("apagones", 0)) + 1)
	GameState.set_flag("horas_perdidas", int(GameState.get_flag("horas_perdidas", 0)) + perdidas)

	# Lo que costo: las pilas que llevabas encima y casi toda la carga.
	GameState.spare_batteries = 0
	GameState.battery = CARGA_AL_VOLVER
	GameState.battery_changed.emit(GameState.battery)

	# Lo que "paso" mientras tanto, anotado a tu nombre.
	director.apply_armed(ANOMALIAS)

	player.teleport(StationBuilder.SPAWN, -PI * 0.5)
	player.set_flashlight(true)

	GameState.add_log("", "Me desperté en la cucheta. La linterna estaba en el piso, apagada.", true)
	GameState.add_log("", "Faltan %d horas del turno y no las tengo." % perdidas, true)

	await fade.show_card("NO TE ACORDÁS DE HABER VUELTO",
		"Faltan %d horas del turno." % perdidas, 3.2)
	await fade.fade_in(2.0)
	player.set_frozen(false)
	_busy = false
	blacked_out.emit(GameState.current_night)


func _room_of(p: Vector3) -> String:
	for id in StationBuilder.ROOMS.keys():
		var r: Rect2 = StationBuilder.ROOMS[id]
		if r.has_point(Vector2(p.x, p.z)):
			return String(id)
	return "pasillo"
