extends Node2D
## A small bounded, physical heap in an activity-only HUD purse.
const Gem=preload("res://presentation/purse_gem.gd")
const HOLD_SECONDS: float=3.0
const FADE_SECONDS: float=0.65
const FLIGHT_SECONDS: float=0.42
const CAPACITY: int=30
const MAX_FLIGHTS: int=42 # Up to 30 incoming and 12 outgoing decorations.
const STEP: float=1.0/120.0
const GRAVITY: float=950.0
var bounds: Rect2=Rect2()
var _fill: float=0.0
var _shown: float=-1.0
var _pulse: float=0.0
var _remaining: float=0.0
var _paused: bool=false
var _flights: Array[Gem]=[]
var _gems: Array[Gem]=[]
var _rng: RandomNumberGenerator=RandomNumberGenerator.new()
var _accumulator: float=0.0

func _init() -> void:
 _rng.seed=71843 # Cosmetic stream, independent of the campaign RNG.

func reset() -> void:
 _shown=-1;_remaining=0;_flights.clear();_gems.clear();_pulse=0;_accumulator=0
 _rng.seed=71843

func reveal() -> void:
 _remaining=HOLD_SECONDS+FADE_SECONDS
 modulate.a=1.0
 queue_redraw()

func _new_gem() -> Gem:
 var gem: Gem=Gem.new()
 gem.radius=_rng.randf_range(7.6,9.1)
 gem.angle=_rng.randf_range(-PI,PI)
 gem.spin=_rng.randf_range(-4.0,4.0)
 gem.ink=Color("399ca9").lerp(Color("83dcc6"),_rng.randf())
 return gem

func present(fullness: float, area: Rect2, stopped: bool) -> void:
 var next_bounds: Rect2=Rect2(Vector2(area.end.x-144,area.position.y+10),Vector2(128,150))
 if bounds!=next_bounds:bounds=next_bounds;queue_redraw()
 _paused=stopped
 var next: float=clampf(fullness,0,1)
 var count: int=roundi(next*CAPACITY)
 if _shown<0:
  for i in range(count):
   var gem: Gem=_new_gem()
   gem.position=Vector2(_rng.randf_range(-25,25),-44-i*12)
   _gems.append(gem)
  # Loaded saves begin with a settled heap, not a shower of starting inventory.
  for step in range(240):_step(STEP)
  _shown=next;reveal()
 elif not is_equal_approx(_fill,next):
  var difference: int=count-roundi(_fill*CAPACITY)
  for i in range(absi(difference)):
   if difference>0:
    var gem: Gem=_new_gem()
    gem.age=-i*0.055
    gem.start=Vector2(_rng.randf_range(-42,-24),-74)
    gem.position=Vector2(_rng.randf_range(-16,16),-48)
    _flights.append(gem)
   else:_remove_gem()
  while _flights.size()>MAX_FLIGHTS:
   for i in range(_flights.size()):
    if not _flights[i].incoming:_flights.remove_at(i);break
  _pulse=0.45;reveal()
 _fill=next

func _remove_gem() -> void:
 var gem: Gem
 if not _gems.is_empty():
  var top: int=0
  for i in range(1,_gems.size()):
   if _gems[i].position.y<_gems[top].position.y:top=i
  gem=_gems.pop_at(top)
  gem.start=gem.position
 else:
  for i in range(_flights.size()-1,-1,-1):
   if _flights[i].incoming:gem=_flights.pop_at(i);gem.start=Vector2(0,-55);break
 if gem==null:return
 gem.incoming=false;gem.age=0
 _flights.append(gem)
 for other in _gems:other.velocity.x+=_rng.randf_range(-7,7)

func _process(seconds: float) -> void:
 if not visible or _paused or _remaining<=0:return
 var elapsed: float=minf(seconds,0.067)
 _remaining=maxf(0,_remaining-seconds)
 modulate.a=smoothstep(0,FADE_SECONDS,_remaining)
 _pulse=maxf(0,_pulse-elapsed)
 for i in range(_flights.size()-1,-1,-1):
  var gem: Gem=_flights[i]
  gem.age+=elapsed
  if gem.age<FLIGHT_SECONDS:continue
  _flights.remove_at(i)
  if gem.incoming:
   gem.velocity=Vector2(_rng.randf_range(-35,35),95)
   _gems.append(gem)
 _accumulator+=elapsed
 while _accumulator>=STEP:
  _step(STEP)
  _accumulator-=STEP
 queue_redraw()

