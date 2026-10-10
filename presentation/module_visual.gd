extends RefCounted
const Style=preload("res://presentation/module_style.gd")
static func relics(view: Node2D, sim: RefCounted) -> void:
 if not sim.life.enabled:return
 for relic: RefCounted in sim.modules.relics:
  if sim.modules.found.has(relic.id) or not sim.frontier.regions[relic.region].discovered or not view._on_screen(relic.x,100):continue
  var alpha: float=view._region_reveal(relic.region)
  var at: Vector2=Vector2(relic.x,430)
  view.draw_rect(Rect2(at+Vector2(-17,-9),Vector2(34,9)),Color(0.2,0.28,0.32,alpha))
  view.draw_rect(Rect2(at+Vector2(-12,-13),Vector2(24,4)),Color(0.48,0.59,0.62,alpha))
  var rise: float=roundf(sin(sim.workforce.elapsed*2.0)*3)*2
  var color: Color=Style.tint(relic.id);color.a=alpha
  view._icon(Style.icon(relic.id),at+Vector2(0,-35+rise),27,color)
  for i: int in range(3):view.draw_rect(Rect2(at+Vector2(-14+i*12,-18-fposmod(sim.workforce.elapsed*10+i*9,30)),Vector2(2,2)),Color(color,alpha*0.6))
static func effects(view: Node2D, sim: RefCounted) -> void:
 _ongoing(view,sim)
 for effect: Dictionary in sim.effects:
  if not view._on_screen(effect.x,620):continue
  if effect.kind=="module_ready":
   var progress: float=clampf(1.0-effect.life/0.9,0.0,1.0)
   var center: Vector2=Vector2(view._view_player_x,386)
   var tint: Color=Style.tint(effect.module);tint.a=sin(progress*PI)
   view.draw_arc(center,18+progress*24,0,TAU,16,tint,2)
   view._icon(Style.icon(effect.module),center+Vector2(0,-42-progress*12),22,tint)
   continue
  if effect.kind in ["module_pickup","module_milestone"]:
   var tint: Color=Style.tint(effect.module);tint.a=clampf(effect.life,0,1)
   view._icon(Style.icon(effect.module),Vector2(effect.x,328-sin(sim.workforce.elapsed*2)*3),31,tint)
   continue
  if effect.kind=="module_link":
   view.draw_line(Vector2(effect.x,396),Vector2(effect.to,402),Color(Style.tint(effect.module),effect.life/0.6),2)
   continue
  if effect.kind=="module_arrow":
   view.draw_line(Vector2(effect.x,402),Vector2(effect.to,397),Color(Style.tint("command"),effect.life/0.4),3)
   continue
  if not effect.kind.begins_with("module_"):continue
  var id: String=effect.kind.trim_prefix("module_")
  if not Style.IDS.has(id):continue
  var at: Vector2=Vector2(effect.x,392)
  var spec: RefCounted=sim.modules.spec_for(id)
  var duration: float=0.5 if id in ["arc","lance"] else 0.8
  var p: float=clampf(1.0-effect.life/duration,0,1)
  var tint: Color=Style.tint(id);tint.a=1-p
  var facing: float=effect.direction
  match id:
   "arc":
    for i: int in range(3):view.draw_arc(at,20+p*(spec.reach-20)-i*8,0,TAU,24,Color(tint,(1-p)*(1-i*0.2)),3)
   "lance":
    var end: Vector2=at+Vector2(facing*spec.reach,0)
    view.draw_line(at,end,Color(tint,(1-p)*0.4),12);view.draw_line(at,end,Color(0.92,0.92,1,1-p),3)
   "frost":
    for i: int in range(7):
     var shard: Vector2=at+Vector2(facing*(20+p*(spec.reach-20)),(i-3)*p*8)
     view.draw_line(shard-Vector2(facing*13,0),shard,tint,2)
   "gravity":
    var center: Vector2=at+Vector2(facing*spec.reach*0.5,5)
    for i: int in range(3):view.draw_arc(center,12+(1-p)*(58-i*12),p*TAU+i,p*TAU+i+PI,16,tint,2)
   "magnet":
    for i: int in range(2):view.draw_arc(at+Vector2(0,28),(1-p)*spec.reach+8+i*10,PI,TAU,24,Color(tint,(1-p)*0.65),2)
   "command","workshop","capacitor":
    view.draw_arc(at,10+p*45,0,TAU,16,Color(tint,(1-p)*0.5),2)
    for i: int in range(6):
     var point: Vector2=at+Vector2.RIGHT.rotated(i*TAU/6+p)*(15+p*45)
     view.draw_rect(Rect2(point.round(),Vector2(3,3)),tint)
static func _ongoing(view: Node2D, sim: RefCounted) -> void:
 var now: int=roundi(sim.workforce.elapsed*30)
 for person: Dictionary in sim.world.people:
  if not view._on_screen(person.x,70):continue
  var id: String="command" if int(person.get("module_command_until",0))>now else "workshop" if int(person.get("module_workshop_until",0))>now else ""
  if id.is_empty():continue
  var tint: Color=Style.tint(id)
  tint.a=0.6+sin(sim.workforce.elapsed*5)*0.2
  view._icon(Style.icon(id),Vector2(person.x,365),15,tint)
 for enemy: Dictionary in sim.raiders:
  if int(enemy.get("module_chill_until",0))<=now or not view._on_screen(enemy.x,65):continue
  for i: int in range(4):
   var base: Vector2=Vector2(enemy.x-16+i*10,428)
   view.draw_line(base,base+Vector2(-3,-8-(i%2)*6),Style.tint("frost"),2)
 if sim.modules.charge_ticks>0:
  var at: Vector2=Vector2(view._view_player_x,392)
  for i: int in range(5):
   var rise: float=fposmod(sim.workforce.elapsed*25+i*10,50)
   view.draw_rect(Rect2(at+Vector2(sin(i*1.7)*20,25-rise),Vector2(2,4)),Color(Style.tint("capacitor"),1-rise/50))
