extends RefCounted
const DESERT=preload("res://art/planets/v001/desert-sky.png")
const FROST=preload("res://art/planets/v001/frost-sky.png")
const TREE=[preload("res://art/planets/v001/desert-tree.png"),preload("res://art/planets/v001/frost-tree.png")]
const ORE=[preload("res://art/planets/v001/desert-ore.png"),preload("res://art/planets/v001/frost-ore.png")]
const SHRUB=[preload("res://art/planets/v001/desert-shrub.png"),preload("res://art/planets/v001/frost-shrub.png")]
const LANDMARK=[preload("res://art/planets/v001/desert-landmark.png"),preload("res://art/planets/v001/frost-landmark.png")]
const GROUND=[preload("res://art/planets/v001/desert-ground.png"),preload("res://art/planets/v001/frost-ground.png")]
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
   var tint: Color=Color("bd8e65") if id==0 else Color("79a6c5")
   tint.a=0.32 if layer==0 else 0.7
   view.draw_texture(tex,at-Vector2(tex.get_width()*0.5,tex.get_height()),tint)
 for region: Dictionary in sim.frontier.regions:
  var x: float=region.x+region.width*0.62
  if not view._on_screen(x,400):continue
  var texture: Texture2D=LANDMARK[id] if region.kind=="ruins" else SHRUB[id]
  var alpha: float=view._region_reveal(sim.frontier.regions.find(region))
  view.draw_texture(texture,Vector2(x-texture.get_width()*0.5,430-texture.get_height()),Color(1,1,1,alpha))
