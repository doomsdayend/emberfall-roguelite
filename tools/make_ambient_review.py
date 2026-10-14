"""Assemble actual offscreen frames; never synthesize background movement in review."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
frames = [Image.open(root / "artifacts/gpu-ambient" / f"ambient_{i:02d}.png").convert("RGB") for i in range(36)]
out = root / "docs/testing/evidence/stage03-foundry-ambient.gif"
frames[0].save(out, save_all=True, append_images=frames[1:], duration=80, loop=0)
print(out)
