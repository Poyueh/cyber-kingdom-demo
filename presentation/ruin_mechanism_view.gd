extends RefCounted
## World-space devices. Shapes, cables and the moving needle explain the rule.
const Clock=preload("res://domain/time/tick_clock.gd")
const Mechanism=preload("res://domain/ruin_mechanism.gd")
const FontSource=preload("res://presentation/localized_font.gd")
const Rules=preload("res://application/ruin_interactions.gd")
const Titles: Array[String]=["","ruin.sand","ruin.frost","ruin.swamp","ruin.volcano","ruin.storm","ruin.void"]
const GOLD: Color=Color("f1ce8a")
const ON: Color=Color("86f8d8")
const OFF: Color=Color("566e7e")
static func title(site: RefCounted) -> String:
 return Titles[site.mechanism.planet]
static func links(view: Node2D, sim: RefCounted, site: RefCounted) -> void:
 var m: RefCounted=site.mechanism
 if m.kind!=Mechanism.Kind.CIRCUIT:return
 for source: int in range(3):
  for target: int in range(3):
   if source==target or not m.masks[source]&(1<<target):continue
   var a: float=site.positions[source];var b: float=site.positions[target]
   if not Rules.known(sim,a) or not Rules.known(sim,b) or not view._on_screen((a+b)*0.5,absf(b-a)*0.5+60):continue
   var lit: bool=m.lit(target)
   var focused: bool=absf(view._view_player_x-a)<90
   var c: Color=GOLD if focused else ON if lit else OFF;c.a=(0.85 if focused else 0.55)*minf(reveal(view,sim,a),reveal(view,sim,b))
   var y: float=417-source*3
   view.draw_polyline(PackedVector2Array([Vector2(a,399),Vector2(a,y),Vector2(b,y),Vector2(b,377)]),c,2)
   var fraction: float=fposmod(sim.workforce.elapsed*0.3+source*0.23,1.0)
   if lit:view.draw_rect(Rect2(Vector2(lerpf(a,b,fraction),y)-Vector2(2,2),Vector2(4,4)),c)
static func station(view: Node2D, sim: RefCounted, site: RefCounted, index: int, alpha: float) -> void:
 var m: RefCounted=site.mechanism
 var at: Vector2=Vector2(site.positions[index],369)
 var now: int=roundi(sim.workforce.elapsed*Clock.TICKS_PER_SECOND)
 var lit: bool=m.lit(index)
 var color: Color=ON if lit else GOLD;color.a=alpha
 var shell: PackedVector2Array=PackedVector2Array([at+Vector2(-12,-24),at+Vector2(12,-24),at+Vector2(24,-12),at+Vector2(24,12),at+Vector2(12,24),at+Vector2(-12,24),at+Vector2(-24,12),at+Vector2(-24,-12),at+Vector2(-12,-24)])
 view.draw_colored_polygon(shell,Color(0.03,0.1,0.15,0.55*alpha))
 view.draw_polyline(shell,Color(color,alpha*0.75),2)
 for side: int in [-1,1]:view.draw_rect(Rect2(at+Vector2(side*29-2,-4),Vector2(4,8)),Color(color,alpha*0.75))
 var hint: String="ruin.circuit.hint"
 match m.kind:
  Mechanism.Kind.CIRCUIT:
   glyph(view,at,index,color,10)
   for k: int in range(3):
    var connected: bool=bool(m.masks[index]&(1<<k))
    glyph(view,at+Vector2(-14+k*14,32),k,Color(color if connected else OFF,alpha),3)
  Mechanism.Kind.BALANCE:
   hint="ruin.balance.hint"
   _gauge(view,at+Vector2(0,-38),m,alpha)
   if index==2:glyph(view,at,2,ON if m.value==m.target else OFF,11)
   else:
    var tint: Color=Color("ffad7a") if index==0 else Color("8dceff");tint.a=alpha
    var count: int=absi(m.warm if index==0 else m.cool)
    for j: int in range(mini(count,3)):
     var center: Vector2=at+Vector2((j-(min(count,3)-1)*0.5)*11,0)
     view.draw_line(center-Vector2(4,0),center+Vector2(4,0),tint,2)
     if index==0:view.draw_line(center-Vector2(0,4),center+Vector2(0,4),tint,2)
  Mechanism.Kind.PULSE:
   hint="ruin.pulse.hint"
   var available: bool=m.accepts(index,now)
   var tint: Color=ON if available or lit else OFF;tint.a=alpha
   view.draw_arc(at,15,-PI/2,-PI/2+TAU*float(m.window)/m.period,16,Color(ON,alpha*0.7),4)
   var angle: float=-PI/2+TAU*float(m.phase(index,now))/m.period
   var needle: Vector2=at+Vector2.from_angle(angle)*18
   view.draw_rect(Rect2(needle-Vector2(2,2),Vector2(4,4)),Color(GOLD,alpha))
   glyph(view,at,index,tint,7)
   if available and not lit:view.draw_arc(at,28,0,TAU,8,Color(ON,alpha*0.5),2)
 if lit:
  view.draw_polyline(PackedVector2Array([at+Vector2(-5,13),at+Vector2(-1,17),at+Vector2(7,9)]),Color(ON,alpha),2)
 if absf(view._view_player_x-site.positions[index])<90 and site.progress<3:
  caption(view,at+Vector2(0,-92),title(site),Color(GOLD,alpha))
  caption(view,at+Vector2(0,-72),hint,Color(ON,alpha))
  caption(view,at+Vector2(45,-3),"E" if view.keyboard_hint else "↓",Color(GOLD,alpha))
