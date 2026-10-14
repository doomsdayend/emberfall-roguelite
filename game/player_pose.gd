extends RefCounted
## Visual keys only; damage windows remain owned by action_data/fighter.
const Data = preload("res://game/action_data.gd")

static func sample(state: String, clock: float, timer: float, index: int) -> Dictionary:
	var breath := sin(clock * 2.6)
	var pose := {"torso": Vector2(1, -76), "pelvis": Vector2(0, -56),
		"front_foot": Vector2(10, -9.5), "rear_foot": Vector2(-9, -9.5),
		"hand": Vector2(23, -53), "offhand": Vector2(-15, -53), "blade": 0.65}
	if state == "idle":
		pose.torso.y += breath * 0.65
		pose.hand.y += breath * 0.4
		pose.offhand.y += breath * 0.4
	elif state == "run":
		var stride := sin(clock * 15)
		pose.pelvis = Vector2(1, -51 + absf(stride) * 1.4)
		pose.torso = Vector2(8, -74 + absf(stride) * 1.4)
		pose.front_foot = Vector2(8 + stride * 19, -9.5 - maxf(0, -stride) * 19)
		pose.rear_foot = Vector2(-8 - stride * 19, -9.5 - maxf(0, stride) * 19)
		pose.hand = Vector2(20 - stride * 9, -52 - maxf(0, stride) * 5)
		pose.offhand = Vector2(-12 + stride * 11, -55)
		pose.blade = 0.65 + stride * 0.18
	elif state == "attack":
		var spec: Dictionary = Data.ATTACKS[clampi(index, 0, 4)]
		# Separate wind-up, active sweep, follow-through and return for every attack.
		var keys: Array = [
			[Vector2(0, -90), Vector2(36, -67), -2.1, 0.15, -5.0, 9.0],
			[Vector2(14, -43), Vector2(29, -85), 1.5, -0.8, 4.0, 11.0],
			[Vector2(-7, -91), Vector2(40, -61), -2.6, 0.7, -9.0, 15.0],
			[Vector2(7, -103), Vector2(35, -52), -2.5, 1.1, -6.0, 13.0],
			[Vector2(14, -93), Vector2(38, -66), -1.9, 0.6, -3.0, 9.0]
		][clampi(index, 0, 4)]
		var wind := smoothstep(0.0, 1.0, clampf(timer / spec.startup, 0, 1))
		var swing := smoothstep(0.0, 1.0, clampf((timer - spec.startup) / spec.active, 0, 1))
		var recovery := smoothstep(0.0, 1.0, clampf((timer - spec.startup - spec.active - 0.035) / maxf(0.01, spec.total - spec.startup - spec.active - 0.035), 0, 1))
		var ready: Vector2 = pose.hand.lerp(keys[0], wind)
		pose.hand = ready.lerp(keys[1], swing).lerp(pose.hand, recovery)
		pose.blade = lerpf(lerpf(lerpf(pose.blade, keys[2], wind), keys[3], swing), pose.blade, recovery)
		var drive := lerpf(keys[4] * wind, keys[5], swing) * (1.0 - recovery)
		pose.pelvis = Vector2(drive * 0.25, -56 + absf(drive) * 0.22)
		pose.torso = Vector2(drive, -76 + absf(drive) * 0.18)
		pose.offhand = Vector2(-15 - drive * 0.45, -55 - swing * 5).lerp(Vector2(-15, -53), recovery)
		pose.front_foot.x = lerpf(10, 22, wind) * (1.0 - recovery) + 10 * recovery
		pose.rear_foot.x = lerpf(-9, -18, wind) * (1.0 - recovery) - 9 * recovery
		if index == 4:
			pose.front_foot.y -= 15
			pose.rear_foot.y -= 23
	return pose
