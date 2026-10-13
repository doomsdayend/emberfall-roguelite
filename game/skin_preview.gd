extends Node2D
## Candidate art-slice skin. It is opt-in and never replaces the prototype by default.
var parts: Dictionary = {}
var source_scale := 1.0

const PARTS := {
	"head": [Vector2(0, -91), Vector2(22.4, 23.0), 0.0, 8],
	"neck": [Vector2(0, -77), Vector2(9, 10), 0.0, 7],
	"torso": [Vector2(0, -67), Vector2(32, 32), 0.0, 5],
	"pelvis": [Vector2(0, -46), Vector2(29, 18), 0.0, 5],
	"cape": [Vector2(-11, -64), Vector2(34, 39), 0.0, 3],
	"upper_arm_back": [Vector2(-15, -62), Vector2(11, 23), -0.08, 2],
	"forearm_back": [Vector2(-18, -45), Vector2(10, 22), -0.05, 2],
	"hand_back": [Vector2(-19, -31), Vector2(7, 11), 0.0, 2],
	"upper_arm_front": [Vector2(15, -62), Vector2(12, 23), 0.08, 6],
	"forearm_front": [Vector2(18, -45), Vector2(11, 22), 0.05, 6],
	"hand_front": [Vector2(20, -31), Vector2(8, 11), 0.0, 7],
	"thigh_back": [Vector2(-8, -30), Vector2(14, 29), 0.03, 2],
	"shin_back": [Vector2(-10, -10), Vector2(12, 29), -0.02, 2],
	"foot_back": [Vector2(-13, -3), Vector2(20, 15), 0.0, 2],
	"thigh_front": [Vector2(8, -30), Vector2(15, 29), -0.03, 4],
	"shin_front": [Vector2(10, -10), Vector2(13, 29), 0.02, 4],
	"foot_front": [Vector2(13, -3), Vector2(21, 15), 0.0, 4],
	"hair_front": [Vector2(1, -93), Vector2(22, 21), 0.0, 10],
	"hair_back": [Vector2(-2, -92), Vector2(22, 21), 0.0, 1],
	"hem": [Vector2(-1, -38), Vector2(27, 20), 0.0, 3],
	"weapon": [Vector2(34, -48), Vector2(10, 77), -0.15, 9]
}

func _ready() -> void:
	for name in PARTS:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/exported/emberblade-v01/" + name + ".png")
		var spec: Array = PARTS[name]
		sprite.position = spec[0]
		sprite.rotation = spec[2]
		sprite.z_index = spec[3]
		var texture_size := Vector2(sprite.texture.get_size())
		sprite.scale = Vector2(spec[1]) / texture_size
		parts[name] = sprite
		add_child(sprite)
	queue_redraw()

func advance(state: String, timer: float, facing: float) -> void:
	scale.x = facing
	var weapon: Sprite2D = parts.get("weapon")
	var front_arm: Sprite2D = parts.get("forearm_front")
	var hand: Sprite2D = parts.get("hand_front")
	if state == "attack":
		var swing := clampf(timer / 0.30, 0.0, 1.0)
		weapon.position = Vector2(12 + swing * 28, -57 + swing * 22)
		weapon.rotation = lerpf(-1.8, 0.5, swing)
		front_arm.rotation = lerpf(0.5, -0.9, swing)
		hand.position = Vector2(14 + swing * 25, -64 + swing * 22)
	elif state == "dodge":
		rotation = sin(timer * 18.0) * 0.18
		weapon.position = Vector2(18, -43)
	else:
		rotation = 0.0
		weapon.position = Vector2(20, -57)
		weapon.rotation = -0.15
		front_arm.rotation = 0.05
		hand.position = Vector2(20, -31)
	queue_redraw()

func _draw() -> void:
	var actor := get_parent()
	if actor != null and actor.get("debug_view") == true:
		draw_rect(Rect2(-16, -96, 32, 96), Color(0.1, 0.9, 1.0, 0.8), false, 1.0)
