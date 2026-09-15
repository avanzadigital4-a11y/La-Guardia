extends Node
## Audio sintetizado en runtime: el juego no depende de ningun asset externo.
## El viento es un generador continuo; los golpes, pasos y crujidos son
## pequenos WAV generados al arrancar.

const RATE := 22050.0

var _cues := {}
var _wind: AudioStreamPlayer
var _wind_playback: AudioStreamGeneratorPlayback
var _wind_phase := 0.0
var _wind_lp := 0.0
var _gust := 0.35
var _gust_target := 0.35
var _creak_timer := 9.0
var _dread := 0.0
var _ambient_points: Array[Vector3] = []
var _external := {}       # id -> AudioStream grabado que reemplaza al sintetizado
var _wind_stream: AudioStream = null
var _rng := RandomNumberGenerator.new()


const VOICE_DIR := "res://audio/voz"
const FX_DIR := "res://audio/efectos"
const AMBIENT_DIR := "res://audio/ambiente"


func _ready() -> void:
	_rng.randomize()
	_build_cues()
	_load_external()
	_start_wind()


## Si hay grabaciones en audio/, mandan ellas. La sintesis queda de respaldo,
## asi se puede ir grabando de a poco sin romper nada.
func _load_external() -> void:
	for id in _cues.keys():
		var stream := _load_audio("%s/%s" % [FX_DIR, id])
		if stream != null:
			_external[id] = stream
	_wind_stream = _load_audio("%s/viento" % AMBIENT_DIR)


