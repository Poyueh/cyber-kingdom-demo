extends RefCounted
const Levels=preload("res://domain/planet_level_layout.gd")
const Layout=preload("res://domain/ruin_layout.gd")
const Streams=preload("res://domain/rng/rng_streams.gd")
const Voyage = preload("res://application/star_voyage.gd")
## Resolve new-journey settings once, after biome rules. Loaded configurations are never remapped.
static func create(base: Dictionary, profiles: Array[Dictionary], selected: Dictionary) -> Voyage:
	var journey: Voyage=Voyage.new(base,profiles)
	for config: Dictionary in journey.configs:
		var options: Dictionary=base.get("ruin_variation",{})
		config.erase("ruin_variation")
		config.erase("level_design")
		config.erase("trail_design")
		if not options.is_empty():Layout.apply(config,options,Streams.new(int(config.seed)).of(Streams.Stream.RUIN_LAYOUT))
		if base.has("level_design"):Levels.apply(config,base.level_design,Streams.new(int(config.seed)).of(Streams.Stream.LEVEL_LAYOUT))
		if base.has("trail_design"):preload("res://domain/trail_rules.gd").apply(config,base.trail_design)
		config.journey_style=int(selected.id)
		config.day_seconds+=float(selected.day_adjustment)
		config.night_first+=int(selected.first_adjustment)
		config.night_growth+=int(selected.growth_adjustment)
		config.night_limit+=int(selected.limit_adjustment)
	return journey
