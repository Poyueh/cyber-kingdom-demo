extends RefCounted
## Sounds that repeat while something keeps happening. Reports the gap between
## strikes rather than single events, so the player can keep its own rhythm.
## Read-only observer: it never touches the model.
const TRADES := {"tree": "work_chop", "stone": "work_mine",
	"herbs": "work_harvest", "berries": "work_harvest", "crop": "work_harvest"}
const KINDS := ["work_chop", "work_mine", "work_hammer", "work_harvest", "footstep", "footstep_slow"]
const EARSHOT := 800.0
const RUN_SPEED := 90.0
const WALK_SPEED := 18.0
const RUN_GAP := 0.28
const WALK_GAP := 0.44
const STRIKE_GAP := 0.52

var _x := 0.0
var _started := false

func sample(sim, x: float, seconds: float, paused: bool) -> Dictionary:
	var pulse := {}
	for kind in KINDS: pulse[kind] = 0.0
	if sim == null or paused:
		_x = x
		_started = true
		return pulse
	for node in sim.frontier.nodes:
		var trade: String = TRADES.get(node.kind, "")
		if trade.is_empty() or not _struck(sim, node) or absf(node.x - x) > EARSHOT: continue
		pulse[trade] = STRIKE_GAP
	for id in sim.world.walls:
		var wall: Dictionary = sim.world.walls[id]
		if wall.pending and absf(sim.world.sites.get(id, 0.0) - x) <= EARSHOT:
			pulse.work_hammer = STRIKE_GAP
	if _started and seconds > 0 and not (sim.has_method("mounted") and sim.mounted()):
		var speed: float = absf(x - _x) / seconds
		if speed >= RUN_SPEED: pulse.footstep = RUN_GAP
		elif speed >= WALK_SPEED: pulse.footstep_slow = WALK_GAP
	_x = x
	_started = true
	return pulse

func _struck(sim, node) -> bool:
	var worker: int = int(node.worker)
	if worker < 0 or worker >= sim.world.people.size(): return false
	return sim.world.people[worker].get("work_state", "") == "work"
