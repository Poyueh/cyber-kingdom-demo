extends Control
## All visual state is a bounded, read-only projection of the voyage.
signal selected(id: int)
const POSITIONS: Array[Vector2]=[Vector2(48,148),Vector2(169,69),Vector2(169,230),Vector2(313,69),Vector2(313,230),Vector2(441,148),Vector2(559,148)]
const COLORS: Array[Color]=[Color("79bda0"),Color("d3a171"),Color("98d8ec"),Color("b4c57e"),Color("ed9974"),Color("94c9ec"),Color("cf9bcc")]
var buttons: Array[Button]=[]
var _labels: Array[Label]=[]
var _masks: Array[int]=[]
var _open: Array[bool]=[]
var _cores: Array[bool]=[]
var _current: int=0
var selection: int=0
var _time: float=0.0
func _ready() -> void:
 custom_minimum_size=Vector2(580,300)
 for id: int in range(7):
  var button: Button=Button.new();button.flat=true;button.custom_minimum_size=Vector2(70,70)
  button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
  button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
  button.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
  button.pressed.connect(func():selected.emit(id));add_child(button);buttons.append(button)
  var label: Label=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",12);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label);_labels.append(label)
 resized.connect(_layout)
 _layout()
func _layout() -> void:
 for id: int in range(buttons.size()):
  var at: Vector2=_point(id)
  buttons[id].position=at-Vector2(35,35);buttons[id].size=Vector2(70,70)
  _labels[id].position=at+Vector2(-52.0,39);_labels[id].size=Vector2(104,48)
 queue_redraw()
func _point(id: int) -> Vector2:return POSITIONS[id]*Vector2(size.x/608.0,1.0)
func present(journey: RefCounted, sim: RefCounted, names: Array[String]) -> void:
 _current=journey.current;_masks.clear();_open.clear();_cores.clear()
 for id: int in range(7):
  _masks.append(journey.required_mask(id));_open.append(journey.accessible(id,sim));_cores.append(journey.has_core(id,sim))
  _labels[id].text=tr(names[id]);_labels[id].modulate=COLORS[id] if _open[id] else Color("788a9c")
  buttons[id].tooltip_text=tr(names[id])
 _layout()
func _process(delta: float) -> void:
 if not is_visible_in_tree():return
 _time=fmod(_time+delta,100.0);queue_redraw()
func _draw() -> void:
 for index: int in range(65):
  var at: Vector2=Vector2(fposmod(index*127.7, size.x),fposmod(index*83.1,285))
  draw_rect(Rect2(at.round(),Vector2(1,1)),Color("476479"))
 if _masks.size()!=7:return
 for target: int in range(7):
  for source: int in range(7):
   if not (_masks[target] & (1<<source)):continue
   var start: Vector2=_point(source);var end: Vector2=_point(target)
   var color: Color=Color("6caaa9") if _cores[source] else Color("304253")
   draw_dashed_line(start,end,color,2,6)
   var middle: Vector2=start.lerp(end,0.53);var direction: Vector2=(end-start).normalized()
   draw_colored_polygon(PackedVector2Array([middle+direction*5,middle-direction*4+direction.orthogonal()*3,middle-direction*4-direction.orthogonal()*3]),color)
 for id: int in range(7):
  var at: Vector2=_point(id);var color: Color=COLORS[id] if _open[id] else Color("344458")
  if id==selection:draw_arc(at,34,0,TAU,40,Color("ead5a1"),2)
  draw_circle(at,26,color.darkened(0.65));draw_circle(at-Vector2(3,3),21,color)
  draw_arc(at+Vector2(3,0),17,PI*0.28,PI*1.18,20,color.lightened(0.25),3)
  draw_arc(at-Vector2(5,0),23,-PI*0.5,PI*0.5,20,color.darkened(0.4),5)
  if _cores[id]:
   draw_colored_polygon(PackedVector2Array([at+Vector2(20,13),at+Vector2(26,20),at+Vector2(20,27),at+Vector2(14,20)]),Color("e8d6a4"))
  elif not _open[id]:
   draw_rect(Rect2(at+Vector2(-5,-2),Vector2(10,8)),Color("99a4af"))
   draw_arc(at-Vector2(0,2),4,PI,TAU,10,Color("99a4af"),2)
  if id==_current:
   var y: float=at.y-44+sin(_time*3)*2
   draw_colored_polygon(PackedVector2Array([Vector2(at.x,y+7),Vector2(at.x-5,y),Vector2(at.x+5,y)]),Color("ffe0a2"))
