extends CharacterBody2D
signal fired(origin: Vector2, direction: float)
var kind := "pursuer"
var elite := false
var training := false
var hp := 45
var facing := -1.0
var state := "idle"
var timer := 0.0
var attack_index := 0
var invulnerability := 0.0
var locked_facing := -1.0
var hit_done := false
var frozen := false
var visual: Node2D

func _ready() -> void:
	collision_layer = 8
	collision_mask = 3
	var collider := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 18
	shape.height = 90
	collider.shape = shape
	collider.position.y = -45
	add_child(collider)
	visual = preload("res://game/pose_visual.gd").new()
	add_child(visual)
	if elite:
		hp = 160

func tick(dt: float, player: Node2D) -> void:
	if frozen:
		return
	invulnerability = maxf(0, invulnerability - dt)
	timer += dt
	velocity.y = minf(1300, velocity.y + 2200 * dt)
	if hp <= 0:
		state = "death"
		velocity.x = move_toward(velocity.x, 0, 3000 * dt)
	elif training:
		velocity.x = 0
	elif state == "hurt":
		velocity.x = move_toward(velocity.x, 0, 1600 * dt)
		if timer >= 0.24:
			state = "recover"
			timer = 0
	elif state == "recover":
		velocity.x = 0
		if timer >= (0.50 if elite else 0.70):
			state = "idle"
	elif state in ["telegraph", "aim"]:
		velocity.x = 0
		if timer >= (0.42 if elite else 0.55):
			state = "attack"
			timer = 0
			hit_done = false
			if kind == "archer":
				fired.emit(global_position + Vector2(facing * 24, -60), locked_facing)
	elif state == "attack":
		velocity.x = locked_facing * 100 if kind != "archer" else 0.0
		if kind != "archer" and not hit_done and timer < 0.14:
			var box := Rect2(global_position + Vector2(0 if locked_facing > 0 else -100, -86), Vector2(100, 80))
			if box.intersects(player.hurt_rect()):
				hit_done = true
				player.take_damage(18 if elite else 10, locked_facing * 260)
		if timer >= 0.22:
			state = "recover"
			timer = 0
	elif player.hp > 0:
		var distance: float = player.global_position.x - global_position.x
		facing = 1.0 if distance >= 0 else -1.0
		var in_range := absf(distance) < (440 if kind == "archer" else 90)
		if absf(distance) < 900:
			if in_range:
				state = "aim" if kind == "archer" else "telegraph"
				timer = 0
				locked_facing = facing
				velocity.x = 0
			else:
				state = "approach"
				velocity.x = facing * (180 if elite else 140)
		else:
			state = "idle"
			velocity.x = 0
	else:
		velocity.x = 0
	move_and_slide()
	visual.advance(dt)

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-22, -90), Vector2(44, 90))

func take_damage(amount: int, knock: float) -> bool:
	if hp <= 0 or invulnerability > 0:
		return false
	hp = maxi(0, hp - amount)
	state = "hurt" if hp > 0 else "death"
	timer = 0
	velocity.x = knock
	invulnerability = 0.10
	return true
