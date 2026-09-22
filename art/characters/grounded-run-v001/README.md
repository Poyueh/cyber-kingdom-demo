# Grounded running cycle

Original armor/cape pixels are from the project-owned generated artwork in `../flight-run-v001/sources/generated.png`. Offline cutout processing preserves the original source. No additional artwork service or runtime rig is used.

Six transparent 1024×192 atlases, each 16 frames in 8 columns; cells 128×96, foot line y=80. Armed/unarmed variants of run, sprint and exhausted walk. Authored foot paths drive contact, push-off, heel recovery and flight; hip movement, counter-swing and cape wave share the same phase.

Rebuild with Pillow + NumPy: `python3 sources/process.py`. Set `ART_PREVIEWS=1` for optional contact sheets/GIFs under `sources/`; previews are excluded from game exports. Run/sprint playback defaults: 32/48 fps; tired walk: 20 fps. The runtime blends cadence rather than restarting the cycle when speed changes.

September 22 refinement: raise the hip and extend the support leg; reduce normal-run heel recovery and tired-walk foot lift. Armed/unarmed variants share these paths. The source drawing and deterministic rebuild script remain intact.

Armour consistency repair: thigh, shin and boot cutouts now come from the established silver `../prosthetic-v001/knight-idle.png`. The same leg pieces and joints drive all six movement sheets plus two four-frame idle sheets (256×192, 2 columns). Idle has a straighter stance, subtle breathing and a moving cape. Armed idle uses the existing scene texture override, preserving editable frame timings; unarmed idle uses the matching sheet. Gold mechanical hands remain part of the source torso artwork.

## Whole-character consistency pass — 2026-09-22

The same generator now also builds `camp-ceremony-v001/draw_sword.png` and the two on-foot rows of `exhaustion-v001/rest.png`. Their original generated source images remain archived. Head, torso, cape, gauntlets, silver thighs/shins/boots and sword palette are shared with locomotion. Existing frame counts, ceremony timings and foot anchors remain intact. Exported poses keep the established roughly 56-pixel standing height; this avoids growing taller when leaving combat.

Leg transforms now preserve plate width independently of bone length. Normal running recovery lifts a foot about 7 pixels before final stature scaling, sprint about 11 (previously 13 and 26); the torso leans less and the hip is higher. Running still has a wider stride and faster cadence than recovery walking. Frame rates and movement rules are unchanged.

Active atlas audit:

| Runtime state | Source / decision |
| --- | --- |
| Armed/unarmed idle, run, sprint, recovery walk | Eight atlases here; common body and silver legs |
| Campfire sword ceremony | Rebuilt from the same parts; no old gold-legged body |
| On-foot breathing | Rebuilt from the same parts; 640×256, two rows |
| Planted combo | `combo-v005/planted.png`; retain authored silver armour, red cape and attack silhouettes |
| Mounted idle, movement and attack | `mounted-v001/mounted.png`; retain intentional top-tier cavalry armour and its horse |
| Mounted recovery | Uses mounted frame 0 directly; no separately generated rider/horse, no horse recolouring |
| Damage/death | Reactions on the current body's presentation; no additional character atlas |
| Prologue | Instantiates `frontier.tscn`, receiving these same replacements |
| Legacy jump/dash/moving attack/training | Retained for legacy scenes/tests; unavailable in the current flat campaign; originals are not bulk-rewritten |

Equipment material follows idle, movement, on-foot recovery, unarmed and ceremony states. Mounted recovery deliberately follows the mounted material rather than tinting the entire horse with the infantry armour shader.

## Broader stride and lowered arms

The next player feedback rejected the close-to-chest hand posture and small stride. Running foot paths now span about 48 source pixels, sprint 60, with counter-swinging hands down near the waist and the armed hand carried farther behind. Plate width remains independent of leg extension; longer strides keep their authored ground contacts instead of clamping the toes upward. Idle, ceremony and recovery continue sharing the same armour parts. Runtime cadence and actual movement speeds are unchanged.

Forward-posture follow-up: the player requested a clearer lean while moving. The upper-body anchor now leads the hip by 4 source pixels in normal running and 8 in sprinting, with shoulder attachment following it. Torso anchor length stays constant as it rotates, preserving head and armour size. Recovery walking has a subtler lean; idle remains unchanged. Foot paths, arm swing, cadence and combat are unchanged.
