extends Node
## Estado global de la partida. Es el unico lugar donde vive el progreso:
## que noche es, que tareas faltan, que vio el jugador y que "recuerda" la
## bitacora (que no siempre es lo mismo).

signal night_started(night: int)
signal night_ended(night: int)
signal tasks_changed()
signal task_completed(id: String)
signal all_tasks_done()
signal logbook_changed()
signal notice(text: String)
signal battery_changed(value: float)

const MAX_NIGHT := 5
const SAVE_PATH := "user://la_guardia_save.json"

var current_night := 1
var tasks: Array = []              # [{id, text, done}]
var flags := {}                    # banderas arbitrarias de progreso
var logbook: Array = []            # [{night, time, text, wrong}]
var radio_logs_found: Array = []
var battery := 1.0
var spare_batteries := 1
var night_active := false


func start_night(n: int) -> void:
	current_night = clampi(n, 1, MAX_NIGHT)
	var data := NightData.get_night(current_night)
	tasks.clear()
	for t in data["tasks"]:
		tasks.append({"id": t["id"], "text": t["text"], "done": false})
	for e in data["logbook"]:
		_push_log(e["time"], e["text"], false)
	battery = 1.0
	night_active = true
	tasks_changed.emit()
	battery_changed.emit(battery)
	night_started.emit(current_night)


func complete_task(id: String) -> bool:
	for t in tasks:
		if t["id"] == id and not t["done"]:
			t["done"] = true
			tasks_changed.emit()
			task_completed.emit(id)
			if pending_tasks() == 0:
				_maybe_add_final_task()
			return true
	return false


func _maybe_add_final_task() -> void:
	var data := NightData.get_night(current_night)
	var final: Dictionary = data.get("final_task", {})
	if final.is_empty() or has_task(final["id"]):
		all_tasks_done.emit()
		return
	tasks.append({"id": final["id"], "text": final["text"], "done": false})
	tasks_changed.emit()
	notice.emit("Tarea nueva: %s" % final["text"])


func has_task(id: String) -> bool:
	for t in tasks:
		if t["id"] == id:
			return true
	return false


func is_task_active(id: String) -> bool:
	for t in tasks:
		if t["id"] == id:
			return not t["done"]
	return false


func is_task_done(id: String) -> bool:
	for t in tasks:
		if t["id"] == id:
			return t["done"]
	return false


func pending_tasks() -> int:
	var n := 0
	for t in tasks:
		if not t["done"]:
			n += 1
	return n


func end_night() -> void:
	night_active = false
	var data := NightData.get_night(current_night)
	for e in data.get("logbook_end", []):
		# Estas entradas las "escribio" el protagonista esa misma noche.
		_push_log(e["time"], e["text"], true)
	night_ended.emit(current_night)


func _push_log(time: String, text: String, wrong: bool) -> void:
	logbook.append({"night": current_night, "time": time, "text": text, "wrong": wrong})
	logbook_changed.emit()


func add_log(time: String, text: String, wrong := false) -> void:
	_push_log(time, text, wrong)


func found_radio_log(id: String) -> void:
	if id not in radio_logs_found:
		radio_logs_found.append(id)


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)


func drain_battery(amount: float) -> void:
	var prev := battery
	battery = clampf(battery - amount, 0.0, 1.0)
	if not is_equal_approx(prev, battery):
		battery_changed.emit(battery)


func use_spare_battery() -> bool:
	if spare_batteries <= 0:
		return false
	spare_batteries -= 1
	battery = 1.0
	battery_changed.emit(battery)
	return true


func reset() -> void:
	current_night = 1
	tasks.clear()
	flags.clear()
	logbook.clear()
	radio_logs_found.clear()
	battery = 1.0
	spare_batteries = 1


func save_game() -> void:
	var data := {
		"night": current_night,
		"flags": flags,
		"logbook": logbook,
		"radio_logs": radio_logs_found,
		"spare": spare_batteries,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	current_night = int(parsed.get("night", 1))
	flags = parsed.get("flags", {})
	logbook = parsed.get("logbook", [])
	radio_logs_found = parsed.get("radio_logs", [])
	spare_batteries = int(parsed.get("spare", 1))
	return true
