extends Node
var failures: Array[String] = []
var checks := 0
var world: Node
var motion_samples: Array = []
var combat_runs := 0
const DT := 1.0 / 120.0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)

func frames(count: int, command: Dictionary = {}) -> void:
	for i in count:
		world.tick(DT, command)
		await get_tree().physics_frame

func reset(index: int = 0) -> void:
	world.load_room(index, 100)
	world.resume()
	await frames(12)

func run(game: Node) -> void:
	world = game
	check(DisplayServer.get_name() == "headless", "headless test environment")
	check(world.mode == "title", "boots to title")
	await reset()
	check(world.room == 0 and world.enemies.is_empty(), "safe first room")
	check(world.player.is_on_floor(), "player settles on solid ground")
	await test_motion()
	await test_combat()
	await test_enemy()
	await test_pause()
	await test_preferences_and_pose()
	if world.art_slice_preview:
		await test_skin_binding()
		await test_enemy_skin_readability()
		test_player_pose_keys()
	await test_flow()
	await test_combat_flows()
	var result := {"suite": "fixed-room-prototype", "passed": failures.is_empty(), "checks": checks,
		"failures": failures, "physics_hz": 120, "motion_samples": motion_samples,
		"room_restarts": 20, "fixture_flows": 10, "combat_flows": combat_runs,
		"gpu_tested": false, "human_playtested": false, "published": false}
	print("PROTOTYPE_RESULT=" + JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)

func test_skin_binding() -> void:
	await reset()
	var skin = world.player.visual.skin_preview
	check(skin != null and skin.parts.size() == 21, "21 painted skin layers loaded")
	var scales := {}
	for id in skin.parts:
		scales[id] = skin.parts[id].scale
	var previous_tip := Vector2.ZERO
	for cycle in 100:
		var angle := float(cycle % 10) * 0.30 - 2.0
		var face := 1.0 if cycle % 2 == 0 else -1.0
		skin.apply_pose(Vector2(4, -37), Vector2(0, -14), Vector2(20, 26), Vector2(-19, 26), Vector2(28, -23), Vector2(-22, -25), angle, 0.0, face, float(cycle) / 120)
		check(skin.parts.weapon.position.is_equal_approx(skin.parts.hand_front.position), "weapon grip remains at front hand")
		check(is_equal_approx(skin.scale.x, face) and skin.scale.y == 1.0, "skin mirrors without changing size")
		var stable := true
		for id in scales:
			stable = stable and skin.parts[id].scale.is_equal_approx(scales[id])
		check(stable, "rig rotations never stretch painted limbs")
		if cycle > 0:
			check(not skin.tip.is_equal_approx(previous_tip), "weapon tip follows changing angle")
		previous_tip = skin.tip
	var chain: Array = skin.bend(Vector2.ZERO, Vector2(100, 0), 16, 16, 1)
	check(is_equal_approx(chain[0].length(), 16) and is_equal_approx(chain[0].distance_to(chain[1]), 16), "unreachable hand target keeps fixed arm lengths")
	check(world.player.body_shape.shape.height == 96 and world.player.body_shape.shape.radius == 16, "skin keeps original collision capsule")

func test_player_pose_keys() -> void:
	var library = preload("res://game/player_pose.gd")
	var idle: Dictionary = library.sample("idle", 0.0, 0.0, 0)
	check(idle.pelvis.y < -53, "standing pelvis avoids persistent crouch")
	check(absf(idle.front_foot.y - idle.rear_foot.y) < 0.01, "idle feet share ground plane")
	for index in range(5):
		var spec: Dictionary = preload("res://game/action_data.gd").ATTACKS[index]
		var early: Dictionary = library.sample("attack", 0.0, 0.0, index)
		var wind: Dictionary = library.sample("attack", 0.0, spec.startup * 0.9, index)
		var active: Dictionary = library.sample("attack", 0.0, spec.startup + spec.active, index)
		var end: Dictionary = library.sample("attack", 0.0, spec.total, index)
		check(early.hand.distance_to(wind.hand) > 10, "attack wind-up visibly moves before active window")
		check(wind.hand.distance_to(active.hand) > 20, "attack has distinct active sweep")
		check(active.torso.distance_to(wind.torso) > 6, "torso drives attack with arm")
		check(end.hand.distance_to(idle.hand) < 0.01, "attack returns smoothly to resting grip")

