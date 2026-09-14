class_name BatteryPickup
extends Interactable
## Pila de repuesto para la linterna.

func get_prompt() -> String:
	return "Tomar pila"


func _on_interact(_who: Node) -> void:
	GameState.spare_batteries += 1
	GameState.notice.emit("Pila de repuesto (%d)" % GameState.spare_batteries)
	AudioDirector.play_cue("pickup", global_position)
	queue_free()
