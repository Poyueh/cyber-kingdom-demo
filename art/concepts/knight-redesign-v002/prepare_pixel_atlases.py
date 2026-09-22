"""Rasterize complete poses once, before any preview magnification.

Keep each clip's original shared scale and row anchors; never fit each frame
individually, which would make body size fluctuate through the animation.
This replaces direct high-resolution source drawing in the browser.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
CELL = (128, 96)


def build(name, source, rows, scale, anchor_x, columns=4):
    sheet = Image.open(ROOT / "sources" / source).convert("RGBA")
    atlas = Image.new("RGBA", (CELL[0] * columns, CELL[1] * len(rows)))
    review = Image.new("RGBA", (CELL[0] * 2, CELL[1] * (columns * len(rows) // 2)))
    for row, (top, bottom, sole) in enumerate(rows):
        for column in range(columns):
            left = round(column * sheet.width / columns)
            right = round((column + 1) * sheet.width / columns)
            tile = sheet.crop((left, top, right, bottom))
            tile = tile.resize((round(tile.width * scale), round(tile.height * scale)), Image.Resampling.NEAREST)
            # Binary edges keep the native pixel silhouette; no blur or new palette.
            tile.putalpha(tile.getchannel("A").point(lambda value: 255 if value >= 180 else 0))
            x, y = round(73 - anchor_x * scale), round(81 - sole * scale)
            bounds = tile.getbbox()
            assert bounds and x + bounds[0] >= 0 and y + bounds[1] >= 0
            assert x + bounds[2] <= CELL[0] and y + bounds[3] <= CELL[1], "Clipped pose"
            cell = Image.new("RGBA", CELL)
            cell.alpha_composite(tile, (x, y))
            atlas.alpha_composite(cell, (column * CELL[0], row * CELL[1]))
            index = row * columns + column
            review.alpha_composite(cell, (index % 2 * CELL[0], index // 2 * CELL[1]))
    atlas.save(ROOT / "preview" / f"{name}.png")
    review.save(ROOT / "preview" / f"{name}-review.png")


if __name__ == "__main__":
    # Original row registration retained from the full-resolution preview.
    build("run-native", "run-v003.png", [(0, 444, 419), (444, 887, 401)], 60 / 348, 320)
    build("previous-native", "selected-run.png", [(0, 298, 285), (298, 574, 263),
          (574, 834, 245), (834, 1086, 244)], 60 / 250, 246)
