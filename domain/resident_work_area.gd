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
	return Vector2(_edge(-1),_edge(1))
func contains(x: float) -> bool:
	var span: Vector2=bounds()
	return x>=span.x and x<=span.y
func clamp_target(x: float) -> float:
	var span: Vector2=bounds()
	return clampf(x,span.x,span.y)

func _edge(side: int) -> float:
	var post: String=_defenses.active_post(side)
	var at: float=_world.sites[post]
	var fallback: float=at+side*_margin
	var regions: Array[Dictionary]=_defenses.frontier.regions
	if regions.is_empty() or not regions[0].has("level_role"):return fallback
	# Authored routes connect one supply clearing at a time. A wall within a
	# clearing keeps ordinary local reach; its completed outer edge opens the gap.
	var ready: bool=post in ["wall","wall_left"]
	if not ready:
		for region: Dictionary in regions:
			if region.level_role==0 and signf(region.x)==side:
				var outer: float=region.x+(region.width if side>0 else 0.0)
				if absf(at-outer)<1:ready=true;break
	if not ready:return fallback
	for region: Dictionary in regions:
		if region.level_role!=0 or signf(region.x)!=side:continue
		var outer: float=region.x+(region.width if side>0 else 0.0)
		if side*(outer-at)>1:return outer
	return fallback
