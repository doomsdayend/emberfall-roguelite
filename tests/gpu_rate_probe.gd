extends SceneTree
var viewport: SubViewport
var game: Node
var tick_index := 0
var completed := false
var frame_times: Array[float] = []
var last_frame := 0
var start_position := Vector2.ZERO
var distance := 0.0
var baseline := 0.0
var top := 10000.0
var attack_events: Array = []
var rate := 60

func _initialize() -> void:
	root.mode = Window.MODE_MINIMIZED
	root.unfocusable = true
	rate = Engine.max_fps
	call_deferred("setup")

func setup() -> void:
	if DisplayServer.get_name() == "headless":
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
	game.start_run()
	game.player.action_event.connect(func(event, instance):
		if tick_index >= 330:
			attack_events.append({"event": event, "instance": instance, "tick": tick_index}))
	process_frame.connect(draw_frame)
	physics_frame.connect(step_world)

func draw_frame() -> void:
	if completed:
		return
	var now := Time.get_ticks_usec()
	if last_frame > 0:
		frame_times.append(float(now - last_frame) / 1000.0)
	last_frame = now
	RenderingServer.force_draw(false)

func step_world() -> void:
	if completed:
		return
	var command := {}
	if tick_index == 30:
		start_position = game.player.position
	if tick_index >= 30 and tick_index < 150:
		command.axis = 1.0
	if tick_index == 150:
		distance = game.player.position.x - start_position.x
	if tick_index == 174:
		# Measure free-space jump, outside the platform's one-way margin.
		game.player.position.x = 130
		baseline = game.player.position.y
		command.jump = true
	if tick_index >= 174 and tick_index < 294:
		command.jump_held = true
	if tick_index == 306:
		game.player.position = Vector2(130, 615)
		game.player.velocity = Vector2.ZERO
	if tick_index == 330:
		command.attack = true
	game.tick(1.0 / 120.0, command)
	if tick_index >= 174 and tick_index < 294:
		top = minf(top, game.player.position.y)
	tick_index += 1
	if tick_index >= 420:
		completed = true
		finish()

func finish() -> void:
	frame_times.sort()
	var sum := 0.0
	for value in frame_times:
		sum += value
	var measured := 1000.0 * frame_times.size() / sum if sum > 0 else 0.0
	var passed := root.mode == Window.MODE_MINIMIZED and distance > 430 and distance < 480 and baseline - top > 190 and baseline - top < 220 and attack_events.size() == 3
	print("GPU_RATE_RESULT=" + JSON.stringify({"passed": passed, "requested_max_fps": rate, "observed_frames_per_second": measured, "frame_interval_p95_ms": frame_times[int(frame_times.size() * 0.95)], "distance_1s": distance, "jump_height": baseline - top, "attack_events": attack_events, "gpu": RenderingServer.get_video_adapter_name(), "frames": frame_times.size(), "main_window_minimized": root.mode == Window.MODE_MINIMIZED, "human_playtested": false}))
	quit(0 if passed else 1)
