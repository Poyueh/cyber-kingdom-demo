extends Resource
## A hunting trip stays near the current completed walls, even after expansion.
const CATCH_CRYSTALS: int=2
@export_range(100,600,10) var wall_margin: float=300.0
@export_range(40,400,5) var patrol_depth: float=220.0
@export_range(20,100,5) var patrol_radius: float=65.0

func configuration() -> Dictionary:
 return {"hunt_wall_margin":wall_margin,"hunt_patrol_depth":patrol_depth,"hunt_patrol_radius":patrol_radius}

func apply(config: Dictionary) -> void:
 wall_margin=clampf(float(config.get("hunt_wall_margin",wall_margin)),100,600)
 patrol_depth=clampf(float(config.get("hunt_patrol_depth",patrol_depth)),40,400)
 patrol_radius=clampf(float(config.get("hunt_patrol_radius",patrol_radius)),20,100)

func contains(x: float, left: float, right: float) -> bool:
 return x>=left-wall_margin and x<=right+wall_margin

static func valid(config: Dictionary) -> bool:
 for key: String in ["hunt_wall_margin","hunt_patrol_depth","hunt_patrol_radius"]:
  if not config.has(key):continue
  var limits: Vector2={"hunt_wall_margin":Vector2(100,600),"hunt_patrol_depth":Vector2(40,400),"hunt_patrol_radius":Vector2(20,100)}[key]
  if not preload("res://domain/trail_rules.gd").number(config[key],limits.x,limits.y):return false
 return true
