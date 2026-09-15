extends Node
func _ready() -> void:
	print("PASO 1: arrancando")
	var t0 := Time.get_ticks_msec()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	print("PASO 2: escena instanciada (%d ms)" % (Time.get_ticks_msec() - t0))
	await get_tree().create_timer(4.0).timeout
	print("PASO 3: espera hecha (%d ms)" % (Time.get_ticks_msec() - t0))
	main.player.teleport(Vector3(0.0, 0.1, -6.0), PI)
	for i in 3:
		await RenderingServer.frame_post_draw
	print("PASO 4: frames dibujados (%d ms)" % (Time.get_ticks_msec() - t0))
	var img := get_viewport().get_texture().get_image()
	print("PASO 5: imagen obtenida %dx%d (%d ms)" % [img.get_width(), img.get_height(), Time.get_ticks_msec() - t0])
	var err := img.save_png("user://prueba.png")
	print("PASO 6: guardada err=%d (%d ms)" % [err, Time.get_ticks_msec() - t0])
	get_tree().quit()
