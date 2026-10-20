extends RefCounted
## World-sized pixel fixtures. All animation uses simulation time and stops on pause.
const SHIP: Texture2D=preload("res://art/settlement/rescue-v001/rescue-ship.png")
const INK: Color=Color("14242b")
const STEEL: Color=Color("526b70")
const LIGHT: Color=Color("92a5a2")
const BRASS: Color=Color("b59a67")
const CYAN: Color=Color("92e4d3")
const GROUPS: Array[Color]=[Color("d7b878"),Color("93d6cc"),Color("b3aacd")]
static func draw_on(view: Node2D, sim: RefCounted) -> void:
 var command: RefCounted=sim.command
 if not command.enabled:return
 var time: float=sim.workforce.elapsed
 if command.ship_visible() and view._on_screen(command.ship_x,200):_ship(view,command,time)
 if not command.unlocked():return
 for side: int in [-1,1]:
  var x: float=command.flag_x(side)
  if view._on_screen(x,100):_flag(view,Vector2(x,430),side,time,command.squads.size(),command.rules.squad_limit)
 var x: float=command.barracks_x()
 if view._on_screen(x,180):
  view._prop("armory",Vector2(x,432))
  _flag(view,Vector2(x-53,432),1,time,-1,0)
  view._icon("sword",Vector2(x,350),25,BRASS)
  for i: int in range(sim.world.tools.blade):view._tool(Vector2(x-22+i*22,414),"blade")
  # Inset stone base and pennants distinguish the marching corps from the bow rack.
  view.draw_rect(Rect2(x-69,428,138,6),INK)
  for i: int in range(6):view.draw_rect(Rect2(x-66+i*22,428,20,3),STEEL)
static func _flag(view: Node2D, at: Vector2, side: int, time: float, count: int, limit: int) -> void:
 view.draw_set_transform(at.round())
 view.draw_rect(Rect2(-14,-4,28,6),INK);view.draw_rect(Rect2(-10,-7,20,5),STEEL)
 view.draw_rect(Rect2(-3,-116,6,112),INK);view.draw_rect(Rect2(-1,-115,2,109),BRASS)
 view.draw_rect(Rect2(-4,-120,8,6),BRASS);view.draw_rect(Rect2(-2,-124,4,4),CYAN)
 for i: int in range(14):
  var wave: float=roundf(sin(time*2.3-i*0.33)*2)*2
  var length: float=52-absf(i-6)*2
  var x: float=4 if side>0 else -length-4
  view.draw_rect(Rect2(x,-111+i*3+wave,length,5),Color("452e39") if i%3==0 else Color("74434a"))
  view.draw_rect(Rect2(x,-111+i*3+wave,2,3),BRASS)
 view._icon("sword",Vector2(side*25,-90),24,Color("d5c29a"))
 if count>=0:
  for i: int in range(limit):
   view.draw_rect(Rect2(-15+i*11,-139,8,8),GROUPS[i] if i<count else STEEL)
 view.draw_set_transform(Vector2.ZERO)
static func _ship(view: Node2D, command: RefCounted, time: float) -> void:
 var at: Vector2=Vector2(roundf(command.ship_x),430)
 var frame: int=1 if command.repaired else 0
 view.draw_texture_rect_region(SHIP,Rect2(at-Vector2(192,106),Vector2(384,112)),Rect2(0,frame*112,384,112))
 if command.repaired:
  for i: int in range(command.waiting):
   var p: Vector2=at+Vector2(-38+i*38,-42)
   view.draw_rect(Rect2(p+Vector2(-2,-4),Vector2(4,4)),Color("d8c5a5"))
   view.draw_rect(Rect2(p+Vector2(-4,0),Vector2(8,8)),Color("668c83"))
   view.draw_rect(Rect2(p+Vector2(-12,10),Vector2(24,1)),CYAN)
  var pulse: float=0.7+sin(time*1.5)*0.2
  view.draw_rect(Rect2(at+Vector2(69,-93),Vector2(2,2)),Color(CYAN,pulse))
 if absf(view._view_player_x-command.ship_x)<200:
  view._icon("person" if command.repaired else "hammer",at+Vector2(0,-123),24,CYAN)
  if command.repaired:
   view.draw_string(view._font,at+Vector2(21,-117),"%d/%d"%[command.waiting,command.rules.passenger_limit],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("dbe7d4"))
static func _panel(view: Node2D, polygon: PackedVector2Array, color: Color) -> void:view.draw_colored_polygon(polygon,color)
static func soldier(view: Node2D, person: Dictionary, time: float) -> void:
 var facing: float=person.get("direction",1.0)
 var attack: float=clampf((person.cooldown-0.82)/0.28,0,1)
 view.draw_set_transform(Vector2(roundf(person.x),roundf(person.get("y",430.0))-26),0,Vector2(facing,1))
 # Broad shield, slim straight blade: no spear protruding from the body.
 var tip: Vector2=Vector2(21+attack*8,-14+attack*20).round()
 view.draw_line(Vector2(9,2),tip,INK,4)
 view.draw_line(Vector2(10,1),tip,Color("b8ccc7"),2)
 view.draw_line(Vector2(7,-1),Vector2(15,5),BRASS,3)
 if attack>0:
  view.draw_line(tip+Vector2(-6,-9),tip+Vector2(8,7),Color("daecb8"),2)
 view.draw_set_transform(Vector2.ZERO)
static func squad_badge(view: Node2D, sim: RefCounted, index: int) -> void:
 for i: int in range(sim.command.squads.size()):
  if index not in sim.command.squads[i].members:continue
  var p: Dictionary=sim.world.people[index]
  var at: Vector2=Vector2(roundf(p.x),roundf(p.get("y",430.0))-61)
  view.draw_rect(Rect2(at-Vector2(4,4),Vector2(8,8)),INK)
  view.draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),GROUPS[i])
  return
