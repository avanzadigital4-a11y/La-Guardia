# -*- coding: utf-8 -*-
extends Node
## Benchmark con render real: camina la estación durante un rato y reporta
## FPS promedio, mínimo y percentil 1%. Pensado para correrlo en la máquina
## objetivo (gama baja) y tener números en vez de impresiones.
##
## Uso:  godot --path . res://tools/benchmark.tscn
## (no lleva --headless: mide el renderizador de verdad)

const RUTA := [
	Vector3(-6.0, 0.1, -2.5), Vector3(0.0, 0.1, -2.5), Vector3(0.0, 0.1, -11.0),
	Vector3(5.0, 0.1, -11.0), Vector3(0.0, 0.1, -11.0), Vector3(0.0, 0.1, 6.0),
	Vector3(0.0, 0.1, 14.0), Vector3(-8.0, 0.1, 20.0), Vector3(0.0, 0.1, 14.0),
	Vector3(0.0, 0.1, -2.5), Vector3(-6.0, 0.1, -2.5),
]
const VELOCIDAD := 3.2
const CALENTAMIENTO := 3.0
const DURACION_MAXIMA := 90.0

var main: Node
var fps: Array[float] = []


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func _run() -> void:
	await get_tree().create_timer(CALENTAMIENTO).timeout
	var player: Node3D = main.player
	# Durante la medición el recorrido lo maneja esta herramienta: si la física
	# del jugador sigue activa, pelea contra las posiciones que le imponemos.
	player.set_physics_process(false)
	player.set_frozen(true)

	var spin := 0.0
	var elapsed := 0.0
	for point in RUTA:
		var stuck := 0.0
		while player.global_position.distance_to(point) > 0.3:
			await get_tree().process_frame
			var delta := minf(get_process_delta_time(), 0.25)
			elapsed += delta
			stuck += delta
			fps.append(float(Engine.get_frames_per_second()))
			player.global_position = player.global_position.move_toward(point, VELOCIDAD * delta)
			# Girar la cámara todo el tiempo: es el caso peor para el culling.
			spin += delta * 0.7
			player.rotation.y = spin
			if stuck > 20.0 or elapsed > DURACION_MAXIMA:
				break
		if elapsed > DURACION_MAXIMA:
			break
	_report()


func _report() -> void:
	fps.sort()
	var avg := 0.0
	for v in fps:
		avg += v
	avg /= maxf(fps.size(), 1)
	var p1: float = fps[maxi(int(fps.size() * 0.01), 0)] if fps.size() > 0 else 0.0
	print("")
	print("BENCHMARK  (%d cuadros medidos)" % fps.size())
	print("  FPS promedio   %6.1f" % avg)
	print("  FPS minimo     %6.1f" % (fps[0] if fps.size() > 0 else 0.0))
	print("  percentil 1%%   %6.1f" % p1)
	print("  escala 3D      %6.2f" % Settings.pixelation)
	print("  efectos PS1    %s" % ("si" if Settings.ps1_effects else "no"))
	print("")
	print("Objetivo del diseno: 30 FPS estables en CPU dual-core con 2 GB de VRAM.")
	get_tree().quit(0)
