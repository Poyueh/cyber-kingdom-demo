extends RefCounted
## Legacy-world adapter; activity anchors keep travel speed out of all combat ranges.
const March=preload("res://domain/invasion_march.gd")
static func speed(enemy: Dictionary, base: float, hero_x: float, world: RefCounted, buildings: Dictionary, profile: March) -> float:
	if not profile.enabled or enemy.get("kind","") in ["dragon","warden"]:return base
	var nearest: float=minf(absf(enemy.x-hero_x),absf(enemy.x-world.sites.hall))
	if nearest<=profile.caution_radius:return base
	for person: Dictionary in world.people:
		if person.role=="wanderer":continue
		nearest=minf(nearest,absf(enemy.x-person.x))
		if nearest<=profile.caution_radius:return base
	for id: String in world.walls:
		var wall: Dictionary=world.walls[id]
		if wall.hp<=0 and not wall.pending:continue
		nearest=minf(nearest,absf(enemy.x-world.sites[id]))
		if nearest<=profile.caution_radius:return base
	for id: String in buildings:
		var site: Dictionary=buildings[id]
		if site.kind!="tower" or (site.level<=0 and not site.pending):continue
		nearest=minf(nearest,absf(enemy.x-site.x))
		if nearest<=profile.caution_radius:return base
	return profile.speed(base,nearest)