func _step(seconds: float) -> void:
 for gem in _gems:
  gem.velocity.y+=GRAVITY*seconds
  gem.velocity*=0.993
  gem.position+=gem.velocity*seconds
  gem.angle+=gem.spin*seconds
  gem.spin*=0.986
 for iteration in range(5):
  for i in range(_gems.size()):
   var a: Gem=_gems[i]
   _contain(a)
   for j in range(i+1,_gems.size()):
    var b: Gem=_gems[j]
    var delta: Vector2=b.position-a.position
    var reach: float=a.radius+b.radius
    var distance_squared: float=delta.length_squared()
    if distance_squared>=reach*reach:continue
    var distance: float=sqrt(maxf(0.0001,distance_squared))
    var normal: Vector2=delta/distance if distance_squared>0.0001 else Vector2.RIGHT
    var correction: Vector2=normal*(reach-distance)*0.5
    a.position-=correction;b.position+=correction
    var impact: float=(b.velocity-a.velocity).dot(normal)
    if impact<0:
     a.velocity+=normal*impact*0.58;b.velocity-=normal*impact*0.58
     a.velocity.x*=0.88;b.velocity.x*=0.88
     a.spin+=normal.x*impact*0.012;b.spin-=normal.x*impact*0.012
 for gem in _gems:_contain(gem)

func _contain(gem: Gem) -> void:
 var half_width: float=lerpf(25,45,clampf((gem.position.y+45)/55.0,0,1))-gem.radius
 if absf(gem.position.x)>half_width:
  gem.position.x=signf(gem.position.x)*half_width
  gem.velocity.x*=-0.2
 var floor_y: float=62.0-pow(absf(gem.position.x)/43.0,3)*21.0-gem.radius
 if gem.position.y>floor_y:
  gem.position.y=floor_y
  gem.velocity.y=-absf(gem.velocity.y)*0.12
  gem.velocity.x*=0.83;gem.spin*=0.8

func _gem(gem: Gem, at: Vector2, alpha: float=1.0) -> void:
 var radius: float=gem.radius
 var points: PackedVector2Array=PackedVector2Array()
 for vertex in [Vector2(0,-1.13),Vector2(0.68,-0.36),Vector2(0.67,0.48),Vector2(0,1.13),Vector2(-0.64,0.38),Vector2(-0.67,-0.35)]:
  points.append((at+(vertex*radius).rotated(gem.angle)).round())
 draw_colored_polygon(points,Color("173f4b")*Color(1,1,1,alpha))
 draw_colored_polygon(PackedVector2Array([points[0],points[1],points[2],points[3],at]),Color(gem.ink,alpha))
 draw_colored_polygon(PackedVector2Array([points[0],at,points[4],points[5]]),Color(gem.ink.darkened(0.30),alpha))
 draw_line(points[0],points[5],Color(0.86,1,0.86,alpha),1.4)
 draw_line(points[0],at,Color(gem.ink.lightened(0.35),alpha),1)

func _draw() -> void:
 if _shown<0 or modulate.a<=0:return
 var bounce: float=sin(_pulse/0.45*TAU)*(_pulse/0.45)
 draw_set_transform(bounds.get_center(),bounce*0.018)
 var outline: PackedVector2Array=PackedVector2Array([Vector2(-32,-52),Vector2(32,-52),Vector2(28,-32),Vector2(35,-13),Vector2(49,12),Vector2(49,36),Vector2(35,56),Vector2(15,67),Vector2(-15,67),Vector2(-35,56),Vector2(-49,36),Vector2(-49,12),Vector2(-35,-13),Vector2(-28,-32)])
 draw_colored_polygon(outline,Color("121e25"))
 draw_polyline(outline+PackedVector2Array([outline[0]]),Color("c0a367"),3)
 for gem in _gems:_gem(gem,gem.position.round())
 for side in [-1,1]:
  draw_polyline(PackedVector2Array([Vector2(side*28,-32),Vector2(side*34,-10),Vector2(side*45,14),Vector2(side*44,36),Vector2(side*32,53),Vector2(side*14,62)]),Color("76523c"),5)
  for y in range(5,42,8):draw_line(Vector2(side*45,y),Vector2(side*42,y+3),Color("d0af73"),1)
 draw_polyline(PackedVector2Array([Vector2(-30,56),Vector2(-13,64),Vector2(13,64),Vector2(30,56)]),Color("a0784e"),3)
 draw_colored_polygon(PackedVector2Array([Vector2(-33,-54),Vector2(33,-54),Vector2(30,-46),Vector2(-30,-46)]),Color("756449"))
 draw_line(Vector2(-30,-52),Vector2(30,-52),Color("e4cc8d"),2)
 draw_line(Vector2(-26,-46),Vector2(26,-46),Color("15232a"),2)
 draw_polyline(PackedVector2Array([Vector2(-28,-37),Vector2(-38,-31),Vector2(-37,-19),Vector2(-32,-16)]),Color("c7a473"),2)
 for gem in _flights:
  if gem.age<0:continue
  var progress: float=clampf(gem.age/FLIGHT_SECONDS,0,1)
  var end: Vector2=gem.position if gem.incoming else Vector2(-68,-35)
  var at: Vector2=gem.start.lerp(end,progress)+Vector2(0,-sin(progress*PI)*(12 if gem.incoming else 54))
  _gem(gem,at,1.0 if gem.incoming else 1.0-progress*progress)
 draw_set_transform(Vector2.ZERO)
