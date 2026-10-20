extends Sprite2D
## Authored hunched poses with a bounded breathing loop; feet remain planted.
const SHEET=preload("res://art/characters/exhaustion-v001/rest.png")
const MOUNTED_SHEET=preload("res://art/characters/motorcycle-v001/mounted.png")
@export var sheet: Texture2D = SHEET
@export var mounted_sheet: Texture2D = MOUNTED_SHEET
@export var mounted_offset: Vector2=Vector2.ZERO
var authored_transition: bool=false
var mounted_rest_frame: int=0
const LOOP: Array[int]=[0,1,2,3,2,1]
var _atlas: AtlasTexture=AtlasTexture.new()
var _age: float=0.0
var _facing: int=1
var _mounted: bool=false
func _init() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 _atlas.atlas=SHEET;texture=_atlas
 visible=false
func reset() -> void:
 _age=0;visible=false
func present(unarmed: bool, mounted: bool, facing: int, seconds: float, weight: float=1.0) -> void:
 _age+=maxf(0,seconds);_facing=facing;_mounted=mounted
 var frame: int=LOOP[int(_age/0.17)%LOOP.size()]
 if authored_transition:frame=3 if weight<0.3 else 2 if weight<0.75 else int(_age/0.35)%2
 _atlas.atlas=mounted_sheet if mounted else sheet
 if mounted:
  var columns: int=roundi(mounted_sheet.get_width()/160.0)
  _atlas.region=Rect2(mounted_rest_frame%columns*160,mounted_rest_frame/columns*128,160,128)
  offset=mounted_offset
 else:
  var row: int=0 if unarmed else 1
  _atlas.region=Rect2(frame*160,row*128,160,128)
  offset=Vector2.ZERO
 flip_h=facing<0;visible=true
 queue_redraw()
func _draw() -> void:
 if not visible:return
 # Two small breath wisps emphasize exhaling, not smoke or a gameplay status icon.
 for i in range(2):
  var phase: float=fposmod(_age/1.02+i*0.18,1)
  if phase<0.45:continue
  var air: float=(phase-0.45)/0.55
  var at:=Vector2(_facing*(20+air*12),(-35 if _mounted else -11)-air*9)
  draw_rect(Rect2(at.round(),Vector2(2+floorf(air*2),2)),Color(0.78,0.9,0.87,(1-air)*0.65))
