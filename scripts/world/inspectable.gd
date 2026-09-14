# -*- coding: utf-8 -*-
class_name Inspectable
extends Interactable
## Objeto que se puede levantar y mirar de cerca, girándolo en la mano. Es el
## verbo que le faltaba al juego: mirar algo con atención y darte cuenta de
## que cambió, sin que nadie te lo diga.

const DISTANCIA := 0.45
const VELOCIDAD_GIRO := 0.008

@export var titulo := "Objeto"
@export var inspect_id := ""

var _holding := false
var _player: Player = null
var _origin_parent: Node = null
var _origin_transform := Transform3D.IDENTITY
var _mesh: MeshInstance3D = null


func get_prompt() -> String:
	return "Mirar de cerca"


func description() -> String:
	var data: Dictionary = NightData.INSPECTABLES.get(inspect_id, {})
	var texts: Dictionary = data.get("textos", {})
	var best := ""
	for night in texts.keys():
		if int(night) <= GameState.current_night:
			best = String(texts[night])
	return best


func _on_interact(who: Node) -> void:
	if _holding or not (who is Player):
		return
	_player = who
	_holding = true
	_player.set_frozen(true)
	_player.look_enabled = false

	_origin_parent = get_parent()
	_origin_transform = transform
	_set_collisions(false)
	var camera: Camera3D = _player.camera
	get_parent().remove_child(self)
	camera.add_child(self)
	transform = Transform3D(Basis(), Vector3(0.0, 0.0, -DISTANCIA))

	var ui := get_tree().get_first_node_in_group("inspect_ui")
	if ui and ui.has_method("open"):
		ui.open(titulo, description())
	AudioDirector.play_cue("pickup", global_position, -12.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _holding:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		rotate_object_local(Vector3.UP, -mm.relative.x * VELOCIDAD_GIRO)
		rotate_object_local(Vector3.RIGHT, -mm.relative.y * VELOCIDAD_GIRO)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		_drop()
		get_viewport().set_input_as_handled()


func _drop() -> void:
	if not _holding:
		return
	_holding = false
	get_parent().remove_child(self)
	_origin_parent.add_child(self)
	transform = _origin_transform
	_set_collisions(true)
	var ui := get_tree().get_first_node_in_group("inspect_ui")
	if ui and ui.has_method("close"):
		ui.close()
	if is_instance_valid(_player):
		_player.set_frozen(false)
		_player.look_enabled = true
	_player = null


func _set_collisions(on: bool) -> void:
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = not on
