extends RefCounted
## Live territorial reach. No cached bounds: a fallen or expanded wall applies immediately.
# The authored 960-wide camera at 1.15 zoom sees roughly 835 world units.
const DEFAULT_MARGIN: float=850.0
const STATION_OFFSET: float=180.0
var _world: RefCounted
var _defenses: RefCounted
var _margin: float
func _init(world: RefCounted, defenses: RefCounted, margin: float=DEFAULT_MARGIN) -> void:
	_world=world;_defenses=defenses;_margin=clampf(margin,200,1600)
func bounds() -> Vector2:
	return Vector2(_world.sites[_defenses.active_post(-1)]-_margin,_world.sites[_defenses.active_post(1)]+_margin)
func contains(x: float) -> bool:
	var span: Vector2=bounds()
	return x>=span.x and x<=span.y
func clamp_target(x: float) -> float:
	var span: Vector2=bounds()
	return clampf(x,span.x,span.y)
