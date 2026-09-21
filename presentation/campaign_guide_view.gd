extends Node2D
const Icons=preload("res://presentation/ui_icons.gd")
const SYMBOLS={"dragon":"dragon","upgrade":"camp","core":"camp","delivery":"hammer","escort":"hammer","join":"rift","fight":"rift","seal":"rift","clear_enemies":"sword","rift":"rift","camp":"camp","recruit":"person","tool":"hammer","harvest":"tree","hunter":"bow","guard":"sword","wall":"wall","defend":"camp","chest":"chest","trade":"trade","collect":"crystal","explore":"map"}
@export_range(28.0,60.0,2.0) var guidance_icon_size:=42.0
var _guide_label: Label
var hint: Dictionary={}
var safe:=Rect2()
var player_x:=0.0
var active_button:=Rect2()
var can_invest:=false
var touch_hint:=true
var pulse:=0.0
const Motion=preload("res://presentation/spirit_motion.gd")
@export_range(40.0,100.0,2.0) var spirit_distance:=68.0
@export_range(80.0,150.0,2.0) var spirit_height:=104.0
var spirit_pose: Dictionary={"visible":false}
var _motion:=Motion.new()
# Original pixel silhouette: broken mechanical halo, hood, crystal heart and trailing cloak.
const GHOST=[
 ".....gg...gg.....",
 "....g.......g....",
 "......aaaa.......",
 "....aaabbbaa.....",
 "...aabbbbbbaa....",
 "...abdddddbba....",
 "..abbdeeeddba....",
 "..abbdeeedbba....",
 "...abbdddbbaa....",
 "....abbbbbaa.....",
 "...aaaccccaaa....",
 "..aabccggccbaa...",
 "..abbccggccbba...",
 "..abbccccccbba...",
 "...abbccccbba....",
 "...aabbbbbbaa....",
 "....aabbbbaa.....",
 "....aabbbba......",
 ".....aabba.......",
 ".....aabba.......",
 "......aab........",
 ".......aa........"]
const PALETTE={"a":Color("306b78"),"b":Color("5ab5b3"),"c":Color("9cdfca"),"d":Color("16333e"),"e":Color("d9fff0"),"g":Color("e5c997")}
func _ready() -> void:
 _guide_label=Label.new()
 _guide_label.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 _guide_label.add_theme_font_size_override("font_size",16)
 _guide_label.add_theme_color_override("font_shadow_color",Color(0.01,0.025,0.04,0.98))
 _guide_label.add_theme_constant_override("shadow_offset_x",2)
 _guide_label.add_theme_constant_override("shadow_offset_y",2)
 _guide_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _guide_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _guide_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(_guide_label)

func present(advice: Dictionary,area: Rect2,x: float,button: Rect2,ready: bool) -> void:
 hint=advice;safe=area;player_x=x;active_button=button;can_invest=ready
 visible=not hint.is_empty()
 queue_redraw()
func track(hero_screen: Vector2, game_time: float) -> void:
 _motion.follow_distance=spirit_distance;_motion.follow_height=spirit_height
 spirit_pose=_motion.sample(hint,hero_screen,player_x,safe,game_time)
 pulse=fposmod(game_time,2)
 if is_instance_valid(_guide_label) and not hint.is_empty():
  var goals: Dictionary={"camp":"拔出劍，點亮最後的營火。","recruit":"把龍晶交給流浪者，邀他留下。","tool":"提供工程錘，居民會自行取用。","harvest":"委託工匠採集，帶回龍晶。","hunter":"提供弓，讓居民狩獵和防守。","wall":"投入龍晶，讓工匠築起城牆。","defend":"夜色降臨，回去保護營火。","chest":"打開寶箱，補充龍晶。","collect":"靠近龍晶，自動收入袋中。","explore":"沿著荒地探索，尋找居民與資源。"}
  var goal: String=tr(goals.get(hint.kind,"擴建避難所，封印雙門並擊敗巨龍。"))
  var command: String=tr("左右拖曳移動，拉遠加速") if touch_hint else tr("A／D 移動；Shift 快跑")
  if hint.kind in ["defend","fight","clear_enemies","dragon"]:
   command=tr("點右側劍鈕攻擊，再點可連斬") if touch_hint else tr("按 J 攻擊，再按可連斬")
  if spirit_pose.get("near",false):
   if hint.action in ["invest","open"]:command=tr("向下拖曳並按住投入／互動") if touch_hint else tr("按住 E 投入／互動")
   if hint.kind=="recruit":command=tr("在附近向下滑動丟出龍晶") if touch_hint else tr("按 E 丟出龍晶")
   if hint.action=="wait":command=tr("等待居民自行領取器具")
  if hint.kind=="farewell":
   goal=tr("你已學會建立家園。需要指引時，回營火旁的引魂壇找我。")
   command=""
  _guide_label.text=goal+"\n"+command
  _guide_label.size=Vector2(minf(310,safe.size.x-24),64)
  var target: Vector2=spirit_pose.get("position",hero_screen)+Vector2(-_guide_label.size.x/2,-155)
  _guide_label.position=Vector2(clampf(target.x,safe.position.x+12,safe.end.x-_guide_label.size.x-12),clampf(target.y,safe.position.y+12,safe.end.y-90))
 queue_redraw()
