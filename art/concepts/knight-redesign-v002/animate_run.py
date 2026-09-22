"""Offline articulated run study, using the preserved generated armour artwork.

Positions are in the first 313 px source cell; outputs use 128 x 96 pixel cells.
The two legs follow the same foot path half a cycle apart, never image blends.
"""
from collections import deque
from math import atan2, cos, pi, sin, sqrt

import numpy as np
from PIL import Image, ImageDraw

FRAMES = 24
COLUMNS = 6
CELL = (128, 96)
SCALE = 0.222
GROUND = 305
HIP = np.array([188.0, 175.0])
THIGH = 57.0
SHIN = 65.0

# Heel contact, loaded support, toe-off, recovery, passing, reach.
# x, foot lift, boot pitch in degrees. Far leg samples phase + 0.5.
FOOT_KEYS = [
    (0.00, 238, 0, -8),
    (0.14, 211, 0, 0),
    (0.30, 177, 0, 8),
    (0.44, 147, 0, 22),
    (0.56, 138, 28, 30),
    (0.70, 181, 33, 0),
    (0.84, 228, 16, -12),
    (1.00, 238, 0, -8),
]


def isolate_subject(image):
    """Discard unrelated fragments at source-cell edges, retaining the knight."""
    a = np.array(image.convert('RGBA'))
    solid = a[:, :, 3] >= 180
    seen = np.zeros(solid.shape, dtype=bool)
    largest = []
    height, width = solid.shape
    for y, x in np.argwhere(solid):
        if seen[y, x]:
            continue
        queue = deque([(int(y), int(x))])
        seen[y, x] = True
        component = []
        while queue:
            py, px = queue.popleft()
            component.append((py, px))
            for dy, dx in ((0, -1), (0, 1), (-1, 0), (1, 0), (-1, -1), (-1, 1), (1, -1), (1, 1)):
                ny, nx = py + dy, px + dx
                if 0 <= ny < height and 0 <= nx < width and solid[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    queue.append((ny, nx))
        if len(component) > len(largest):
            largest = component
    a[:, :, 3] = 0
    for y, x in largest:
        a[y, x, 3] = 255
    return Image.fromarray(a)


def masked(source, polygons):
    mask = Image.new('L', source.size)
    draw = ImageDraw.Draw(mask)
    for polygon in polygons:
        draw.polygon(polygon, fill=255)
    out = source.copy()
    out.putalpha(Image.fromarray(np.minimum(np.array(source.getchannel('A')), np.array(mask))))
    return out


def parts(source):
    body = masked(source, [
        [(0, 0), (313, 0), (313, 165), (216, 165), (199, 157),
         (189, 171), (182, 201), (166, 204), (150, 195), (140, 183), (0, 242)],
        [(16, 233), (130, 174), (160, 161), (173, 187), (21, 247), (14, 242)],
    ])
    thigh = masked(source, [[(188, 164), (207, 177), (223, 191), (238, 201),
                             (244, 219), (236, 232), (216, 225), (201, 210), (183, 193)]])
    shin = masked(source, [[(212, 214), (242, 213), (247, 246), (247, 270),
                            (253, 282), (238, 290), (222, 282), (216, 256), (207, 236)]])
    boot = masked(source, [[(223, 276), (249, 273), (251, 281), (269, 286),
                            (274, 296), (270, 306), (221, 306), (220, 287)]])
    arm = masked(body, [[(216, 124), (232, 129), (239, 132), (265, 132),
                         (271, 140), (270, 156), (258, 162), (225, 153), (214, 143)]])
    a = np.array(body)
    a[np.array(arm)[:, :, 3] > 0] = 0
    return Image.fromarray(a), thigh, shin, boot, arm


def rotate_about(piece, pivot, degrees, offset=(0, 0)):
    angle = degrees * pi / 180
    pivot = np.array(pivot, dtype=float)
    target = pivot + offset
    return transform_piece(piece, pivot, pivot + [1, 0], target,
                           target + [cos(angle), sin(angle)])


def render_body(body, arm, phase, bob):
    # Rear cloth lags the shoulder; the cyan arm, blade and armour remain rigid.
    a = np.array(body)
    yy, xx = np.indices(a.shape[:2])
    cloth = (a[:, :, 0] > a[:, :, 1] * 1.35) & (xx < 180) & (yy < 200)
    cloth_pixels = np.zeros_like(a)
    cloth_pixels[cloth] = a[cloth]
    a[cloth] = 0
    warped = np.zeros_like(a)
    for x in range(180):
        lag = min(1, max(0, (180 - x) / 110))
        shift = round(5 * lag * sin(phase * 2 * pi - lag * 2))
        if shift >= 0:
            warped[shift:, x] = cloth_pixels[:313 - shift, x]
        else:
            warped[:shift, x] = cloth_pixels[-shift:, x]
    torso = Image.fromarray(warped)
    torso.alpha_composite(Image.fromarray(a))
    torso.alpha_composite(rotate_about(arm, [220, 131], 9 * cos(phase * 2 * pi)))
    # Whole ribcage and pelvis follow the same axis; never translate hips alone.
    return rotate_about(torso, HIP, -8 + 1.5 * cos(phase * 2 * pi), (0, bob))


def transform_piece(piece, origin, end, target, target_end, shade=1.0):
    """Rotate a piece, scaling along its bone only; armour width stays fixed."""
    origin, end, target, target_end = map(lambda p: np.array(p, dtype=float), (origin, end, target, target_end))
    v, w = end - origin, target_end - target
    a, b = atan2(v[1], v[0]), atan2(w[1], w[0])
    basis_a = np.array([[cos(a), -sin(a)], [sin(a), cos(a)]])
    basis_b = np.array([[cos(b), -sin(b)], [sin(b), cos(b)]])
    forward = basis_b @ np.diag([np.linalg.norm(w) / np.linalg.norm(v), 1]) @ basis_a.T
    inverse = np.linalg.inv(forward)
    shift = origin - inverse @ target
    out = piece.transform(piece.size, Image.Transform.AFFINE,
                          (inverse[0, 0], inverse[0, 1], shift[0], inverse[1, 0], inverse[1, 1], shift[1]),
                          resample=Image.Resampling.NEAREST)
    if shade != 1:
        a = np.array(out)
        a[:, :, :3] = (a[:, :, :3].astype(float) * shade).astype('uint8')
        out = Image.fromarray(a)
    return out


def foot_pose(phase):
    phase %= 1
    for left, right in zip(FOOT_KEYS, FOOT_KEYS[1:]):
        if phase <= right[0]:
            t = (phase - left[0]) / (right[0] - left[0])
            # Linear ground travel prevents a planted foot accelerating mid-step.
            x = left[1] + (right[1] - left[1]) * t
            ease = (1 - cos(t * pi)) / 2
            lift = left[2] + (right[2] - left[2]) * ease
            pitch = left[3] + (right[3] - left[3]) * ease
            return x, lift, pitch * pi / 180
    raise AssertionError('Unreachable phase')


def knee_between(hip, ankle):
    delta = ankle - hip
    distance = np.linalg.norm(delta)
    assert abs(THIGH - SHIN) < distance < THIGH + SHIN, (hip, ankle, distance)
    along = (THIGH ** 2 - SHIN ** 2 + distance ** 2) / (2 * distance)
    bend = sqrt(max(0, THIGH ** 2 - along ** 2))
    direction = delta / distance
    return hip + direction * along + np.array([direction[1], -direction[0]]) * bend


def render_leg(thigh, shin, boot, phase, hip, shade):
    x, lift, pitch = foot_pose(phase)
    # Position from the rotated boot silhouette, so support really touches ground.
    ankle_origin = np.array([237.0, 282.0])
    direction = np.array([cos(pitch), sin(pitch)])
    rotated_boot = transform_piece(boot, ankle_origin, ankle_origin + [30, 0],
                                   ankle_origin, ankle_origin + direction * 30, shade)
    sole_offset = rotated_boot.getbbox()[3] - ankle_origin[1]
    ankle = np.array([x, GROUND - lift - sole_offset])
    knee = knee_between(hip, ankle)
    result = Image.new('RGBA', boot.size)
    result.alpha_composite(transform_piece(thigh, [190, 175], [228, 218], hip, knee, shade))
    result.alpha_composite(transform_piece(shin, [228, 218], [237, 282], knee, ankle, shade))
    result.alpha_composite(transform_piece(boot, ankle_origin, ankle_origin + [30, 0],
                                          ankle, ankle + direction * 30, shade))
    return result


def build_run(root):
    sheet = Image.open(root / 'sources/balanced-run.png')
    source = isolate_subject(sheet.crop((0, 0, sheet.width // 4, sheet.height // 4)))
    assert source.size == (313, 313), 'Re-author the masks if the preserved source changes.'
    body, thigh, shin, boot, arm = parts(source)
    atlas = Image.new('RGBA', (COLUMNS * CELL[0], (FRAMES // COLUMNS) * CELL[1]))
    frames = []
    for index in range(FRAMES):
        phase = index / FRAMES
        bob = 1.8 * sin(phase * 4 * pi)
        hip = HIP + [0, bob]
        frame = render_leg(thigh, shin, boot, phase + .5, hip + [-3, 0], .72)
        frame.alpha_composite(render_leg(thigh, shin, boot, phase, hip, 1.0))
        frame.alpha_composite(render_body(body, arm, phase, bob))
        small = frame.resize((round(313 * SCALE), round(313 * SCALE)), Image.Resampling.NEAREST)
        cell = Image.new('RGBA', CELL)
        cell.alpha_composite(small, (round(73 - 219 * SCALE), round(81 - GROUND * SCALE)))
        assert cell.getbbox()[0] > 0 and cell.getbbox()[2] < CELL[0], 'Clipped stride'
        frames.append(cell)
        atlas.alpha_composite(cell, ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
    # One palette for the entire cycle prevents stationary armour highlights flickering.
    atlas = atlas.quantize(colors=32, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert('RGBA')
    atlas.save(root / 'preview/run.png')
    frames = [atlas.crop(((i % COLUMNS) * CELL[0], (i // COLUMNS) * CELL[1],
                          (i % COLUMNS + 1) * CELL[0], (i // COLUMNS + 1) * CELL[1]))
              for i in range(FRAMES)]
    assert len({frame.tobytes() for frame in frames}) == FRAMES, 'Repeated rather than articulated frames'
    # Fixed key-pose strip makes alternating front / rear feet easy to inspect.
    strip = Image.new('RGBA', (CELL[0] * 6, CELL[1]))
    for column, index in enumerate((0, 4, 8, 12, 16, 20)):
        strip.alpha_composite(frames[index], (column * CELL[0], 0))
    strip.save(root / 'preview/run-steps.png')
    return frames


if __name__ == '__main__':
    from pathlib import Path
    build_run(Path(__file__).resolve().parent)
