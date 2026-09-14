class_name Bed
extends Interactable
## La cucheta. Cierra la noche cuando la tarea final esta activa.

func get_prompt() -> String:
	if GameState.is_task_active("sleep"):
		return "Dormir"
	return "Tu cucheta"


func _on_interact(who: Node) -> void:
	if not GameState.is_task_active("sleep"):
		if who and who.has_method("show_notice"):
			who.show_notice("Todavía queda trabajo.")
		return
	GameState.complete_task("sleep")
