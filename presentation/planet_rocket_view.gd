extends RefCounted
const Ground=preload("res://presentation/grounded_art.gd")
const ATLAS=preload("res://art/planets/v001/rocket.png")
const Ops=preload("res://application/planet_operations.gd")
static func draw_on(view: Node2D, sim: RefCounted) -> void:
 if not sim.planet.enabled:return
 var time: float=sim.workforce.elapsed
 var x: float=Ops.rocket_x(sim)
 if view._on_screen(x,180) and (sim.planet.reactor or sim.planet.wrecked):
  var frame: int=2 if sim.planet.rocket_ready else (1 if sim.planet.rocket_pending else 0)
  var tint: Color=Color(1.2,1.35,1.35) if absf(view._view_player_x-x)<73 else Color.WHITE
  var source:=Rect2i(frame*180,0,180,188)
  view.draw_texture_rect_region(ATLAS,Ground.frame_rect(ATLAS,source,Vector2(roundf(x),430)),Rect2(source),tint)
  view._icon("map" if sim.planet.rocket_ready else "hammer",Vector2(x,218),29,Color("9de0db"))
  if sim.planet.rocket_pending:
   view.draw_line(Vector2(x-32,237),Vector2(x+32,237),Color("24434d"),4)
   view.draw_line(Vector2(x-32,237),Vector2(x-32+64*sim.planet.work/sim.planet.work_required,237),Color("8ce4de"),4)
static func draw_details(view: Node2D, sim: RefCounted) -> void:
 if not sim.planet.enabled:return
 var time: float=sim.workforce.elapsed
 var core: float=Ops.core_x(sim)
 if sim.planet.cleared and not sim.planet.core_claimed and view._on_screen(core):
  view._icon("crystal",Vector2(core,389+sin(time*2.8)*5),43,Color("a6fbeb"))
  view.draw_arc(Vector2(core,389),29,time, time+4.2,20,Color("66bcb0"),2)
 for effect: Dictionary in sim.effects:
  if effect.kind!="planet_strike":continue
  if not view._on_screen(effect.x,250):continue
  preload("res://presentation/dragon_elements.gd").draw(view,sim,effect)
