extends Control
const Icons=preload("res://presentation/ui_icons.gd")
signal region_selected(title: String)
var survey: Dictionary={}
const COLORS: Dictionary={"forest":Color("396752"),"quarry":Color("426273"),"ruins":Color("725859"),"unknown":Color("263039")}
func _ready() -> void:
 custom_minimum_size=Vector2(280,190)
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(queue_redraw)
func present(data: Dictionary) -> void:
 survey=data;queue_redraw()
func _map_x(world_x: float) -> float:
 return 18+(size.x-36)*inverse_lerp(survey.left,survey.right,world_x)
func _draw() -> void:
 if survey.is_empty():return
 draw_rect(Rect2(18,83,size.x-36,38),Color("263f44"))
 for region: Dictionary in survey.regions:
  var left: float=_map_x(region.x)
  var right: float=_map_x(region.x+region.width)
  draw_rect(Rect2(left+1,83,maxf(1,right-left-2),38),COLORS[region.kind])
  if region.kind=="unknown":
   draw_line(Vector2(left+2,88),Vector2(right-2,115),Color("3b464c"),2)
 for marker: Dictionary in survey.markers:
  var x: float=_map_x(marker.x)
  var y: float=20 if marker.kind=="gear" else 49 if marker.kind=="chest" else 141
  draw_line(Vector2(x,102),Vector2(x,y+12),Color(0.56,0.7,0.68,0.45),1)
  draw_texture_rect(Icons.get_icon(marker.kind),Rect2(x-12,y,24,24),false)
 var knight_x: float=_map_x(survey.knight)
 draw_line(Vector2(knight_x,77),Vector2(knight_x,125),Color("e9ca83"),2)
 draw_colored_polygon(PackedVector2Array([Vector2(knight_x-7,66),Vector2(knight_x+7,66),Vector2(knight_x,76)]),Color("ffe0a0"))
func _gui_input(event: InputEvent) -> void:
 if survey.is_empty():return
 var clicked: bool=(event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)
 if not clicked:return
 var at: Vector2=event.position
 for marker: Dictionary in survey.markers:
  var y: float=20 if marker.kind=="gear" else 49 if marker.kind=="chest" else 141
  if Rect2(_map_x(marker.x)-18,y-6,36,36).has_point(at):
   region_selected.emit(marker.title);accept_event();return
 for region: Dictionary in survey.regions:
  if at.x>=_map_x(region.x) and at.x<=_map_x(region.x+region.width):
   region_selected.emit(region.title);accept_event();return
 region_selected.emit("營火腹地");accept_event()
