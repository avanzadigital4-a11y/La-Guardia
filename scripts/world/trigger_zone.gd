class_name TriggerZone
extends Area3D
## Zona que completa una tarea con solo llegar caminando. Sirve para que no
## todas las tareas se resuelvan apretando [E] sobre un objeto.

signal triggered()

@export var task_id := ""
@export var notice := ""
@export var once := true

var active := true


func configure(size: Vector3) -> void:
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


func _on_body_entered(body: Node3D) -> void:
	if not active or not body.is_in_group("player"):
		return
	if task_id != "" and not GameState.is_task_active(task_id):
		return
	if once:
		active = false
	if task_id != "":
		GameState.complete_task(task_id)
	if notice != "":
		GameState.notice.emit(notice)
	triggered.emit()
