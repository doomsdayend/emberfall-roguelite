from pathlib import Path
import hashlib
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / "assets/source/stage03-slice-contract.json").read_text(encoding="utf-8"))
rig = json.loads((root / "assets/source/emberblade-rig-spec.json").read_text(encoding="utf-8"))
assert contract["stage"] == "03-art-slice"
character = contract["character"]
assert character["expected_visual_height"] == rig["visual_height"]
assert character["expected_head_height"] == rig["head_height"]
assert character["expected_collision"]["width"] == rig["collision_width"]
assert character["expected_collision"]["height"] == rig["collision_height"]
assert character["required_layers"] == rig["layers"]
assert character["required_attachments"] == [item["id"] for item in rig["attachments"]]
parts_path = root / "assets/source" / character["parts_sheet"]["reference"]
with Image.open(parts_path) as parts_image:
    assert parts_image.mode == "RGBA"
    assert parts_image.getchannel("A").getbbox() is not None
assert character["parts_sheet"]["grid"] == [5, 5]
skin = json.loads((root / "assets/source" / character["skin_manifest"]["reference"]).read_text(encoding="utf-8"))
assert skin["status"] == "rig_preview_candidate"
assert len(skin["parts"]) == character["skin_manifest"]["parts"] == len(character["required_layers"])
for part in skin["parts"]:
    texture = root / part["texture"].replace("res://", "")
    assert texture.exists(), texture
    assert hashlib.sha256(texture.read_bytes()).hexdigest() == part["sha256"]
for entry in (character, contract["environment"], contract["enemy"]):
    path = root / "assets/source" / entry["reference"]
    assert path.exists(), path
    with Image.open(path) as image:
        assert image.width >= 1280 and image.height >= 720
    assert hashlib.sha256(path.read_bytes()).hexdigest()
assert contract["final_gate"] == {"layered_source": False, "license_reviewed": False, "runtime_integrated": False}
print("ART_SLICE_CONTRACT_RESULT=" + json.dumps({"passed": True, "bones": len(rig["bones"]), "layers": len(character["required_layers"]), "attachments": len(character["required_attachments"]), "parts_grid": character["parts_sheet"]["grid"], "enemy_states": len(contract["enemy"]["required_states"]), "final_gate": contract["final_gate"]}))
