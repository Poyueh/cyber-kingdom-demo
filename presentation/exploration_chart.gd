extends Control
const Icons=preload("res://presentation/ui_icons.gd")
signal region_selected(title: String)
var survey: Dictionary={}
var _selected_x: float=INF
const COLORS: Dictionary={"forest":Color("416d5b"),"quarry":Color("526e83"),"ruins":Color("866d65"),"unknown":Color("202f3a")}
const GOLD=Color("dbbd83")
func _ready() -> void:
 custom_minimum_size=Vector2(280,190)
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(queue_redraw)
func present(data: Dictionary) -> void:
 survey=data;_selected_x=INF;queue_redraw()
func _map_x(world_x: float) -> float:
 return 26+(size.x-52)*inverse_lerp(survey.left,survey.right,world_x)
func _marker_y(kind: String) -> float:
 return 25 if kind in ["gear","lock"] else 66 if kind=="chest" else 156
func _draw() -> void:
 if survey.is_empty():return
 draw_rect(Rect2(Vector2.ZERO,size),Color("0c1922"))
 for x: int in range(14,int(size.x),28):draw_line(Vector2(x,8),Vector2(x,size.y-8),Color(0.24,0.42,0.45,0.10),1)
 for y: int in range(14,int(size.y),28):draw_line(Vector2(8,y),Vector2(size.x-8,y),Color(0.24,0.42,0.45,0.10),1)
 for corner: Vector2 in [Vector2(0,0),Vector2(size.x,0),Vector2(0,size.y),size]:
  var inward:=Vector2(1 if corner.x==0 else -1,1 if corner.y==0 else -1)
  draw_line(corner,corner+Vector2(inward.x*16,0),GOLD,2)
  draw_line(corner,corner+Vector2(0,inward.y*12),GOLD,2)
 draw_line(Vector2(26,120),Vector2(size.x-26,120),Color("52666a"),1)
 for region: Dictionary in survey.regions:_terrain(region)
 for marker: Dictionary in survey.markers:
  var x: float=_map_x(marker.x)
  var at:=Vector2(x,_marker_y(marker.kind))
  draw_line(Vector2(x,118),at,Color(0.55,0.76,0.72,0.3),1)
  draw_circle(at,17,Color("172c34"))
  draw_arc(at,17,0,TAU,24,Color("647e77"),1)
  draw_texture_rect(Icons.get_icon(marker.kind),Rect2(at-Vector2(11,11),Vector2(22,22)),false,Color("e7d4ad"))
  draw_circle(Vector2(x,120),2,GOLD)
 var knight_x: float=_map_x(survey.knight)
 draw_line(Vector2(knight_x,98),Vector2(knight_x,128),GOLD,2)
 draw_colored_polygon(PackedVector2Array([Vector2(knight_x-6,87),Vector2(knight_x+6,87),Vector2(knight_x,96)]),Color("ffe0a0"))
 if is_finite(_selected_x):
  var x: float=_map_x(_selected_x)
  draw_arc(Vector2(x,120),9,0,TAU,16,Color("a1f1d6"),2)
func _terrain(region: Dictionary) -> void:
 var left: float=_map_x(region.x)+1
 var right: float=_map_x(region.x+region.width)-1
 var width: float=maxf(1,right-left)
 var color: Color=COLORS[region.kind]
 if region.kind=="unknown":
  for dot: int in range(3):draw_circle(Vector2(left+width*(dot+0.5)/3,115),1,Color("44565e"))
  return
 var heights:=PackedFloat32Array([7,19,9,25,12,17,5] if region.kind=="forest" else [5,9,28,14,23,8,4] if region.kind=="quarry" else [4,22,22,10,27,27,5])
 var points:=PackedVector2Array([Vector2(left,117)])
 for i: int in range(heights.size()):points.append(Vector2(left+width*i/(heights.size()-1),117-heights[i]))
 points.append(Vector2(right,117))
 draw_colored_polygon(points,color)
 draw_line(Vector2(left,121),Vector2(right,121),color.lightened(0.25),2)
 draw_line(Vector2(left,129),Vector2(right,129),Color(color,0.3),1)
func _gui_input(event: InputEvent) -> void:
 if survey.is_empty():return
 var clicked: bool=(event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)
 if not clicked:return
 var at: Vector2=event.position
 for marker: Dictionary in survey.markers:
  if at.distance_to(Vector2(_map_x(marker.x),_marker_y(marker.kind)))<=22:
   _select(marker.x,marker.title);return
 for region: Dictionary in survey.regions:
  if at.x>=_map_x(region.x) and at.x<=_map_x(region.x+region.width):
   _select(region.x+region.width*0.5,region.title);return
 _select(survey.knight,"營火腹地")
func _select(x: float, title: String) -> void:
 _selected_x=x;region_selected.emit(title);queue_redraw();accept_event()
