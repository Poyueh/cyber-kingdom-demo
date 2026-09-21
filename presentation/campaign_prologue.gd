extends Control
## A skippable, bounded prologue explains the player's verbs before the title.
signal completed
const SKY=preload("res://art/refuge/v001/skyline.png")
const SHRINE=preload("res://art/frontier/v002/hall-1.png")
const FIRE=preload("res://art/campaign/v001/campfire.png")
const KNIGHT=preload("res://art/characters/unarmed-v001/run.png")
const WALL=preload("res://art/structures/immersive-v001/wall-2.png")
const PEOPLE=preload("res://art/characters/resident-motion-v002/residents.png")
const Icons=preload("res://presentation/ui_icons.gd")
const CAPTIONS: Array[String]=[
 "魔法與巨龍統治荒野，人類只剩機械義肢與一縷火光。",
 "拔出龍晶之劍，點亮營火，為流浪的人建立家園。",
 "把龍晶交給居民，提供器具，讓他們採集、建造與狩獵。",
 "夜裡守住營火。有限的龍晶，要留給自己還是居民？",
 "封印兩側地獄之門，召出巨龍。帶著你的王國，迎戰最後一夜。"]
const SHOT_SECONDS: float=4.5
var _elapsed: float=0
var _caption: Label
var _skip: Button
var _finished: bool=false
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 _caption=Label.new();add_child(_caption)
 _caption.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 _caption.add_theme_font_size_override("font_size",22)
 _caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _skip=Button.new();_skip.text=tr("跳過前導");_skip.custom_minimum_size=Vector2(130,48);add_child(_skip)
 _skip.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 _skip.pressed.connect(finish)
 _layout()
 resized.connect(_layout)
func _layout() -> void:
 _caption.position=Vector2(size.x*0.1,size.y*0.78)
 _caption.size=Vector2(size.x*0.8,size.y*0.18)
 _skip.position=Vector2(maxf(0,size.x-154),20)
func _process(seconds: float) -> void:
 if _finished:return
 _elapsed+=seconds
 if _elapsed>=CAPTIONS.size()*SHOT_SECONDS:finish();return
 _caption.text=tr(CAPTIONS[mini(CAPTIONS.size()-1,int(_elapsed/SHOT_SECONDS))])
 var phase: float=fposmod(_elapsed,SHOT_SECONDS)
 _caption.modulate.a=minf(1,phase*2)*minf(1,(SHOT_SECONDS-phase)*2)
 queue_redraw()
func finish() -> void:
 if _finished:return
 _finished=true;completed.emit();queue_free()
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
  get_viewport().set_input_as_handled();finish()
func _draw() -> void:
 var shot: int=mini(CAPTIONS.size()-1,int(_elapsed/SHOT_SECONDS))
 var phase: float=fposmod(_elapsed,SHOT_SECONDS)/SHOT_SECONDS
 draw_rect(Rect2(Vector2.ZERO,size),Color("0b1220"))
 var horizon: float=size.y*0.68
 draw_texture_rect(SKY,Rect2(-phase*20,20,size.x+40,horizon),false,Color(0.5,0.64,0.78))
 draw_rect(Rect2(0,horizon,size.x,size.y-horizon),Color("101d2a"))
 var center: Vector2=Vector2(size.x*0.5,horizon)
 if shot>=1:
  draw_texture_rect(SHRINE,Rect2(center-Vector2(90,145),Vector2(180,145)),false)
  draw_texture_rect(FIRE,Rect2(center+Vector2(70,-65),Vector2(66,66)),false)
  for i in range(12):
   var rise: float=fposmod(_elapsed*0.9+i*0.17,1)
   draw_rect(Rect2(center+Vector2(sin(i+_elapsed*2)*14,-15-rise*55),Vector2(4,7)),Color(1,0.53+rise*0.3,0.19,1-rise))
 if shot<2:
  var at: Vector2=center+Vector2(-240+phase*100,-112)
  var frame: int=int(_elapsed*9)%8
  draw_texture_rect_region(KNIGHT,Rect2(at,Vector2(149,112)),Rect2((frame%4)*128,floori(frame/4.0)*96,128,96))
  if shot==1:
   draw_texture_rect(Icons.get_icon("sword"),Rect2(center+Vector2(-25,-45-phase*90),Vector2(45,45)),false,Color(0.8,1,0.9,1-phase))
 for i in range(0 if shot<2 else 4):
  var x: float=center.x-200+i*74+phase*35
  var frame: int=int(_elapsed*7+i)%8
  var row: int=0 if shot<2 else (10 if i%2==0 else 6)
  draw_texture_rect_region(PEOPLE,Rect2(x,horizon-70,70,70),Rect2(frame*64,row*64,64,64))
 if shot==2:
  for i in range(3):
   var progress: float=fposmod(_elapsed*0.65+i*0.3,1)
   var pos: Vector2=center+Vector2(-180+progress*220,-65-sin(progress*PI)*70)
   draw_texture_rect(Icons.get_icon("crystal"),Rect2(pos,Vector2(22,22)),false)
 if shot>=3:
  for direction in [-1,1]:draw_texture_rect(WALL,Rect2(center+Vector2(direction*270-40,-145),Vector2(80,145)),false)
  draw_rect(Rect2(Vector2.ZERO,Vector2(size.x,horizon)),Color(0.02,0.015,0.13,0.25))
 if shot==4:
  for direction in [-1,1]:
   var at: Vector2=center+Vector2(direction*350,-130)
   draw_texture_rect(Icons.get_icon("rift"),Rect2(at,Vector2(64,64)),false,Color(0.8,0.4,0.9,1-phase))
  var at: Vector2=Vector2(size.x*0.5-80,65+sin(_elapsed*2)*10)
  draw_texture_rect(Icons.get_icon("dragon"),Rect2(at,Vector2(160,140)),false,Color(0.85,0.61,0.66,phase))
 draw_rect(Rect2(0,0,size.x,16),Color.BLACK)
