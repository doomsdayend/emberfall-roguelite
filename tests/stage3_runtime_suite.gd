extends Node

var world: Node
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func run(target: Node) -> void:
	world = target
	check(world.stage3_slice, "stage3 flag enables extended flow")
	check(world.ROOMS.size() == 8, "extended flow exposes eight rooms")
	for index in range(8):
		world.load_room(index, 100)
		await get_tree().physics_frame
		if index == 0 or index == 5:
			check(world.enemies.is_empty(), "room %d is a non-combat room" % index)
		elif index == 7:
			check(world.enemies.size() == 1 and world.enemies[0].kind == "kilnwarden", "room 7 contains kilnwarden")
			check(world.enemies[0].hp == 420, "boss starts with dedicated health")
		else:
			check(world.enemies.size() >= 1, "room %d has combat content" % index)
	world.load_room(7, 100)
	var boss = world.enemies[0]
	boss.hp = 200
	boss.state = "boss_slag"
	boss.timer = 0.1
	check(boss.phase == 1, "boss begins phase one")
	boss.hp = 100
	boss.state = "boss_charge"
	boss.timer = 0.1
	check(boss.phase == 1 or boss.phase == 2, "boss phase state remains bounded")
	check(world.player.damage_bonus == 0, "boon state starts clean")
	print("STAGE03_RUNTIME_RESULT=" + JSON.stringify({"passed": failures.is_empty(), "rooms": 8, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
