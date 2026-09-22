"""Compact distinct stationary/advancing sword atlases; retain original sources."""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/characters/directed-slash-v001'
OUT.mkdir(exist_ok=True)
planted = Image.open(ROOT / 'art/characters/combo-v005/planted.png').convert('RGBA')
moving = Image.open(ROOT / 'art/characters/combo-v004/moving.png').convert('RGBA')

def restrained_trail(tile):
    pixels = np.array(tile)
    red, green, blue = [pixels[:, :, i].astype(int) for i in range(3)]
    yy, xx = np.indices(red.shape)
    # The reactor stays bright. Only the detached cyan sweep outside the torso fades.
    arc = (green > red + 12) & (blue > red + 12) & ((xx > 96) | (yy < 38))
    pixels[arc, 3] = (pixels[arc, 3].astype(float) * .18).astype('uint8')
    return Image.fromarray(pixels)

for mode in ['planted', 'advancing']:
    atlas = Image.new('RGBA', (1280, 384))
    for step in range(3):
        for frame in range(8):
            gait = [0, 0, 1, 3, 5, 6, 7, 7][frame]
            source = planted if mode == 'planted' else moving
            row = step if mode == 'planted' else step * 8 + gait
            tile = source.crop((frame * 160, row * 128, (frame + 1) * 160, (row + 1) * 128))
            atlas.alpha_composite(restrained_trail(tile), (frame * 160, step * 128))
    atlas.save(OUT / (mode + '.png'))
