extends RefCounted
const SKIES=[preload("res://art/planets/v001/desert-sky.png"),preload("res://art/planets/v001/frost-sky.png"),preload("res://art/planets/v002/swamp-sky.png"),preload("res://art/planets/v002/volcanic-sky.png"),preload("res://art/planets/v002/storm-sky.png"),preload("res://art/planets/v002/void-sky.png")]
const TREE=[preload("res://art/planets/v001/desert-tree.png"),preload("res://art/planets/v001/frost-tree.png"),preload("res://art/planets/v002/swamp-tree.png"),preload("res://art/planets/v002/volcanic-tree.png"),preload("res://art/planets/v002/storm-tree.png"),preload("res://art/planets/v002/void-tree.png")]
const ORE=[preload("res://art/planets/v001/desert-ore.png"),preload("res://art/planets/v001/frost-ore.png"),preload("res://art/planets/v002/swamp-ore.png"),preload("res://art/planets/v002/volcanic-ore.png"),preload("res://art/planets/v002/storm-ore.png"),preload("res://art/planets/v002/void-ore.png")]
const SHRUB=[preload("res://art/planets/v001/desert-shrub.png"),preload("res://art/planets/v001/frost-shrub.png"),preload("res://art/planets/v002/swamp-shrub.png"),preload("res://art/planets/v002/volcanic-shrub.png"),preload("res://art/planets/v002/storm-shrub.png"),preload("res://art/planets/v002/void-shrub.png")]
const LANDMARK=[preload("res://art/planets/v001/desert-landmark.png"),preload("res://art/planets/v001/frost-landmark.png"),preload("res://art/planets/v002/swamp-landmark.png"),preload("res://art/planets/v002/volcanic-landmark.png"),preload("res://art/planets/v002/storm-landmark.png"),preload("res://art/planets/v002/void-landmark.png")]
const GROUND=[preload("res://art/planets/v001/desert-ground.png"),preload("res://art/planets/v001/frost-ground.png"),preload("res://art/planets/v002/swamp-ground.png"),preload("res://art/planets/v002/volcanic-ground.png"),preload("res://art/planets/v002/storm-ground.png"),preload("res://art/planets/v002/void-ground.png")]
const TINTS: Array[Color]=[Color("bd8e65"),Color("79a6c5"),Color("929779"),Color("bc816d"),Color("789ead"),Color("b091bf")]
static func texture(id: int, name: String) -> Texture2D:
 if id<=0:return null
 if name in ["tree","tree-plain"]:return TREE[id-1]
 if name in ["crystal","stone"]:return ORE[id-1]
 if name in ["berries","herbs"]:return SHRUB[id-1]
 return null
static func draw_on(view: Node2D, sim: RefCounted) -> void:
 var id: int=sim.planet.id-1
 var bounds: Rect2=view._background_rect()
 # Repeat sparse silhouettes in screen-cullable cells, grounded above the path.
 for layer: int in range(2):
  var step: int=430 if layer==0 else 730
  var offset: float=bounds.position.x*(0.72 if layer==0 else 0.32)
  var first: int=floori((bounds.position.x-offset)/step)-1
  var last: int=ceili((bounds.end.x-offset)/step)+1
  for index: int in range(first,last):
   var tex: Texture2D=TREE[id] if posmod(index,3)!=0 else LANDMARK[id]
   var at: Vector2=Vector2(round(index*step+offset),430)
   var tint: Color=TINTS[id]
   tint.a=0.32 if layer==0 else 0.7
   view.draw_texture(tex,at-Vector2(tex.get_width()*0.5,tex.get_height()),tint)
 for region: Dictionary in sim.frontier.regions:
  var x: float=region.x+region.width*0.62
  if not view._on_screen(x,400):continue
  var texture: Texture2D=LANDMARK[id] if region.kind=="ruins" else SHRUB[id]
  var alpha: float=view._region_reveal(sim.frontier.regions.find(region))
  if alpha<=0:continue
  view.draw_texture(texture,Vector2(x-texture.get_width()*0.5,430-texture.get_height()),Color(1,1,1,alpha))

 # Bounded ambient particles only in the visible rectangle; they carry no damage.
 var time: float=sim.workforce.elapsed
 for index: int in range(25):
  var at: Vector2=Vector2(bounds.position.x+fposmod(index*173.0+time*(5 if id==2 else -8),bounds.size.x),bounds.position.y+fposmod(index*53.0+time*(36 if id==4 else -10),bounds.size.y))
  var tint: Color=TINTS[id].lightened(0.25);tint.a=0.28
  if id==4:view.draw_line(at,at+Vector2(-3,15),tint,1)
  elif id>=2:view.draw_rect(Rect2(at.round(),Vector2(2,2)),tint)
