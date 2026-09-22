"""Keep whole poses intact; fix only depth lighting and transparent edge noise.

No limb transforms, retargeting, stretching, frame interpolation or palette reduction.
The preview crops the resulting source sheet directly, so its full-size reference is
exactly the same asset as the animated view.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent

# Polygon coordinates within 444 px source cells, covering the FAR leg only.
# The generator shaded both shins brightly in these poses, hiding leg alternation.
FAR_LEGS = {
    2: [(279,235),(310,235),(337,234),(363,251),(360,279),(326,307),
        (292,325),(281,312),(304,286),(308,275),(276,270)],
    3: [(295,242),(320,254),(349,268),(371,279),(360,304),(344,348),
        (366,359),(376,375),(338,384),(313,369),(312,350),(329,308),
        (319,295),(293,284)],
    4: [(277,260),(300,273),(320,286),(340,309),(341,339),(351,379),
        (380,397),(396,414),(380,426),(326,425),(314,410),(321,392),
        (307,363),(302,335),(289,314),(276,298)],
    5: [(286,260),(307,275),(330,295),(334,323),(321,348),(308,385),
        (329,402),(338,417),(305,426),(278,423),(278,408),(287,384),
        (292,354),(299,333),(285,316),(273,295)],
}


def build():
    source = Image.open(ROOT / 'sources/run-v003-generated.png').convert('RGBA')
    assert source.size == (1774, 887), 'Review masks before replacing the source.'
    pixels = np.array(source)
    pixels[:, :, 3] = np.where(pixels[:, :, 3] >= 180, 255, 0)
    for index, polygon in FAR_LEGS.items():
        x, y = round(index % 4 * source.width / 4), round(index // 4 * source.height / 2)
        mask = Image.new('L', source.size)
        ImageDraw.Draw(mask).polygon([(px+x, py+y) for px,py in polygon], fill=255)
        # Exclude red cloth should a polygon overlap the skirt edge.
        steel = np.abs(pixels[:, :, 0].astype(int) - pixels[:, :, 1].astype(int)) < 35
        region = (np.array(mask) > 0) & steel & (pixels[:, :, 3] > 0)
        pixels[region, :3] = (pixels[region, :3].astype(float) * .66).astype('uint8')
    output = Image.fromarray(pixels)
    # Lighting edits may not change the opaque silhouette or pixel positions.
    assert np.array_equal(pixels[:, :, 3] > 0, np.array(source)[:, :, 3] >= 180)
    output.save(ROOT / 'sources/run-v003.png')


if __name__ == '__main__':
    build()
