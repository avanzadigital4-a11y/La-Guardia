class_name Door
extends Interactable
## Puerta con bisagra. El nodo entero rota, asi que la colision acompana.

@export var open_angle := 95.0
@export var locked := false
@export var locked_text := "Trabada."

var is_open := false
var base_yaw := 0.0
var _tween: Tween


func configure(width: float, mat: Material) -> void:
	# El origen del nodo es la bisagra: la hoja se dibuja hacia +X.
	# La orientacion actual es la de la hoja cerrada.
	base_yaw = rotation.y
	setup_box(Vector3(width, Build.DOOR_H - 0.06, 0.08), mat, Vector3(width * 0.5, (Build.DOOR_H - 0.06) * 0.5, 0.0))
	prompt_text = "Abrir"


func get_prompt() -> String:
	if locked:
		return "Trabada"
	return "Cerrar" if is_open else "Abrir"


func _on_interact(who: Node) -> void:
	if locked:
		if who and who.has_method("show_notice"):
			who.show_notice(locked_text)
		AudioDirector.play_cue("door_locked", global_position)
		return
	set_open(not is_open)
	AudioDirector.play_cue("door", global_position)


func set_open(value: bool, instant := false) -> void:
	is_open = value
	var target := base_yaw + (deg_to_rad(open_angle) if value else 0.0)
	if instant:
		rotation.y = target
		return
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation:y", target, 0.9).set_trans(Tween.TRANS_SINE)
