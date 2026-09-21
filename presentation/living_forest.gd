extends RefCounted
## View-only parallax placement. Hashes are local decoration, not the gameplay RNG.
const Details=preload("res://presentation/frontier_details.gd")
const Ground=preload("res://presentation/grounded_art.gd")
const KINDS: Array[String]=["fir","cedar","oak","dead_tree"]
static func behind(view: Node2D, time: float) -> void:
 for layer in range(3):
  var scroll: float=[0.22,0.48,0.78][layer]
  var spacing: float=[210.0,295.0,390.0][layer]
  var offset: float=view._span.x*(1.0-scroll)
  for index in range(floori((view._span.x-offset)/spacing)-2,ceili((view._span.y-offset)/spacing)+2):
   var seed: int=posmod(index*1747+layer*419,997)
   var x: float=index*spacing+offset+seed%95
   if not view._on_screen(x,280):continue
   var texture: Texture2D=Details.TEXTURES[KINDS[seed%4]]
   var height: float=[170.0,240.0,320.0][layer]+seed%83
   var scale: float=height/texture.get_height()
   var at: Vector2=Ground.anchor(texture,Vector2(x,422+layer*3),scale)
   var color: Color=[Color("385563"),Color("304854"),Color("273e49")][layer]
   color.a=[0.44,0.58,0.72][layer]
   var sway: float=sin(time*0.48+index)*0.009
   view.draw_set_transform(at,sway,Vector2(-1 if seed%2 else 1,1))
   view.draw_texture_rect(texture,Rect2(-texture.get_width()*scale*0.5,-height,texture.get_width()*scale,height),false,color)
 view.draw_set_transform(Vector2.ZERO)
static func foreground(view: Node2D, time: float) -> void:
 for index in range(floori(view._span.x/320)-1,ceili(view._span.y/320)+1):
  var x: float=index*320+posmod(index*173,110)
  if not view._on_screen(x,80):continue
  var texture: Texture2D=Details.TEXTURES["ferns" if posmod(index,3) else "log"]
  var height: float=18+posmod(index*31,20)
  var scale: float=height/texture.get_height()
  var at: Vector2=Ground.anchor(texture,Vector2(x,442),scale)
  view.draw_set_transform(at,sin(time*0.6+index)*0.025)
  view.draw_texture_rect(texture,Rect2(-texture.get_width()*scale*0.5,-height,texture.get_width()*scale,height),false,Color(0.18,0.32,0.32,0.74))
 view.draw_set_transform(Vector2.ZERO)
