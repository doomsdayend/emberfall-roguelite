extends SceneTree
## Only run through tools/capture-prototype.ps1, which starts minimized.
var viewport: SubViewport
var game: Node
var captures: Array[String] = []
var failed := false

func _initialize() -> void:
	root.mode = Window.MODE_MINIMIZED
	root.unfocusable = true
	call_deferred("capture_all")

func capture_all() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("GPU capture requires a real renderer and a minimized native window")
		quit(1)
		return
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	game = (load("res://game/prototype.tscn") as PackedScene).instantiate()
	viewport.add_child(game)
	game.set_physics_process(false)
	await capture("title")
	game.show_menu("settings")
	await capture("settings")
	game.start_run()
	await capture("refuge")
	for pose in ["birth", "start", "stop", "turn", "land", "interact"]:
		game.player.visual.set_pose(pose, 0.10 if pose != "birth" else 0.24)
		await capture(pose)
	game.load_room(2)
	game.resume()
	game.player.position = Vector2(570, 620)
	game.player.start_attack(0)
	game.player.timer = 0.03
	await capture("windup")
	game.player.timer = 0.11
	await capture("active")
	game.player.timer = 0.24
	await capture("recovery")
	game.player.state = "dodge"
	game.player.timer = 0.12
	await capture("dodge")
	game.show_menu("pause")
	await capture("pause")
	game.player.hp = 0
	game.player.state = "death"
	game.show_menu("death")
	await capture("death")
	game.load_room(4, 80)
	for enemy in game.enemies:
		enemy.hp = 0
		enemy.state = "death"
	game.player.state = "idle"
	game.show_menu("win")
	await capture("victory")
	print("GPU_CAPTURE_RESULT=" + JSON.stringify({"passed": not failed, "display": DisplayServer.get_name(), "gpu": RenderingServer.get_video_adapter_name(), "captures": captures, "size": "1280x720", "main_window_minimized": root.mode == Window.MODE_MINIMIZED, "performance_tested": false}))
	quit(1 if failed or root.mode != Window.MODE_MINIMIZED else 0)

func capture(label: String) -> void:
	game.update_hud()
	game.queue_redraw()
	for actor in game.actors.get_children():
		actor.visual.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var screenshot := viewport.get_texture().get_image()
	var path := "res://artifacts/gpu/" + label + ".png"
	DirAccess.make_dir_recursive_absolute("res://artifacts/gpu")
	if screenshot == null or screenshot.is_empty() or screenshot.get_size() != Vector2i(1280, 720):
		failed = true
	elif screenshot.save_png(path) != OK:
		failed = true
	else:
		captures.append(label)
