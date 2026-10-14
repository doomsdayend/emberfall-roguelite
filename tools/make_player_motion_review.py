"""GPU crops at 1.5x for joint review, plus a sampled attack GIF at slow speed."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
source = root / "artifacts/gpu-art-slice"
out = root / "docs/testing/evidence"
names = ["idle_corrected", "idle_corrected_left"]
names += [f"action_{action}_{frame}" for action in range(5) for frame in range(6)]
sheet = Image.new("RGB", (2070, 6 * 335), "#171c26")
draw = ImageDraw.Draw(sheet)
for i, name in enumerate(names):
    shot = Image.open(source / (name + ".png")).convert("RGB")
    crop = shot.crop((30, 420, 260, 630)).resize((345, 315), Image.Resampling.NEAREST)
    x, y = i % 6 * 345, i // 6 * 335
    draw.text((x + 8, y + 4), name + " | GPU crop 1.5x", fill="#eedac2")
    sheet.paste(crop, (x, y + 20))
sheet.save(out / "stage03-player-motion-review.png")
print(out / "stage03-player-motion-review.png")
frames = []
for i in range(36):
    shot = Image.open(source / f"slash_motion_{i:02d}.png").convert("RGB")
    frames.append(shot.crop((30, 420, 260, 630)).resize((460, 420), Image.Resampling.NEAREST))
# Each sample advances 0.30/35 seconds of attack time; display at 4x slow motion.
frames[0].save(out / "stage03-slash-slow.gif", save_all=True, append_images=frames[1:],
               duration=40, loop=0)