func test_enemy_skin_readability() -> void:
	await reset(2)
	var enemy = world.enemies[0]
	var preview = enemy.visual.skin_preview
	check(preview != null, "pursuer preview loads during room creation")
	var sprite: Sprite2D = preview.sprite
	var bounds := sprite.get_rect()
	for face in [1.0, -1.0]:
		preview.apply_pose("idle", face, 0.0, true)
		var left: Vector2 = sprite.transform * bounds.position
		var right: Vector2 = sprite.transform * (bounds.position + Vector2(bounds.size.x, 0))
		check(is_equal_approx(left.x + right.x, 0.0), "mirrored enemy remains centered on collider")
		check(is_equal_approx(absf(sprite.scale.y) * bounds.size.y, 108.0), "enemy retains visual height")
		preview.apply_pose("telegraph", face, 0.20, true)
		check(preview.warning_visible, "telegraph marker survives skin replacement in either direction")
		preview.apply_pose("death", face, 0.50, false)
		check(not preview.warning_visible, "dead enemy hides warning")
		var above_floor := true
		for point in [bounds.position, bounds.position + Vector2(bounds.size.x, 0), bounds.end, bounds.position + Vector2(0, bounds.size.y)]:
			above_floor = above_floor and (sprite.transform * point).y <= 0.01
		check(above_floor, "settled enemy sprite stays above floor in either direction")
	preview.apply_pose("hurt", 1.0, 0.05, true)
	check(not preview.warning_visible, "hurt interrupt hides warning")
	var capsule: CapsuleShape2D = enemy.get_child(0).shape
	check(capsule.radius == 18 and capsule.height == 90, "enemy art retains existing collision capsule")
	check(world.enemies[1].visual.skin_preview == null, "archer keeps its procedural visual")

func test_motion() -> void:
	for sample_hz in [30, 60, 120]:
		await reset()
		var start: Vector2 = world.player.position
		# Render-input sampling simulated at these rates; actual physics remains
		# 120Hz. This is not a measured GPU/FPS benchmark.
		var command := {}
		for i in 120:
			if i % (120 / sample_hz) == 0:
				command = {"axis": 1.0}
			await frames(1, command)
		var distance: float = world.player.position.x - start.x
		await frames(24)
		check(absf(world.player.velocity.x) < 0.01, "brake to rest %d" % sample_hz)
		await reset()
		var baseline: float = world.player.position.y
		await frames(1, {"jump": true, "jump_held": true})
		var top: float = world.player.position.y
		for i in 120:
			await frames(1, {"jump_held": true})
			top = minf(top, world.player.position.y)
		var high: float = baseline - top
		await reset()
		baseline = world.player.position.y
		await frames(1, {"jump": true, "jump_held": true})
		top = world.player.position.y
		for i in 120:
			await frames(1)
			top = minf(top, world.player.position.y)
		var low: float = baseline - top
		check(distance > 430 and distance < 480, "movement distance %d" % sample_hz)
		check(high > 190 and high < 220, "long jump 2-2.5H %d" % sample_hz)
		check(low > 20 and low < high * 0.6, "tap jump shorter %d" % sample_hz)
		motion_samples.append({"input_sample_hz": sample_hz, "distance_1s": distance, "long_jump": high, "short_jump": low})
	check(absf(motion_samples[0].distance_1s - motion_samples[2].distance_1s) < 1, "sampling movement invariant")
	await reset()
	# Walk off the right edge of a one-way platform, then use coyote time.
	world.player.position = Vector2(603, 439)
	world.player.velocity = Vector2.ZERO
	await frames(8)
	await frames(4, {"axis": 1.0})
	world.player.position.x = 635
	await frames(2, {"axis": 1.0})
	check(not world.player.is_on_floor(), "walked off platform")
	await frames(1, {"jump": true, "jump_held": true})
	check(world.player.velocity.y < -800, "coyote jump accepted")
	await reset()
	world.player.position = Vector2(500, 420)
	world.player.velocity = Vector2(0, 350)
	await frames(1, {"jump": true, "jump_held": true})
	await frames(9, {"jump_held": true})
	check(world.player.velocity.y < -500, "buffered jump fires on platform landing")
	await reset()
	world.player.position = Vector2(500, 439)
	world.player.velocity = Vector2.ZERO
	await frames(8)
	check(world.player.is_on_floor(), "standing on one-way platform")
	await frames(1, {"down": true, "jump": true})
	await frames(24)
	check(world.player.position.y > 480, "drop through one-way")
	check(world.player.get_collision_mask_value(1), "solid collisions remain enabled during drop")
	await reset()
	world.player.position.x = 1220
	await frames(1, {"dodge": true, "axis": 1.0})
	await frames(45, {"axis": 1.0})
	check(world.player.position.x < 1265, "dodge cannot pass solid wall")
	check(world.player.get_collision_mask_value(1), "dodge retains solid mask")
	await reset()
	world.player.position.x = 910
	await frames(70, {"axis": 1.0})
	check(world.player.position.x > 1070, "ramp and corner traversable")

