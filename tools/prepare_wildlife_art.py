"""Pack approved animal artwork into grounded, native-resolution atlases.

Mechanical processing only: extract alpha-connected full-body poses, use one
scale for the entire species, nearest-neighbour sample, and align the feet.
The exact same native pixels are used in game and in the contact/loop previews.
Requires Pillow and NumPy. Source images and prompts remain versioned.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from sprite_components import components

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/concepts/wildlife-v002"
OUT = ROOT / "art/characters/wildlife-v002"
REVIEW = ROOT / "docs/reports/wildlife-v002"


def bounds(part):
    return (min(left for _, left, _ in part), min(y for y, _, _ in part),
            max(right for _, _, right in part), max(y for y, _, _ in part) + 1)


def prepare(name, spec):
    raw = np.array(Image.open(SOURCE / (name + ".png")).convert("RGBA"))
    parts = sorted(components(raw[:, :, 3] >= 145),
                   key=lambda p: sum(r-l for _, l, r in p), reverse=True)
    major = parts[:8]
    assert len(major) == 8 and min(sum(r-l for _, l, r in p) for p in major) > 1000, name
    assert len(parts) <= 8 or sum(r-l for _, l, r in parts[8]) < 100, (name, "extra body part")
    major.sort(key=lambda p: bounds(p)[3])
    ordered = []
    for row in range(2):
        ordered.extend(sorted(major[row*4:row*4+4], key=lambda p: bounds(p)[0]))
    boxes = [bounds(p) for p in ordered]
    cell_w, cell_h = raw.shape[1] / 4, raw.shape[0] / 2
    for index, (x, y, right, bottom) in enumerate(boxes):
        assert x >= (index % 4)*cell_w-32 and right <= (index % 4+1)*cell_w+32, (name, index, "crosses cell")
        assert y >= (index // 4)*cell_h and bottom <= (index // 4+1)*cell_h, (name, index, "crosses row")
    scale = min(spec["height"] / max(b-y for _, y, _, b in boxes),
                84 / max(r-x for x, _, r, _ in boxes))
    atlas = Image.new("RGBA", (384, 160))
    frames, metadata = [], []
    for index, (part, box) in enumerate(zip(ordered, boxes)):
        x, y, right, bottom = box
        tile = np.zeros((bottom-y, right-x, 4), dtype=np.uint8)
        for yy, left, end in part:
            tile[yy-y, left-x:end-x] = raw[yy, left:end]
            tile[yy-y, left-x:end-x, 3] = 255
        native = Image.fromarray(tile).resize(
            (round((right-x)*scale), round((bottom-y)*scale)), Image.Resampling.NEAREST)
        # A shared source-cell centre prevents a moving foot or tail from
        # recentering the torso. Never fit, stretch or rotate individual limbs.
        dx = round(48 + (x-((index % 4)+0.5)*cell_w)*scale)
        dy = 74-native.height
        assert dx >= 0 and dx+native.width <= 96 and dy >= 0, (name, index, dx, dy)
        frame = Image.new("RGBA", (96, 80))
        frame.alpha_composite(native, (dx, dy))
        atlas.alpha_composite(frame, ((index % 4)*96, (index // 4)*80))
        preview = Image.new("RGBA", frame.size, "#1a2b32")
        preview.alpha_composite(frame)
        frames.append(preview.convert("RGB"))
        metadata.append({"source_bounds": box, "native_bounds": frame.getbbox()})
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    (REVIEW / ".gdignore").touch()
    atlas.save(OUT / (name + ".png"))
    contact = Image.new("RGBA", atlas.size, "#1a2b32")
    contact.alpha_composite(atlas)
    contact.convert("RGB").resize((768, 320), Image.Resampling.NEAREST).save(REVIEW / (name+"-contact.png"))
    large = [f.resize((384, 320), Image.Resampling.NEAREST) for f in frames]
    large[0].save(REVIEW / (name+"-walk.webp"), save_all=True,
                  append_images=large[1:], duration=125, loop=0, lossless=True)
    return {"scale": scale, "cell": [96, 80], "ground_pivot": [48, 74], "frames": metadata}


def main():
    manifest = json.loads((SOURCE / "manifest.json").read_text())
    checks = {name: prepare(name, spec) for name, spec in manifest.items()
              if (SOURCE / (name+".png")).exists()}
    (REVIEW / "atlas-checks.json").write_text(json.dumps(checks, indent=2)+"\n")
    print("Prepared", len(checks), "species /", len(checks)*8, "complete poses")


if __name__ == "__main__":
    main()
