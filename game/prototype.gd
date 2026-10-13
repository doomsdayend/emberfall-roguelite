extends Node2D
const Fighter = preload("res://game/fighter.gd")
const Enemy = preload("res://game/enemy.gd")
const Router = preload("res://game/input_router.gd")
const ROOMS := ["避难所", "训练场", "铸坊一层", "铸坊二层", "守门者"]
const UI_FONT = preload("res://assets/fonts/NotoSansSC.ttf")
const Settings = preload("res://game/settings_store.gd")
var mode := "title"
var room := 0
var player: CharacterBody2D
var enemies: Array = []
var projectiles: Array = []
var sparks: Array = []
var geometry: Node2D
var actors: Node2D
var router := Router.new()
var ui: CanvasLayer
var hud: Label
var panel: VBoxContainer
var hitstop := 0.0
var shake := 0.0
var shake_enabled := true
var volume := 0.35
var debug_view := false
var event_log: Array[String] = []
var tone: AudioStreamPlayer
var clock := 0.0
var physics_steps := 0
var completed_runs := 0
var test_mode := false
var pending_command: Dictionary = {}
var settings := Settings.new()
var settings_status := ""
var art_slice_preview := false

func _ready() -> void:
	test_mode = "--prototype-test" in OS.get_cmdline_user_args()
	art_slice_preview = "--art-slice-preview" in OS.get_cmdline_user_args()
	if test_mode or "--gpu-test" in OS.get_cmdline_user_args():
		settings.path = "user://automated-tests/test-preferences.cfg"
	settings.load_values()
	volume = settings.volume
	shake_enabled = settings.shake_enabled
	if art_slice_preview:
		var background := Sprite2D.new()
		background.texture = preload("res://assets/exported/foundry-backdrop-v01.png")
		background.position = Vector2(640, 360)
		background.scale = Vector2(1280.0 / background.texture.get_width(), 720.0 / background.texture.get_height())
		background.modulate = Color(0.72, 0.72, 0.72, 1.0)
		background.z_index = -10
		add_child(background)
	geometry = Node2D.new()
	add_child(geometry)
	actors = Node2D.new()
	add_child(actors)
	build_ui()
	tone = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.12
	tone.stream = generator
	add_child(tone)
	show_menu("title")
	if test_mode:
		call_deferred("run_tests")

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	if art_slice_preview:
		var hud_backing := ColorRect.new()
		hud_backing.position = Vector2(20, 15)
		hud_backing.size = Vector2(900, 112)
		hud_backing.color = Color(0.06, 0.08, 0.11, 0.84)
		hud_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(hud_backing)
	hud = Label.new()
	hud.position = Vector2(32, 22)
	hud.add_theme_font_size_override("font_size", 21)
	hud.add_theme_font_override("font", UI_FONT)
	ui.add_child(hud)
	panel = VBoxContainer.new()
	panel.position = Vector2(420, 170)
	panel.custom_minimum_size = Vector2(440, 380)
	panel.add_theme_constant_override("separation", 16)
	var theme := Theme.new()
	theme.default_font = UI_FONT
	panel.theme = theme
	ui.add_child(panel)

