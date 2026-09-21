extends Node2D
## Bounded moving exhalations; strength eases in the parent presentation only.
var _age: float=0.0
var _weight: float=0.0
var _facing: int=1
var _mounted: bool=false
func present(weight: float, facing: int, seconds: float, active: bool, mounted: bool) -> void:
 _age+=maxf(0,seconds);_weight=weight;_facing=facing;_mounted=mounted
 visible=active and weight>0.05
 if visible:queue_redraw()
func _draw() -> void:
 for index: int in range(2):
  var phase: float=fposmod(_age*1.4+index*0.21,1.0)
  var at: Vector2=Vector2(_facing*(15+phase*14),(-35 if _mounted else -21)-phase*7)
  draw_rect(Rect2(at.round(),Vector2(2,2)),Color(0.78,0.93,0.94,_weight*(1.0-phase)*0.6))
