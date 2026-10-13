"""Build a review board for stage 3 reference assets; this is not a runtime asset."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
out = root / "docs/testing/evidence/stage03-reference-review.png"
items = [
    ("EMBERBLADE / reference", root / "assets/source/stage03-emberblade-sheet-v01.png"),
    ("FOUNDRY TRAINING / reference", root / "assets/source/stage03-training-ground-v01.png"),
    ("PURSUER / reference", root / "assets/source/stage03-pursuer-sheet-v01.png"),
]
thumb_w, thumb_h = 768, 432
board = Image.new("RGB", (thumb_w * 2, thumb_h * 2 + 44), "#171c26")
draw = ImageDraw.Draw(board)
font = ImageFont.load_default()
for index, (label, path) in enumerate(items):
    image = Image.open(path).convert("RGB")
    image.thumbnail((thumb_w, thumb_h - 24), Image.Resampling.LANCZOS)
    cell_x = (index % 2) * thumb_w
    cell_y = (index // 2) * thumb_h + 24
    draw.text((cell_x + 12, cell_y - 18), label, fill="#e9dcc4", font=font)
    x = cell_x + (thumb_w - image.width) // 2
    y = cell_y + (thumb_h - 24 - image.height) // 2
    board.paste(image, (x, y))
    if "FOUNDRY" in label:
        scale_x = image.width / 1672.0
        scale_y = image.height / 941.0
        safe = (x, y + int(420 * scale_y), x + int(1280 * scale_x), y + int(720 * scale_y))
        draw.rectangle(safe, outline="#eaa45b", width=3)
        draw.text((safe[0] + 8, safe[1] + 8), "gameplay safe rect 1280x300", fill="#eaa45b", font=font)
draw.text((12, board.height - 18), "Stage 03 reference review | generated references only | pending layering, license review, runtime integration", fill="#e9dcc4", font=font)
board.save(out)
print(out)