func button(text: String, callback: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(440, 44)
	item.pressed.connect(callback)
	panel.add_child(item)

func show_menu(next: String) -> void:
	mode = next
	if next == "win" and is_instance_valid(player):
		player.visual.set_pose("victory", 1000)
	actors.visible = next not in ["title", "settings"]
	pending_command.clear()
	get_viewport().canvas_transform = Transform2D.IDENTITY
	router.barrier()
	if is_instance_valid(player):
		player.clear_buffers()
		player.frozen = true
	for enemy in enemies:
		enemy.frozen = true
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	panel.show()
	var title := Label.new()
	title.text = "余烬之路  /  0.1.0-dev.2\n" + {"title": "固定房间动作原型", "pause": "已暂停", "settings": "设置", "win": "守门者已被击败", "death": "余烬熄灭"}.get(next, next)
	title.add_theme_font_size_override("font_size", 27)
	panel.add_child(title)
	if next == "title":
		button("从避难所出发", start_run)
		button("设置", func(): show_menu("settings"))
		button("退出游戏", func(): get_tree().quit())
	elif next == "settings":
		button("屏幕震动：" + ("开" if shake_enabled else "关"), func(): shake_enabled = not shake_enabled; save_settings(); show_menu("settings"))
		var slider := HSlider.new()
		var volume_label := Label.new()
		volume_label.text = "命中音效音量"
		panel.add_child(volume_label)
		slider.max_value = 1
		slider.step = 0.05
		slider.value = volume
		var status := Label.new()
		slider.value_changed.connect(func(value): volume = value; save_settings(); status.text = settings_status)
		panel.add_child(slider)
		button("返回标题", func(): show_menu("title"))
		status.text = settings_status
		panel.add_child(status)
	elif next == "pause":
		button("继续游戏", resume)
		button("重新开始本房间", func(): load_room(room, 100); resume())
		button("返回标题", func(): show_menu("title"))
	else:
		button("再次出发", start_run)
		button("返回标题", func(): show_menu("title"))
	update_hud()

func start_run() -> void:
	load_room(0, 100)
	resume()

func resume() -> void:
	mode = "play"
	actors.show()
	panel.hide()
	router.barrier()
	if is_instance_valid(player):
		player.frozen = false
	for enemy in enemies:
		enemy.frozen = false

func load_room(index: int, health: int = 100) -> void:
	room = index
	pending_command.clear()
	for parent in [geometry, actors]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()
	enemies.clear()
	projectiles.clear()
	sparks.clear()
	hitstop = 0
	shake = 0
	add_platform(Rect2(-100, 620, 1480, 100))
	add_platform(Rect2(-40, -200, 40, 920))
	add_platform(Rect2(1280, -200, 40, 920))
	add_platform(Rect2(380, 440, 230, 18), true)
	add_platform(Rect2(710, 340, 190, 18), true)
	# Traversable ramp and a corner exercise ordinary solid collisions.
	var ramp := StaticBody2D.new()
	ramp.collision_layer = 1
	var poly := CollisionPolygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(930, 620), Vector2(1080, 565), Vector2(1080, 620)])
	ramp.add_child(poly)
	geometry.add_child(ramp)
	player = Fighter.new()
	player.position = Vector2(130, 615)
	actors.add_child(player)
	player.hp = health
	player.debug_view = debug_view
	player.hit_landed.connect(on_hit)
	player.action_event.connect(on_action)
	if room == 1:
		spawn_enemy("pursuer", Vector2(680, 615), false, true)
	elif room == 2:
		spawn_enemy("pursuer", Vector2(700, 615))
		spawn_enemy("archer", Vector2(1060, 560))
	elif room == 3:
		spawn_enemy("archer", Vector2(720, 615))
		spawn_enemy("pursuer", Vector2(1020, 580))
	elif room == 4:
		spawn_enemy("pursuer", Vector2(820, 615), true)
	router.barrier()
	queue_redraw()
	update_hud()

func add_platform(rect: Rect2, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2 if one_way else 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.get_center()
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 8
	body.add_child(collision)
	geometry.add_child(body)

func spawn_enemy(kind: String, point: Vector2, elite: bool = false, training: bool = false) -> void:
	var enemy := Enemy.new()
	enemy.kind = kind
	enemy.elite = elite
	enemy.training = training
	enemy.position = point
	actors.add_child(enemy)
	enemy.fired.connect(func(origin, direction): projectiles.append({"position": origin, "direction": direction, "age": 0.0}))
	enemies.append(enemy)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if mode == "play":
				show_menu("pause")
			elif mode == "pause":
				resume()
		elif event.keycode == KEY_F3 and is_instance_valid(player):
			debug_view = not debug_view
			player.debug_view = debug_view

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "play":
		show_menu("pause")

func _physics_process(dt: float) -> void:
	if test_mode:
		return
	tick(dt, router.poll() if mode == "play" else {})

func tick(dt: float, command: Dictionary) -> void:
	if mode != "play":
		return
	physics_steps += 1
	clock += dt
	if hitstop > 0:
		for action in ["attack", "heavy", "jump", "dodge"]:
			if command.get(action, false):
				pending_command[action] = true
		player.frozen = true
		for enemy in enemies:
			enemy.frozen = true
		hitstop = maxf(0, hitstop - dt)
		return
	command = command.duplicate()
	for action in pending_command:
		command[action] = true
	pending_command.clear()
	player.frozen = false
	for enemy in enemies:
		enemy.frozen = false
	player.tick(dt, command, enemies)
	for enemy in enemies:
		enemy.tick(dt, player)
	for i in range(projectiles.size() - 1, -1, -1):
		var shot: Dictionary = projectiles[i]
		var origin: Vector2 = shot.position
		shot.position += Vector2(shot.direction * 360 * dt, 0)
		shot.age += dt
		var query := PhysicsRayQueryParameters2D.create(origin, shot.position, 3)
		var blocked := not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
		var crossed := Rect2(Vector2(minf(origin.x, shot.position.x) - 4, origin.y - 4), Vector2(absf(shot.position.x - origin.x) + 8, 8))
		if blocked or shot.age > 4 or crossed.intersects(player.hurt_rect()):
			if not blocked and crossed.intersects(player.hurt_rect()):
				player.take_damage(9, shot.direction * 170)
			projectiles.remove_at(i)
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].life -= dt
		sparks[i].point += sparks[i].velocity * dt
		if sparks[i].life <= 0:
			sparks.remove_at(i)
	shake = maxf(0, shake - dt)
	# Camera feedback never changes physics or world-space hitboxes.
	get_viewport().canvas_transform.origin = Vector2(sin(clock * 170) * 3, cos(clock * 130) * 2) if shake_enabled and shake > 0 else Vector2.ZERO
	if player.hp <= 0:
		show_menu("death")
	elif command.get("interact", false):
		interact()
	update_hud()
	queue_redraw()

