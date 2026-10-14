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
	game.player.state = "run"
	game.player.visual.override_remaining = 0
	game.player.visual.clock = 0.08
	await capture("run")
	for state in ["rise", "apex", "fall", "hurt"]:
		game.player.state = state
		await capture(state)
	game.player.state = "idle"
	for pose in ["birth", "start", "stop", "turn", "land", "interact"]:
		game.player.visual.set_pose(pose, 0.10 if pose != "birth" else 0.24)
		await capture(pose)
	game.load_room(2)
	game.resume()
	var pursuer = game.enemies[0]
	pursuer.state = "telegraph"
	pursuer.timer = 0.20
	pursuer.visual.override_remaining = 0
	pursuer.facing = 1
	await capture("pursuer_telegraph")
	pursuer.facing = -1
	await capture("pursuer_telegraph_left")
	pursuer.state = "attack"
	pursuer.timer = 0.08
	await capture("pursuer_attack")
	pursuer.state = "hurt"
	pursuer.timer = 0.05
	await capture("pursuer_hurt")
	pursuer.state = "death"
	pursuer.timer = 0.22
	await capture("pursuer_death")
	pursuer.timer = 0.50
	await capture("pursuer_death_settled")
	pursuer.state = "idle"
	pursuer.timer = 0
	game.player.position = Vector2(570, 620)
	game.player.start_attack(0)
	game.player.timer = 0.03
	await capture("windup")
	game.player.timer = 0.11
	await capture("active")
	game.player.timer = 0.24
	await capture("recovery")
	game.player.start_attack(3)
	game.player.timer = 0.30
	await capture("heavy")
	game.player.facing = -1
	await capture("heavy_left")
	game.player.facing = 1
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
	# Preview children must exist and receive the state before framebuffer capture.
	await process_frame
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var screenshot := viewport.get_texture().get_image()
	var directory := "res://artifacts/gpu-art-slice" if game.art_slice_preview else "res://artifacts/gpu"
	var path := directory + "/" + label + ".png"
	DirAccess.make_dir_recursive_absolute(directory)
	if screenshot == null or screenshot.is_empty() or screenshot.get_size() != Vector2i(1280, 720):
		failed = true
	elif screenshot.save_png(path) != OK:
		failed = true
	else:
		captures.append(label)
