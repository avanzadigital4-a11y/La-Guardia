class_name Prop
extends Node3D
## Objeto del mundo que puede cambiar de estado fuera de camara.
## Guarda su pose "normal" y una pose alterada; la anomalia solo intercambia
## entre las dos mientras el jugador no esta mirando.

@export var prop_id := ""

var normal_transform := Transform3D.IDENTITY
var altered_transform := Transform3D.IDENTITY
var altered := false


func register(id: String, altered_offset: Vector3, altered_rot_deg: float) -> void:
	prop_id = id
	normal_transform = transform
	var t := transform
	t.origin += altered_offset
	t.basis = t.basis.rotated(Vector3.UP, deg_to_rad(altered_rot_deg))
	altered_transform = t
	add_to_group("prop")


func set_altered(value: bool) -> void:
	altered = value
	transform = altered_transform if value else normal_transform