func test_combat() -> void:
	await reset(1)
	var enemy = world.enemies[0]
	world.player.position.x = 610
	var hp: int = enemy.hp
	await frames(1, {"attack": true})
	await frames(6)
	check(enemy.hp == hp, "startup does not deal damage")
	await frames(10)
	check(enemy.hp == hp - 14, "active slash hits once")
	await frames(10)
	check(enemy.hp == hp - 14, "same attack instance cannot double-hit")
	# Remove displacement and increase target health for a full three-hit chain.
	enemy.hp = 300
	enemy.invulnerability = 0
	world.player.state = "idle"
	world.hitstop = 0
	world.player.start_attack(0)
	while world.player.timer < 0.22 and world.player.attack_index == 0:
		await frames(1)
	await frames(1, {"attack": true})
	await frames(16)
	check(world.player.attack_index == 1, "buffer chains first into second")
	while world.player.timer < 0.27 and world.player.attack_index == 1:
		await frames(1)
	await frames(1, {"attack": true})
	await frames(18)
	check(world.player.attack_index == 2, "buffer chains second into third")
	check(world.player.attack_instance >= 4, "every swing has unique instance")
	world.player.state = "idle"
	await frames(1, {"heavy": true})
	check(world.player.attack_index == 3, "heavy has independent action")
	world.player.state = "idle"
	await frames(1, {"jump": true, "jump_held": true})
	await frames(1, {"attack": true, "jump_held": true})
	check(world.player.attack_index == 4, "air attack has independent action")
	world.player.invulnerability = 0
	check(world.player.take_damage(5, -100), "damage interrupts aerial attack")
	check(world.player.state == "hurt", "hurt wins over attack")
	check(not world.player.take_damage(5, -100), "multiple sources obey hit immunity")
	await reset()
	await frames(1, {"dodge": true})
	await frames(8)
	check(not world.player.take_damage(10, 0), "dodge invulnerable segment")
	await frames(22)
	check(world.player.take_damage(10, 0), "dodge late recovery vulnerable")
	await reset()
	world.player.start_attack(0)
	await frames(20)
	await frames(1, {"dodge": true})
	check(world.player.state == "dodge", "attack recovery can cancel to dodge")
	await frames(40)
	await frames(1, {"dodge": true})
	check(world.player.state != "dodge", "dodge cooldown enforced")
	world.player.invulnerability = 0
	world.player.take_damage(999, 0)
	var instance: int = world.player.attack_instance
	await frames(2, {"attack": true})
	check(world.mode == "death" and world.player.attack_instance == instance, "death stops combat and opens settlement")

func test_enemy() -> void:
	await reset(2)
	var melee = world.enemies[0]
	var archer = world.enemies[1]
	world.player.position.x = melee.position.x - 60
	await frames(1)
	check(melee.state == "telegraph", "melee announces before attack")
	var hp: int = world.player.hp
	await frames(45)
	check(world.player.hp == hp, "telegraph cannot damage")
	await frames(35)
	check(world.player.hp < hp, "melee damage after telegraph")
	await reset(2)
	archer = world.enemies[1]
	world.player.position = Vector2(900, 560)
	await frames(1)
	check(archer.state == "aim", "archer announces aim")
	await frames(30)
	check(world.projectiles.is_empty(), "archer cannot fire without warning")
	await frames(40)
	check(not world.projectiles.is_empty() or world.player.hp < 100, "archer eventually fires")
	archer.hp = 0
	var shots: int = world.projectiles.size()
	await frames(20)
	check(archer.state == "death" and world.projectiles.size() <= shots, "dead archer cannot fire")

