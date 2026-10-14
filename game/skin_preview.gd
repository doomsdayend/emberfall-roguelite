extends Node2D
## Rigid painted layers follow the shared pose anchors. Gameplay never reads these.
var parts: Dictionary = {}
var sizes: Dictionary = {}
var pivots: Dictionary = {}
var joints: Dictionary = {}
var grip := Vector2.ZERO
var tip := Vector2.ZERO
const ORDER := ["hair_back", "cape", "thigh_back", "shin_back", "foot_back", "upper_arm_back", "forearm_back", "hand_back", "pelvis", "hem", "torso", "neck", "head", "thigh_front", "shin_front", "foot_front", "upper_arm_front", "forearm_front", "weapon", "hand_front", "hair_front"]

func _ready() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source/emberblade-skin-v01.json"))
	for item in manifest.parts:
		var sprite := Sprite2D.new()
		sprite.name = item.id
		sprite.texture = load(item.texture)
		assert(sprite.texture != null, "Missing skin texture " + item.id)
		sprite.centered = false
		var size := Vector2(item.size[0], item.size[1])
		var pivot := Vector2(item.pivot[0], item.pivot[1]) * size
		sizes[item.id] = size
		pivots[item.id] = pivot
		# Resampling scale is fixed once. Animation rotates/translates, never stretches.
		sprite.scale = size / Vector2(sprite.texture.get_size())
		sprite.offset = -pivot / sprite.scale
		sprite.z_index = ORDER.find(item.id)
		parts[item.id] = sprite
		add_child(sprite)
	# The head art already includes hair. Extra hair layers remain editable but hidden.
	parts.hair_front.hide()
	parts.hair_back.hide()

func place(id: String, point: Vector2, angle: float = 0.0) -> void:
	parts[id].position = point
	parts[id].rotation = angle

func bend(start: Vector2, target: Vector2, first: float, second: float, side: float) -> Array[Vector2]:
	var delta := target - start
	var length := clampf(delta.length(), absf(first - second) + 0.01, first + second - 0.01)
	var direction := delta.normalized() if delta.length() > 0.01 else Vector2.DOWN
	var along := (first * first - second * second + length * length) / (2 * length)
	var height := sqrt(maxf(0, first * first - along * along))
	return [start + direction * along + direction.orthogonal() * height * side, start + direction * length]

func limb(prefix: String, suffix: String, start: Vector2, target: Vector2, first: float, second: float, side: float) -> Vector2:
	var chain := bend(start, target, first, second, side)
	place(prefix + suffix, start, (chain[0] - start).angle() - PI / 2)
	var lower := "forearm" if prefix == "upper_arm" else "shin"
	place(lower + suffix, chain[0], (chain[1] - chain[0]).angle() - PI / 2)
	joints[prefix + suffix] = chain[0]
	return chain[1]

func apply_pose(torso: Vector2, pelvis: Vector2, front_foot: Vector2, rear_foot: Vector2, hand: Vector2, offhand: Vector2, blade_angle: float, body_angle: float, facing: float, clock: float) -> void:
	if parts.is_empty():
		return
	position = Vector2(0, -30)
	rotation = body_angle
	scale = Vector2(facing, 1)
	var lean := (torso - pelvis).angle() + PI / 2
	place("torso", torso + Vector2(0, -9), lean)
	place("pelvis", pelvis)
	place("neck", torso + Vector2(0, -13), lean)
	place("head", torso + Vector2(1, -10), lean * 0.35)
	place("cape", torso + Vector2(-11, -10), lean + sin(clock * 6) * 0.08)
	place("hem", pelvis + Vector2(0, 2), sin(clock * 6) * 0.06)
	var rear := limb("thigh", "_back", pelvis + Vector2(-6, 2), rear_foot + Vector2(0, -2), 22, 22, 1)
	var front := limb("thigh", "_front", pelvis + Vector2(6, 2), front_foot + Vector2(0, -2), 22, 22, 1)
	place("foot_back", rear)
	place("foot_front", front)
	var off := limb("upper_arm", "_back", torso + Vector2(-9, -1).rotated(lean), offhand, 16, 16, -1)
	grip = limb("upper_arm", "_front", torso + Vector2(9, -1).rotated(lean), hand, 16, 16, -1)
	place("hand_back", off, parts.forearm_back.rotation)
	place("hand_front", grip, blade_angle + PI / 2)
	place("weapon", grip, blade_angle + PI / 2)
	tip = grip + Vector2.from_angle(blade_angle) * (sizes.weapon.y * 0.84)
