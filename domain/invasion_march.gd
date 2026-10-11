extends RefCounted
## Distance-derived travel adjustment. No timer, camera state or saved entity fields.
const Stats=preload("res://domain/stats/stat_block.gd")
const Buff=preload("res://domain/stats/modifier.gd")
const SOURCE: StringName=&"travel:invasion_march"
const STAT: StringName=&"movement_speed"
var enabled: bool=false
var caution_radius: float=0.0
var _blend_distance: float=0.0
var _multiplier: float=1.0
var _stats: Stats=Stats.new()
var _adjustment: Buff

func _init(config: Dictionary) -> void:
	enabled=config.has("march_version")
	if not enabled:return
	assert(valid_config(config),"Invalid invasion march profile")
	caution_radius=float(config.march_caution_radius)
	_blend_distance=float(config.march_blend_distance)
	_multiplier=float(config.march_multiplier)
	_adjustment=Buff.make(STAT,Buff.Op.MULT,1.0,SOURCE)
	_stats.apply(_adjustment)

func speed(base: float, nearest_activity: float) -> float:
	if not enabled:return base
	_stats.set_base(STAT,base)
	_adjustment.value=lerpf(1.0,_multiplier,clampf((nearest_activity-caution_radius)/_blend_distance,0.0,1.0))
	return _stats.value_of(STAT)

static func valid_config(config: Dictionary) -> bool:
	var limits: Dictionary={"march_version":Vector2(1,1),"march_multiplier":Vector2(1.1,4.0),"march_caution_radius":Vector2(1000,2000),"march_blend_distance":Vector2(200,1200)}
	if not limits.keys().any(func(key: String)->bool:return config.has(key)):return true
	for key: String in limits:
		var value: Variant=config.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):return false
		if value<limits[key].x or value>limits[key].y:return false
	return true
