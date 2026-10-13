"""Deterministic, editable cuts from the generated parts sheet; candidate art only."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/stage03-emberblade-parts-v01.png"
# Reviewed pixel rectangles on the actual 1243x1266 source, not an assumed grid.
# Canonical texture sizes contain overlap; runtime segment lengths remain fixed.
PARTS = [
    ("head", [16, 15, 239, 245], [23, 22.4], [0.50, 1.0]),
    ("neck", [330, 88, 429, 197], [9, 10], [0.50, 0.5]),
    ("torso", [505, 23, 718, 254], [32, 32], [0.50, 0.1]),
    ("pelvis", [755, 59, 970, 253], [29, 18], [0.50, 0.4]),
    ("cape", [993, 9, 1243, 268], [34, 39], [0.83, 0.08]),
    ("upper_arm_back", [57, 260, 184, 494], [11, 23], [0.50, 0.15]),
    ("forearm_back", [321, 271, 423, 496], [10, 22], [0.50, 0.12]),
    ("hand_back", [573, 293, 656, 483], [7, 11], [0.50, 0.15]),
    ("upper_arm_front", [805, 263, 916, 493], [12, 23], [0.50, 0.15]),
    ("forearm_front", [1055, 263, 1157, 496], [11, 22], [0.50, 0.12]),
    ("hand_front", [63, 527, 180, 720], [8, 11], [0.50, 0.15]),
    ("thigh_back", [309, 496, 437, 742], [14, 29], [0.50, 0.13]),
    ("shin_back", [558, 496, 667, 742], [12, 29], [0.50, 0.12]),
    ("foot_back", [773, 548, 968, 734], [20, 15], [0.32, 0.35]),
    ("thigh_front", [1040, 498, 1173, 742], [15, 29], [0.50, 0.13]),
    ("shin_front", [60, 733, 177, 976], [13, 29], [0.50, 0.12]),
    ("foot_front", [284, 777, 472, 970], [21, 15], [0.32, 0.35]),
    ("hair_front", [505, 764, 720, 979], [22, 21], [0.50, 0.4]),
    ("hair_back", [752, 762, 971, 981], [22, 21], [0.50, 0.4]),
    ("hem", [1015, 778, 1194, 953], [27, 20], [0.50, 0.0]),
    ("weapon", [64, 984, 192, 1256], [21, 77], [0.50, 0.84]),
]

def build():
    image = Image.open(SOURCE).convert("RGBA")
    assert image.size == (1243, 1266), "Source changed; review cut rectangles again"
    destination = ROOT / "assets/exported/emberblade-v01"
    destination.mkdir(parents=True, exist_ok=True)
    records = []
    atlas = Image.new("RGBA", (640, 768), (0, 0, 0, 0))
    # A separate editable PNG per layer; atlas is for preview/review only.
    for index, (name, rectangle, size, pivot) in enumerate(PARTS):
        cut = image.crop(rectangle)
        alpha = cut.getchannel("A")
        assert alpha.getbbox() is not None, name
        cut.save(destination / (name + ".png"))
        preview = cut.copy()
        preview.thumbnail((116, 116), Image.Resampling.LANCZOS)
        atlas.alpha_composite(preview, (index % 5 * 128 + 6, index // 5 * 128 + 6))
        records.append({"id": name, "source_rect": rectangle, "size": size, "pivot": pivot,
                        "texture": "res://assets/exported/emberblade-v01/" + name + ".png",
                        "sha256": hashlib.sha256((destination / (name + ".png")).read_bytes()).hexdigest()})
    atlas.save(destination / "parts-review.png")
    specification = {"schema": 1, "status": "rig_preview_candidate", "source": SOURCE.name,
                     "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                     "scale_policy": "fixed anatomical lengths; no animated stretching",
                     "parts": records}
    (ROOT / "assets/source/emberblade-skin-v01.json").write_text(json.dumps(specification, indent=2) + "\n", encoding="utf-8")
    print("SKIN_BUILD_RESULT=" + json.dumps({"passed": True, "parts": len(records), "final_art": False}))

if __name__ == "__main__":
    build()
