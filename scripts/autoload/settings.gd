extends Node
## Opciones del jugador, persistidas en user://opciones.cfg.

signal changed()

const PATH := "user://opciones.cfg"

var mouse_sensitivity := 1.0     # multiplicador
var master_volume := 0.8         # 0..1
var ps1_effects := true          # grano, scanlines, vineta
var pixelation := 0.55           # escala interna del viewport 3D


func _ready() -> void:
	load_settings()
	apply()


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	var vp := get_viewport()
	if vp is Window:
		(vp as Window).scaling_3d_scale = clampf(pixelation, 0.25, 1.0)
	changed.emit()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("juego", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("juego", "master_volume", master_volume)
	cfg.set_value("juego", "ps1_effects", ps1_effects)
	cfg.set_value("juego", "pixelation", pixelation)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	mouse_sensitivity = float(cfg.get_value("juego", "mouse_sensitivity", mouse_sensitivity))
	master_volume = float(cfg.get_value("juego", "master_volume", master_volume))
	ps1_effects = bool(cfg.get_value("juego", "ps1_effects", ps1_effects))
	pixelation = float(cfg.get_value("juego", "pixelation", pixelation))
