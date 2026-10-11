extends RefCounted
## Distinct facility keepers are visual staff, never fabricated free workers.
const Cast=preload("res://data/settlement_identity.tres")
static func draw_on(view: Node2D, sim: RefCounted, hero_x: float) -> void:
	if sim.frontier.city_level==0:return
	assert(Cast.valid())
	for index: int in range(Cast.sites.size()):
		var site: StringName=Cast.sites[index]
		if not sim.site_visible(site):continue
		if site not in [&"hall",&"drill"] and not sim.built.get(site,false):continue
		var at: Vector2=Vector2(sim.world.sites[site],430)+Cast.offsets[index]
		if not view._on_screen(at.x,Cast.cell.x):continue
		if sim.raiders.any(func(e: Dictionary)->bool:return e.fighter.is_alive() and absf(e.x-at.x)<180):continue
		var frame: int=Cast.cycle[posmod(floori(sim.workforce.elapsed*Cast.frames_per_second)+index,Cast.cycle.size())]
		var facing: float=-1.0 if hero_x<at.x else 1.0
		view.draw_set_transform(at.round(),0,Vector2(facing,1))
		view.draw_texture_rect_region(Cast.attendants,Rect2(-Cast.cell.x*0.5,-Cast.baseline,Cast.cell.x,Cast.cell.y),Rect2(frame*Cast.cell.x,index*Cast.cell.y,Cast.cell.x,Cast.cell.y))
	view.draw_set_transform(Vector2.ZERO)
