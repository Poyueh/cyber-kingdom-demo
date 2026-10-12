extends RefCounted
## One bounded visual transition, reset on restart/load; saved camps never replay.
const Style=preload("res://data/camp_reveal.tres")
const EXTRACTION_SECONDS: float=2.4
var _sim: RefCounted
var _started: float=-1.0
var _age: float=-1.0

static func extracting(sim: RefCounted, player_x: float) -> bool:
	if not sim.life.enabled or not sim.hero.is_alive():return false
	for effect: Dictionary in sim.effects:
		if effect.kind=="camp_ignition" and effect.life>0 and absf(player_x-effect.x)<96:return true
	return false

func present(sim: RefCounted) -> void:
	if not is_same(_sim,sim):
		_sim=sim;_started=-1.0;_age=-1.0
	if _started<0:
		for effect: Dictionary in sim.effects:
			if effect.kind=="camp_ignition":
				_started=maxf(0,sim.workforce.elapsed-(EXTRACTION_SECONDS-effect.life))
				break
	if _started>=0:_age=maxf(0,sim.workforce.elapsed-_started)

func progress() -> float:
	if _age<0:return 1.0
	return smoothstep(EXTRACTION_SECONDS,EXTRACTION_SECONDS+Style.assembly_seconds,_age)

func draw_on(view: Node2D, sim: RefCounted) -> void:
	var amount: float=progress()
	var hall: float=sim.world.sites.hall
	view._prop("stone",Vector2(hall,430),0.45,Color(1,1,1,1-amount))
	if amount<=0:return
	var tint: Color=Color(1,1,1,amount)
	view._prop("hall-%d"%sim.frontier.city_level,Vector2(hall,430),1.0,tint)
	view._prop("campfire",Vector2(hall+104,430),0.7,tint)
	for site: String in ["workshop","hunt_tools","drill"]:
		if site!="drill" and not sim.built.get(site,false):continue
		var at: Vector2=Vector2(sim.world.sites[site],430)
		if not view._on_screen(at.x,320):continue
		view._prop(site,at,1.0,tint)
		preload("res://presentation/construction_scaffold.gd").draw_on(view,at,112,amount,1-amount)
