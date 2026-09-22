"""Install the approved native run and same-character supporting study poses.

No runtime image processing. Keep source art under concepts, outside exports.
Supporting attack/ceremony poses are an initial integration, not new hand-drawn
animation. Mounted support retains the existing horse and matches rider armour.
"""
from pathlib import Path
import shutil
from collections import deque
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/concepts/knight-redesign-v002'
OUT = ROOT / 'art/characters/blacksteel-v001'
OUT.mkdir(exist_ok=True)
NEAREST = Image.Resampling.NEAREST


def cell(sheet, index, columns=4, size=(128, 96)):
    x, y = index % columns * size[0], index // columns * size[1]
    return sheet.crop((x, y, x + size[0], y + size[1]))


def pack(cells, columns, name):
    w, h = cells[0].size
    sheet = Image.new('RGBA', (w * columns, h * ((len(cells) + columns - 1) // columns)))
    for i, drawing in enumerate(cells):
        sheet.alpha_composite(drawing, (i % columns * w, i // columns * h))
    sheet.save(OUT / name)
    return sheet


def erase(image, polygon):
    result = image.copy()
    ImageDraw.Draw(result).polygon(polygon, fill=(0, 0, 0, 0))
    return result


def support_pose(index):
    sheet = Image.open(SOURCE / 'sources/design.png').convert('RGBA')
    # All design poses share a scale. Kneeling stays shorter than standing.
    rect = {9: (362, 724, 820, 1086), 10: (724, 724, 1086, 1086),
            11: (1086, 650, 1448, 1086)}[index]
    tile = sheet.crop(rect)
    tile.putalpha(tile.getchannel('A').point(lambda a: 255 if a >= 180 else 0))
    # Uneven source gutters include disconnected neighbouring sword tips.
    a = np.array(tile)
    visible = a[:, :, 3] > 0
    seen = np.zeros(visible.shape, bool)
    components = []
    for y, x in np.argwhere(visible):
        if seen[y, x]:
            continue
        queue = deque([(int(y), int(x))]); seen[y, x] = True
        part = []
        while queue:
            cy, cx = queue.popleft(); part.append((cy, cx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < tile.height and 0 <= nx < tile.width and visible[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True; queue.append((ny, nx))
        components.append(part)
    keep = max(components, key=len)
    a[:, :, 3] = 0
    for y, x in keep:
        a[y, x, 3] = 255
    tile = Image.fromarray(a)
    bounds = tile.getbbox()
    face = {9: 228, 10: 234, 11: 248}[index]
    scale = 60 / 310
    tile = tile.resize((round(tile.width * scale), round(tile.height * scale)), NEAREST)
    result = Image.new('RGBA', (128, 96))
    result.alpha_composite(tile, (round(73 - face * scale), round(81 - bounds[3] * scale)))
    return result


def overlay_cell(image, dy=0):
    result = Image.new('RGBA', (160, 128))
    result.alpha_composite(image, (16, 16 + dy))
    return result


shutil.copyfile(SOURCE / 'preview/run-native.png', OUT / 'run.png')
idle = Image.open(SOURCE / 'preview/idle.png').convert('RGBA')
idle.save(OUT / 'idle.png')
run = Image.open(OUT / 'run.png').convert('RGBA')
unarmed_run = [erase(cell(run, i), [(22, 64), (51, 48), (53, 54), (25, 70)]) for i in range(8)]
pack(unarmed_run, 4, 'run-unarmed.png')
unarmed_idle = erase(idle, [(30, 70), (53, 52), (56, 56), (34, 77)])
unarmed_idle.save(OUT / 'idle-unarmed.png')

slash = Image.open(SOURCE / 'preview/slash.png').convert('RGBA')
shutil.copyfile(SOURCE / 'preview/slash.png', OUT / 'attack.png')
thrust, kneel, raised = [support_pose(i) for i in (9, 10, 11)]
unarmed_kneel = erase(kneel, [(75, 38), (82, 38), (82, 85), (76, 85)])
pack([overlay_cell(pose, dy) for pose in (unarmed_kneel, kneel) for dy in (0, 1, 0, -1)], 4, 'rest.png')
pack([overlay_cell(pose) for pose in (unarmed_kneel, kneel, kneel, raised, raised, raised, idle, idle)], 4, 'ceremony.png')

# Three combo timings remain owned by the existing combat motion resource.
orders = [(0, 1, 2, 3, 4, 5, 6, 7), (7, 6, 5, 4, 3, 2, 1, 0), (0, 1, 2, 2, 3, 4, 6, 7)]
planted, advancing = [], []
for order in orders:
    for j, index in enumerate(order):
        pose = cell(slash, index)
        # Combo child sits 16px above the main visual; preserve the world sole.
        planted.append(overlay_cell(pose, 16))
        advancing.append(overlay_cell(thrust if j in (3, 4) else pose, 16))
pack(planted, 8, 'planted.png')
pack(advancing, 8, 'advancing.png')

# Existing horse animation is retained; update only the rider identity.
mounted = Image.open(ROOT / 'art/characters/mounted-v001/mounted.png').convert('RGBA')
head = idle.crop((62, 20, 77, 35)).resize((11, 12), NEAREST)
horses = []
for i in range(6):
    pose = cell(mounted, i, 6, (160, 128))
    a = np.array(pose)
    yy, xx = np.indices(a.shape[:2])
    rider = (xx >= 54) & (xx < 99) & (yy >= 23) & (yy < 72) & (a[:, :, 3] > 0)
    rgb = a[:, :, :3].astype(float)
    metal = rider & (rgb[:, :, 1] >= rgb[:, :, 0] * .56) & (rgb[:, :, 2] >= rgb[:, :, 0] * .35)
    grey = rgb.mean(2) * .65
    for c, ratio in enumerate((.90, .98, 1.04)):
        a[:, :, c][metal] = np.clip(grey[metal] * ratio, 0, 255)
    pose = Image.fromarray(a)
    # Pose-specific original helmet positions, in native pixels.
    hx, hy = [(72, 24), (73, 27), (78, 29), (78, 12), (68, 28), (73, 32)][i]
    ImageDraw.Draw(pose).rectangle((hx + 1, hy + 1, hx + 11, hy + 12), fill=(0, 0, 0, 0))
    pose.alpha_composite(head, (hx + 1, hy))
    horses.append(pose)
pack(horses, 6, 'mounted.png')

# Godot SpriteFrames includes complete fallbacks so no old silver body flashes.
clips = {'idle': ('idle.png', 1, 1, 3), 'run': ('run.png', 8, 4, 12),
         'sprint': ('run.png', 8, 4, 18), 'tired_walk': ('run.png', 8, 4, 7),
         'attack': ('attack.png', 8, 4, 12), 'dash': ('run.png', 8, 4, 18),
         'jump': ('run.png', 4, 4, 12)}
files = list(dict.fromkeys(v[0] for v in clips.values()))
lines = ['[gd_resource type="SpriteFrames" format=3]', '']
for i, file in enumerate(files):
    lines += [f'[ext_resource type="Texture2D" path="res://art/characters/blacksteel-v001/{file}" id="{i}"]']
animations = []
for name, (file, count, columns, fps) in clips.items():
    refs = []
    for i in range(count):
        key = f'{name}_{i}'
        lines += ['', f'[sub_resource type="AtlasTexture" id="{key}"]',
                  f'atlas = ExtResource("{files.index(file)}")',
                  f'region = Rect2({i % columns * 128}, {i // columns * 96}, 128, 96)', 'filter_clip = true']
        refs.append('{"duration": 1.0, "texture": SubResource("' + key + '")}')
    animations.append('{"frames": [' + ', '.join(refs) + f'], "loop": true, "name": &"{name}", "speed": {fps}.0' + '}')
lines += ['', '[resource]', 'animations = [' + ',\n'.join(animations) + ']']
(ROOT / 'data/blacksteel_frames.tres').write_text('\n'.join(lines) + '\n')

review = [idle, unarmed_idle, cell(run, 0), cell(run, 4), unarmed_run[0], kneel, raised, thrust]
pack(review, 4, 'contact.png')
