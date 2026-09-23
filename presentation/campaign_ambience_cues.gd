extends RefCounted
## Decides how loud each ambience bed should be for where the knight is standing.
## Read-only observer: it never touches the model and keeps nothing in the save.
const REGION_BEDS := {"forest": "amb_forest", "quarry": "amb_crystal", "ruins": "amb_ruins"}
const BEDS := ["amb_day", "amb_night", "amb_campfire", "amb_city", "amb_forest", "amb_crystal", "amb_ruins"]
const CAMPFIRE_RANGE := 260.0
const CITY_RANGE := 700.0
const EDGE_FADE := 220.0

func sample(sim, x: float, paused: bool) -> Dictionary:
	var mix := {}
	for bed in BEDS: mix[bed] = 0.0
	if sim == null or paused:
		return mix
	mix.amb_night = 1.0 if sim.clock.is_night else 0.0
	mix.amb_day = 0.0 if sim.clock.is_night else 1.0
	for region in sim.frontier.regions:
		var bed: String = REGION_BEDS.get(region.kind, "")
		if bed.is_empty(): continue
		mix[bed] = maxf(mix[bed], _inside(x, region.x, region.x + region.width))
	if sim.frontier.city_level > 0:
		var hall: float = sim.world.sites.hall
		mix.amb_campfire = _near(x, hall, CAMPFIRE_RANGE)
		if sim.frontier.city_level >= 2:
			mix.amb_city = _near(x, hall, CITY_RANGE)
	return mix

func _inside(x: float, start: float, stop: float) -> float:
	if x < start - EDGE_FADE or x > stop + EDGE_FADE: return 0.0
	if x >= start and x <= stop: return 1.0
	var outside: float = start - x if x < start else x - stop
	return clampf(1.0 - outside / EDGE_FADE, 0.0, 1.0)

func _near(x: float, centre: float, range_units: float) -> float:
	return clampf(1.0 - absf(x - centre) / range_units, 0.0, 1.0)
