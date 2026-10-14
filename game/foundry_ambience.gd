extends Node2D
## Deterministic decoration behind actors; no collision, RNG or gameplay events.
var elapsed := 0.0
const FURNACES := [Vector2(110, 435), Vector2(420, 352), Vector2(746, 354)]

func advance(dt: float) -> void:
	elapsed += dt
	queue_redraw()

func ember_position(index: int) -> Vector2:
	var origin: Vector2 = FURNACES[index % FURNACES.size()]
	var age := fposmod(elapsed * (0.19 + float(index % 4) * 0.025) + float(index) * 0.618, 1.0)
	return origin + Vector2(sin(float(index) * 2.7 + age * 4) * 22 + age * 38, -age * 180)

func _draw() -> void:
	# Soft concentric glows stay anchored to the painted furnace mouths.
	for i in FURNACES.size():
		var pulse := 0.75 + 0.16 * sin(elapsed * 2.1 + float(i)) + 0.09 * sin(elapsed * 5.3 + float(i) * 2)
		for layer in range(12, 0, -1):
			draw_circle(FURNACES[i], float(layer) * 4.5, Color(1.0, 0.35, 0.08, 0.009 * pulse))
	# Sparse translucent smoke drifts right and rises above the combat silhouettes.
	for i in range(9):
		var age := fposmod(elapsed * 0.035 + float(i) / 9.0, 1.0)
		var origin: Vector2 = FURNACES[i % FURNACES.size()]
		var center := origin + Vector2(20 + age * 100 + sin(elapsed * 0.25 + float(i)) * 12, -55 - age * 150)
		var fade := sin(age * PI)
		for layer in range(5, 0, -1):
			draw_circle(center, float(layer) * (9 + age * 4), Color(0.40, 0.43, 0.47, 0.012 * fade))
	for i in range(30):
		var age := fposmod(elapsed * (0.19 + float(i % 4) * 0.025) + float(i) * 0.618, 1.0)
		var alpha := sin(age * PI) * 0.65
		var point := ember_position(i)
		draw_line(point + Vector2(-0.7, 2.2), point, Color(1.0, 0.48, 0.16, alpha), 1.0, true)
		draw_circle(point, 0.8, Color(1.0, 0.78, 0.42, alpha))
