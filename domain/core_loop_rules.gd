extends RefCounted
const LIMITS: Dictionary={"core_loop_version":Vector2(1,1),"core_enemy_health":Vector2(1,200),"core_enemy_damage":Vector2(1,50),"core_wall_damage":Vector2(1,50),"core_warning":Vector2(20,90),"core_min_defenders":Vector2(1,3),"core_arrival_radius":Vector2(16,80),"core_sprint_ratio":Vector2(0.2,0.8),"core_second_gap":Vector2(10,40)}
static func valid(config: Dictionary) -> bool:
 if not LIMITS.keys().any(func(k: String) -> bool:return config.has(k)):return true
 for key: String in LIMITS:
  var value: Variant=config.get(key)
  if not (value is int or value is float) or not is_finite(float(value)):return false
  if value<LIMITS[key].x or value>LIMITS[key].y:return false
 for key: String in preload("res://domain/trail_rules.gd").LIMITS:
  var bounds: Vector2=preload("res://domain/trail_rules.gd").LIMITS[key]
  var value: Variant=config.get("core_trail_"+key)
  if not preload("res://domain/trail_rules.gd").number(value,bounds.x,bounds.y,key in preload("res://domain/trail_rules.gd").WHOLE):return false
 if config.core_trail_combat_side!=1 or config.core_trail_guard_count!=1:return false
 return config.core_loop_version==1 and config.core_min_defenders==floorf(config.core_min_defenders) and config.get("voyage_enabled",0)==0
