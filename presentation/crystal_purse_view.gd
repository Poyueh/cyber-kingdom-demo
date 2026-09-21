extends Node2D
## Screen-fixed leather purse; only fullness is shown, never a numerical counter.
const PURSE=preload("res://art/ui/purse-v001/purse.png")
const GEMS: Array[Vector2]=[Vector2(28,29),Vector2(36,30),Vector2(44,30),Vector2(52,29),Vector2(24,24),Vector2(32,24),Vector2(40,24),Vector2(48,24),Vector2(56,24),Vector2(32,19),Vector2(40,18),Vector2(48,19)]
var bounds: Rect2=Rect2()
var _fill: float=0.0
var _shown: float=-1.0
var _pulse: float=0.0
var _age: float=0.0
var _paused: bool=false
func present(fullness: float, area: Rect2, stopped: bool) -> void:
 bounds=Rect2(area.end-Vector2(112,112),Vector2(96,96))
 _paused=stopped
 if _shown<0:_shown=fullness
 elif not is_equal_approx(_fill,fullness):_pulse=0.3
 _fill=clampf(fullness,0,1)
 queue_redraw()
func _process(seconds: float) -> void:
 if not visible or _paused:return
 _age=fposmod(_age+seconds,120.0)
 _pulse=maxf(0,_pulse-seconds)
 _shown=move_toward(_shown,_fill,seconds*1.8)
 queue_redraw()
func _draw() -> void:
 var bounce: float=sin(_pulse/0.3*PI)*0.045
 var scale_factor: float=bounds.size.x/80
 draw_set_transform(bounds.get_center(),0,Vector2(1+bounce,1-bounce)*scale_factor)
 draw_texture(PURSE,Vector2(-40,-40))
 for i in range(ceili(_shown*GEMS.size())):
  var at: Vector2=GEMS[i]-Vector2(40,40)
  var shape:=PackedVector2Array([at+Vector2(0,-5),at+Vector2(3,0),at+Vector2(0,5),at+Vector2(-3,0)])
  draw_colored_polygon(shape,Color("386e79"))
  draw_colored_polygon(PackedVector2Array([at+Vector2(0,-4),at+Vector2(2,0),at+Vector2(0,4),at+Vector2(-2,0)]),Color("85d8c6"))
  draw_line(at+Vector2(0,-3),at+Vector2(-1,0),Color("deffe4"),1)
 if _shown>0.9:
  var glint: float=maxf(0,sin(_age*2.2))*0.7
  draw_line(Vector2(-2,-25),Vector2(2,-25),Color(0.8,1,0.9,glint),1)
  draw_line(Vector2(0,-27),Vector2(0,-23),Color(0.8,1,0.9,glint),1)
 draw_set_transform(Vector2.ZERO)
