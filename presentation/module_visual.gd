extends RefCounted
static func relics(view: Node2D, sim: RefCounted) -> void:
 if not sim.life.enabled:return
 for relic in sim.modules.relics:
  if sim.modules.found.has(relic.id) or not sim.frontier.regions[relic.region].discovered or not view._on_screen(relic.x,100):continue
  var alpha: float=view._region_reveal(relic.region)
  var at: Vector2=Vector2(relic.x,430)
  view.draw_rect(Rect2(at+Vector2(-17,-9),Vector2(34,9)),Color(0.2,0.28,0.32,alpha))
  view.draw_rect(Rect2(at+Vector2(-12,-13),Vector2(24,4)),Color(0.48,0.59,0.62,alpha))
  var rise: float=roundf(sin(sim.workforce.elapsed*2.0)*3)*2
  var color: Color=Color("7cffdb") if relic.id=="arc" else Color("e2aaff");color.a=alpha
  view._icon("gear" if relic.id=="arc" else "sword",at+Vector2(0,-35+rise),27,color)
  for i in range(3):view.draw_rect(Rect2(at+Vector2(-14+i*12,-18-fposmod(sim.workforce.elapsed*10+i*9,30)),Vector2(2,2)),Color(color,alpha*0.6))
static func effects(view: Node2D, sim: RefCounted) -> void:
 for effect in sim.effects:
  if not view._on_screen(effect.x,340):continue
  var at: Vector2=Vector2(effect.x,392)
  if effect.kind=="module_arc":
   var p: float=1.0-effect.life/0.5
   for i in range(3):view.draw_arc(at,20+p*130-i*8,0,TAU,24,Color(0.42,1,0.85,(1-p)*(1-i*0.2)),3)
  elif effect.kind=="module_lance":
   var alpha: float=effect.life/0.5
   var end: Vector2=at+Vector2(effect.direction*300,0)
   view.draw_line(at,end,Color(0.75,0.4,1,alpha*0.5),12)
   view.draw_line(at,end,Color(0.92,0.92,1,alpha),3)
