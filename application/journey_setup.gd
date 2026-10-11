extends RefCounted
const Layout=preload("res://domain/ruin_layout.gd")
const Streams=preload("res://domain/rng/rng_streams.gd")
const Voyage = preload("res://application/star_voyage.gd")
## Resolve new-journey settings once, after biome rules. Loaded configurations are never remapped.
static func create(base: Dictionary, profiles: Array[Dictionary], selected: Dictionary) -> Voyage:
	var journey: Voyage=Voyage.new(base,profiles)
	for config: Dictionary in journey.configs:
		var options: Dictionary=base.get("ruin_variation",{})
		config.erase("ruin_variation")
		if not options.is_empty():Layout.apply(config,options,Streams.new(int(config.seed)).of(Streams.Stream.RUIN_LAYOUT))
		config.journey_style=int(selected.id)
		config.day_seconds+=float(selected.day_adjustment)
		config.night_first+=int(selected.first_adjustment)
		config.night_growth+=int(selected.growth_adjustment)
		config.night_limit+=int(selected.limit_adjustment)
	return journey
