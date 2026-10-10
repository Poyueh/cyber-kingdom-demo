extends RefCounted
const Junction=preload("res://art/structures/mount-v001/junction.png")
const Cradle=preload("res://art/structures/mount-v001/cradle.png")
const Stable=preload("res://art/structures/mount-v001/stable.png")
const Ruins=preload("res://presentation/ruin_visual.gd")
const Known=preload("res://application/ruin_interactions.gd")
const Icons=preload("res://presentation/ui_icons.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
static func draw_on(view: Node2D, sim: RefCounted) -> void:
 var q: RefCounted=sim.mount_quest
 if not sim.life.enabled:return
 if q.warning(roundi(sim.workforce.elapsed*Clock.TICKS_PER_SECOND)):
  var pulse: float=maxf(0,sin(sim.workforce.elapsed*1.4))
  if pulse>0.15:
   var inverse: Transform2D=view.get_viewport().get_canvas_transform().affine_inverse()
   for side: int in [-1,1]:
    if not sim.mission.side_open(side):continue
    var edge: float=(inverse*Vector2(40 if side<0 else view.get_viewport_rect().size.x-40,150)).x
    view.draw_texture_rect(Icons.get_icon("rift"),Rect2(edge-15,284,30,30),false,Color(1,0.48,0.25,pulse*0.8))
 if q.enabled:
  for index: int in range(2):_junction(view,sim,index)
  if Known.known(sim,q.ruin_x) and view._on_screen(q.ruin_x,210):
   var tint:=Color.WHITE; tint.a=Ruins._reveal(view,sim,q.ruin_x)
   if q.recovered:tint=Color(0.38,0.48,0.5,tint.a)
   _prop(view,Cradle,q.ruin_x,tint)
   if absf(view._view_player_x-q.ruin_x)<120 and not q.recovered:
    Ruins._caption(view,Vector2(q.ruin_x,223),"喚醒機械戰馬" if q.powered() else "沿纜線對準兩座導流器",Color("c5e9df"))
   if q.powered() and not q.recovered:
    view.draw_arc(Vector2(q.ruin_x,356),36,-PI,PI,20,Color(0.3,1,0.82,0.5+sin(sim.workforce.elapsed*3)*0.2),2)
 if (q.recovered or q.unlocked) and sim.frontier.city_level>0 and view._on_screen(q.stable_x,200):
  var tint:=Color.WHITE if q.unlocked else Color(0.53,0.66,0.67,0.75)
  if absf(view._view_player_x-q.stable_x)<65:tint=tint.lightened(0.3)
  _prop(view,Stable,q.stable_x,tint)
  if absf(view._view_player_x-q.stable_x)<90:
   var key: String=("下馬" if q.riding else "騎乘機械戰馬") if q.unlocked else "修復馬廄"
   Ruins._caption(view,Vector2(q.stable_x,223),key,Color("e2d0a5"))
static func _prop(view: Node2D, texture: Texture2D, x: float, tint: Color) -> void:
 view.draw_texture(texture,Vector2(roundf(x-texture.get_width()*0.5),430-texture.get_height()),tint)
static func _junction(view: Node2D, sim: RefCounted, index: int) -> void:
 var q: RefCounted=sim.mount_quest
 var x: float=q.levers[index]
 if not Known.known(sim,x) or not view._on_screen(x,400):return
 var alpha: float=Ruins._reveal(view,sim,x)
 var aligned: bool=q.rotations[index]==index+1
 var fed: bool=aligned and (index==0 or q.rotations[0]==1)
 var tint:=Color("8af0d0") if fed else Color("a58b62")
 tint.a=alpha
 var next: float=q.levers[1] if index==0 else q.ruin_x
 view.draw_line(Vector2(next,428),Vector2(x,428),Color(0.2,0.29,0.32,alpha),3)
 if fed:
  for k: int in range(5):
   var dot_x: float=lerpf(x,next,fposmod(sim.workforce.elapsed*0.3+k*0.2,1))
   view.draw_rect(Rect2(Vector2(dot_x,426).round(),Vector2(7,3)),tint)
 _prop(view,Junction,x,Color(1,1,1,alpha))
 var center:=Vector2(x-3,394)
 view.draw_circle(center,12,Color(0.06,0.12,0.15,alpha))
 view.draw_arc(center,13,0,TAU,12,tint,2)
 # Permanent bright socket shows the target; the handle shows the current turn.
 var goal: float=-PI*0.5+(index+1)*TAU/3
 var angle: float=-PI*0.5+q.rotations[index]*TAU/3
 view.draw_circle(center+Vector2.from_angle(goal)*20,3,Color(0.45,0.96,0.8,alpha))
 view.draw_line(center,center+Vector2.from_angle(angle)*10,tint,3)
 if absf(view._view_player_x-x)<85 and not q.recovered:
  Ruins._caption(view,Vector2(x,324),"把指針轉向發光接點",tint)
  Ruins._caption(view,Vector2(x,346),"E" if view.keyboard_hint else "↓",tint)
