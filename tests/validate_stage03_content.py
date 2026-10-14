from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
data = json.loads((root / "assets/source/stage03-content-catalog.json").read_text(encoding="utf-8"))
assert data["stage"] == "03-art-slice"
assert data["area"]["room_count"] == 8
assert len(data["enemies"]) == 3
assert {e["role"] for e in data["enemies"]} == {"melee", "projectile", "displacement"}
assert data["elite"]["unique_behavior"]
assert data["boss"]["phases"] == 2
assert len(data["boss"]["attacks"]) >= 3
for attack in data["boss"]["attacks"]:
    assert attack["telegraph_ms"] > 0 and attack["active_ms"] > 0 and attack["recovery_ms"] > 0
    assert attack["counter"]
assert len(data["boss"]["phase_two_changes"]) >= 2
assert len(data["rooms"]) == 8
assert data["rooms"][0]["kind"] == "safe"
assert data["rooms"][-1]["kind"] == "boss"
assert len(data["boons"]) >= 4
assert len({b["route"] for b in data["boons"]}) >= 3
print("STAGE03_CONTENT_RESULT={\"passed\":true,\"rooms\":8,\"enemy_roles\":3,\"boss_attacks\":3,\"boss_phases\":2,\"boons\":4}")
