extends CharacterBody2D
const Data = preload("res://game/action_data.gd")
signal hit_landed(target: Node, heavy: bool)
signal action_event(event: String, instance: int)
var hp := 100
var facing := 1.0
var state := "idle"
var timer := 0.0
var coyote := 0.0
var jump_buffer := 0.0
var attack_buffer := 0.0
var dodge_cooldown := 0.0
var invulnerability := 0.0
var drop_timer := 0.0
var attack_index := -1
var attack_instance := 0
var targets_hit: Dictionary = {}
var active_emitted := false
var body_shape: CollisionShape2D
var visual: Node2D
var debug_view := false
var frozen := false
var damage_bonus := 0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = 8.0
	body_shape = CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 16
	shape.height = 96
	body_shape.shape = shape
	body_shape.position.y = -48
	add_child(body_shape)
	visual = preload("res://game/pose_visual.gd").new()
	add_child(visual)

func tick(dt: float, cmd: Dictionary, enemies: Array) -> void:
	if hp <= 0:
		state = "death"
		velocity.x = move_toward(velocity.x, 0.0, Data.BRAKE * dt)
		velocity.y += Data.GRAVITY * dt
		move_and_slide()
		visual.advance(dt)
		queue_redraw()
		return
	invulnerability = maxf(0, invulnerability - dt)
	dodge_cooldown = maxf(0, dodge_cooldown - dt)
	drop_timer = maxf(0, drop_timer - dt)
	set_collision_mask_value(2, drop_timer <= 0)
	var grounded := is_on_floor()
	coyote = Data.COYOTE if grounded else maxf(0, coyote - dt)
	jump_buffer = Data.BUFFER if cmd.get("jump", false) else maxf(0, jump_buffer - dt)
	attack_buffer = Data.BUFFER if cmd.get("attack", false) else maxf(0, attack_buffer - dt)
	var axis: float = cmd.get("axis", 0.0)
	if axis != 0:
		facing = signf(axis)
	if cmd.get("down", false) and cmd.get("jump", false) and grounded:
		drop_timer = 0.22
		set_collision_mask_value(2, false)
		jump_buffer = 0
		coyote = 0
		velocity.y = 80
	if state == "hurt":
		timer += dt
		if timer >= 0.22:
			state = "idle"
	elif state == "dodge":
		timer += dt
		velocity.x = facing * 760
		if timer >= Data.DODGE_DURATION:
			state = "idle"
	else:
		var can_cancel: bool = state != "attack" or timer >= Data.ATTACKS[attack_index].startup + Data.ATTACKS[attack_index].active
		if cmd.get("dodge", false) and dodge_cooldown <= 0 and can_cancel:
			state = "dodge"
			timer = 0
			dodge_cooldown = Data.DODGE_COOLDOWN
			attack_buffer = 0
			velocity.x = facing * 760
			action_event.emit("dodge", attack_instance)
		elif state == "attack":
			advance_attack(dt, enemies)
			velocity.x = move_toward(velocity.x, axis * 100, Data.BRAKE * dt)
		else:
			velocity.x = move_toward(velocity.x, axis * Data.SPEED, (Data.ACCEL if axis != 0 else Data.BRAKE) * dt)
			if jump_buffer > 0 and coyote > 0:
				velocity.y = Data.JUMP
				jump_buffer = 0
				coyote = 0
				grounded = false
				action_event.emit("jump", attack_instance)
			if cmd.get("heavy", false):
				start_attack(3 if grounded else 4)
			elif attack_buffer > 0:
				start_attack(0 if grounded else 4)
			else:
				state = "run" if absf(velocity.x) > 5 else "idle"
				if not grounded:
					state = "rise" if velocity.y < -120 else "apex" if velocity.y < 120 else "fall"
	if not cmd.get("jump_held", false) and velocity.y < -360:
		velocity.y = -360
	velocity.y = minf(velocity.y + Data.GRAVITY * dt, 1300)
	move_and_slide()
	if not grounded and is_on_floor() and state not in ["attack", "dodge", "hurt"]:
		state = "land"
		action_event.emit("land", attack_instance)
	queue_redraw()
	visual.advance(dt)

func start_attack(index: int) -> void:
	state = "attack"
	attack_index = index
	attack_instance += 1
	timer = 0
	attack_buffer = 0
	targets_hit.clear()
	active_emitted = false
	action_event.emit("startup", attack_instance)

func advance_attack(dt: float, enemies: Array) -> void:
	var spec: Dictionary = Data.ATTACKS[attack_index]
	var previous := timer
	timer += dt
	# Intersect the elapsed interval with active time, avoiding skipped windows.
	if timer >= spec.startup and previous < spec.startup + spec.active:
		if not active_emitted:
			active_emitted = true
			action_event.emit("active", attack_instance)
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.hp <= 0 or targets_hit.has(enemy.get_instance_id()):
				continue
			if attack_rect().intersects(enemy.hurt_rect()):
				targets_hit[enemy.get_instance_id()] = true
				if enemy.take_damage(spec.damage + damage_bonus, facing * spec.knock):
					hit_landed.emit(enemy, attack_index == 2 or attack_index == 3)
	if timer >= spec.total:
		if attack_buffer > 0 and attack_index < 2 and is_on_floor():
			start_attack(attack_index + 1)
		else:
			state = "idle"
			timer = 0
			action_event.emit("recover", attack_instance)

func attack_rect() -> Rect2:
	var reach: float = Data.ATTACKS[attack_index].reach if attack_index >= 0 else 0.0
	return Rect2(global_position + Vector2(10 if facing > 0 else -reach - 10, -86), Vector2(reach, 74))

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-18, -90), Vector2(36, 90))

func take_damage(amount: int, knock: float) -> bool:
	if hp <= 0 or invulnerability > 0 or (state == "dodge" and timer >= 0.04 and timer < 0.20):
		return false
	hp = maxi(0, hp - amount)
	state = "hurt" if hp > 0 else "death"
	timer = 0
	attack_buffer = 0
	jump_buffer = 0
	invulnerability = 0.50
	velocity.x = knock
	action_event.emit(state, attack_instance)
	visual.queue_redraw()
	return true

func clear_buffers() -> void:
	jump_buffer = 0
	attack_buffer = 0

func _draw() -> void:
	if debug_view:
		draw_rect(Rect2(-16, -96, 32, 96), Color.CYAN, false)
		if state == "attack":
			var rect := attack_rect()
			rect.position -= global_position
			draw_rect(rect, Color.ORANGE, false)
