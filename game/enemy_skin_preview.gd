extends Node2D
## Single-reference enemy preview. It is intentionally a runtime candidate, not final layered art.
var sprite: Sprite2D
var texture := preload("res://assets/exported/foundry-pursuer-v01.png")
var warning_visible := false
var visual_height := 108.0

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-float(texture.get_width()) * 0.5, -float(texture.get_height()))
	sprite.scale = Vector2.ONE * (visual_height / float(texture.get_height()))
	sprite.z_index = 2
	add_child(sprite)

func apply_pose(state: String, facing: float, timer: float, alive: bool) -> void:
	if sprite == null:
		return
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2(facing, 1.0) * (visual_height / float(texture.get_height()))
	sprite.modulate = Color.WHITE if alive else Color(0.48, 0.42, 0.40, 0.75)
	sprite.rotation = 0.0
	warning_visible = state in ["telegraph", "aim"] and alive
	if state in ["telegraph", "aim"]:
		sprite.modulate = Color(1.0, 0.78, 0.56, 1.0)
	elif state == "attack":
		sprite.rotation = -0.10 * facing
	elif state == "hurt":
		sprite.modulate = Color(1.0, 0.42, 0.32, 1.0)
	elif state == "death":
		# Rotate about the feet, then lift the horizontal body clear of the floor.
		sprite.rotation = lerpf(0.0, PI * 0.5 * facing, clampf(timer / 0.45, 0.0, 1.0))
		sprite.position.y = -float(texture.get_width()) * sprite.scale.y * 0.5 * absf(sin(sprite.rotation))
	queue_redraw()

func _draw() -> void:
	# Keep the warning independent of sprite facing, texture tint and death tilt.
	if warning_visible:
		draw_circle(Vector2(0, -124), 12, Color("302317"))
		draw_line(Vector2(0, -132), Vector2(0, -123), Color("ffe9a6"), 3)
		draw_circle(Vector2(0, -117), 2, Color("ffe9a6"))
