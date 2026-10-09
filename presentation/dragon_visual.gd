extends RefCounted
## Four aligned generated pixel poses; animation uses simulation time, so pause freezes it.
const SHEET=preload("res://art/characters/dragon-v001/dragon.png")
const BIOMES=[preload("res://art/planets/v001/sand-dragon.png"),preload("res://art/planets/v001/frost-dragon.png")]
static func draw(view: Node2D, enemy: Dictionary, time: float) -> void:
 if not enemy.fighter.is_alive():return
 if view._sim.planet.enabled and view._sim.planet.id>0:
  draw_biome(view,enemy,time);return
 var hit: Dictionary=view.hit_feedback.enemy_pose(enemy)
 var direction: float=enemy.get("direction",-1.0)
 var frame: int=3 if enemy.windup>0 else [0,2,0,1][int(time*3.2)%4]
 var breathing:=sin(time*2.6)*1.5
 var tint:=Color.WHITE.lerp(Color(1.8,1.3,1.1),hit.flash)
 view.draw_set_transform(Vector2(enemy.x,430)+hit.offset*0.4,hit.rotation*0.12,Vector2(-direction,1)*Vector2(1,1-(1-hit.scale.y)*0.3))
 view.draw_texture_rect_region(SHEET,Rect2(-172,-245+breathing,307.2,249.6-breathing),Rect2(frame*256,0,256,208),tint)
 view.draw_set_transform(Vector2.ZERO)
 if enemy.windup>0:
  var aim: float=enemy.target.x
  var progress: float=1-enemy.windup/1.6
  view.draw_line(Vector2(aim-100,428),Vector2(aim+100,428),Color(1,0.53,0.3,0.5+progress*0.4),4)
  for i in range(12):
   var point: Vector2=Vector2(enemy.x+direction*132,300)+Vector2(cos(i*2.1+time*7),sin(i*2.1+time*7))*((1-progress)*25+4)
   view.draw_rect(Rect2(point.round(),Vector2(3,3)),Color("ffd694"))

static func draw_fallen(view: Node2D, body: Dictionary, progress: float) -> void:
 if view._sim.planet.enabled and view._sim.planet.id>0:
  view.draw_texture_rect_region(BIOMES[view._sim.planet.id-1],Rect2(body.x-160,210,320,224),Rect2(960,0,320,224),Color(1,1,1,1-progress));return
 view.draw_set_transform(Vector2(body.x,430),0,Vector2(-body.direction,1-progress*0.4))
 view.draw_texture_rect_region(SHEET,Rect2(-172,-245,307.2,249.6),Rect2(0,0,256,208),Color(1.4,0.9,0.8,1-progress))
 view.draw_set_transform(Vector2.ZERO)

static func draw_biome(view: Node2D, enemy: Dictionary, time: float) -> void:
 var id: int=view._sim.planet.id-1
 var frame: int=2 if enemy.windup>0 else (3 if enemy.cooldown>3 else int(time*3)%2)
 var hit: Dictionary=view.hit_feedback.enemy_pose(enemy)
 # Generated creatures face left; never stretch individual limbs or poses.
 view.draw_set_transform(Vector2(round(enemy.x),430)+hit.offset*0.3,0,Vector2(-enemy.direction,1))
 view.draw_texture_rect_region(BIOMES[id],Rect2(-160,-220,320,224),Rect2(frame*320,0,320,224),Color.WHITE.lerp(Color(1.7,1.5,1.4),hit.flash))
 view.draw_set_transform(Vector2.ZERO)
 if enemy.windup>0:
  var aim: float=enemy.target.x
  var radius: float=105 if id==0 else 85
  var tint: Color=Color("efa754") if id==0 else Color("98e9ff")
  tint.a=0.6+sin(time*14)*0.25
  view.draw_line(Vector2(aim-radius,428),Vector2(aim+radius,428),tint,4)
  for i: int in range(7):view.draw_rect(Rect2(aim-radius+i*radius/3,420,3,7),tint)
