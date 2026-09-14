# -*- coding: utf-8 -*-
extends Node
## Exporta la estación a una escena .tscn lista para hornear la luz.
##
## La estación se construye por código, y LightmapGI solo hornea geometría que
## exista en una escena guardada. Esta herramienta arma la estación una vez,
## le genera UV2 a cada malla, la marca como estática, le agrega el nodo
## LightmapGI y guarda todo en scenes/estacion_horneable.tscn.
##
## Uso:
##   godot --headless --path . res://tools/exportar_estacion.tscn
##   (después, abrir esa escena en el editor y apretar "Bake Lightmaps")
##
## El resultado del horneado se usa como referencia visual y como fuente de
## las texturas de luz: el juego sigue construyendo la estación por código.

const OUT := "res://scenes/estacion_horneable.tscn"
const TEXEL := 0.2


func _ready() -> void:
	var root := Node3D.new()
	root.name = "EstacionHorneable"
	add_child(root)

	var station := StationBuilder.new()
	station.name = "Estacion"
	root.add_child(station)
	station.build(Color(0.30, 0.32, 0.34))

	# Las noches 3 y 5 encienden tramos que el resto del tiempo no existen:
	# se hornean igual, para tener la luz de todos los estados.
	Build.set_active(station.south_section, true)
	Build.set_active(station.subnivel_section, true)
	Build.set_active(station.south_wall, true)

	var meshes := 0
	var unwrapped := 0
	for node in _all_meshes(station):
		meshes += 1
		node.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		if _prepare_mesh(node):
			unwrapped += 1

	for light in _all_lights(station):
		light.light_bake_mode = Light3D.BAKE_STATIC

	var lightmap := LightmapGI.new()
	lightmap.name = "LightmapGI"
	lightmap.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	lightmap.bounces = 2
	lightmap.use_denoiser = true
	root.add_child(lightmap)

	_set_owner(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		print("No pude empaquetar la escena.")
		get_tree().quit(1)
		return
	var err := ResourceSaver.save(packed, OUT)
	if err != OK:
		print("No pude guardar %s (error %d)" % [OUT, err])
		get_tree().quit(1)
		return
	print("Escrito %s" % OUT)
	print("  mallas: %d   con UV2 generado: %d" % [meshes, unwrapped])
	print("  siguiente paso: abrir la escena en el editor y apretar Bake Lightmaps")
	get_tree().quit(0)


## BoxMesh no sirve para hornear: hay que pasarlo a ArrayMesh y generarle UV2.
func _prepare_mesh(node: MeshInstance3D) -> bool:
	var mesh := node.mesh
	if mesh == null:
		return false
	var array_mesh := ArrayMesh.new()
	for surface in mesh.get_surface_count():
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(surface))
	if array_mesh.lightmap_unwrap(node.global_transform, TEXEL) != OK:
		node.mesh = array_mesh
		return false
	node.mesh = array_mesh
	return true


func _all_meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_meshes(c))
	return out


func _all_lights(node: Node) -> Array[Light3D]:
	var out: Array[Light3D] = []
	if node is Light3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_lights(c))
	return out


func _set_owner(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		if c != owner_node:
			c.owner = owner_node
		_set_owner(c, owner_node)
