extends RefCounted
const Voyage = preload("res://application/star_voyage.gd")
## Resolve new-journey settings once, after biome rules. Loaded configurations are never remapped.
static func create(base: Dictionary, profiles: Array[Dictionary], selected: Dictionary) -> Voyage:
	var journey: Voyage=Voyage.new(base,profiles)
	for config: Dictionary in journey.configs:
		config.journey_style=int(selected.id)
		config.day_seconds+=float(selected.day_adjustment)
		config.night_first+=int(selected.first_adjustment)
		config.night_growth+=int(selected.growth_adjustment)
		config.night_limit+=int(selected.limit_adjustment)
	return journey
