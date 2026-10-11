extends RefCounted
## Stateless tactics. Saved day, queue index and timer completely determine arrivals.
const Clock = preload("res://domain/time/tick_clock.gd")
const BALANCED: StringName = &"balanced"
const PRESSURE: StringName = &"pressure"
const PINCER: StringName = &"pincer"
const STYLES: Array[StringName] = [PRESSURE,PINCER,BALANCED]
const LEGACY_SPACING_TICKS: int = 75
var enabled: bool = false
var first_day: int = 0
var warning_ticks: int = 0
var _gap_ticks: int = 0
var _planet: int = 0

func _init(config: Dictionary) -> void:
	enabled = config.has("night_pattern_version")
	if not enabled: return
	assert(valid_config(config), "Invalid night pattern profile")
	first_day = int(config.night_pattern_first_day)
	warning_ticks = Clock.ticks_for(config.night_pattern_warning)
	_gap_ticks = Clock.ticks_for(config.night_pattern_gap)
	_planet = int(config.get("planet_id",0))

func style(day: int) -> StringName:
	if not enabled or day<first_day: return BALANCED
	return STYLES[(day-first_day+_planet)%3]

func lead_side(day: int) -> int:
	var cycle: int = floori(maxi(0,day-first_day)/3.0)
	return -1 if (cycle+_planet)%2==0 else 1

func split_at(total: int) -> int:
	return ceili(total*0.5)

func side_for(day: int, index: int, total: int) -> int:
	match style(day):
		PRESSURE: return -lead_side(day) if index%4==3 else lead_side(day)
		PINCER: return lead_side(day) if index<split_at(total) else -lead_side(day)
	return 1 if index%2==0 else -1

func gap_after(day: int, used: int, total: int) -> int:
	if style(day)==PINCER and used==split_at(total) and used<total: return _gap_ticks
	return LEGACY_SPACING_TICKS

static func valid_config(config: Dictionary) -> bool:
	var limits: Dictionary = {"night_pattern_version":Vector2(1,1),"night_pattern_first_day":Vector2(3,8),"night_pattern_warning":Vector2(45,120),"night_pattern_gap":Vector2(10,30)}
	if not limits.keys().any(func(k: String)->bool:return config.has(k)): return true
	for key: String in limits:
		var value: Variant = config.get(key)
		if not (value is int or value is float) or not is_finite(float(value)): return false
		if value<limits[key].x or value>limits[key].y or floorf(value)!=value: return false
	return true
