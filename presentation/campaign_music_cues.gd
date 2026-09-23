extends RefCounted
## Chooses which music belongs to this moment. Read-only observer: it never touches
## the model, and it keeps no history in the campaign save.
const REFUGE_RANGE := 900.0

var _survived := -1
var _outcome := ""
var _session: RefCounted
var _city := -1

func sample(sim, x: float, paused: bool) -> Dictionary:
	if sim == null:
		return {"track": "title", "layer": "", "sting": ""}
	var fresh: bool = not is_same(_session, sim)
	var result := {"track": _loop(sim, x), "layer": _layer(sim), "sting": ""}
	if not fresh and not paused:
		if sim.mission.outcome != _outcome and sim.mission.outcome in ["victory", "defeat"]:
			result.sting = sim.mission.outcome + "_theme"
		elif _city == 0 and sim.frontier.city_level > 0:
			result.sting = "founding_theme"
		elif sim.clock.survived > _survived:
			result.sting = "dawn_sting"
	_session = sim
	_outcome = sim.mission.outcome
	_survived = sim.clock.survived
	_city = sim.frontier.city_level
	return result

func _loop(sim, x: float) -> String:
	if sim.mission.outcome in ["victory", "defeat"]:
		return ""
	if sim.mission.dragon_summoned and not sim.mission.dragon_defeated:
		return "dragon_boss"
	if sim.clock.is_night:
		return "night_watch"
	var settled: bool = sim.frontier.city_level > 0 and absf(x - sim.world.sites.hall) <= REFUGE_RANGE
	return "day_refuge" if settled else "day_explore"

func _layer(sim) -> String:
	if _loop(sim, sim.world.sites.hall) != "night_watch":
		return ""
	for raider in sim.raiders:
		if raider.fighter.is_alive():
			return "night_raid"
	return ""
