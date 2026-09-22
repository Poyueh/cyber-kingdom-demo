extends RefCounted
## A brief sunrise seal: safe-area anchored, no permanent HUD or extra font assets.
const DURATION: float=4.6
static func draw(canvas: Node2D, font: Font, safe: Rect2, day: int, remaining: float, caption: String) -> void:
 var age: float=DURATION-remaining
 var alpha: float=smoothstep(0.0,0.65,age)*smoothstep(0.0,1.25,remaining)
 var center: Vector2=Vector2(roundf(safe.get_center().x),safe.position.y+55+6*(1-smoothstep(0,1,age)))
 var gold: Color=Color(0.92,0.81,0.56,alpha)
 var dim: Color=Color(0.52,0.78,0.77,alpha*0.6)
 var reveal: float=smoothstep(0.15,1.3,age)
 for side: int in [-1,1]:
  canvas.draw_line(center+Vector2(side*28,10),center+Vector2(side*(28+63*reveal),10),dim,1)
  var jewel: Vector2=center+Vector2(side*98,10)
  canvas.draw_polyline(PackedVector2Array([jewel+Vector2(-3,0),jewel+Vector2(0,-3),jewel+Vector2(3,0),jewel+Vector2(0,3),jewel+Vector2(-3,0)]),Color(gold,alpha*reveal),1)
 # Sunrise arc with seven rays, rising into the engraved horizon.
 canvas.draw_arc(center+Vector2(0,10),12,PI,TAU,17,gold,2)
 canvas.draw_line(center+Vector2(-19,10),center+Vector2(19,10),gold,1)
 for index: int in range(7):
  var direction: Vector2=Vector2.from_angle(PI+index*PI/6)
  canvas.draw_line(center+Vector2(0,10)+direction*17,center+Vector2(0,10)+direction*(20+2*reveal),dim,1)
 var label: String=caption%day
 var width: float=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
 canvas.draw_string(font,center+Vector2(-width/2,41),label,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(0.94,0.92,0.79,alpha))
