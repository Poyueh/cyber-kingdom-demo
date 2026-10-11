extends Node2D
## Cinematic dust and embers follow confirmed breath; no fake combat or save state.
var _sim: RefCounted
var _age: float=0.0
var _active: bool=false
var _impact_x: float=0.0
var _impact_age: float=100.0
var _seen: Array[Dictionary]=[]
var _time: float=0.0
func present(sim: RefCounted, age: float, active: bool) -> void:
 var delta: float=maxf(0,sim.workforce.elapsed-_time);_time=sim.workforce.elapsed
 _sim=sim;_age=age;_active=active;_impact_age+=delta
 for effect: Dictionary in sim.effects:
  if effect.kind=="dragon_fire" and not _seen.any(func(old: Dictionary)->bool:return is_same(old,effect)):
   _impact_x=effect.to;_impact_age=0.0
 _seen.assign(sim.effects);queue_redraw()
func _draw() -> void:
 if not _active or _sim==null:return
 var inverse: Transform2D=get_viewport().get_canvas_transform().affine_inverse()
 var bounds: Rect2=Rect2(inverse*Vector2.ZERO,get_viewport_rect().size*inverse.get_scale())
 # The arriving mass eclipses the skyline before the close encounter.
 var shadow: float=sin(clampf(_age/2.4,0,1)*PI)*0.30
 draw_rect(bounds,Color(0.015,0.025,0.045,shadow))
 if _impact_age>3.0:return
 var fade: float=1.0-_impact_age/3.0
 if _impact_age<0.12:draw_rect(bounds,Color(1.0,0.65,0.30,(1-_impact_age/0.12)*0.18))
 for index: int in range(32):
  var speed: float=25+index%7*13
  var side: float=-1.0 if index%2==0 else 1.0
  var at: Vector2=Vector2(_impact_x+side*speed*_impact_age,428-sin(minf(1,_impact_age/2)*PI)*(16+index%9*9))
  if not bounds.has_point(at):continue
  draw_rect(Rect2(at.round(),Vector2(3 if index%3 else 5,2)),Color(1.0,0.40+index%4*0.1,0.16,fade))
