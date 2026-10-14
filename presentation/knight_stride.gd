extends RefCounted
## A shared two-step phase. The costume and facing can change without swapping feet.
const Appearance = preload("res://data/knight_appearance.gd")
const SPRINT_THRESHOLD: float = 240.0
var phase: float = 0.0

func reset() -> void:
	phase = 0.0

func advance(seconds: float, speed: float, appearance: Appearance, tired: bool) -> void:
	if seconds <= 0 or not is_finite(seconds) or not is_finite(speed): return
	var reference: float = appearance.run_reference_speed
	var fps: float = appearance.run_fps
	if tired:
		reference = appearance.tired_reference_speed
		fps = appearance.tired_fps
	elif absf(speed) > SPRINT_THRESHOLD:
		reference = appearance.sprint_reference_speed
		fps = appearance.sprint_fps
	if reference <= 0 or appearance.stride_frames <= 0: return
	# Integrate travel distance; a wall, pause or zero displacement cannot march in place.
	var cycles: float = absf(speed) * seconds / reference * fps / appearance.stride_frames
	phase = fposmod(phase + cycles, 1.0)

func frame(count: int) -> int:
	return mini(count - 1, int(phase * count)) if count > 0 else 0
