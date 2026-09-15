class_name RoomWatcher
extends Area3D
## Detecta entrada/salida del jugador en una sala. Las anomalias fuera de
## camara se aplican cuando el jugador NO esta adentro: sale, vuelve, y algo
## cambio sin que viera la transicion.

signal player_entered(room_id: String)
signal player_exited(room_id: String)

@export var room_id := ""

var player_inside := false


func configure(id: String, rect: Rect2, height := Build.WALL_H, base_y := 0.0) -> void:
	room_id = id
	monitoring = true
	collision_layer = 0
	collision_mask = Build.LAYER_PLAYER
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(rect.size.x - 0.4, height, rect.size.y - 0.4)
	col.shape = bs
	add_child(col)
	var c := rect.get_center()
	position = Vector3(c.x, base_y + height * 0.5, c.y)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_entered.emit(room_id)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_exited.emit(room_id)
