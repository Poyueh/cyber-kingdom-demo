extends RefCounted
## Original pixel masonry and a small projection, sharing the guide's palette.
const Ghost=preload("res://presentation/campaign_guide_view.gd")
static func draw_on(canvas: Node2D, at: Vector2, time: float, selected: bool, available: bool) -> void:
 canvas.draw_set_transform(at)
 var stone: Color=Color("5c7276") if selected else Color("394b55")
 canvas.draw_rect(Rect2(-31,-6,62,6),Color("152731"))
 canvas.draw_rect(Rect2(-27,-12,54,7),stone)
 canvas.draw_rect(Rect2(-21,-17,42,5),Color("82908a"))
 canvas.draw_rect(Rect2(-17,-32,34,15),Color("243943"))
 canvas.draw_rect(Rect2(-17,-32,34,3),stone)
 canvas.draw_rect(Rect2(-19,-36,38,4),Color("b59769"))
 for side in [-1,1]:
  canvas.draw_rect(Rect2(side*22-4,-48,8,34),Color("182e3b"))
  canvas.draw_rect(Rect2(side*22-4,-48,8,4),Color("b59769"))
  canvas.draw_rect(Rect2(side*22-1,-41,2,19),Color("62b7b0") if available else stone)
 canvas.draw_rect(Rect2(-2,-27,4,7),Color("b0edd5"))
 var bob: float=roundf(sin(time*2)*2)*2
 var alpha: float=(0.75+0.15*sin(time*2.5)) if available else 0.25
 for y in range(Ghost.GHOST.size()):
  for x in range(Ghost.GHOST[y].length()):
   var ink: String=Ghost.GHOST[y][x]
   if not Ghost.PALETTE.has(ink):continue
   var color: Color=Ghost.PALETTE[ink];color.a=alpha
   canvas.draw_rect(Rect2(x*2-16,y*2-89+bob,2,2),color)
 if available:
  for i in range(3):
   var rise: float=fposmod(time*0.4+i*0.33,1)
   canvas.draw_rect(Rect2(-12+i*12,-36-rise*18,2,2),Color(0.5,0.9,0.82,1-rise))
 canvas.draw_set_transform(Vector2.ZERO)
