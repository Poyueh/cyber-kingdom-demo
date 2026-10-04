extends RefCounted
const Rules=preload("res://application/ruin_interactions.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
const FontSource=preload("res://presentation/localized_font.gd")
const STONE=preload("res://presentation/frontier_details.gd")
const Ground=preload("res://presentation/grounded_art.gd")
static func draw_on(view: Node2D, sim: RefCounted) -> void:
 for site: RefCounted in sim.trials.sites:
  for index: int in range(3):
   var x: float=site.positions[index]
   if not view._on_screen(x,180) or not Rules.known(sim,x):continue
   var alpha: float=_reveal(view,sim,x)
   var at:=Vector2(x,430)
   var lit: bool=site.order.find(index)<site.progress
   var tint:=Color("8ff6cf") if lit else Color("d0ad79")
   tint.a=alpha
   var texture: Texture2D=STONE.TEXTURES["gear"]
   var origin: Vector2=Ground.anchor(texture,at)
   view.draw_texture(texture,(origin-Vector2(texture.get_width()*0.5,texture.get_height())).round(),Color(0.55,0.66,0.7,alpha))
   var center: Vector2=at+Vector2(0,-61)
   view.draw_circle(center,16,Color(0.04,0.11,0.15,alpha*0.85))
   view.draw_arc(center,17,0,TAU,12,Color(tint,alpha*0.6),2)
   view.draw_line(at+Vector2(0,-15),center+Vector2(0,18),Color(tint,alpha*0.45),2)
   glyph(view,center,index,tint,9)
   if lit:
    for step: int in range(4):
     view.draw_rect(Rect2(at+Vector2(-22+step*14,-4),Vector2(6,2)),Color(tint,alpha*0.6))
   if absf(view._view_player_x-x)<90 and site.progress<3:
    view.draw_arc(at+Vector2(0,-61),22,-PI,PI,16,Color(tint,alpha*0.4),2)
    _caption(view,at+Vector2(0,-112),"依石碑符序接通" if not site.timed else "由外向內接通，能量耗盡會重置",tint)
    _caption(view,at+Vector2(0,-90),"E" if view.keyboard_hint else "↓",tint)
    if site.deadline>0:
     var energy: float=clampf(float(site.deadline-roundi(sim.workforce.elapsed*Clock.TICKS_PER_SECOND))/sim.trials.duration,0,1)
     view.draw_arc(center,25,-PI*0.5,-PI*0.5+TAU*energy,24,tint,3)
  if view._on_screen(site.x,220) and sim.frontier.regions[site.region].discovered:
   _vault(view,sim,site)
 for effect: Dictionary in sim.effects:
  if effect.kind not in ["rune_success","rune_reset","ruin_open"] or not view._on_screen(effect.x,200):continue
  var tint:=Color("ffd490") if effect.kind=="ruin_open" else Color("74ffd3") if effect.kind=="rune_success" else Color("ee827b")
  var fraction: float=clampf(effect.life/(1.5 if effect.kind=="ruin_open" else 0.8),0,1)
  tint.a=fraction
  view.draw_arc(Vector2(effect.x,390),18+(1-fraction)*65,0,TAU,24,tint,3)
static func _vault(view: Node2D, sim: RefCounted, site: RefCounted) -> void:
 var at:=Vector2(site.x,430)
 var alpha: float=view._region_reveal(site.region)
 var tint:=Color("83e8d0") if site.progress==3 else Color("d6b57e");tint.a=alpha
 if site.progress<3:
  var seal:=PackedVector2Array([at+Vector2(-34,-57),at+Vector2(-20,-74),at+Vector2(20,-74),at+Vector2(34,-57),at+Vector2(34,-18),at+Vector2(20,-5),at+Vector2(-20,-5),at+Vector2(-34,-18),at+Vector2(-34,-57)])
  view.draw_colored_polygon(seal,Color(0.06,0.16,0.2,alpha*0.65))
  view.draw_polyline(seal,Color(tint,alpha*0.65),2)
  for line: int in range(3):
   var y: float=-62+fposmod(sim.workforce.elapsed*12+line*19,52)
   view.draw_line(at+Vector2(-26,y),at+Vector2(26,y),Color(tint,alpha*0.12),1)
 for index: int in range(3):
  var lit: Color=tint if index<site.progress else Color(0.55,0.57,0.6,alpha)
  glyph(view,at+Vector2(-28+28*index,-92),site.order[index],lit,7)
  if index<2:view.draw_line(at+Vector2(-17+28*index,-92),at+Vector2(-10+28*index,-92),Color(tint,alpha*0.4),1)
 if absf(view._view_player_x-site.x)<150:
  _caption(view,at+Vector2(0,-135),"疾光中繼" if site.timed else "古龍符序",tint)
  _caption(view,at+Vector2(0,-116),"封印已解開" if site.progress==3 else "沿來路尋找符石",tint)
 if site.deadline>0:
  var remaining: float=clampf(float(site.deadline-roundi(sim.workforce.elapsed*Clock.TICKS_PER_SECOND))/sim.trials.duration,0,1)
  view.draw_line(at+Vector2(-40,-76),at+Vector2(-40+80*remaining,-76),tint,3)
static func glyph(view: CanvasItem, at: Vector2, symbol: int, color: Color, radius: float) -> void:
 match symbol:
  0:view.draw_arc(at,radius,0,TAU,12,color,2)
  1:view.draw_polyline(PackedVector2Array([at+Vector2(-radius,radius*0.6),at+Vector2(0,-radius),at+Vector2(radius,radius*0.6)]),color,2)
  2:view.draw_polyline(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius,0),at+Vector2(0,radius),at+Vector2(-radius,0),at+Vector2(0,-radius)]),color,2)
static func _caption(view: Node2D, at: Vector2, key: String, color: Color) -> void:
 var font: Font=FontSource.current()
 var text: String=view.tr(key)
 var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
 view.draw_string(font,at-Vector2(width*0.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
static func _reveal(view: Node2D, sim: RefCounted, x: float) -> float:
 for index: int in range(sim.frontier.regions.size()):
  var region: Dictionary=sim.frontier.regions[index]
  if x>=region.x and x<=region.x+region.width:return view._region_reveal(index)
 return 0
