extends RefCounted
## Authored pixel furrows and an irrigation channel identify land before planting.
static func draw_on(canvas: Node2D, at: Vector2, selected: bool, alpha: float) -> void:
 var light: float=1.65 if selected else 1.0
 canvas.draw_set_transform(at)
 for row in range(3):
  var ink: Color=Color("564337")*light;ink.a=alpha
  canvas.draw_rect(Rect2(-52+row*5,-13+row*5,100-row*9,4),ink)
  ink=Color("977956")*light;ink.a=alpha
  for col in range(10-row):canvas.draw_rect(Rect2(-50+col*10+row*5,-13+row*5,6,2),ink)
 var water: Color=Color("58aaa5")*light;water.a=alpha
 canvas.draw_rect(Rect2(-61,-11,4,12),water)
 canvas.draw_rect(Rect2(-57,-2,112,2),water.darkened(0.3))
 canvas.draw_rect(Rect2(50,-19,5,18),Color(0.42*light,0.5*light,0.46*light,alpha))
 canvas.draw_rect(Rect2(48,-21,10,4),water)
 canvas.draw_set_transform(Vector2.ZERO)
