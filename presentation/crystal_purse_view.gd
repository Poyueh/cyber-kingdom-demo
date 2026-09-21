extends Node2D
## Open cutaway HUD purse: gems are visible inside, activity reveals it briefly.
const HOLD_SECONDS: float=3.0
const FADE_SECONDS: float=0.65
const FLIGHT_SECONDS: float=0.48
const MAX_FLIGHTS: int=12
var bounds: Rect2=Rect2()
var _fill: float=0.0
var _shown: float=-1.0
var _pulse: float=0.0
var _remaining: float=0.0
var _age: float=0.0
var _paused: bool=false
var _flights: Array[Dictionary]=[] # UI-only particles, bounded and never saved.
var _slots: Array[Vector2]=[]

func _init() -> void:
 for row in range(6):
  var count: int=[4,6,6,6,5,3][row]
  for column in range(count):
   _slots.append(Vector2((column-(count-1)*0.5)*8+sin((row*6+column)*2.3)*1.2,32-row*9+sin(column*1.9+row)*1.3))

func reset() -> void:
 _shown=-1;_remaining=0;_flights.clear();_pulse=0

func reveal() -> void:
 _remaining=HOLD_SECONDS+FADE_SECONDS
 modulate.a=1.0
 queue_redraw()

func present(fullness: float, area: Rect2, stopped: bool) -> void:
 var next_bounds: Rect2=Rect2(Vector2(area.end.x-112,area.position.y+14),Vector2(96,104))
 if bounds!=next_bounds:bounds=next_bounds;queue_redraw()
 _paused=stopped
 var next: float=clampf(fullness,0,1)
 if _shown<0:
  _shown=next;reveal()
 elif not is_equal_approx(_fill,next):
  var difference: int=roundi(next*30)-roundi(_fill*30)
  for i in range(mini(8,absi(difference))):
   if _flights.size()>=MAX_FLIGHTS:_flights.pop_front()
   _flights.append({"age":-i*0.045,"incoming":difference>0,"slot":clampi(roundi(next*30)-1-i,0,29)})
  _pulse=0.45;reveal()
 _fill=next

func _process(seconds: float) -> void:
 if not visible or _paused or _remaining<=0:return
 _age=fposmod(_age+seconds,120.0)
 _remaining=maxf(0,_remaining-seconds)
 modulate.a=smoothstep(0,FADE_SECONDS,_remaining)
 _pulse=maxf(0,_pulse-seconds)
 _shown=move_toward(_shown,_fill,seconds*1.4)
 for flight in _flights:flight.age+=seconds
 _flights=_flights.filter(func(flight):return flight.age<FLIGHT_SECONDS)
 queue_redraw()

func _gem(at: Vector2, ink: Color=Color("82e3cc"), alpha: float=1.0) -> void:
 draw_colored_polygon(PackedVector2Array([at+Vector2(0,-5),at+Vector2(4,0),at+Vector2(0,5),at+Vector2(-4,0)]),Color("25494f")*Color(1,1,1,alpha))
 draw_colored_polygon(PackedVector2Array([at+Vector2(0,-4),at+Vector2(3,0),at+Vector2(0,4),at]),Color(ink,alpha))
 draw_line(at+Vector2(0,-3),at+Vector2(-2,0),Color(0.9,1,0.84,alpha),1)

func _draw() -> void:
 if _shown<0 or modulate.a<=0:return
 var bounce: float=sin(_pulse/0.45*TAU)*(_pulse/0.45)
 draw_set_transform(bounds.get_center()+Vector2(0,2),bounce*0.028,Vector2(1+absf(bounce)*0.025,1-absf(bounce)*0.025))
 var outline: PackedVector2Array=PackedVector2Array([Vector2(-25,-34),Vector2(25,-34),Vector2(21,-19),Vector2(23,-8),Vector2(33,15),Vector2(34,29),Vector2(26,41),Vector2(12,47),Vector2(-12,47),Vector2(-26,41),Vector2(-34,29),Vector2(-33,15),Vector2(-23,-8),Vector2(-21,-19)])
 draw_colored_polygon(outline,Color("111d29"))
 draw_polyline(outline+PackedVector2Array([outline[0]]),Color("c0a367"),3)
 draw_colored_polygon(PackedVector2Array([Vector2(-19,-25),Vector2(19,-25),Vector2(16,-12),Vector2(28,16),Vector2(28,29),Vector2(20,38),Vector2(8,42),Vector2(-8,42),Vector2(-20,38),Vector2(-28,29),Vector2(-28,16),Vector2(-16,-12)]),Color("3c3630"))
 # Thirty distinct gems rise from the bottom; capacity is read without a counter.
 for index in range(clampi(roundi(_shown*30),0,30)):
  _gem(_slots[index]+Vector2(sin(_age*6+index)*absf(bounce),0))
 # Leather edge, seams and open mouth stay in front of the contents.
 for side in [-1,1]:
  draw_polyline(PackedVector2Array([Vector2(side*22,-12),Vector2(side*30,12),Vector2(side*30,29),Vector2(side*22,39),Vector2(side*10,43)]),Color("76523c"),4)
  for y in range(4,33,7):draw_line(Vector2(side*29,y),Vector2(side*27,y+2),Color("d0af73"),1)
 draw_colored_polygon(PackedVector2Array([Vector2(-26,-36),Vector2(26,-36),Vector2(23,-29),Vector2(-23,-29)]),Color("756449"))
 draw_line(Vector2(-23,-34),Vector2(23,-34),Color("e4cc8d"),2)
 draw_line(Vector2(-19,-29),Vector2(19,-29),Color("15232a"),2)
 draw_polyline(PackedVector2Array([Vector2(-20,-20),Vector2(-29,-17),Vector2(-29,-8),Vector2(-25,-5)]),Color("c7a473"),2)
 for flight in _flights:
  if flight.age<0:continue
  var progress: float=clampf(flight.age/FLIGHT_SECONDS,0,1)
  var start: Vector2=Vector2(-32,-45) if flight.incoming else Vector2(0,-35)
  var end: Vector2=_slots[flight.slot] if flight.incoming else Vector2(-48,34)
  var at: Vector2=start.lerp(end,progress)+Vector2(0,-sin(progress*PI)*8)
  _gem(at,Color("b8ffe2"),1 if flight.incoming else 1-progress*progress)
 draw_set_transform(Vector2.ZERO)