func _load_audio(path_without_ext: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		var path: String = path_without_ext + String(ext)
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is AudioStream:
				return res
	return null


## Linea grabada de un registro de radio, si existe.
func voice_clip(log_id: String, line_index: int) -> AudioStream:
	return _load_audio("%s/%s_%d" % [VOICE_DIR, log_id, line_index + 1])


func _build_cues() -> void:
	_cues["step"] = _wav(_noise_hit(0.13, 0.35, 0.55))
	_cues["click"] = _wav(_noise_hit(0.05, 0.25, 1.0))
	_cues["door"] = _wav(_creak_sound(1.0, 120.0, 260.0))
	_cues["door_locked"] = _wav(_clunk())
	_cues["task"] = _wav(_beeps([660.0, 880.0], 0.09))
	_cues["panel"] = _wav(_beeps([440.0], 0.12))
	_cues["pickup"] = _wav(_beeps([880.0], 0.07))
	_cues["creak"] = _wav(_creak_sound(1.8, 55.0, 95.0))
	_cues["radio_on"] = _wav(_noise_hit(0.35, 0.4, 0.9))
	_cues["step_snow"] = _wav(_noise_hit(0.22, 0.12, 0.2))
	# Bucles, para las anomalias sonoras: algo que quedo andando donde no
	# tendria que haber nada andando. A diferencia de los cues de arriba, no
	# se disparan y terminan: se prenden y quedan.
	_cues["goteo"] = _wav(_goteo(3.2), true)
	_cues["motor"] = _wav(_motor(2.0), true)
	_cues["hiss"] = _wav(_noise_loop(1.0), true)


func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(RATE)
	stream.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream


func _noise_hit(dur: float, cutoff: float, sharpness: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * cutoff
		out[i] = lp * pow(1.0 - t, 2.0 + sharpness * 3.0)
	return out


func _noise_loop(dur: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.5
		out[i] = lp * 0.35
	return out


func _creak_sound(dur: float, f0: float, f1: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var freq: float = lerpf(f0, f1, t * t)
		phase += TAU * freq / RATE
		var wobble := sin(t * 40.0) * 0.35
		var env := sin(PI * t)
		out[i] = (sin(phase) * 0.5 + _rng.randf_range(-1.0, 1.0) * 0.12) * env * (0.7 + wobble * 0.3)
	return out


func _clunk() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.append_array(_noise_hit(0.09, 0.2, 1.2))
	out.append_array(_silence(0.06))
	out.append_array(_noise_hit(0.09, 0.2, 1.2))
	return out


func _beeps(freqs: Array, dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for f in freqs:
		var n := int(RATE * dur)
		var part := PackedFloat32Array()
		part.resize(n)
		for i in n:
			var t := float(i) / n
			part[i] = sin(TAU * float(f) * float(i) / RATE) * sin(PI * t) * 0.5
		out.append_array(part)
	return out


func _silence(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * dur))
	out.fill(0.0)
	return out


func _start_wind() -> void:
	if _wind_stream != null:
		# Viento grabado: nada de generador.
		_wind = AudioStreamPlayer.new()
		_wind.name = "Viento"
		_wind.stream = _wind_stream
		_wind.volume_db = -10.0
		_wind.finished.connect(func(): _wind.play())
		add_child(_wind)
		_wind.play()
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.35
	_wind = AudioStreamPlayer.new()
	_wind.name = "Viento"
	_wind.stream = gen
	_wind.volume_db = -12.0
	add_child(_wind)
	_wind.play()
	_wind_playback = _wind.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(delta: float) -> void:
	_fill_wind()
	_ambient_creaks(delta)


func _fill_wind() -> void:
	if _wind_playback == null:
		return
	var frames := _wind_playback.get_frames_available()
	if frames <= 0:
		return
	for i in frames:
		if _rng.randf() < 0.00004:
			_gust_target = _rng.randf_range(0.15, 1.0)
		_gust = lerpf(_gust, _gust_target, 0.00008)
		_wind_lp += (_rng.randf_range(-1.0, 1.0) - _wind_lp) * 0.045
		_wind_phase += 0.00013
		var body := _wind_lp * (0.45 + _gust * 0.55)
		var whistle := sin(_wind_phase * TAU * 40.0) * 0.03 * _gust
		var s := clampf(body + whistle, -1.0, 1.0) * (0.55 + _dread * 0.4)
		_wind_playback.push_frame(Vector2(s, s))


## Las salas de la estacion, para que los ruidos ambiente vengan de un lugar
## concreto y no del aire. Las carga el NightDirector al construir el mundo.
func set_ambient_points(points: Array[Vector3]) -> void:
	_ambient_points = points


func _ambient_creaks(delta: float) -> void:
	_creak_timer -= delta * (1.0 + _dread)
	if _creak_timer > 0.0:
		return
	_creak_timer = _rng.randf_range(14.0, 38.0)
	var pos := _distant_point()
	# Cuanto mas lejos, mas apagado: el crujido llega de otra habitacion.
	play_cue("creak" if _rng.randf() > 0.25 else "door", pos, -16.0)


func _distant_point() -> Vector3:
	if _ambient_points.is_empty():
		return Vector3.ZERO
	var player := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	var candidates: Array[Vector3] = []
	if player is Node3D:
		var here: Vector3 = (player as Node3D).global_position
		for p in _ambient_points:
			if p.distance_to(here) > 7.0:
				candidates.append(p)
	if candidates.is_empty():
		candidates = _ambient_points
	return candidates[_rng.randi() % candidates.size()]


func set_dread(value: float) -> void:
	_dread = clampf(value, 0.0, 1.0)


func play_cue(id: String, pos: Vector3, volume_db := -6.0) -> void:
	if not _cues.has(id) and not _external.has(id):
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = _external.get(id, _cues.get(id))
	p.unit_size = 6.0
	p.max_distance = 30.0
	p.volume_db = volume_db
	p.position = pos
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


## Fuente sonora que queda prendida hasta que alguien la apaga. La usan las
## anomalias de tipo "sonido": una canilla que gotea en una sala donde no hay
## canilla, un motor andando con el equipo apagado. El que la prende se queda
## con el nodo y es el responsable de liberarlo.
func loop_at(id: String, pos: Vector3, volume_db := -14.0) -> AudioStreamPlayer3D:
	if not _cues.has(id) and not _external.has(id):
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = _external.get(id, _cues.get(id))
	p.unit_size = 5.0
	p.max_distance = 22.0
	p.volume_db = volume_db
	p.position = pos
	add_child(p)
	p.play()
	return p


## Goteo: golpes espaciados sobre silencio. Lo que lo hace inquietante es que
## el intervalo no es exacto.
func _goteo(dur: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var pos := int(RATE * 0.25)
	while pos < n:
		var largo := mini(int(RATE * 0.07), n - pos)
		for i in largo:
			var t := float(i) / float(largo)
			out[pos + i] = sin(TAU * 1400.0 * float(i) / RATE) * exp(-9.0 * t) * 0.5
		pos += int(RATE * _rng.randf_range(0.55, 0.95))
	return out


## Motor: un zumbido grave con su armonico, apenas desafinado para que lata.
func _motor(dur: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = (sin(TAU * 46.0 * t) * 0.6 + sin(TAU * 92.7 * t) * 0.25
			+ sin(TAU * 139.0 * t) * 0.1) * 0.35
	return out


## Voz de radio: no es habla, es la cadencia del habla. Silabas de ruido
## filtrado sobre un zumbido bajo, para que los registros suenen a alguien
## hablando atras de la portadora mientras se leen los subtitulos.
func voice(seconds: float, pos: Vector3, pitch := 1.0) -> AudioStreamPlayer3D:
	var n := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var syllable := maxi(int(RATE * 0.15), 1)
	var base := 98.0 * pitch
	var freq := base
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var index := i / syllable
		if i % syllable == 0:
			freq = base * _rng.randf_range(0.82, 1.28)
		var t := float(i % syllable) / float(syllable)
		var env := sin(PI * t)
		var gap := 0.15 if index % 5 == 4 else 1.0   # respiraciones
		phase += TAU * freq / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.3
		var body := sin(phase) * 0.45 + sin(phase * 2.0) * 0.18 + lp * 0.4
		out[i] = body * env * gap * 0.55
	var p := AudioStreamPlayer3D.new()
	p.stream = _wav(out)
	p.unit_size = 5.0
	p.max_distance = 20.0
	p.volume_db = -13.0
	p.position = pos
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p


## Reproduce una linea de registro: la grabada si esta, la sintetizada si no.
## Devuelve cuanto dura, para que el subtitulo acompane.
func play_line(log_id: String, line_index: int, pos: Vector3, fallback_seconds := 3.0) -> float:
	var clip := voice_clip(log_id, line_index)
	if clip == null:
		voice(fallback_seconds, pos, 1.0 if log_id != "rl_05" else 0.92)
		return fallback_seconds
	var p := AudioStreamPlayer3D.new()
	p.stream = clip
	p.unit_size = 5.0
	p.max_distance = 20.0
	p.volume_db = -6.0
	p.position = pos
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return maxf(clip.get_length(), 1.0)


func start_hiss(pos: Vector3) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = _external.get("hiss", _cues["hiss"])
	p.unit_size = 5.0
	p.max_distance = 18.0
	p.volume_db = -14.0
	p.position = pos
	add_child(p)
	p.play()
	return p


func stop_hiss(p: AudioStreamPlayer3D) -> void:
	if is_instance_valid(p):
		p.stop()
		p.queue_free()