static func vault(view: Node2D, site: RefCounted, alpha: float) -> void:
 var m: RefCounted=site.mechanism
 var at: Vector2=Vector2(site.x,338)
 if m.kind==Mechanism.Kind.BALANCE:_gauge(view,at,m,alpha)
 else:
  for index: int in range(3):glyph(view,at+Vector2(-28+28*index,0),index,Color(ON if m.lit(index) else OFF,alpha),9)
 if absf(view._view_player_x-site.x)<150:
  caption(view,at+Vector2(0,-46),title(site),Color(GOLD,alpha))
  caption(view,at+Vector2(0,-26),"封印已解開" if site.progress==3 else "沿來路尋找符石",Color(ON,alpha))
static func _gauge(view: CanvasItem, at: Vector2, m: RefCounted, alpha: float) -> void:
 var width: float=80.0
 for tick: int in range(m.minimum,m.maximum+1):
  var x: float=at.x-width/2+width*float(tick-m.minimum)/(m.maximum-m.minimum)
  var tint: Color=Color("8dceff") if tick<m.target else Color("ffad7a")
  if tick==m.target:tint=ON
  tint.a=alpha
  view.draw_rect(Rect2(Vector2(x-2,at.y-4),Vector2(4,8)),tint)
 var needle: float=at.x-width/2+width*float(m.value-m.minimum)/(m.maximum-m.minimum)
 view.draw_polyline(PackedVector2Array([Vector2(needle-4,at.y-12),Vector2(needle,at.y-7),Vector2(needle+4,at.y-12)]),Color(GOLD,alpha),2)
 view.draw_rect(Rect2(Vector2(at.x-width/2+width*float(m.target-m.minimum)/(m.maximum-m.minimum)-4,at.y-6),Vector2(8,12)),Color(ON,alpha),false,1)
static func glyph(view: CanvasItem, at: Vector2, index: int, color: Color, radius: float) -> void:
 match index:
  0:view.draw_rect(Rect2(at-Vector2(radius,radius),Vector2(radius*2,radius*2)),color,false,2)
  1:view.draw_polyline(PackedVector2Array([at+Vector2(-radius,radius),at+Vector2(0,-radius),at+Vector2(radius,radius),at+Vector2(-radius,radius)]),color,2)
  2:view.draw_polyline(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius,0),at+Vector2(0,radius),at+Vector2(-radius,0),at+Vector2(0,-radius)]),color,2)
static func caption(view: CanvasItem, at: Vector2, key: String, tint: Color) -> void:
 var font: Font=FontSource.current();var text: String=view.tr(key)
 var size: int=14
 var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 if width>350:size=maxi(10,floori(size*350/width));width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 view.draw_rect(Rect2(at-Vector2(width/2+6,size+2),Vector2(width+12,size+8)),Color(0.02,0.06,0.1,tint.a*0.8))
 view.draw_string(font,at-Vector2(width/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)
static func reveal(view: Node2D, sim: RefCounted, x: float) -> float:
 for index: int in range(sim.frontier.regions.size()):
  var region: Dictionary=sim.frontier.regions[index]
  if x>=region.x and x<=region.x+region.width:return view._region_reveal(index)
 return 0.0
