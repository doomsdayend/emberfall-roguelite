extends Node2D
## Articulated, original prototype drawing. Not final hand-painted character art.
var clock := 0.0
var pose_override := "birth"
var override_remaining := 0.24
var previous_state := "idle"
var previous_facing := 1.0
var skin_preview: Node2D

func _ready() -> void:
	if "--art-slice-preview" in OS.get_cmdline_user_args():
		_setup_skin_preview()

func _setup_skin_preview() -> void:
	var actor = get_parent()
	if not is_instance_valid(actor) or skin_preview != null:
		return
	if actor.get("kind") == null:
		skin_preview = preload("res://game/skin_preview.gd").new()
	elif actor.get("kind") == "pursuer":
		skin_preview = preload("res://game/enemy_skin_preview.gd").new()
	if skin_preview != null:
		add_child(skin_preview)

func set_pose(pose: String, duration: float) -> void:
	pose_override = pose
	override_remaining = duration
	queue_redraw()

func advance(dt: float) -> void:
	var actor = get_parent()
	if actor.get("frozen") != true:
		clock += dt
		override_remaining = maxf(0, override_remaining - dt)
		if actor.state == "land" and previous_state != "land":
			set_pose("land", 0.10)
		elif actor.state == "run" and previous_state == "idle":
			set_pose("start", 0.10)
		elif actor.state == "idle" and previous_state == "run":
			set_pose("stop", 0.12)
		elif actor.facing != previous_facing and actor.state in ["idle", "run"]:
			set_pose("turn", 0.10)
	previous_state = actor.state
	previous_facing = actor.facing
	queue_redraw()

