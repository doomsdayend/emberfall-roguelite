extends Node2D
## Single-reference enemy preview. It is intentionally a runtime candidate, not final layered art.
var sprite: Sprite2D
var texture := preload("res://assets/exported/foundry-pursuer-v01.png")

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(-30, -108)
	sprite.scale = Vector2.ONE * (108.0 / float(texture.get_height()))
	sprite.z_index = 2
	add_child(sprite)

func apply_pose(state: String, facing: float, timer: float, alive: bool) -> void:
	if sprite == null:
		return
	sprite.position = Vector2(-30, -108)
	sprite.scale = Vector2(absf(sprite.scale.x) * facing, absf(sprite.scale.y))
	sprite.modulate = Color.WHITE if alive else Color(0.48, 0.42, 0.40, 0.75)
	sprite.rotation = 0.0
	if state in ["telegraph", "aim"]:
		sprite.modulate = Color(1.0, 0.78, 0.56, 1.0)
	elif state == "attack":
		sprite.rotation = -0.10 * facing
	elif state == "hurt":
		sprite.modulate = Color(1.0, 0.42, 0.32, 1.0)
	elif state == "death":
		sprite.rotation = lerpf(0.0, PI * 0.5 * facing, clampf(timer / 0.45, 0.0, 1.0))
