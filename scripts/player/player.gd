class_name Player
extends CharacterBody3D
## Cuidador nocturno. Caminar, mirar, linterna, interactuar. Sin combate.

const WALK_SPEED := 2.4
const SPRINT_SPEED := 4.0
const ACCEL := 9.0
const MOUSE_SENS := 0.0022   # base, escalada por Settings.mouse_sensitivity
const PITCH_LIMIT := deg_to_rad(85.0)
const BATTERY_DRAIN := 0.0025      # ~6:40 de linterna encendida por carga
const STEP_DISTANCE := 1.9

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay

var can_move := true
var flashlight_on := true
var _bob_time := 0.0
var _step_accum := 0.0
var _focus: Interactable = null
var _flicker := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = Build.LAYER_PLAYER
	collision_mask = Build.LAYER_WORLD
	ray.target_position = Vector3(0, 0, -2.6)
	ray.collision_mask = Build.LAYER_INTERACT
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_flashlight()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		var sens := MOUSE_SENS * Settings.mouse_sensitivity
		rotate_y(-mm.relative.x * sens)
		head.rotation.x = clampf(head.rotation.x - mm.relative.y * sens, -PITCH_LIMIT, PITCH_LIMIT)
	if not can_move:
		return
	if event.is_action_pressed("flashlight"):
		_toggle_flashlight()
	elif event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 14.0 * delta
	else:
		velocity.y = 0.0

	var dir := Vector3.ZERO
	if can_move:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := SPRINT_SPEED if (can_move and Input.is_action_pressed("sprint")) else WALK_SPEED
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)
	move_and_slide()

	_head_bob(delta, Vector2(velocity.x, velocity.z).length())
	_update_focus()
	_update_battery(delta)


func _head_bob(delta: float, speed: float) -> void:
	if speed > 0.2:
		_bob_time += delta * speed * 3.0
		head.position.y = 1.55 + sin(_bob_time * 2.0) * 0.022
		_step_accum += speed * delta
		if _step_accum >= STEP_DISTANCE:
			_step_accum = 0.0
			# Afuera se camina sobre nieve; adentro, sobre chapa.
			var outside := global_position.z > 11.0
			AudioDirector.play_cue("step_snow" if outside else "step", global_position, -8.0 if outside else -6.0)
	else:
		_bob_time = 0.0
		head.position.y = lerpf(head.position.y, 1.55, delta * 6.0)


func _update_focus() -> void:
	var found: Interactable = null
	if ray.is_colliding():
		var c := ray.get_collider()
		if c is Interactable and (c as Interactable).can_interact():
			found = c
	if found != _focus:
		_focus = found
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("set_prompt"):
			hud.set_prompt(_focus.get_prompt() if _focus else "")


func _try_interact() -> void:
	if _focus and is_instance_valid(_focus):
		_focus.interact(self)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("set_prompt") and is_instance_valid(_focus):
			hud.set_prompt(_focus.get_prompt())


func _toggle_flashlight() -> void:
	if GameState.battery <= 0.0 and not flashlight_on:
		if GameState.use_spare_battery():
			show_notice("Pila cambiada.")
		else:
			show_notice("La linterna está muerta.")
			return
	flashlight_on = not flashlight_on
	AudioDirector.play_cue("click", global_position)
	_update_flashlight()


func _update_battery(delta: float) -> void:
	if not flashlight_on:
		return
	GameState.drain_battery(BATTERY_DRAIN * delta)
	if GameState.battery <= 0.0:
		flashlight_on = false
		show_notice("La linterna se apagó.")
		_update_flashlight()
		return
	# Parpadeo cuando queda poca carga.
	if GameState.battery < 0.22:
		_flicker -= delta
		if _flicker <= 0.0:
			_flicker = randf_range(0.15, 1.2)
			flashlight.light_energy = randf_range(0.4, 3.0)
	else:
		flashlight.light_energy = 3.2


func _update_flashlight() -> void:
	flashlight.visible = flashlight_on
	flashlight.light_energy = 3.2


func show_notice(text: String) -> void:
	GameState.notice.emit(text)


func teleport(pos: Vector3, look_yaw := 0.0) -> void:
	global_position = pos
	rotation.y = look_yaw
	head.rotation.x = 0.0
	velocity = Vector3.ZERO


func set_frozen(frozen: bool) -> void:
	can_move = not frozen
	if frozen:
		velocity = Vector3.ZERO
