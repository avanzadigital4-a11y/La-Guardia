extends Node
## Opciones del jugador, persistidas en user://opciones.cfg.

signal changed()

const PATH := "user://opciones.cfg"

var mouse_sensitivity := 1.0     # multiplicador
var master_volume := 0.8         # 0..1
var ps1_effects := true          # grano, scanlines, vineta
var shadows := true              # sombras: lo mas caro del cuadro
var pixelation := 0.55           # escala interna del viewport 3D
var fullscreen := false
var invert_y := false
var head_bob := true
var fov := 68.0
var subtitle_size := 16
var keybinds := {}               # accion -> physical_keycode

const REBINDABLE := [
	["move_forward", "Adelante"],
	["move_back", "Atrás"],
	["move_left", "Izquierda"],
	["move_right", "Derecha"],
	["sprint", "Apurar el paso"],
	["interact", "Usar"],
	["flashlight", "Linterna"],
	["logbook", "Bitácora"],
]


func _ready() -> void:
	load_settings()
	apply()


func apply() -> void:
	_apply_keybinds()
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	var vp := get_viewport()
	if vp is Window:
		(vp as Window).scaling_3d_scale = clampf(pixelation, 0.25, 1.0)
	changed.emit()


## Rehace el InputMap con las teclas elegidas por el jugador.
func _apply_keybinds() -> void:
	for action in keybinds.keys():
		if not InputMap.has_action(action):
			continue
		var code := int(keybinds[action])
		if code == 0:
			continue
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		InputMap.action_add_event(action, ev)


func key_for(action: String) -> int:
	if keybinds.has(action):
		return int(keybinds[action])
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return int((ev as InputEventKey).physical_keycode)
	return 0


func key_name(action: String) -> String:
	var code := key_for(action)
	if code == 0:
		return "sin asignar"
	return OS.get_keycode_string(code)


func rebind(action: String, code: int) -> void:
	keybinds[action] = code
	apply()
	save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("juego", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("juego", "master_volume", master_volume)
	cfg.set_value("juego", "ps1_effects", ps1_effects)
	cfg.set_value("juego", "shadows", shadows)
	cfg.set_value("juego", "pixelation", pixelation)
	cfg.set_value("juego", "fullscreen", fullscreen)
	cfg.set_value("juego", "invert_y", invert_y)
	cfg.set_value("juego", "head_bob", head_bob)
	cfg.set_value("juego", "fov", fov)
	cfg.set_value("juego", "subtitle_size", subtitle_size)
	cfg.set_value("teclas", "binds", keybinds)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	mouse_sensitivity = float(cfg.get_value("juego", "mouse_sensitivity", mouse_sensitivity))
	master_volume = float(cfg.get_value("juego", "master_volume", master_volume))
	ps1_effects = bool(cfg.get_value("juego", "ps1_effects", ps1_effects))
	shadows = bool(cfg.get_value("juego", "shadows", shadows))
	pixelation = float(cfg.get_value("juego", "pixelation", pixelation))
	fullscreen = bool(cfg.get_value("juego", "fullscreen", fullscreen))
	invert_y = bool(cfg.get_value("juego", "invert_y", invert_y))
	head_bob = bool(cfg.get_value("juego", "head_bob", head_bob))
	fov = float(cfg.get_value("juego", "fov", fov))
	subtitle_size = int(cfg.get_value("juego", "subtitle_size", subtitle_size))
	keybinds = cfg.get_value("teclas", "binds", {})
