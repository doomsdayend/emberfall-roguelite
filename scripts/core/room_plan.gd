class_name RoomPlan
extends RefCounted

const COMBAT_TEMPLATES := ["ruined_gate", "ash_gallery", "broken_bridge"]

# Planning interface only: actual room instantiation arrives in stage 5.
static func generate(seed_value: int, combat_count: int = 3) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rooms: Array[Dictionary] = [{"kind": "safe", "template": "camp", "seed": seed_value}]
	for index in range(clampi(combat_count, 1, 12)):
		rooms.append({
			"kind": "combat",
			"template": COMBAT_TEMPLATES[rng.randi_range(0, COMBAT_TEMPLATES.size() - 1)],
			"seed": rng.randi(),
		})
	rooms.append({"kind": "boss", "template": "warden", "seed": rng.randi()})
	return rooms
