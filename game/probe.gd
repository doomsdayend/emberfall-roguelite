extends Node2D
## Minimal resource/import/export probe, deliberately no game loop or player art.

var failures: Array[String] = []

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
	var result := {
		"probe": "windows-preproduction-1",
		"engine": Engine.get_version_info().string,
		"display": DisplayServer.get_name(),
		"os": OS.get_name(),
		"passed": failures.is_empty(),
		"failures": failures,
		"visual_quality_tested": false,
		"playable": false,
	}
	print("PROBE_RESULT=" + JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)
