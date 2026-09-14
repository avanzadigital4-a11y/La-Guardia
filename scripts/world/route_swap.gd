class_name RouteSwap
extends Area3D
## El recorrido deja de llevar a donde deberia. El jugador cruza un umbral y
## sale por otro, conservando su posicion relativa y hacia donde camina: no
## hay pantalla de carga ni corte, solo un pasillo que no devuelve lo que
## deberia.

signal swapped(times: int)
signal exhausted()

@export var loop_limit := 0        # 0 = sin limite
@export var active := false
@export var directional := true   # solo se dispara caminando hacia adelante

var destination: Node3D
var times := 0

static var _cooldown := 0.0


func configure(dest: Node3D, size := Vector3(3.0, 2.6, 0.6)) -> void:
	destination = dest
	monitoring = true
	collision_layer = 0
	collision_mask = Build.LAYER_PLAYER
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	col.position.y = size.y * 0.5
	add_child(col)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func _on_body_entered(body: Node3D) -> void:
	if not active or destination == null or _cooldown > 0.0:
		return
	if not body.is_in_group("player"):
		return
	if directional and body is CharacterBody3D:
		var forward := -global_transform.basis.z
		var motion: Vector3 = (body as CharacterBody3D).velocity
		if motion.length() > 0.1 and forward.dot(motion.normalized()) < 0.25:
			return
	_cooldown = 1.5
	times += 1

	var rel := global_transform.affine_inverse() * body.global_position
	var yaw_delta := destination.global_rotation.y - global_rotation.y
	body.global_position = destination.global_transform * rel
	body.rotate_y(yaw_delta)
	if body is CharacterBody3D:
		var v: Vector3 = (body as CharacterBody3D).velocity
		(body as CharacterBody3D).velocity = v.rotated(Vector3.UP, yaw_delta)

	AudioDirector.play_cue("creak", body.global_position, -14.0)
	swapped.emit(times)
	if loop_limit > 0 and times >= loop_limit:
		active = false
		exhausted.emit()
