extends Node3D
## Punto de entrada: arma el mundo, la interfaz y el post-proceso, y le pasa
## el control al NightDirector.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var station: StationBuilder
var player: Player
var director: NightDirector
var hud: CanvasLayer
var logbook_ui: CanvasLayer
var sensor_ui: CanvasLayer
var fade: CanvasLayer
var pause_menu: CanvasLayer
var world_env: WorldEnvironment
var post_material: ShaderMaterial
var blackout: Blackout
var shadows: ShadowBudget


func _ready() -> void:
	_setup_environment()
	_setup_station()
	_setup_player()
	_setup_ui()
	_setup_post_process()

	director = NightDirector.new()
	director.name = "NightDirector"
	add_child(director)
	director.setup(station, player, fade, world_env)

	shadows = ShadowBudget.new()
	shadows.name = "PresupuestoDeSombras"
	add_child(shadows)
	shadows.setup(station.all_lights, player)

	blackout = Blackout.new()
	blackout.name = "Apagon"
	add_child(blackout)
	blackout.setup(station, player, fade, director)

	director.start_night(GameState.current_night)
	var args := OS.get_cmdline_user_args()
	if "--capturas" in args or "--capture" in args:
		_capture_debug()


func _setup_environment() -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.025, 0.03)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.16, 0.18, 0.22)
	# Ambiente casi nulo. Con 0.55 no habia sombra posible: la luz de relleno
	# levantaba todos los rincones y la estacion quedaba pareja. Lo que se ve
	# ahora lo tiene que poner una lampara o la linterna.
	e.ambient_light_energy = 0.10
	e.fog_enabled = true
	e.fog_light_color = Color(0.10, 0.11, 0.13)
	e.fog_density = 0.04
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env = WorldEnvironment.new()
	world_env.name = "Entorno"
	world_env.environment = e
	add_child(world_env)


func _setup_station() -> void:
	station = StationBuilder.new()
	station.name = "Estacion"
	add_child(station)
	station.build(Color(0.30, 0.32, 0.34))


func _setup_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = StationBuilder.SPAWN


func _setup_ui() -> void:
	hud = _add_layer("HUD", "res://scripts/ui/hud.gd")
	logbook_ui = _add_layer("Bitacora", "res://scripts/ui/logbook_ui.gd")
	sensor_ui = _add_layer("PanelSensores", "res://scripts/ui/sensor_ui.gd")
	fade = _add_layer("Fundido", "res://scripts/ui/screen_fade.gd")
	pause_menu = _add_layer("Pausa", "res://scripts/ui/pause_menu.gd")
	_add_layer("Estadisticas", "res://scripts/ui/stats_overlay.gd")
	_add_layer("Inspeccion", "res://scripts/ui/inspect_ui.gd")


func _add_layer(name: String, script_path: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = name
	layer.set_script(load(script_path))
	add_child(layer)
	return layer


func _setup_post_process() -> void:
	var shader := load("res://shaders/ps1_post.gdshader") as Shader
	if shader == null:
		return
	var layer := CanvasLayer.new()
	layer.name = "PostProceso"
	layer.layer = 5
	add_child(layer)

	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	layer.add_child(copy)

	post_material = ShaderMaterial.new()
	post_material.shader = shader
	post_material.set_shader_parameter("time_seed", randf() * 100.0)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = post_material
	layer.add_child(rect)

	GameState.night_started.connect(_on_night_started_post)
	Settings.changed.connect(_apply_post_settings.bind(rect))
	_apply_post_settings(rect)


func _apply_post_settings(rect: ColorRect) -> void:
	if is_instance_valid(rect):
		rect.visible = Settings.ps1_effects


func _on_night_started_post(night: int) -> void:
	if post_material:
		post_material.set_shader_parameter("dread", clampf((night - 1) / 4.0, 0.0, 1.0))


## Guarda progreso y estado del mundo, para poder retomar la noche donde iba.
func save_now() -> void:
	if director:
		GameState.save_game(director.world_state())
	else:
		GameState.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("logbook"):
		if sensor_ui.is_open:
			sensor_ui.close()
		logbook_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		if sensor_ui.is_open:
			sensor_ui.close()
			get_viewport().set_input_as_handled()
		elif logbook_ui.is_open:
			logbook_ui.close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause"):
			pause_menu.toggle()
			get_viewport().set_input_as_handled()


## Herramienta de desarrollo: corre el juego con  -- --capturas  y guarda una
## captura de cada ambiente en user:// para revisar la estetica sin jugar.
func _capture_debug() -> void:
	var views := [
		[Vector3(-6.0, 0.1, -2.5), -PI * 0.5, "dorm"],
		[Vector3(0.0, 0.1, -6.0), PI, "pasillo"],
		[Vector3(0.0, 0.1, -6.0), 0.0, "pasillo_sur"],
		[Vector3(-5.0, 0.1, -11.0), -PI * 0.5, "control"],
		[Vector3(5.0, 0.1, -9.0), PI * 0.5, "generador"],
		[Vector3(0.0, 0.1, 13.0), PI, "patio"],
		[Vector3(0.0, 0.1, 9.8), PI, "esclusa"],
	]
	var views_n3 := [
		[Vector3(0.0, 0.1, -17.0), 0.0, "n3_pasillo_sur"],
		[Vector3(0.0, -0.4, -26.0), 0.0, "n3_subnivel"],
		[Vector3(-4.5, 0.1, -3.0), -PI * 0.5, "n3_dormitorio"],
		[Vector3(0.0, 0.1, 14.0), PI, "n3_patio"],
	]
	await get_tree().create_timer(6.0).timeout
	for v in views:
		player.teleport(v[0], v[1])
		await get_tree().create_timer(0.4).timeout
		for i in 3:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://shot_%s.png" % v[2])
	await director.start_night(3)
	# Con las anomalias de la noche aplicadas, para ver los objetos extra.
	for id in NightData.get_night(3).get("anomalias", []):
		director.anomalies.apply(String(id))
	for v in views_n3:
		player.teleport(v[0], v[1])
		await get_tree().create_timer(0.4).timeout
		for i in 3:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://shot_%s.png" % v[2])
	print("Capturas guardadas en %s" % ProjectSettings.globalize_path("user://"))
	# Es una herramienta, no una sesion de juego: termina cuando termino.
	get_tree().quit()
