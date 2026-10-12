extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_room()
	await process_frame
	check(main.flow.state == SessionFlow.State.PREPARATION, "technical room uses safe preparation state")
	for frame in range(60):
		await physics_frame
	var player: PlayerController = main.room.player
	check(player.is_on_floor(), "player settles on floor")
	var start_x := player.position.x
	Input.action_press("move_right")
	for frame in range(15):
		await physics_frame
	Input.action_release("move_right")
	check(player.position.x > start_x + 30, "input moves player right")
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	check(player.velocity.y < 0, "jump creates upward velocity")
	main.toggle_pause()
	var paused_position := player.position
	for frame in range(10):
		await physics_frame
	check(player.position == paused_position, "pause freezes actor physics")
	main.show_menu()
	check(not paused, "return to menu clears pause")
	check(main.flow.state == SessionFlow.State.MENU, "return to menu resets state")
	main.start_room()
	await process_frame
	check(is_instance_valid(main.room.player), "technical room can reopen without old actors")
	main.show_menu()
	main.queue_free()
	await process_frame
	print("INTEGRATION TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
