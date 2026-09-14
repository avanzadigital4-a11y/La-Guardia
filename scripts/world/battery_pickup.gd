class_name BatteryPickup
extends Interactable
## Pila de repuesto para la linterna.

var taken := false

func get_prompt() -> String:
	return "Tomar pila"


func _on_interact(_who: Node) -> void:
	GameState.spare_batteries += 1
	GameState.notice.emit("Pila de repuesto (%d)" % GameState.spare_batteries)
	AudioDirector.play_cue("pickup", global_position)
	taken = true
	visible = false
	enabled = false


## La estacion se repone entre noches: las pilas vuelven a su lugar.
func restock() -> void:
	taken = false
	visible = true
	enabled = true
