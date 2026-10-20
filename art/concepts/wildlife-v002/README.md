# Wildlife v002 art sources

Generated with the built-in OpenAI image_gen tool, using the existing
`art/frontier/v002/deer.png` solely as an art-direction reference.
Exact prompts and generation output locations are in `prompts.json`.
Seven species each have eight complete poses. The badger received one padding
correction; `badger-before-padding.png` preserves the rejected clipped source.
The deer itself is unchanged.

`manifest.json` sets the fixed native height for each animal. Run
`python3 tools/prepare_wildlife_art.py` with Pillow and NumPy to rebuild
`art/characters/wildlife-v002` and `docs/reports/wildlife-v002`.
This is mechanical alpha extraction, fixed-scale nearest-neighbour sampling,
and grounded atlas packing. It does not invent pixels, paint anatomy, stretch
limbs or fit each pose to a different scale.

Originals are excluded by every export preset. Runtime uses seven 384×160
native atlases, with complete 96×80 poses and the same (48,74) foot pivot.