func _draw() -> void:
	var actor = get_parent()
	var state: String = actor.state
	if override_remaining > 0 and state not in ["attack", "dodge", "hurt", "death", "rise", "apex", "fall"]:
		state = pose_override
	var facing: float = actor.facing
	var torso := Vector2(0, -67)
	var pelvis := Vector2(0, -44)
	var front_foot := Vector2(11, -4)
	var rear_foot := Vector2(-12, -4)
	var hand := Vector2(27, -53)
	var offhand := Vector2(-19, -54)
	var blade_angle := 0.9
	var body_angle := 0.0
	if state == "birth":
		torso.y += 9 * (override_remaining / 0.24)
		pelvis.y += 5 * (override_remaining / 0.24)
		hand = Vector2(10, -76)
	elif state == "start":
		torso.x = 14
		rear_foot.x = -25
	elif state == "stop":
		torso.x = -9
		front_foot.x = 27
		pelvis.y += 4
	elif state == "turn":
		torso.x = -8
		hand.x = 13
		front_foot.x = 20
		rear_foot.x = -20
	elif state == "interact":
		hand = Vector2(36, -72)
		torso.x = 8
	elif state == "victory":
		hand = Vector2(18, -104)
		blade_angle = -PI / 2
		offhand = Vector2(-24, -80)
	if state in ["run", "approach"]:
		var stride := sin(clock * 20)
		front_foot = Vector2(stride * 27, -4 - maxf(0, -stride) * 18)
		rear_foot = Vector2(-stride * 27, -4 - maxf(0, stride) * 18)
		torso.x = 9
		torso.y += absf(stride) * 3
		hand = Vector2(-stride * 17, -56)
		offhand = Vector2(stride * 17, -56)
	elif state in ["rise", "apex", "fall"]:
		front_foot = Vector2(18, -20 if state != "fall" else -7)
		rear_foot = Vector2(-15, -31 if state == "apex" else -12)
		hand = Vector2(26, -80)
		blade_angle = -1.7
	elif state == "land":
		torso.y += 12
		pelvis.y += 13
		front_foot.x = 24
		rear_foot.x = -22
	elif state == "attack":
		var duration: float = actor.get("timer")
		var index = actor.get("attack_index")
		if index == null:
			index = 0
		var start: float = preload("res://game/action_data.gd").ATTACKS[index].startup
		var active: float = preload("res://game/action_data.gd").ATTACKS[index].active
		var total: float = preload("res://game/action_data.gd").ATTACKS[index].total
		var swing := clampf((duration - start) / active, 0, 1)
		hand = Vector2(lerpf(-12, 43, swing), lerpf(-90, -58, swing))
		blade_angle = lerpf(-2.0 if index != 1 else 1.8, 0.1 if index != 1 else -0.6, swing)
		if index == 2:
			blade_angle = lerpf(-2.4, 0.8, swing)
		elif index == 3:
			hand = Vector2(lerpf(-8, 37, swing), lerpf(-110, -45, swing))
			blade_angle = lerpf(-2.6, 1.2, swing)
		elif index == 4:
			front_foot.y -= 15
			rear_foot.y -= 25
		torso.x = lerpf(-5, 14, swing)
		front_foot.x = 25
		rear_foot.x = -24
		var recover := clampf((duration - start - active) / (total - start - active), 0, 1)
		hand = hand.lerp(Vector2(27, -53), recover)
		blade_angle = lerpf(blade_angle, 0.9, recover)
		torso.x = lerpf(torso.x, 0, recover)
		front_foot.x = lerpf(front_foot.x, 11, recover)
		rear_foot.x = lerpf(rear_foot.x, -12, recover)
	elif state == "dodge":
		body_angle = actor.timer / 0.34 * TAU
		torso.y = -48
		hand = Vector2(12, -38)
		front_foot = Vector2(18, -32)
		rear_foot = Vector2(-16, -24)
	elif state == "hurt":
		torso.x = -13
		hand.y = -76
		body_angle = -0.2
	elif state == "death":
		body_angle = -PI / 2
		torso.y = -46
		pelvis.y = -24
	if actor.get("kind") == null and state in ["idle", "run", "attack"]:
		var pose := preload("res://game/player_pose.gd").sample(state, clock, actor.timer, actor.attack_index)
		torso = pose.torso
		pelvis = pose.pelvis
		front_foot = pose.front_foot
		rear_foot = pose.rear_foot
		hand = pose.hand
		offhand = pose.offhand
		blade_angle = pose.blade
	var tint := Color("46505e")
	if actor.get("kind") == "archer":
		tint = Color("5c715b")
	elif actor.get("kind") == "pursuer":
		tint = Color("806151")
	if state in ["telegraph", "aim"]:
		hand = Vector2(30, -84)
		tint = tint.lightened(0.35)
	draw_set_transform(Vector2(0, -30), body_angle, Vector2(facing, 1))
	var offset := Vector2(0, 30)
	torso += offset
	pelvis += offset
	front_foot += offset
	rear_foot += offset
	hand += offset
	offhand += offset
	if skin_preview != null:
		if actor.get("kind") == "pursuer":
			skin_preview.apply_pose(state, facing, actor.timer, actor.hp > 0)
		else:
			skin_preview.apply_pose(torso, pelvis, front_foot, rear_foot, hand, offhand, blade_angle, body_angle, facing, clock)
		return
	# Separate limbs bend at knees/elbows; no static box standing in for motion.
	limb(pelvis, (pelvis + rear_foot) * 0.5 + Vector2(-8, -2), rear_foot, tint.darkened(0.25), 10)
	limb(torso + Vector2(-8, 2), offhand + Vector2(-5, -9), offhand, tint.darkened(0.2), 8)
	draw_colored_polygon(PackedVector2Array([torso + Vector2(-17, -7), torso + Vector2(17, -7), pelvis + Vector2(14, 10), pelvis + Vector2(-16, 8)]), tint)
	draw_colored_polygon(PackedVector2Array([torso + Vector2(-10, -13), torso + Vector2(-30, 12), pelvis + Vector2(-25 - sin(clock * 6) * 5, 8), pelvis + Vector2(-9, -4)]), Color("a74437"))
	limb(pelvis + Vector2(5, 3), (pelvis + front_foot) * 0.5 + Vector2(12, 0), front_foot, tint, 12)
	limb(torso + Vector2(12, 0), (torso + hand) * 0.5 + Vector2(6, 8), hand, Color("d9cfb9"), 8)
	var head := torso + Vector2(1, -21)
	draw_circle(head, 11.2, Color("d9b28b"))
	draw_arc(head + Vector2(-1, -3), 11, -PI, 0.4, 12, Color("292c35"), 8)
	draw_line(head + Vector2(6, -1), head + Vector2(10, -1), Color("292c35"), 2)
	if actor.get("kind") == "archer":
		draw_arc(hand + Vector2(-4, 0), 31, -1.2, 1.2, 16, Color("bd9259"), 4)
		draw_line(hand + Vector2(7, -29), hand + Vector2(7, 29), Color("d9cfb9"), 1)
	elif actor.get("kind") == "pursuer":
		var tip := hand + Vector2.from_angle(blade_angle) * 48
		draw_line(hand, tip, Color("805c44"), 8)
		draw_circle(tip, 12, Color("a9a6a0"))
	else:
		var tip := hand + Vector2.from_angle(blade_angle) * 67.2
		draw_line(hand, tip, Color("e2d9c8"), 5)
		draw_line(hand + Vector2(-5, -5), hand + Vector2(6, 5), Color("bd9259"), 4)
	if state in ["telegraph", "aim"]:
		draw_string(ThemeDB.fallback_font, torso + Vector2(-3, -47), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffe9a6"))

func limb(a: Vector2, joint: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array([a, joint, b]), color, width, true)
	draw_circle(joint, width * 0.55, color)
