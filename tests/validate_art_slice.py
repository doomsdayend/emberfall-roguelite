from pathlib import Path
from PIL import Image
import json, hashlib
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'assets/source/stage03-art-manifest.json').read_text(encoding='utf-8-sig'))
assert manifest['stage']=='03-art-slice'
assert len(manifest['assets'])==3
for item in manifest['assets']:
    p=root/item['path']; assert p.exists(), p
    with Image.open(p) as im: assert im.size==(item['width'],item['height']), im.size
    assert hashlib.sha256(p.read_bytes()).hexdigest()==item['sha256']
    assert item['status']=='reference_pending_layering'
assert len(manifest.get('derived', [])) == 2
for item in manifest['derived']:
    p = root / item['path']
    assert p.exists(), p
    with Image.open(p) as im:
        assert im.mode == 'RGBA'
        assert im.size == (item['width'], item['height'])
        assert im.getchannel('A').getbbox() is not None
    assert hashlib.sha256(p.read_bytes()).hexdigest() == item['sha256']
    assert item['status'] == 'cutout_pending_cleanup'
for item in manifest.get('runtime_candidates', []):
    p = root / item['path']
    with Image.open(p) as im:
        assert im.size == (item['width'], item['height'])
    assert hashlib.sha256(p.read_bytes()).hexdigest() == item['sha256']
print('ART_SLICE_REFERENCE_RESULT='+json.dumps({'passed':True,'assets':len(manifest['assets']),'runtime_candidates':len(manifest.get('runtime_candidates', [])),'sizes':[(x['width'],x['height']) for x in manifest['assets']],'final_art_accepted':False,'licensed_for_final':False},ensure_ascii=False))

