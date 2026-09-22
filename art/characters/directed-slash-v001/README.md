# Directed sword cuts

Two compact 1280×384 atlases, each three eight-frame cuts, cells 160×128 with the existing y=112 sole anchor. `planted.png` retains the authored v005 stationary choreography. `advancing.png` compacts selected poses from the existing v004 moving atlas into a single step sequence per cut; it does not replay a walking cycle during the swing.

Rebuild with `tools/prepare_directed_slash.py` (Pillow + NumPy). All source images remain in combo-v005 and combo-v004. Detached cyan sweep pixels are reduced to 18% alpha outside the torso; the reactor, steel blade and red cape remain readable. No stacked full-body afterimages are added. Mounted procedural trails are separately thinner and lower opacity; hit sparks and hit stop are retained.

`knight_combo_motion.tres` sets `moving_gait_rows=1`. Older resources retain the eight-row default. Runtime selects this atlas using current direction intent, preserving the same combo step and progress when the direction is released; it never restarts the swing or damage window.
