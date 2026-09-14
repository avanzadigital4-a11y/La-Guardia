class_name SensorPanel
extends Interactable
## Consola de sensores. Abre la UI de lectura y, si corresponde, completa
## la tarea de "verificar sensores".

@export var task_id := "sensors"


func get_prompt() -> String:
	return "Leer panel de sensores"


func _on_interact(_who: Node) -> void:
	var ui := get_tree().get_first_node_in_group("sensor_ui")
	if ui and ui.has_method("open"):
		ui.open()
	AudioDirector.play_cue("panel", global_position)
	if GameState.is_task_active(task_id):
		GameState.complete_task(task_id)
		GameState.add_log("", "Sensores del nivel 1 dentro de rango.", false)
