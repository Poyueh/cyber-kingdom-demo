extends Control
## PanelContainer places children inside content margins; decorate the outer plate.
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 var skin: StyleBox=get_parent().get_theme_stylebox("panel")
 var top_left: Vector2=-Vector2(skin.get_content_margin(SIDE_LEFT),skin.get_content_margin(SIDE_TOP))
 var bounds: Vector2=size+Vector2(skin.get_content_margin(SIDE_LEFT)+skin.get_content_margin(SIDE_RIGHT),skin.get_content_margin(SIDE_TOP)+skin.get_content_margin(SIDE_BOTTOM))
 var gold: Color=Color("b49c6870")
 draw_rect(Rect2(top_left+Vector2(7,7),bounds-Vector2(14,14)),Color("617c7740"),false,1)
 for side: int in [-1,1]:
  var x: float=12.0 if side<0 else bounds.x-12.0
  var inward: float=-side
  for y: float in [12.0,bounds.y-12.0]:
   var down: float=1.0 if y<bounds.y*0.5 else -1.0
   draw_line(top_left+Vector2(x,y),top_left+Vector2(x+inward*18,y),gold,2)
   draw_line(top_left+Vector2(x,y),top_left+Vector2(x,y+down*8),gold,2)