func room_clear() -> bool:
	for enemy in enemies:
		if enemy.hp > 0 and not enemy.training:
			return false
	return true

func interact() -> bool:
	if mode == "play" and room == 1:
		for enemy in enemies:
			if enemy.training and player.position.distance_to(enemy.position) < 100:
				enemy.hp = 45
				enemy.state = "idle"
				player.visual.set_pose("interact", 0.25)
				on_action("interact", player.attack_instance)
	if mode != "play" or player.position.distance_to(Vector2(1190, 620)) > 100 or not room_clear():
		return false
	if room == 4:
		completed_runs += 1
		show_menu("win")
	else:
		load_room(room + 1, player.hp)
	return true

func on_action(event: String, instance: int) -> void:
	event_log.append("%s:%d" % [event, instance])
	if event_log.size() > 16:
		event_log.pop_front()

func on_hit(target: Node2D, heavy: bool) -> void:
	hitstop = maxf(hitstop, 0.07 if heavy else 0.035)
	shake = 0.12 if heavy else 0.06
	for i in 7:
		sparks.append({"point": target.global_position + Vector2(0, -60), "velocity": Vector2.from_angle(float(i) * TAU / 7) * 100, "life": 0.22})
	play_tone(130 if heavy else 350)

func play_tone(frequency: float) -> void:
	if test_mode or DisplayServer.get_name() == "headless":
		return
	tone.play()
	var playback := tone.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		for i in mini(playback.get_frames_available(), 2205):
			var sample := sin(float(i) / 22050 * frequency * TAU) * volume * (1.0 - float(i) / 2205) * 0.3
			playback.push_frame(Vector2(sample, sample))

func update_hud() -> void:
	hud.text = "余烬之路 · 固定房间开发原型 0.1.0-dev.2"
	if is_instance_valid(player) and mode not in ["title", "settings"]:
		hud.text += "\n%s  |  生命 %d  |  闪避冷却 %.2f 秒\nA/D 移动 · 空格 跳跃 · S+空格 下穿 · J 普攻 · K 重击 · Shift 闪避 · E 交互 · Esc 暂停" % [ROOMS[room], player.hp, player.dodge_cooldown]
		if debug_view:
			hud.text += "\n%s  t=%.3f  instance=%d\n%s" % [player.state, player.timer, player.attack_instance, str(event_log)]

func _draw() -> void:
	if not art_slice_preview:
		draw_rect(Rect2(0, 0, 1280, 720), Color("171c26"))
		for i in 10:
			draw_rect(Rect2(i * 150 - 20, 100 + (i % 3) * 30, 34, 520), Color("222a35"))
	draw_rect(Rect2(0, 620, 1280, 100), Color("3f4249"))
	draw_line(Vector2(0, 620), Vector2(1280, 620), Color("b8a788"), 3)
	for rect in [Rect2(380, 440, 230, 18), Rect2(710, 340, 190, 18)]:
		draw_rect(rect, Color("71695c"))
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("d9cfb9"), 3)
	draw_colored_polygon(PackedVector2Array([Vector2(930, 620), Vector2(1080, 565), Vector2(1080, 620)]), Color("545557"))
	if is_instance_valid(player) and mode not in ["title", "settings"]:
		var unlocked := room_clear()
		draw_arc(Vector2(1190, 566), 47, -PI, PI, 32, Color("e3b76b") if unlocked else Color("725848"), 5)
		draw_string(UI_FONT, Vector2(1125, 508), "E：前往出口" if unlocked else "击败所有敌人", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e5d9c5"))
	for shot in projectiles:
		draw_line(shot.position, shot.position + Vector2(-shot.direction * 18, 0), Color("ffae71"), 4)
	for spark in sparks:
		draw_circle(spark.point, 2, Color("ffe2a0"))
	if mode != "play":
		draw_rect(Rect2(395, 145, 490, 430), Color("171c26"))

func run_tests() -> void:
	var suite := preload("res://tests/prototype_suite.gd").new()
	add_child(suite)
	await suite.run(self)

func save_settings() -> void:
	settings.volume = volume
	settings.shake_enabled = shake_enabled
	settings_status = "设置已保存" if settings.save_values() == OK else "设置保存失败，请检查目录权限"
