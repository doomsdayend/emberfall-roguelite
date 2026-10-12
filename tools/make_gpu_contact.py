"""Contact sheet of real GPU captures; never substitutes for full-size review."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
names = ["title", "settings", "refuge", "birth", "start", "stop", "turn", "land", "interact", "windup", "active", "recovery", "dodge", "pause", "death", "victory"]
sheet = Image.new("RGB", (1920, ((len(names) + 2) // 3) * 380), "#171c26")
draw = ImageDraw.Draw(sheet)
for index, name in enumerate(names):
    x, y = index % 3 * 640, index // 3 * 380
    frame = Image.open(root / "artifacts/gpu" / (name + ".png")).convert("RGB")
    assert frame.size == (1280, 720)
    sheet.paste(frame.resize((640, 360)), (x, y + 20))
    draw.text((x + 10, y + 4), name.upper() + " | Intel Graphics / OpenGL / 1280x720 source", fill="#e9dcc4")
out = root / "docs/testing/evidence/stage02-gpu-contact.png"
sheet.save(out)
print(out)
