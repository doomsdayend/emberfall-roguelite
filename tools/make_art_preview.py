"""Create a 1x camera-scale review board from concept references, not runtime art."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw

root = Path(__file__).resolve().parents[1]
art = root / "output" / "imagegen"
model = Image.open(art / "emberblade-model-v04.png").convert("RGB")
regions = Image.open(art / "regions-concept-v01.png").convert("RGB")
# Side reference occupies this region in the reviewed 1536x1024 sheet.
hero = model.crop((166, 122, 394, 828))
hero = hero.resize((round(hero.width * 112 / hero.height), 112), Image.Resampling.LANCZOS)
board = Image.new("RGB", (1280, 720), "#20252e")
draw = ImageDraw.Draw(board)
draw.text((28, 20), "CAMERA SCALE REVIEW | 1280 x 720 | CONCEPT ONLY", fill="#eadfc8")
for index, title in enumerate(("FOUNDRY", "GALLERY", "SANCTUM")):
    y0 = round(index * regions.height / 3)
    y1 = round((index + 1) * regions.height / 3)
    panel = ImageOps.fit(regions.crop((0, y0, regions.width, y1)), (1000, 190))
    y = 65 + index * 210
    board.paste(panel, (240, y))
    # Deliberately preserve the ivory reference background. This is a size
    # reference, not a falsely claimed transparent character/game screenshot.
    board.paste(hero, (75, y + 65))
    draw.text((28, y + 8), title + " | HERO 112px", fill="#eadfc8")
    draw.line((28, y + 178, 205, y + 178), fill="#ad9471")
out = art / "camera-scale-review-v02.png"
board.save(out)
print(out)

keys_path = art / "emberblade-action-keys-v02.png"
if keys_path.exists():
    keys = Image.open(keys_path).convert("RGB")
    silhouettes = Image.new("RGB", (1280, 720), "#e9e2d4")
    sd = ImageDraw.Draw(silhouettes)
    sd.text((45, 45), "SILHOUETTE REVIEW | 1280 x 720 | TARGET SCALE, CONCEPT ONLY", fill="#282c35")
    baseline = 560
    sd.line((60, baseline, 1220, baseline), fill="#80745e", width=2)
    for box, height, x, label in (
        ((242, 813, 341, 947), 112, 160, "EMBERBLADE 112px"),
        ((460, 778, 710, 947), 108, 410, "PURSUER 108px"),
        ((788, 777, 917, 947), 120, 670, "ARCHER 120px"),
        ((983, 735, 1358, 947), 260, 1000, "GUARDIAN 260px"),
    ):
        piece = keys.crop(box)
        alpha = piece.convert("L").point(lambda p: 255 if p < 150 else 0)
        bounds = alpha.getbbox()
        if not bounds:
            raise ValueError("No silhouette pixels: " + label)
        alpha = alpha.crop(bounds)
        alpha = alpha.resize((round(alpha.width * height / alpha.height), height), Image.Resampling.LANCZOS)
        ink = Image.new("RGB", alpha.size, "#282c35")
        silhouettes.paste(ink, (x - alpha.width // 2, baseline - height), alpha)
        sd.text((x - 80, baseline + 28), label, fill="#282c35")
    out = art / "silhouette-scale-review-v02.png"
    silhouettes.save(out)
    print(out)

# Human-reviewed landmarks, not OCR of a generated ruler. Raster concepts may
# deviate slightly; the runtime rig's exact five-head contract is independent.
measurements = Image.new("RGB", (1536, 1090), "#eee5d5")
measurements.paste(model, (0, 0))
md = ImageDraw.Draw(measurements)
for x, top, chin, sole, label in (
    (402, 122, 255, 828, "SIDE"),
    (726, 124, 264, 828, "FRONT"),
    (1018, 135, 273, 828, "BACK (ESTIMATED)"),
):
    ratio = (sole - top) / (chin - top)
    md.line((x, top, x, sole), fill="#df3a31", width=2)
    for y in (top, chin, sole):
        md.line((x - 12, y, x + 12, y), fill="#df3a31", width=2)
    md.text((30 + (0 if x == 402 else 470 if x == 726 else 970), 1045),
            f"{label}: {sole-top}px / {chin-top}px = {ratio:.2f} heads", fill="#282c35")
measurements.save(art / "model-proportion-review-v01.png")