func _icon(key: String,at: Vector2,size: float=24,tint:=Color("dce9dc")) -> void:
 draw_texture_rect(Icons.get_icon(key),Rect2(at-Vector2.ONE*size/2,Vector2.ONE*size),false,tint)
func _draw() -> void:
 if hint.is_empty() or not spirit_pose.visible:return
 var at: Vector2=spirit_pose.position
 var direction: float=spirit_pose.direction
 var phase: float=spirit_pose.phase
 # Distant motes drift back toward the knight; no collision or interaction target.
 for i in range(4):
  var travel:=fposmod(phase*0.6+i*0.25,1.0)
  var point:=at+Vector2(-direction*(12+travel*21),12+travel*23)
  draw_rect(Rect2(point.round(),Vector2(2,2)),Color(0.42,0.86,0.83,(1-travel)*0.65))
 draw_set_transform(at,0,Vector2(direction,1))
 for y in range(GHOST.size()):
  var sway: float=roundf(sin(phase*3-y*0.25)*maxf(0,y-12)*0.2)
  for x in range(GHOST[y].length()):
   var ink: String=GHOST[y][x]
   if PALETTE.has(ink):
    var color: Color=PALETTE[ink];color.a=0.90 if y<15 else 0.76
    draw_rect(Rect2(Vector2(x*2-17+sway,y*2-29),Vector2(2,2)),color)
 # Alternate beckoning and pointing; the free hand and halo answer the motion.
 var beckon:=sin(phase*3.4)
 var elbow:=Vector2(18,-10-beckon*4)
 var hand:=Vector2(28,-12-maxf(0,beckon)*13)
 draw_line(Vector2(9,-5),elbow,Color("5ab5b3"),5)
 draw_line(elbow,hand,Color("9cdfca"),4)
 draw_rect(Rect2(hand.round()-Vector2(2,2),Vector2(7,4)),Color("d9fff0"))
 draw_line(Vector2(-10,-5),Vector2(-18,-2+sin(phase*3.4+1)*6),Color("9cdfca"),4)
 draw_arc(Vector2(0,-35),19+sin(phase*2)*2,0.2,PI-0.2,12,Color(0.8,0.91,0.74,0.55),2)
 if not spirit_pose.near:
  for i in range(2):
   var x:=39+i*9
   var color:=Color(0.68,0.94,0.85,0.4+0.4*sin(phase*4-i))
   draw_line(Vector2(x,-12),Vector2(x+4,-8),color,2)
   draw_line(Vector2(x+4,-8),Vector2(x,-4),color,2)
 draw_set_transform(Vector2.ZERO)
 var badge:=at+Vector2(0,-65)
 draw_circle(badge,guidance_icon_size*0.67,Color(0.025,0.10,0.14,0.88))
 draw_arc(badge,guidance_icon_size*0.67,0,TAU,24,Color(0.55,0.92,0.8,0.6+sin(phase*3)*0.15),2)
 _icon("spirit" if hint.kind=="farewell" else SYMBOLS.get(hint.kind,"map"),badge,guidance_icon_size,Color("c7ffe2"))
 if can_invest:_icon("crystal",at+Vector2(40,-58),26)
 if hint.has("seal_progress"):
  draw_rect(Rect2(at+Vector2(-18,26),Vector2(36,3)),Color("294650"))
  draw_rect(Rect2(at+Vector2(-18,26),Vector2(36*clampf(hint.seal_progress,0,1),3)),Color("9cdfca"))
 if can_invest and touch_hint:
  var from:=at+Vector2(40,-36+sin(phase*4)*3)
  draw_line(from,from+Vector2(0,10),Color("abe6d3"),2)
  draw_line(from+Vector2(-4,6),from+Vector2(0,10),Color("abe6d3"),2)
  draw_line(from+Vector2(4,6),from+Vector2(0,10),Color("abe6d3"),2)
