# Grounded running cycle

Original armor/cape pixels are from the project-owned generated artwork in `../flight-run-v001/sources/generated.png`. Offline cutout processing preserves the original source. No additional artwork service or runtime rig is used.

Six transparent 1024×192 atlases, each 16 frames in 8 columns; cells 128×96, foot line y=80. Armed/unarmed variants of run, sprint and exhausted walk. Authored foot paths drive contact, push-off, heel recovery and flight; hip movement, counter-swing and cape wave share the same phase.

Rebuild with Pillow + NumPy: `python3 sources/process.py`. Set `ART_PREVIEWS=1` for optional contact sheets/GIFs under `sources/`; previews are excluded from game exports. Run/sprint playback defaults: 32/48 fps; tired walk: 20 fps. The runtime blends cadence rather than restarting the cycle when speed changes.

September 22 refinement: raise the hip and extend the support leg; reduce normal-run heel recovery and tired-walk foot lift. Armed/unarmed variants share these paths. The source drawing and deterministic rebuild script remain intact.

Armour consistency repair: thigh, shin and boot cutouts now come from the established silver `../prosthetic-v001/knight-idle.png`. The same leg pieces and joints drive all six movement sheets plus two four-frame idle sheets (256×192, 2 columns). Idle has a straighter stance, subtle breathing and a moving cape. Armed idle uses the existing scene texture override, preserving editable frame timings; unarmed idle uses the matching sheet. Gold mechanical hands remain part of the source torso artwork.
