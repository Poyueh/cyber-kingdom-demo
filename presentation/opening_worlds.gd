extends Control
## Glimpses of the shipped worlds, not a route map or gameplay state.
const Scenery=preload("res://presentation/planet_scenery.gd")
var elapsed: float=0.0
var starts: float=3.4
var ends: float=13.2
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func present(time: float) -> void:
 elapsed=time
 visible=elapsed>=starts and elapsed<ends
 if visible:queue_redraw()
func _draw() -> void:
 var progress: float=clampf((elapsed-starts)/(ends-starts)*6.0,0.0,5.999)
 var index: int=int(progress)
 var local: float=progress-index
 draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
 draw_rect(Rect2(0,0,960,540),Color("09121d"))
 _world(index,local,1.0)
 if index>0 and local<0.22:_world(index-1,1.0,1.0-smoothstep(0,0.22,local))
 # A single luminous signal leads the eye through seven unknown worlds.
 for mark: int in range(7):
  var at: Vector2=Vector2(372+mark*36,85)
  var tint: Color=Color("b7e3df") if mark<=index+1 else Color("526677")
  draw_arc(at,5.0,0,TAU,12,tint,1.0)
  if mark==index+1:draw_circle(at,2.0,Color("e8d7a9"))
 draw_set_transform(Vector2.ZERO)
func _world(index: int, phase: float, alpha: float) -> void:
 draw_texture_rect(Scenery.SKIES[index],Rect2(-10-phase*15,-8,995,560),false,Color(0.8,0.88,0.96,alpha))
 var landmark: Texture2D=Scenery.LANDMARK[index]
 var ratio: float=230.0/landmark.get_height()
 var dimensions: Vector2=landmark.get_size()*ratio
 draw_texture_rect(landmark,Rect2(preload("res://presentation/grounded_art.gd").anchor(landmark,Vector2(480,440),ratio)-Vector2(dimensions.x/2,dimensions.y),dimensions),false,Color(0.73,0.84,0.88,alpha))
 for tile: int in range(3):
  draw_texture_rect(Scenery.GROUND[index],Rect2(tile*384-phase*10,437,384,38),false,Color(0.5,0.65,0.75,alpha))
 draw_rect(Rect2(0,475,960,65),Color(0.025,0.045,0.07,alpha*0.9))
 for spark: int in range(18):
  var x: float=fposmod(spark*173+phase*20,960)
  var y: float=fposmod(spark*61-phase*26,410)
  draw_rect(Rect2(Vector2(x,y).round(),Vector2(2,2)),Color(0.58,0.85,0.92,alpha*0.4))
