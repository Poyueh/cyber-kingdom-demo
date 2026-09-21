# Raider locomotion

Sixteen-frame transparent 1024×192 atlas derived from the project's existing `../sentinel/processed/sentinel-v001.png`. Original art retained. Leg plates are cut and posed offline; no runtime pixel processing. Regenerate with Pillow: `python3 sources/process.py`; optional review images use `ART_PREVIEWS=1`.

`presentation/raider_motion_view.gd` advances foot phase from distance travelled, freezes during pause, and uses the original combat drawings for anticipation/strike/recovery. Per-enemy state is removed when the enemy leaves; no changes to damage timing or saves.
