from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
names = ["refuge", "windup", "active", "recovery", "dodge", "victory"]
sheet = Image.new("RGB", (1920, 2 * 380), "#171c26")
draw = ImageDraw.Draw(sheet)
for index, name in enumerate(names):
    image = Image.open(root / "artifacts/gpu" / (name + ".png")).convert("RGB")
    assert image.size == (1280, 720)
    x, y = index % 3 * 640, index // 3 * 380
    draw.text((x + 10, y + 4), name.upper() + " | skin preview / Intel Graphics / OpenGL", fill="#e9dcc4")
    sheet.paste(image.resize((640, 360)), (x, y + 20))
out = root / "docs/testing/evidence/stage03-art-slice-gpu-contact.png"
sheet.save(out)
print(out)
