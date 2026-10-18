extends RefCounted
const Levels=preload("res://domain/planet_level_layout.gd")
const Layout=preload("res://domain/ruin_layout.gd")
const Streams=preload("res://domain/rng/rng_streams.gd")
const Voyage = preload("res://application/star_voyage.gd")
## Resolve new-journey settings once, after biome rules. Loaded configurations are never remapped.
static func create(base: Dictionary, profiles: Array[Dictionary], selected: Dictionary) -> Voyage:
	var journey: Voyage=Voyage.new(base,profiles)
	for config: Dictionary in journey.configs:_finish(config,base,selected)
	return journey

## The Demo's world: the journey's forest, built the same way, but with no voyage.
static func create_forest(base: Dictionary, profile: Dictionary, selected: Dictionary) -> Dictionary:
	var config: Dictionary=base.duplicate(true)
	config.merge(profile,true)
	config.planet_id=0;config.voyage_enabled=0
	config.economy=config.get("economy",{}).duplicate(true)
	config.economy.planet_id=0
	_finish(config,base,selected)
	return config

## Gate layout comes from the planet resource rather than its rules dictionary.
static func gate_rules(profile: Resource) -> Dictionary:
	return {"rift_layout_version":1,"rift_left_count":profile.left_gates,"rift_right_count":profile.right_gates}

static func _finish(config: Dictionary, base: Dictionary, selected: Dictionary) -> void:
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
