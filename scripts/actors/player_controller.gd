class_name PlayerController
extends CharacterBody2D

const SPEED := 300.0
const GRAVITY := 1600.0
const JUMP_SPEED := -600.0
const DASH_SPEED := 680.0
const DASH_DURATION := 0.14
const DASH_COOLDOWN := 0.7
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

var facing := 1.0
var dash_remaining := 0.0
var dash_cooldown := 0.0
var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0
var animation_time := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 48)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -24)
	add_child(collider)

func _physics_process(delta: float) -> void:
	animation_time += delta
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	jump_buffer_remaining = maxf(0.0, jump_buffer_remaining - delta)
	if is_on_floor():
		coyote_remaining = COYOTE_TIME
	else:
		coyote_remaining = maxf(0.0, coyote_remaining - delta)
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_remaining = JUMP_BUFFER
	if jump_buffer_remaining > 0.0 and coyote_remaining > 0.0:
		velocity.y = JUMP_SPEED
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		dash_remaining = DASH_DURATION
		dash_cooldown = DASH_COOLDOWN
	if dash_remaining > 0.0:
		dash_remaining = maxf(0.0, dash_remaining - delta)
		velocity = Vector2(facing * DASH_SPEED, 0)
	else:
		velocity.x = move_toward(velocity.x, axis * SPEED, 2400.0 * delta)
		velocity.y += GRAVITY * delta
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var sway := sin(animation_time * 8.0) * (2.0 if absf(velocity.x) > 1.0 else 0.7)
	draw_circle(Vector2(0, -3), 19, Color(0.015, 0.02, 0.04, 0.4))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, -33), Vector2(12, -33), Vector2(17 - facing * 5, -5),
		Vector2(-18 - facing * 4 + sway, -7),
	]), Color("ba5145"))
	draw_line(Vector2(-6, -13), Vector2(-7 - sway, -1), Color("182334"), 7)
	draw_line(Vector2(6, -13), Vector2(7 + sway, -1), Color("182334"), 7)
	draw_circle(Vector2(0, -39), 12, Color("e5bd8e"))
	draw_arc(Vector2(0, -39), 13, PI, TAU, 16, Color("b85348"), 9)
	draw_line(Vector2(facing * 2, -40), Vector2(facing * 8, -40), Color("273246"), 2)
	draw_line(Vector2(facing * 10, -27), Vector2(facing * 20, -18), Color("e5bd8e"), 5)
	if dash_remaining > 0.0:
		draw_line(Vector2(-facing * 20, -24), Vector2(-facing * 55, -24), Color(1, 0.65, 0.3, 0.5), 3)
