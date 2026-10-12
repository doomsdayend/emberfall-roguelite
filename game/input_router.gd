extends RefCounted
const KEYS := [KEY_SPACE, KEY_J, KEY_K, KEY_SHIFT, KEY_L, KEY_E, KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_S]
var previous: Dictionary = {}
var blocked := true

func barrier() -> void:
	blocked = true
	previous.clear()

func released() -> bool:
	for key in KEYS:
		if Input.is_physical_key_pressed(key):
			return false
	return not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func poll() -> Dictionary:
	var held := {
		"jump": Input.is_physical_key_pressed(KEY_SPACE),
		"attack": Input.is_physical_key_pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
		"heavy": Input.is_physical_key_pressed(KEY_K) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT),
		"dodge": Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_L),
		"interact": Input.is_physical_key_pressed(KEY_E),
	}
	var axis := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	return route(held, axis, down, released())

func route(held: Dictionary, axis: float, down: bool, neutral: bool) -> Dictionary:
	if blocked:
		if neutral:
			blocked = false
		return {}
	var result := {}
	for action in held:
		result[action] = held[action] and not previous.get(action, false)
	result.jump_held = held.jump
	result.axis = axis
	result.down = down
	previous = held
	return result
