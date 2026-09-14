class_name Interactable
extends StaticBody3D
## Base de todo lo que el jugador puede mirar y usar con [E].

signal used(who: Node)

@export var prompt_text := "Usar"
@export var enabled := true

var _cooldown := 0.0


func _ready() -> void:
	collision_layer = Build.LAYER_WORLD | Build.LAYER_INTERACT
	collision_mask = 0
	add_to_group("interactable")


func setup_box(size: Vector3, mat: Material, mesh_offset := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = mesh_offset
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	col.position = mesh_offset
	add_child(col)
	return mi


func can_interact() -> bool:
	return enabled and _cooldown <= 0.0


func get_prompt() -> String:
	return prompt_text


func interact(who: Node) -> void:
	if not can_interact():
		return
	_cooldown = 0.35
	used.emit(who)
	_on_interact(who)


func _on_interact(_who: Node) -> void:
	pass


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
