extends Node2D
## Minimal resource/import/export probe, deliberately no game loop or player art.

var failures: Array[String] = []
const Rig = preload("res://game/character_rig.gd")
var method_events := 0

func on_rig_event() -> void:
	method_events += 1

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _ready() -> void:
	# Never open a game accidentally. Non-test launch also exits immediately.
	if not "--probe" in OS.get_cmdline_user_args():
		print("Preproduction technical probe; no playable game yet. Use --headless -- --probe.")
		get_tree().quit()
		return
	call_deferred("run_probe")

func run_probe() -> void:
	check(DisplayServer.get_name() == "headless", "probe requires headless display")
	var texture := load("res://assets/source/import_probe.svg") as Texture2D
	check(texture != null, "SVG imported as Texture2D")
	if texture:
		check(texture.get_size() == Vector2(64, 64), "imported dimensions 64x64")
		var sprite := Sprite2D.new()
		sprite.texture = texture
		add_child(sprite)
		# Exercise engine animation tracks with fixed time steps, without a renderer.
		var animation := Animation.new()
		animation.length = 0.3
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(".:position:x"))
		animation.track_insert_key(track, 0.0, 0.0)
		animation.track_insert_key(track, 0.3, 30.0)
		var library := AnimationLibrary.new()
		library.add_animation("probe", animation)
		var player := AnimationPlayer.new()
		sprite.add_child(player)
		player.add_animation_library("", library)
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.play("probe")
		player.advance(0.15)
		check(is_equal_approx(sprite.position.x, 15.0), "animation midpoint")
		player.advance(0.15)
		check(is_equal_approx(sprite.position.x, 30.0), "animation endpoint")
	check_rig()
	var result := {
		"probe": "windows-preproduction-2",
		"engine": Engine.get_version_info().string,
		"display": DisplayServer.get_name(),
		"os": OS.get_name(),
		"passed": failures.is_empty(),
		"failures": failures,
		"visual_quality_tested": false,
		"playable": false,
		"rig_transition_cycles": 100,
		"method_events": method_events,
	}
	print("PROBE_RESULT=" + JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)

func check_rig() -> void:
	var rig := Rig.new()
	rig.name = "Rig"
	add_child(rig)
	rig.build()
	check(rig.bones.size() == 16, "16 independent limb bones")
	check(rig.attachments.size() == 8, "8 attachment points")
	check(is_equal_approx(rig.specification.visual_height / rig.specification.head_height, 5.0), "five-head rig contract")
	check(rig.attachments.feet.global_position.is_equal_approx(Vector2.ZERO), "feet at origin")
	check(is_equal_approx(rig.bones.head.global_position.y - rig.specification.head_height, -112.0), "head crown at 112")
	var arm: Bone2D = rig.bones.arm_front
	var hand: Marker2D = rig.attachments.hand_main
	var rest_distance := arm.global_position.distance_to(hand.global_position)
	var animation := Animation.new()
	animation.length = 0.3
	var rotation_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_track, NodePath("Rig/pelvis/torso/arm_front:rotation"))
	animation.track_insert_key(rotation_track, 0.0, 0.0)
	animation.track_insert_key(rotation_track, 0.15, -0.8)
	animation.track_insert_key(rotation_track, 0.3, 0.0)
	var event_track := animation.add_track(Animation.TYPE_METHOD)
	animation.track_set_path(event_track, NodePath("."))
	animation.track_insert_key(event_track, 0.1, {"method": "on_rig_event", "args": []})
	var library := AnimationLibrary.new()
	library.add_animation("swing_probe", animation)
	var player := AnimationPlayer.new()
	add_child(player)
	player.add_animation_library("", library)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	for cycle in 100:
		rig.reset_pose()
		player.stop()
		player.play("swing_probe")
		player.advance(0.15)
		check(is_equal_approx(arm.rotation, -0.8), "bone rotation midpoint %d" % cycle)
		check(is_equal_approx(arm.global_position.distance_to(hand.global_position), rest_distance), "hand keeps arm length %d" % cycle)
		var before_pause := method_events
		player.advance(0.0)
		check(method_events == before_pause, "zero time does not re-fire event %d" % cycle)
		player.advance(0.15)
		check(is_zero_approx(arm.rotation), "bone recovery %d" % cycle)
		for bone: Bone2D in rig.bones.values():
			check(bone.scale.is_equal_approx(Vector2.ONE), "no bone stretch %d" % cycle)
	check(method_events == 100, "one event for each of 100 transitions")
