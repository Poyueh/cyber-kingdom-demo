extends RefCounted
const ATLAS=preload("res://art/planets/v001/rocket.png")
const Ops=preload("res://application/planet_operations.gd")
static func draw_on(view: Node2D, sim: RefCounted) -> void:
 if not sim.planet.enabled:return
 var time: float=sim.workforce.elapsed
 var x: float=Ops.rocket_x(sim)
 if view._on_screen(x,180) and (sim.planet.reactor or sim.planet.wrecked):
  var frame: int=2 if sim.planet.rocket_ready else (1 if sim.planet.rocket_pending else 0)
  var tint: Color=Color(1.2,1.35,1.35) if absf(view._view_player_x-x)<73 else Color.WHITE
  view.draw_texture_rect_region(ATLAS,Rect2(x-90,246,180,188),Rect2(frame*180,0,180,188),tint)
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
  var id: int=sim.planet.id
  var tint: Color=preload("res://presentation/planet_scenery.gd").TINTS[maxi(0,id-1)].lightened(0.4)
  tint.a=effect.life/0.85
  var radius: float=sim.planet.attack.radius
  if id==5:
   var points: PackedVector2Array=PackedVector2Array()
   for part: int in range(8):points.append(Vector2(effect.x+sin(part*7.2)*18,200+part*32))
   view.draw_polyline(points,tint,5)
   view.draw_line(Vector2(effect.x-radius,428),Vector2(effect.x+radius,428),Color.WHITE*tint.a,3)
  elif id==6:
   view.draw_arc(Vector2(effect.x,400),radius,PI+0.3,TAU+0.3,18,tint,5)
   view.draw_line(Vector2(effect.x-radius,426),Vector2(effect.x+radius,350),tint,3)
  elif id==3:
   for i: int in range(8):
    var at: Vector2=Vector2(effect.x+cos(i*2.4)*radius,412-sin(i*1.7)*26-(0.85-effect.life)*55)
    view.draw_circle(at,5+effect.life*5,tint)
  else:
   for i: int in range(11):
    var at: Vector2=Vector2(effect.x-radius+i*radius/5,428)
    view.draw_colored_polygon(PackedVector2Array([at+Vector2(-8,0),at+Vector2(0,-25-(i%3)*15),at+Vector2(9,0)]),tint)
