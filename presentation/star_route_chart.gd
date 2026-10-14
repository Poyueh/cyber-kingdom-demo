extends Control
## All visual state is a bounded, read-only projection of the voyage.
signal selected(id: int)
const POSITIONS: Array[Vector2]=[Vector2(0.39,0.47),Vector2(0.02,0.07),Vector2(0.14,0.92),Vector2(0.55,0.03),Vector2(0.74,0.72),Vector2(0.98,0.27),Vector2(0.94,1.0)]
const COLORS: Array[Color]=[Color("79bda0"),Color("d3a171"),Color("98d8ec"),Color("b4c57e"),Color("ed9974"),Color("94c9ec"),Color("cf9bcc")]
const Style=preload("res://data/cosmic_interface.tres")
var _planets: Array[ColorRect]=[]
var buttons: Array[Button]=[]
var _labels: Array[Label]=[]

var _open: Array[bool]=[]
var _cores: Array[bool]=[]
var _seals: Array[int]=[]
var _current: int=0
var selection: int=0
var _time: float=0.0
func _ready() -> void:
 custom_minimum_size=Vector2(530,270)
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 size_flags_vertical=Control.SIZE_EXPAND_FILL
 for id: int in range(7):
  var planet: ColorRect=ColorRect.new();planet.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var shader: ShaderMaterial=ShaderMaterial.new();shader.shader=preload("res://presentation/atlas_planet.gdshader")
  shader.set_shader_parameter("kind",id);shader.set_shader_parameter("tint",COLORS[id]);planet.material=shader
  add_child(planet);_planets.append(planet)
  var button: Button=Button.new();button.flat=true;button.custom_minimum_size=Vector2(70,70)
  button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
  button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
  button.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
  button.pressed.connect(func():selected.emit(id));add_child(button);buttons.append(button)
  var label: Label=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",14);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label);_labels.append(label)
 resized.connect(_layout)
 _layout()
func _layout() -> void:
 for id: int in range(buttons.size()):
  var at: Vector2=_point(id)
  var diameter: float=minf(Style.planet_diameter,maxf(56,(size.y-44)*0.24))
  _planets[id].position=at-Vector2.ONE*diameter*0.5;_planets[id].size=Vector2.ONE*diameter
  buttons[id].position=at-Vector2(35,35);buttons[id].size=Vector2(70,70)
  _labels[id].position=at+Vector2(-52.0,diameter*0.5+3);_labels[id].size=Vector2(104,44)
 queue_redraw()
func _point(id: int) -> Vector2:
 return Vector2(54,48)+POSITIONS[id]*Vector2(size.x-108,maxf(110,size.y-126))
func present(journey: RefCounted, sim: RefCounted, names: Array[String]) -> void:
 _current=journey.current;_open.clear();_cores.clear();_seals.clear()
 for id: int in range(7):
  _open.append(journey.accessible(id,sim));_cores.append(journey.has_core(id,sim))
  _labels[id].text=tr(names[id]);_labels[id].modulate=COLORS[id] if _open[id] else Color("788a9c")
  var report: Dictionary=preload("res://application/voyage_progress.gd").read(journey,sim,id)
  var seal: int=-1
  if report.known:
   seal=0
   for index: int in range(3):
    if report.goals[index].complete:seal|=1<<index
  _seals.append(seal)
  buttons[id].tooltip_text=tr(names[id])
  _planets[id].material.set_shader_parameter("discovered",1.0 if _open[id] else 0.0)
 _layout()
func _process(delta: float) -> void:
 if not is_visible_in_tree():return
 _time=fmod(_time+delta,4096.0)
 for planet: ColorRect in _planets:planet.material.set_shader_parameter("phase",_time*Style.planet_rotation)
 queue_redraw()
func _draw() -> void:
 if _open.size()!=7:return
 if selection!=_current:
  var start: Vector2=_point(_current);var end: Vector2=_point(selection)
  var direction: Vector2=(end-start).normalized()
  start+=direction*38;end-=direction*38
  draw_dashed_line(start,end,Color("5c8e98"),1,4)
  var pulse: Vector2=start.lerp(end,fposmod(_time*Style.route_speed,1.0)).round()
  draw_rect(Rect2(pulse-Vector2(1,1),Vector2(3,3)),Color("c4e1dc"))
 for id: int in range(7):
  var at: Vector2=_point(id)
  if id==selection:
   draw_arc(at,39,0,TAU,56,Color("a58f60"),1)
   draw_arc(at,43,_time*0.2,_time*0.2+PI*0.35,24,Color("f3d89c"),2)
  # Status marks sit outside the planet, so its physical silhouette stays visible.
  if _cores[id]:
   draw_colored_polygon(PackedVector2Array([at+Vector2(27,20),at+Vector2(33,27),at+Vector2(27,34),at+Vector2(21,27)]),Color("e8d6a4"))
  elif not _open[id]:
   draw_rect(Rect2(at+Vector2(24,23),Vector2(10,8)),Color("99a4af"))
   draw_arc(at+Vector2(29,23),4,PI,TAU,10,Color("99a4af"),2)
  if _seals[id]>=0:
   for index: int in range(3):
    draw_rect(Rect2(at+Vector2(-10+index*8,-40),Vector2(4,3)),Color("ead5a1") if _seals[id]&(1<<index) else Color("40565e"))
  if id==_current:
   var y: float=at.y-52+sin(_time*3)*2
   draw_colored_polygon(PackedVector2Array([Vector2(at.x,y+7),Vector2(at.x-5,y),Vector2(at.x+5,y)]),Color("ffe0a2"))
