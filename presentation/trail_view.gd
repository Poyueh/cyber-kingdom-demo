extends RefCounted
const Ground=preload("res://presentation/grounded_art.gd")
## Local landmarks and telegraphs reflect saved encounter state. No gameplay timers here.
const Trails=preload("res://domain/trail_encounters.gd")
const PROPS=preload("res://art/settlement/inhabitants-v001/trail-props.png")
const COLORS: Array[Color]=[Color("9dcc94"),Color("e7b16a"),Color("a3deeb"),Color("b9d97c"),Color("fa9b65"),Color("91d5ee"),Color("c5a6ed")]
static func draw_on(view: Node2D, sim: RefCounted) -> void:
	var color: Color=COLORS[clampi(sim.planet.id,0,6)]
	for index: int in range(sim.trails.sites.size()):
		var site: Trails.Site=sim.trails.sites[index]
		if not site.revealed or not view._on_screen(site.x,130):continue
		var at: Vector2=Vector2(roundf(site.x),430)
		var glow: float=0.7+sin(sim.workforce.elapsed*2.0)*0.15
		var alpha: float=view._region_reveal(site.region)
		if alpha<=0:continue
		var tint: Color=Color(0.48,0.52,0.55,alpha) if site.claimed else Color(1,1,1,alpha)
		var source:=Rect2i(index*128,sim.planet.id*80,128,80)
		view.draw_texture_rect_region(PROPS,Ground.frame_rect(PROPS,source,at),Rect2(source),tint)
		if site.claimed:continue
		var locked: bool=not sim.trails.available(index)
		view._icon("lock" if locked else "crystal",at+Vector2(0,-57),19,Color(color,glow))
		for i: int in range(3):
			var phase: float=fposmod(sim.workforce.elapsed*0.35+i*0.33,1.0)
			view.draw_rect(Rect2(at+Vector2(-22+i*21,-18-phase*22),Vector2(2,2)),Color(color,glow*(1-phase)))
	for enemy: Dictionary in sim.raiders:
		if not enemy.has("trail_slot") or not enemy.fighter.is_alive() or not view._on_screen(enemy.x,400):continue
		var unit: Trails.Unit=sim.trails.units[int(enemy.trail_slot)]
		if unit.phase!=Trails.Phase.WINDUP:continue
		var progress: float=1-float(unit.remaining)/sim.trails.windup_ticks
		var reach: float=sim.trails.rules.reach
		var left: float=unit.target_x-reach
		var width: float=reach*2
		view.draw_rect(Rect2(left,428,width,3),Color(color,0.22+progress*0.5))
		view.draw_rect(Rect2(left,426,width*progress,2),Color(color,0.55))
		for x: float in [left,left+width]:view.draw_line(Vector2(x,424),Vector2(x,431),Color(color,0.8),2)
	for effect: Dictionary in sim.effects:
		if effect.kind!="trail_impact" or not view._on_screen(effect.x,180):continue
		var progress: float=1-float(effect.life)/0.45
		view.draw_arc(Vector2(effect.x,430),float(effect.to)*progress,PI,TAU,18,Color(color,1-progress),3)
