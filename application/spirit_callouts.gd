extends RefCounted
## After the guided opening the ghost keeps calling the goal of the moment:
## build, gather crystals, survive the night raid, seal the gates, then the dragon,
## its core and the rocket.
## A read-only projection of the world; it never changes the simulation.
const LOW_CRYSTALS: int = 4

static func goal(sim: RefCounted) -> String:
	if sim.clock.is_night or sim.raiders.any(func(enemy: Dictionary) -> bool: return enemy.fighter.is_alive() and not enemy.has("trail_slot")):
		return "survive"
	if sim.mission.dragon_summoned and not sim.mission.dragon_defeated: return "dragon"
	if sim.planet.enabled and sim.planet.cleared and not sim.planet.rocket_ready:
		return "rocket" if sim.planet.core_claimed else "core"
	var open: bool = sim.mission.rifts.any(func(rift: Dictionary) -> bool: return not rift.get("sealed", false))
	# Gates are sealed with engineers after the two guided nights.
	if open and sim.core_loop.stage >= 5 and sim.pouch.amount >= int(sim.prices.get("rift", LOW_CRYSTALS)): return "seal"
	if sim.pouch.amount < LOW_CRYSTALS: return "gather"
	return "build"

static func next(sim: RefCounted, x: float) -> Dictionary:
	var key: String = "spirit.call." + goal(sim)
	return {"kind": "call_" + goal(sim), "x": x, "y": 430.0, "key": "", "action": "wait", "stage": 0,
		"core": true, "mood": "cheer", "lesson": key, "goal": key}
