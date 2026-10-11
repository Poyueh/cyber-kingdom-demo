"""Pack generated full-body poses onto a common native pixel grid.

Mechanical production step only: connected-component extraction, ONE fixed
scale per sheet, nearest-neighbour sampling and ground alignment. No invented
poses, limb transforms or per-frame resizing. Rebuild from versioned sources.
Requires Pillow and NumPy; prompts and source manifest live beside the sources.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from sprite_components import components

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/concepts/devourers-v001'
OUT = ROOT / 'art/characters/devourers-v001'
REVIEW = ROOT / 'docs/reports/devourers-v001'

def bounds(part):
    return min(l for _, l, _ in part), min(y for y, _, _ in part), max(r for _, _, r in part), max(y for y, _, _ in part) + 1

def prepare(name, spec):
    raw = np.array(Image.open(SOURCE / (name + '.png')).convert('RGBA'))
    count = spec['frames']
    parts = components(raw[:, :, 3] >= 145)
    major = sorted(parts, key=lambda p: sum(r-l for _, l, r in p), reverse=True)[:count]
    assert len(major) == count, (name, len(major), count)
    major.sort(key=lambda p: bounds(p)[3])
    ordered = []
    for row in range(count // 4):
        ordered.extend(sorted(major[row*4:(row+1)*4], key=lambda p: bounds(p)[0]))
    tiles = []
    for part in ordered:
        x, y, right, bottom = bounds(part)
        tile = np.zeros((bottom-y, right-x, 4), dtype=np.uint8)
        for yy, left, end in part:
            tile[yy-y, left-x:end-x] = raw[yy, left:end]
            tile[yy-y, left-x:end-x, 3] = 255
        tiles.append(Image.fromarray(tile))
    width, height = spec['cell']
    # Reference standing height establishes scale; maximum bounds only guard
    # against clipping, and the SAME scale then applies to ALL action frames.
    scale = min(spec['standing_height'] / max(t.height for t in tiles[:8]),
                (width-12) / max(t.width for t in tiles),
                (height-12) / max(t.height for t in tiles))
    atlas = Image.new('RGBA', (width*4, height*(count//4)))
    previews = []
    meta = []
    for index, tile in enumerate(tiles):
        native = tile.resize((round(tile.width*scale), round(tile.height*scale)), Image.Resampling.NEAREST)
        # Keep a stable hindquarters pivot: forward claw/neck extensions remain
        # forward extensions instead of dragging the whole body backwards.
        facing = spec['facing']
        pivot = native.width * (0.5 if facing == 'left' else 0.40)
        dx = round(width*.5-pivot)
        dy = height-6-native.height
        assert 0 <= dx and dx+native.width <= width and dy >= 0, (name,index,dx,dy,native.size)
        frame = Image.new('RGBA',(width,height));frame.alpha_composite(native,(dx,dy))
        atlas.alpha_composite(frame,((index%4)*width,(index//4)*height))
        background = Image.new('RGBA',(width,height),'#1d2734');background.alpha_composite(frame)
        previews.append(background.convert('RGB'))
        meta.append({'source_bounds':bounds(ordered[index]),'native_bounds':frame.getbbox()})
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    atlas.save(OUT/(name+'.png'))
    previews[0].save(REVIEW/(name+'-walk.webp'),save_all=True,append_images=previews[1:8],duration=100,loop=0,lossless=True)
    # Contact sheet is built from the SAME frames used by the game.
    contact = Image.new('RGB',atlas.size,'#1d2734');contact.paste(atlas,mask=atlas.getchannel('A'))
    contact.save(REVIEW/(name+'-contact.png'))
    return {'scale':scale,'cell':spec['cell'],'frames':meta}

def main():
    manifest=json.loads((SOURCE/'manifest.json').read_text())
    results={}
    for name,spec in manifest.items():
        if (SOURCE/(name+'.png')).exists():
            results[name]=prepare(name,spec)
            print('Prepared',name,len(results[name]['frames']))
    (REVIEW/'atlas-checks.json').write_text(json.dumps(results,indent=2)+'\n')

if __name__ == '__main__':main()
