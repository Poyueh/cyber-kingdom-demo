extends Control
## A bounded, presentation-only camp tableau; no world simulation or save access.
const SKY: Texture2D=preload("res://art/planets/v002/void-sky.png")
const GROUND: Texture2D=preload("res://art/refuge/v001/ground.png")
const FIRE: Texture2D=preload("res://art/campaign/v001/campfire.png")
const FRAMES: SpriteFrames=preload("res://data/blacksteel_v003_frames.tres")
var _age: float=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
 if not is_visible_in_tree():return
 _age=fmod(_age+delta,120.0);queue_redraw()
func _draw() -> void:
 var scale_to_view: Vector2=size/Vector2(960,540)
 draw_set_transform(Vector2.ZERO,0,scale_to_view)
 draw_texture_rect(SKY,Rect2(-8,0,976,540),false,Color("899bab"))

 for index: int in range(16):
  draw_rect(Rect2(0,index*30,960,30),Color(0.015,0.025,0.045,0.53*(1.0-float(index)/16)))
 draw_rect(Rect2(0,445,960,95),Color("07131d"))
 for index: int in range(3):draw_texture_rect(GROUND,Rect2(index*384,433,384,32),false,Color("7e9898"))
 var fire_at: Vector2=Vector2(383,440)
 var frame: Texture2D=FRAMES.get_frame_texture(&"idle",int(_age*4)%FRAMES.get_frame_count(&"idle"))
 var scale: float=192.0/frame.get_height()
 var feet: Vector2=preload("res://presentation/grounded_art.gd").anchor(frame,Vector2(305,435),scale)
 draw_texture_rect(frame,Rect2(feet-Vector2(128,192),Vector2(256,192)),false)
 var fire_origin: Vector2=preload("res://presentation/grounded_art.gd").anchor(FIRE,Vector2(383,438),57.0/FIRE.get_height())
 draw_texture_rect(FIRE,Rect2(fire_origin-Vector2(34,57),Vector2(68,57)),false,Color(1.0,0.91+sin(_age*7.0)*0.07,0.76))
 for index: int in range(20):
  var phase: float=fposmod(_age*0.19+index*0.071,1.0)
  var at: Vector2=fire_at+Vector2(sin(index*2.3+phase*4)*22,-18-phase*120)
  draw_rect(Rect2(at.round(),Vector2(2,2)),Color(1,0.7,0.35,sin(phase*PI)*0.7))
 draw_line(Vector2(46,300),Vector2(194,300),Color("7b765c"),1)
 for index: int in range(7):
  var at: Vector2=Vector2(46+index*18,318)
  var diamond: PackedVector2Array=PackedVector2Array([at+Vector2(0,-3),at+Vector2(3,0),at+Vector2(0,3),at+Vector2(-3,0)])
  draw_colored_polygon(diamond,Color("dbb97d") if index==0 else Color("45616a"))
 for star: int in range(18):
  var at: Vector2=Vector2(60+fposmod(star*91,440),55+fposmod(star*57,230))
  draw_rect(Rect2(at,Vector2(1,1)),Color(0.65,0.84,0.92,0.18+0.15*sin(_age*0.7+star)))
 draw_set_transform(Vector2.ZERO)
