class_name TaskPoint
extends Interactable
## Punto de mundo que completa una tarea de la lista de la noche.

@export var task_id := ""
@export var active_prompt := "Revisar"
@export var done_prompt := "Ya esta revisado"
@export var inactive_text := "No hace falta todavia."
@export var notice_on_done := ""
@export var log_time := ""
@export var log_text := ""


func get_prompt() -> String:
	if GameState.is_task_done(task_id):
		return done_prompt
	return active_prompt


func _on_interact(who: Node) -> void:
	if GameState.is_task_done(task_id):
		if who and who.has_method("show_notice"):
			who.show_notice(done_prompt + ".")
		return
	if not GameState.is_task_active(task_id):
		if who and who.has_method("show_notice"):
			who.show_notice(inactive_text)
		return
	GameState.complete_task(task_id)
	AudioDirector.play_cue("task", global_position)
	if notice_on_done != "":
		GameState.notice.emit(notice_on_done)
	if log_text != "":
		GameState.add_log(log_time, log_text, false)
