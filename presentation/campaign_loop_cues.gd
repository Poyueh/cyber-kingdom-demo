extends RefCounted
## Continuous effect loops: how loud each should sit right now.
## Read-only observer: it never touches the model.
const LOOPS := ["horse_gallop", "dragon_wing", "seal_progress"]
const EARSHOT := 1200.0
const MOVING := 8.0

var _x := 0.0
var _started := false

func sample(sim, x: float, seconds: float, paused: bool) -> Dictionary:
	var mix := {}
	for loop in LOOPS: mix[loop] = 0.0
	if sim == null or paused:
		_x = x
		_started = true
		return mix
	var moving: bool = _started and seconds > 0 and absf(x - _x) / seconds >= MOVING
	if moving and sim.has_method("mounted") and sim.mounted(): mix.horse_gallop = 1.0
	for raider in sim.raiders:
		if raider.get("kind", "") == "dragon" and raider.fighter.is_alive() and absf(raider.x - x) <= EARSHOT:
			mix.dragon_wing = 1.0
	for rift in sim.mission.rifts:
		if rift.progress > 0 and not rift.sealed and absf(rift.x - x) <= EARSHOT:
			mix.seal_progress = 1.0
	_x = x
	_started = true
	return mix
