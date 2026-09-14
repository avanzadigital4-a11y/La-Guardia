# -*- coding: utf-8 -*-
class_name SuitCounter
extends Interactable
## El perchero de la esclusa. Contar los trajes es una tarea del turno, y es
## la forma mas barata que tiene el juego de decirte que algo no cierra: el
## numero cambia y no hay manera de discutirlo.

@export var task_id := "trajes"

var _last_count := -1


func get_prompt() -> String:
	if GameState.is_task_done(task_id):
		return "Ya los contaste"
	return "Contar los trajes"


func count_suits() -> int:
	var station := get_parent()
	var n := 0
	if station and "variants" in station:
		for id in station.variants.keys():
			var node: Node3D = station.variants[id]
			if is_instance_valid(node) and node.visible:
				n += 1
	return n


func _on_interact(who: Node) -> void:
	var n := count_suits()
	_last_count = n
	AudioDirector.play_cue("task", global_position)
	var text := ""
	match n:
		3:
			text = "Tres trajes. Los tres secos."
		2:
			text = "Dos. Tendrían que ser tres."
		1:
			text = "Uno. Falta contar a quién le faltan los otros dos."
		0:
			text = "Ninguno. El perchero está vacío."
		_:
			text = "%d trajes. No me acuerdo cuántos eran." % n
	GameState.notice.emit(text)
	if GameState.is_task_active(task_id):
		GameState.complete_task(task_id)
		GameState.add_log("", "Conté los trajes de la esclusa: %d." % n, n != 3)
	elif who and who.has_method("show_notice"):
		who.show_notice(text)
