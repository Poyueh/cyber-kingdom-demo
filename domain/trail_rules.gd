extends RefCounted
## Creation-only roadside moments, resolved from the already-authored route.
const Level=preload("res://domain/planet_level_layout.gd")
const PREFIX: String="trail_"
const VERSION: int=1
const LIMITS: Dictionary[String,Vector2]={
	"combat_side":Vector2(-1,1),"guard_count":Vector2(1,2),"health":Vector2(18,160),
	"damage":Vector2(1,30),"speed":Vector2(30,110),"windup_seconds":Vector2(0.75,2),
	"recovery_seconds":Vector2(1.5,3),"reach":Vector2(25,120),"charge_distance":Vector2(0,180),
	"charge_seconds":Vector2(0.25,0.8),"territory":Vector2(150,210),"notice":Vector2(180,240),
	"combat_reward":Vector2(1,4),"discovery_reward":Vector2(1,3)}
const WHOLE: Array[String]=["combat_side","guard_count","health","damage","combat_reward","discovery_reward"]
static func number(value: Variant, lo: float, hi: float, whole: bool=false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=lo and value<=hi and (not whole or floorf(value)==value)
static func apply(config: Dictionary, profiles: Array[Dictionary]) -> void:
	assert(profiles.size()==7 and Level.valid_config(config) and config.has(Level.MARKER))
	var profile: Dictionary=profiles[int(config.planet_id)]
	assert(profile.planet_id==config.planet_id and profile.size()==LIMITS.size()+1)
	config.trail_version=VERSION
	for key: String in LIMITS:config[PREFIX+key]=profile[key]
	for side: int in [-1,1]:
		for zone: Level.Zone in Level.zones(config.economy):
			if zone.side!=side or zone.role!=Level.Role.VISTA:continue
			var name: String="combat" if side==int(profile.combat_side) else "discovery"
			config[PREFIX+name+"_region"]=zone.index
			config[PREFIX+name+"_x"]=zone.x+zone.width*0.5
			break
	assert(valid_config(config),"Roadside moments must stay inside separate wilderness rooms")
static func valid_config(config: Dictionary) -> bool:
	if config.has("trail_design"):return false
	if not config.has("trail_version"):
		return not config.keys().any(func(key: String)->bool:return key.begins_with(PREFIX))
	if not number(config.trail_version,VERSION,VERSION,true) or not config.has(Level.MARKER):return false
	if not Level.valid_config(config):return false
	var allowed: Array[String]=["trail_version"]
	for key: String in LIMITS:
		var bounds: Vector2=LIMITS[key]
		if not number(config.get(PREFIX+key),bounds.x,bounds.y,key in WHOLE):return false
		allowed.append(PREFIX+key)
	if config.trail_combat_side==0:return false
	var zones: Array[Level.Zone]=Level.zones(config.economy)
	for name: String in ["combat","discovery"]:
		var region_key: String=PREFIX+name+"_region"
		var x_key: String=PREFIX+name+"_x"
		allowed.append(region_key);allowed.append(x_key)
		if not number(config.get(region_key),0,zones.size()-1,true):return false
		var zone: Level.Zone=zones[int(config[region_key])]
		if zone.role!=Level.Role.VISTA or zone.side!=int(config.trail_combat_side)*(1 if name=="combat" else -1):return false
		if not number(config.get(x_key),zone.x+zone.width*0.5,zone.x+zone.width*0.5):return false
		if zone.width*0.5<float(config.trail_territory)+35:return false
	for key: String in config:
		if key.begins_with(PREFIX) and not key in allowed:return false
	return true