func test_pause() -> void:
	await reset(2)
	world.projectiles.append({"position": world.player.position + Vector2(-8, -50), "direction": 1.0, "age": 0.0})
	world.player.attack_buffer = 0.12
	world.show_menu("pause")
	var hp: int = world.player.hp
	var position: Vector2 = world.player.position
	var age: float = world.projectiles[0].age
	var timer: float = world.enemies[0].timer
	await frames(120, {"attack": true})
	check(world.player.hp == hp and world.player.position == position, "pause freezes player and damage")
	check(world.enemies[0].timer == timer and world.projectiles[0].age == age, "pause freezes AI and projectiles")
	check(world.player.attack_buffer == 0 and world.router.blocked, "pause clears buffer and arms input barrier")
	world.resume()
	# Dummy display does not preserve OS keyboard state for synthetic events.
	# Exercise the same snapshot router used by poll; real keyboard remains QA.
	var held := {"attack": true, "jump": false}
	check(world.router.route(held, 0, false, false).is_empty() and world.router.blocked, "held attack blocked on resume")
	world.router.route({"attack": false, "jump": false}, 0, false, true)
	check(not world.router.blocked, "release clears input barrier")
	check(world.router.route(held, 0, false, false).attack, "new attack after release accepted")
	check(not world.router.route(held, 0, false, false).attack, "holding attack does not repeat edge")
	world._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(world.mode == "pause", "focus loss pauses")

func test_flow() -> void:
	for i in 20:
		await reset(2)
		check(world.enemies.size() == 2 and world.player.hp == 100 and world.projectiles.is_empty(), "room restart clean %d" % i)
	# Integration flows exercise gate/scene/state cleanup; combat is tested above.
	# Target elimination below is a test fixture, not claimed human playthrough.
	for run_index in 10:
		world.start_run()
		await frames(4)
		check(not world.interact(), "gate needs proximity %d" % run_index)
		for index in 5:
			check(world.room == index, "ordered room %d/%d" % [run_index, index])
			world.player.position = Vector2(1190, 620)
			if index >= 2:
				check(not world.interact(), "living enemies lock gate")
			for enemy in world.enemies:
				enemy.hp = 0
			check(world.interact(), "clear room opens gate")
			await get_tree().physics_frame
		check(world.mode == "win", "final gate opens victory")
		world.show_menu("title")
		check(world.mode == "title", "victory returns title")

func test_preferences_and_pose() -> void:
	var Store = preload("res://game/settings_store.gd")
	var store := Store.new()
	store.path = "user://automated-tests/preferences-regression.cfg"
	store.volume = 0.6
	store.shake_enabled = false
	check(store.save_values() == OK, "settings first atomic save")
	var restored := Store.new()
	restored.path = store.path
	restored.load_values()
	check(is_equal_approx(restored.volume, 0.6) and not restored.shake_enabled, "settings survive a fresh store instance")
	store.volume = 0.2
	check(store.save_values() == OK, "settings replace existing file on Windows")
	restored.load_values()
	check(is_equal_approx(restored.volume, 0.2), "replacement settings loaded")
	var config := ConfigFile.new()
	config.set_value("meta", "schema", 1)
	config.set_value("audio", "volume", 999)
	config.set_value("display", "shake", "invalid")
	config.save(store.path)
	restored.load_values()
	check(restored.volume == 1 and restored.shake_enabled, "invalid preferences clamp or use defaults")
	config.set_value("meta", "schema", 999)
	config.save(store.path)
	restored.load_values()
	check(is_equal_approx(restored.volume, 0.35) and restored.shake_enabled, "unknown preference schema uses defaults")
	check(world.UI_FONT.has_char("烬".unicode_at(0)) and world.UI_FONT.has_char("暂".unicode_at(0)), "bundled font supports Chinese UI")
	await reset()
	world.player.position.y = 610
	world.player.velocity.y = 300
	await frames(6)
	check(world.player.visual.pose_override == "land" and world.player.visual.override_remaining > 0, "physics retains landing pose across render gaps")
	var clock: float = world.player.visual.clock
	world.show_menu("pause")
	await frames(30)
	check(world.player.visual.clock == clock, "pause freezes pose clock")

func test_combat_flows() -> void:
	for run_index in 10:
		world.start_run()
		var iterations := 0
		while world.mode == "play" and iterations < 12000:
			iterations += 1
			var command := {}
			var target: Node2D
			var distance := INF
			for enemy in world.enemies:
				if enemy.hp > 0 and not enemy.training:
					var delta: float = absf(enemy.position.x - world.player.position.x)
					if delta < distance:
						distance = delta
						target = enemy
			if target:
				var direction := signf(target.position.x - world.player.position.x)
				if distance > 110:
					command.axis = direction
				else:
					world.player.facing = direction
					if world.player.state != "attack":
						command.heavy = true
			else:
				command.axis = 1.0
				command.interact = true
			await frames(1, command)
		check(world.mode == "win", "real combat flow wins %d (mode=%s room=%d hp=%d ticks=%d)" % [run_index, world.mode, world.room, world.player.hp, iterations])
		if world.mode == "win":
			combat_runs += 1
		world.show_menu("title")
