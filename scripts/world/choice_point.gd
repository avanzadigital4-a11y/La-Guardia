class_name ChoicePoint
extends Interactable
## Punto de decision de la ultima noche. Cada uno cierra el juego de una
## manera distinta.

@export var ending_id := "salir"
@export var task_id := "decidir"
@export var choice_prompt := "Decidir"


func get_prompt() -> String:
	if GameState.is_task_active(task_id):
		return choice_prompt
	return ""


func can_interact() -> bool:
	return super.can_interact() and GameState.is_task_active(task_id)


func _on_interact(_who: Node) -> void:
	GameState.set_flag("ending", ending_id)
	GameState.complete_task(task_id)
