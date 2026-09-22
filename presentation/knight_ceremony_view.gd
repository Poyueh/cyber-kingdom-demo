extends Sprite2D
## One short, interruptible celebration using authored extraction poses.
const SHEET=preload("res://art/characters/camp-ceremony-v001/draw_sword.png")
@export var sheet: Texture2D = SHEET
const ENDS: Array[float]=[0.20,0.47,0.70,0.85,1.22,1.62,1.96,2.4]
var _atlas: AtlasTexture=AtlasTexture.new()
var _age: float=0.0
var _facing: int=1
func _init() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 _atlas.atlas=SHEET;texture=_atlas
 visible=false
func present(age: float, facing: int) -> void:
 _atlas.atlas=sheet
 _age=age;_facing=facing;flip_h=facing<0
 var index: int=0
 while index<ENDS.size()-1 and age>ENDS[index]:index+=1
 _atlas.region=Rect2((index%4)*160,(index/4)*128,160,128)
 visible=true
 queue_redraw()
func _draw() -> void:
 var release: float=smoothstep(0.88,0.99,_age)*(1.0-smoothstep(1.1,1.7,_age))
 if release<=0:return
 var tip: Vector2=Vector2(_facing*2,-54)
 draw_line(tip+Vector2(0,-13),tip+Vector2(0,13),Color(0.85,1,0.85,release),2)
 draw_line(tip+Vector2(-9,0),tip+Vector2(9,0),Color(0.85,1,0.85,release),2)
 for i in range(9):
  var age: float=maxf(0,_age-0.8)
  var at: Vector2=tip+Vector2(cos(i*2.4)*age*55,sin(i*2.4)*age*32+age*age*22)
  draw_rect(Rect2(at.round(),Vector2(2,2)),Color(1,0.78,0.4,release))
