class_name RadioLog
extends Interactable
## Grabadora encontrable. Reproduce lineas con ruido de portadora.

@export var log_id := ""
@export var task_id := ""   # si se completa al escuchar el registro entero

var _playing := false


func get_prompt() -> String:
	if _playing:
		return "Reproduciendo"
	if task_id != "" and GameState.is_task_active(task_id):
		return "Escuchar la señal entera"
	return "Escuchar registro"


func _on_interact(_who: Node) -> void:
	if _playing:
		return
	var data: Dictionary = NightData.RADIO_LOGS.get(log_id, {})
	if data.is_empty():
		return
	_playing = true
	GameState.found_radio_log(log_id)
	AudioDirector.play_cue("radio_on", global_position)
	var hiss := AudioDirector.start_hiss(global_position)
	var lines: Array = data["lines"]
	for i in lines.size():
		var seconds := AudioDirector.play_line(log_id, i, global_position, 3.0)
		Subtitles.show_line("%s: %s" % [data["label"], lines[i]], seconds + 0.4)
		await get_tree().create_timer(seconds + 0.6).timeout
		if not is_inside_tree():
			return
	AudioDirector.stop_hiss(hiss)
	Subtitles.clear()
	_playing = false
	if task_id != "" and GameState.is_task_active(task_id):
		GameState.complete_task(task_id)
