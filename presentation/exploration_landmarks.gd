extends RefCounted
## Native-size existing pixel props, composed into readable silhouettes on flat ground.
const Art=preload("res://presentation/frontier_details.gd")
const Ground=preload("res://presentation/grounded_art.gd")
static func layout(sim: RefCounted) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for index: int in range(sim.frontier.regions.size()):
  var region: Dictionary=sim.frontier.regions[index]
  var site: Dictionary={"region":index,"kind":region.kind,"x":roundf(region.x+region.width*0.5),"node":-1,"module":""}
  for n: int in range(sim.frontier.nodes.size()):
   var resource: RefCounted=sim.frontier.nodes[n]
   if resource.region==index and resource.kind=="cache":site.x=resource.x;site.node=n;break
  for relic: RefCounted in sim.modules.relics:
   if relic.region==index:site.x=relic.x;site.node=-1;site.module=relic.id;break
  result.append(site)
 return result
static func draw_on(view: Node2D, sites: Array[Dictionary], sim: RefCounted) -> void:
 for site: Dictionary in sites:
  if not view._on_screen(site.x,220):continue
  var reveal: float=view._region_reveal(site.region)
  if reveal<=0:continue
  var at:=Vector2(roundf(site.x),430)
  var ink:=Color(0.8,0.91,0.94,reveal)
  match site.kind:
   "forest":
    _prop(view,"dead_tree",at+Vector2(-68,0),ink)
    _prop(view,"log",at+Vector2(74,0),ink)
    _prop(view,"gear",at+Vector2(-30,0),ink)
    _prop(view,"ferns",at+Vector2(105,0),ink)
   "quarry":
    _prop(view,"basalt",at+Vector2(-64,0),ink)
    _prop(view,"quartz",at+Vector2(62,0),ink)
    _prop(view,"gear",at+Vector2(8,0),ink)
   "ruins":
    _prop(view,"arch",at+Vector2(-69,0),ink)
    _prop(view,"dragon_statue",at+Vector2(73,0),ink)
    _prop(view,"gear",at+Vector2(-104,0),ink)
  var unclaimed: bool=(site.node>=0 and not sim.frontier.nodes[site.node].collected) or (not site.module.is_empty() and not sim.modules.found.has(site.module))
  # Lit ground runes lead inward to an actual remaining reward; spent sites go quiet.
  if not unclaimed:continue
  for side: int in [-1,1]:
   for step: int in range(3):
    var x: float=at.x+side*(112-step*28)
    var pulse: float=0.55+0.25*sin(sim.workforce.elapsed*2.0-step*0.9)
    view.draw_rect(Rect2(x-5,426,10,3),Color(0.3,0.95,0.86,reveal*pulse))
    view.draw_rect(Rect2(x-side*4-1,423,3,3),Color(0.7,1.0,0.92,reveal*pulse))
static func _prop(view: Node2D, key: String, at: Vector2, tint: Color) -> void:
 var texture: Texture2D=Art.TEXTURES[key]
 var origin: Vector2=Ground.anchor(texture,at)
 view.draw_texture(texture,(origin-Vector2(texture.get_width()*0.5,texture.get_height())).round(),tint)
