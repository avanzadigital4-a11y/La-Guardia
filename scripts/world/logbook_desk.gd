class_name LogbookDesk
extends Interactable
## La bitacora fisica sobre el escritorio.

func get_prompt() -> String:
	return "Leer la bitácora"


func _on_interact(_who: Node) -> void:
	var ui := get_tree().get_first_node_in_group("logbook_ui")
	if ui and ui.has_method("open"):
		ui.open()
	if GameState.is_task_active("logbook_check"):
		GameState.complete_task("logbook_check")
