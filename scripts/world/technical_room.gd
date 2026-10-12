class_name TechnicalRoom
extends Node2D

var player: PlayerController
var elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_add_wall(Vector2(640, 650), Vector2(1280, 60))
	_add_wall(Vector2(-20, 350), Vector2(40, 700))
	_add_wall(Vector2(1300, 350), Vector2(40, 700))
	_add_wall(Vector2(480, 535), Vector2(190, 24))
	_add_wall(Vector2(820, 455), Vector2(180, 24))
	player = PlayerController.new()
	player.position = Vector2(180, 600)
	add_child(player)

func _add_wall(at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("101c30"))
	draw_circle(Vector2(1020, 145), 67, Color("586578"))
	draw_circle(Vector2(1042, 128), 60, Color("101c30"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 430), Vector2(0, 315), Vector2(150, 195), Vector2(350, 375),
		Vector2(570, 240), Vector2(830, 355), Vector2(1070, 250), Vector2(1280, 345), Vector2(1280, 430)
	]), Color("1c2c43"))
	for x in [70, 315, 630, 1050, 1225]:
		draw_rect(Rect2(x, 245, 29, 375), Color("293a50"))
		draw_rect(Rect2(x - 12, 240, 53, 18), Color("3c4c60"))
		draw_rect(Rect2(x - 8, 600, 45, 20), Color("3c4c60"))
	for platform in [Rect2(385, 523, 190, 24), Rect2(730, 443, 180, 24), Rect2(0, 620, 1280, 100)]:
		draw_rect(platform, Color("293544"))
		draw_line(platform.position, platform.position + Vector2(platform.size.x, 0), Color("70818a"), 3)
	for x in [110, 660, 1110]:
		draw_line(Vector2(x, 350), Vector2(x, 480), Color("68717b"), 2)
		draw_circle(Vector2(x, 485), 24 + sin(elapsed * 3 + x) * 2, Color(1, 0.58, 0.22, 0.05))
		draw_rect(Rect2(x - 7, 474, 14, 20), Color("f4b968"))
	for index in range(22):
		var x := fmod(index * 79 + elapsed * (8 + index % 4), 1280)
		var y := 300 + fmod(index * 43 - elapsed * 8 + 720, 300)
		draw_circle(Vector2(x, y), 1.2, Color(1, 0.65, 0.3, 0.3))
