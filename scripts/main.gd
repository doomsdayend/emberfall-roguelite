extends Node2D

var flow := SessionFlow.new()
var room: TechnicalRoom
var ui: CanvasLayer

func _ready() -> void:
	InputSetup.configure()
	ui = CanvasLayer.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	show_menu()

func _clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()

func _label(text: String, at: Vector2, font_size: int, color := Color("ead7bb")) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	ui.add_child(label)
	return label

func _button(text: String, at: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(300, 48)
	button.pressed.connect(callback)
	ui.add_child(button)

func show_menu() -> void:
	get_tree().paused = false
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
		room = null
	if flow.state != SessionFlow.State.MENU:
		flow.transition(SessionFlow.State.MENU)
	_clear_ui()
	_label("EMBERFALL", Vector2(105, 155), 64)
	_label("Ash remembers every step.", Vector2(110, 240), 24, Color("c99b78"))
	_button("Open technical room", Vector2(110, 330), start_room)
	_button("Quit", Vector2(110, 392), func(): get_tree().quit())
	_label("STAGE 2 / DEVELOPMENT FOUNDATION", Vector2(110, 550), 20)
	_label("No combat, rewards or saves yet. Not a playable release.", Vector2(110, 590), 20, Color("9aa6b5"))

func start_room() -> void:
	if not flow.begin_run(12345):
		return
	_clear_ui()
	room = TechnicalRoom.new()
	add_child(room)
	_label("SAFE TECHNICAL ROOM", Vector2(35, 25), 26)
	_label("Move: A/D or arrows   Jump: Space   Dash: Shift   Pause: Esc", Vector2(35, 65), 20)
	_label("Original visual placeholders / stage 2 / no gameplay release", Vector2(35, 680), 18)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and is_instance_valid(room):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		_clear_ui()
		_label("PAUSED", Vector2(490, 210), 48)
		_button("Resume", Vector2(490, 300), toggle_pause)
		_button("Return to menu", Vector2(490, 362), show_menu)
	else:
		_clear_ui()
		_label("SAFE TECHNICAL ROOM", Vector2(35, 25), 26)
		_label("Move: A/D or arrows   Jump: Space   Dash: Shift   Pause: Esc", Vector2(35, 65), 20)
