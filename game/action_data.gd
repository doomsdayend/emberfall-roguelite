extends RefCounted
## H = 96. All durations in seconds; shared by gameplay, poses and tests.
const H := 96.0
const SPEED := 480.0
const ACCEL := 3200.0
const BRAKE := 4000.0
const GRAVITY := 2200.0
const JUMP := -960.0
const COYOTE := 0.10
const BUFFER := 0.12
const DODGE_DURATION := 0.34
const DODGE_COOLDOWN := 0.72
const ATTACKS := [
	{"name": "slash_1", "startup": 0.07, "active": 0.06, "total": 0.30, "damage": 14, "reach": 92.0, "knock": 210.0, "stop": 0.035},
	{"name": "slash_2", "startup": 0.09, "active": 0.08, "total": 0.36, "damage": 18, "reach": 105.0, "knock": 260.0, "stop": 0.04},
	{"name": "slash_3", "startup": 0.13, "active": 0.09, "total": 0.48, "damage": 28, "reach": 122.0, "knock": 360.0, "stop": 0.07},
	{"name": "heavy", "startup": 0.25, "active": 0.12, "total": 0.70, "damage": 40, "reach": 135.0, "knock": 420.0, "stop": 0.08},
	{"name": "air", "startup": 0.08, "active": 0.10, "total": 0.36, "damage": 18, "reach": 95.0, "knock": 200.0, "stop": 0.04},
]
