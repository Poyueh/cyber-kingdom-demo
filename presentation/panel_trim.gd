extends Control
## Pixel-stepped teal gradients and engraved borders, below the panel content.
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 var skin: StyleBox=get_parent().get_theme_stylebox("panel")
 var origin: Vector2=-Vector2(skin.get_content_margin(SIDE_LEFT),skin.get_content_margin(SIDE_TOP))
 var bounds: Vector2=size+Vector2(skin.get_content_margin(SIDE_LEFT)+skin.get_content_margin(SIDE_RIGHT),skin.get_content_margin(SIDE_TOP)+skin.get_content_margin(SIDE_BOTTOM))
 var cosmic: bool=get_parent().has_meta("cosmic")
 if not cosmic:
  for band: int in range(24):
   var weight: float=float(band)/23.0
   var top: float=floorf(4+(bounds.y-8)*band/24)
   var bottom: float=floorf(4+(bounds.y-8)*(band+1)/24)
   var tint: Color=Color("35534b50").lerp(Color("040b1430"),weight)
   draw_rect(Rect2(origin+Vector2(4,top),Vector2(bounds.x-8,bottom-top)),tint)
 draw_rect(Rect2(origin+Vector2(7,7),bounds-Vector2(14,14)),Color("617c7740"),false,1)
 var gold: Color=Color("bfa36d9c")
 for side: int in [-1,1]:
  var x: float=12.0 if side<0 else bounds.x-12.0
  var inward: float=-side
  for y: float in [12.0,bounds.y-12.0]:
   var down: float=1.0 if y<bounds.y*0.5 else -1.0
   var at: Vector2=origin+Vector2(x,y)
   draw_line(at,at+Vector2(inward*34,0),gold,2)
   draw_line(at,at+Vector2(0,down*18),gold,2)
   draw_polyline(PackedVector2Array([at+Vector2(inward*4,down*12),at+Vector2(inward*4,down*4),at+Vector2(inward*20,down*4)]),Color("75958b80"),1)
   draw_rect(Rect2(at+Vector2(inward*26-1,down*5-1),Vector2(2,2)),gold)
 # Sparse symmetrical diamonds stay at the edge, clear of the reading area.
 for step: int in range(3):
  var x: float=bounds.x*0.5+(step-1)*12
  var at: Vector2=origin+Vector2(x,7)
  draw_polyline(PackedVector2Array([at+Vector2(0,-3),at+Vector2(3,0),at+Vector2(0,3),at+Vector2(-3,0),at+Vector2(0,-3)]),gold,1)
