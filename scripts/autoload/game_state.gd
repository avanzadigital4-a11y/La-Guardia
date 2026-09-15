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
const SAVE_PATH := "user://la_guardia_save.json"   # partida vieja, se migra sola
const SLOTS := 3

var current_night := 1
var tasks: Array = []              # [{id, text, done}]
var flags := {}                    # banderas arbitrarias de progreso
var logbook: Array = []            # [{night, time, text, wrong}]
var anomalies_seen: Array = []     # [{night, id}] lo que cambio de verdad en esta partida
var radio_logs_found: Array = []
var battery := 1.0
var spare_batteries := 0   # las de repuesto se buscan en la estacion
var night_active := false
var pending_world := {}   # estado del mundo a restaurar al continuar
var slot := 1


func start_night(n: int) -> void:
	current_night = clampi(n, 1, MAX_NIGHT)
	var data := NightData.get_night(current_night)
	tasks.clear()
	for t in data["tasks"]:
		tasks.append({
			"id": t["id"],
			"text": t["text"],
			"done": false,
			"steps": int(t.get("steps", 1)),
			"done_steps": 0,
		})
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
	tasks.append({"id": final["id"], "text": final["text"], "done": false, "steps": 1, "done_steps": 0})
	tasks_changed.emit()
	notice.emit("Tarea nueva: %s" % final["text"])


## Avanza una tarea de varios pasos (la ronda exterior, el generador). La
## completa recien cuando se cubrieron todos.
func advance_task(id: String) -> bool:
	for t in tasks:
		if t["id"] == id and not t["done"]:
			t["done_steps"] = int(t["done_steps"]) + 1
			if int(t["done_steps"]) >= int(t["steps"]):
				return complete_task(id)
			tasks_changed.emit()
			notice.emit("%s (%d/%d)" % [t["text"], t["done_steps"], t["steps"]])
			return true
	return false


func task_progress(id: String) -> String:
	for t in tasks:
		if t["id"] == id and int(t["steps"]) > 1 and not t["done"]:
			return " (%d/%d)" % [t["done_steps"], t["steps"]]
	return ""


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


## Cada anomalia que se aplica queda anotada con su noche. No es para el
## jugador: es el material con el que despues el parte del turno le muestra,
## en su propia letra, lo que hizo sin acordarse. Una misma anomalia no se
## anota dos veces en la misma noche.
func record_anomaly(id: String) -> void:
	for e in anomalies_seen:
		if String(e.get("id", "")) == id and int(e.get("night", 0)) == current_night:
			return
	anomalies_seen.append({"night": current_night, "id": id})


## Las anomalias de una noche, en el orden en que pasaron.
func anomalies_of_night(night: int) -> Array:
	var out: Array = []
	for e in anomalies_seen:
		if int(e.get("night", 0)) == night:
			out.append(String(e.get("id", "")))
	return out


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
	anomalies_seen.clear()
	radio_logs_found.clear()
	battery = 1.0
	spare_batteries = 0
	pending_world = {}


static func slot_path(n: int) -> String:
	return "user://la_guardia_%d.json" % clampi(n, 1, SLOTS)


## Resumen de cada ranura, para el menu: {"usado", "noche", "fecha"}.
static func slot_info(n: int) -> Dictionary:
	var path := slot_path(n)
	if not FileAccess.file_exists(path):
		return {"usado": false, "noche": 0, "fecha": ""}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"usado": false, "noche": 0, "fecha": ""}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"usado": false, "noche": 0, "fecha": ""}
	return {
		"usado": true,
		"noche": int(parsed.get("night", 1)),
		"fecha": String(parsed.get("fecha", "")),
		"en_curso": not Dictionary(parsed.get("mundo", {})).is_empty(),
	}


static func delete_slot(n: int) -> void:
	var path := slot_path(n)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func any_slot_used() -> bool:
	for i in range(1, SLOTS + 1):
		if slot_info(i)["usado"]:
			return true
	return false


## `world` lo arma el NightDirector: alcanza para retomar a mitad de noche.
func save_game(world := {}) -> void:
	var data := {
		"night": current_night,
		"flags": flags,
		"logbook": logbook,
		"anomalias_vistas": anomalies_seen,
		"radio_logs": radio_logs_found,
		"spare": spare_batteries,
		"mundo": world,
		"fecha": Time.get_datetime_string_from_system(false, true),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func load_game(from_slot := 0) -> bool:
	if from_slot > 0:
		slot = clampi(from_slot, 1, SLOTS)
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		# Partida guardada antes de que existieran las ranuras.
		if FileAccess.file_exists(SAVE_PATH):
			path = SAVE_PATH
		else:
			return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	current_night = int(parsed.get("night", 1))
	flags = parsed.get("flags", {})
	logbook = parsed.get("logbook", [])
	anomalies_seen = parsed.get("anomalias_vistas", [])
	radio_logs_found = parsed.get("radio_logs", [])
	spare_batteries = int(parsed.get("spare", 0))
	pending_world = parsed.get("mundo", {})
	return true
