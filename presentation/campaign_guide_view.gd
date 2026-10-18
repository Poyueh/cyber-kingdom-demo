extends Node2D
const Icons=preload("res://presentation/ui_icons.gd")
const SYMBOLS={"rest":"camp","resident_income":"crystal","work_income":"hammer","merchant_return":"trade","merchant_wait":"trade","merchant":"trade","dragon":"dragon","upgrade":"camp","core":"camp","delivery":"hammer","escort":"hammer","join":"rift","fight":"rift","seal":"rift","clear_enemies":"sword","rift":"rift","camp":"camp","recruit":"person","tool":"hammer","harvest":"tree","hunter":"bow","guard":"sword","wall":"wall","defend":"camp","chest":"chest","trade":"trade","collect":"crystal","explore":"map"}
@export_range(28.0,60.0,2.0) var guidance_icon_size:=42.0
var _guide_label: Label
var reserved_caption: Rect2=Rect2()
var reserved_regions: Array[Rect2]=[]
var hint: Dictionary={}
var safe:=Rect2()
var player_x:=0.0
var active_button:=Rect2()
var can_invest:=false
var target_cost: int=0
var touch_hint:=true
var pulse:=0.0
const Motion=preload("res://presentation/spirit_motion.gd")
@export_range(40.0,100.0,2.0) var spirit_distance:=68.0
@export_range(80.0,150.0,2.0) var spirit_height:=104.0
var spirit_pose: Dictionary={"visible":false}
var _motion:=Motion.new()
var _lesson: String=""
var _celebrate_until: float=0.0
var _changed_at: float=0.0
var _target_screen: Vector2=Vector2.ZERO
var _last_lesson_rank: int=-1
const LESSON_RANKS: Array[String]=["core.light","core.recruit","core.hammer","core.harvest","core.working","core.collect","core.bow","core.wall","core.assign","core.first_warning","core.first_night","core.autonomy","core.second_night"]
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
 _target_screen=hero_screen+Vector2(float(hint.get("x",player_x))-player_x,float(hint.get("y",430))-430)
 if hint.get("core",false):
  var lesson: String=hint.get("lesson","")
  if lesson!=_lesson or game_time<_changed_at:
   var rank: int=LESSON_RANKS.find(lesson)
   if _lesson!="" and rank>_last_lesson_rank and game_time>=_changed_at:_celebrate_until=game_time+1.1
   _lesson=lesson;_last_lesson_rank=rank;_changed_at=game_time
  # Independent preparation is acknowledged, then the companion quietly steps aside.
  if hint.get("mood")=="rest":modulate.a=clampf(1.0-(game_time-_changed_at-7.0)/2.0,0.0,1.0)
 else:_lesson="";_last_lesson_rank=-1
 if is_instance_valid(_guide_label) and not hint.is_empty():
  var goals: Dictionary={"resident_income":"guide.income","work_income":"guide.work_income","merchant_return":"guide.merchant_return","merchant_wait":"guide.merchant_wait","merchant":"靠近商人領取龍晶；付一顆委託，隔天再補給。","camp":"拔出劍，點亮最後的營火。","recruit":"把龍晶交給流浪者，邀他留下。","tool":"提供工程錘，居民會自行取用。","harvest":"guide.harvest_local","hunter":"提供弓，讓居民狩獵和防守。","wall":"投入龍晶，讓工匠築起城牆。","defend":"夜色降臨，回去保護營火。","chest":"打開寶箱，補充龍晶。","collect":"靠近龍晶，自動收入袋中。","explore":"沿著荒地探索，尋找居民與資源。"}
  var goal: String=tr(goals.get(hint.kind,"擴建避難所，封印裂隙並擊敗巨龍。"))
  if hint.has("goal"):goal=tr(hint.goal)
  var command: String=tr("左右拖曳移動，拉遠加速") if touch_hint else tr("A／D 移動；同方向連按兩次並按住衝刺")
  if hint.kind in ["defend","fight","clear_enemies","dragon"]:
   command=tr("點右側劍鈕攻擊，再點可連斬") if touch_hint else tr("按 J 或滑鼠左鍵攻擊，再按可連斬")
  if spirit_pose.get("near",false):
   if hint.action in ["invest","open"]:command=tr("向下拖曳並按住投入／互動") if touch_hint else tr("按住 E 投入／互動")
   if hint.kind=="recruit":command=tr("在附近向下滑動丟出龍晶") if touch_hint else tr("按 E 丟出龍晶")
   if hint.action=="wait":command=tr("等待居民自行領取器具")
   if hint.key=="rocket" and hint.action=="wait":command=tr("guide.command.rocket_wait")
   if hint.kind in ["resident_income","collect"]:command=tr("guide.command.collect")
   if hint.kind=="work_income":command=tr("guide.command.work_wait")
   if hint.kind in ["merchant_return","merchant_wait"]:command=tr("guide.command.trade_wait")
   if hint.kind=="defend" and hint.action=="wait":command=tr("guide.command.defend_wait")
   if hint.kind=="delivery":command=tr("guide.command.delivery")
   if hint.kind in ["escort","join"]:command=tr("guide.command.escort")
   if hint.kind=="seal":command=tr("guide.command.seal")
  if hint.kind=="farewell":
   goal=tr("你已學會建立家園。需要指引時，回營火旁的引魂壇找我。")
   command=""
  _guide_label.text=goal if hint.get("core",false) else goal+"\n"+command
  _guide_label.size=Vector2(minf(310,safe.size.x-24),0)
  _guide_label.size.y=_guide_label.get_minimum_size().y
  var target: Vector2=spirit_pose.get("position",hero_screen)+Vector2(-_guide_label.size.x/2,-100-_guide_label.size.y)
  _guide_label.position=Vector2(clampf(target.x,safe.position.x+12,safe.end.x-_guide_label.size.x-12),clampf(target.y,safe.position.y+12,safe.end.y-_guide_label.size.y-12))
  _avoid_caption_rect(reserved_caption)
  for bounds: Rect2 in reserved_regions:_avoid_caption_rect(bounds)
 queue_redraw()
func _avoid_caption_rect(bounds: Rect2) -> void:
 if not bounds.has_area() or not bounds.intersects(_guide_label.get_rect()):return
 var left: float=bounds.position.x-_guide_label.size.x-8
 var right: float=bounds.end.x+8
 var left_fits: bool=left>=safe.position.x+12
 var right_fits: bool=right+_guide_label.size.x<=safe.end.x-12
 if left_fits and (not right_fits or absf(left-_guide_label.position.x)<=absf(right-_guide_label.position.x)):
  _guide_label.position.x=left
 elif right_fits:_guide_label.position.x=right
 else:
  var left_space: float=bounds.position.x-safe.position.x-20
  var right_space: float=safe.end.x-bounds.end.x-20
  _guide_label.size.x=maxf(1,maxf(left_space,right_space))
  _guide_label.size.y=_guide_label.get_minimum_size().y
  _guide_label.position.x=safe.position.x+12 if left_space>=right_space else bounds.end.x+8
  _guide_label.position.y=clampf(_guide_label.position.y,safe.position.y+12,safe.end.y-_guide_label.size.y-12)

func _icon(key: String,at: Vector2,size: float=24,tint:=Color("dce9dc")) -> void:
 draw_texture_rect(Icons.get_icon(key),Rect2(at-Vector2.ONE*size/2,Vector2.ONE*size),false,tint)
func _draw() -> void:
 if hint.is_empty() or not spirit_pose.visible:return
 var at: Vector2=spirit_pose.position
 var direction: float=spirit_pose.direction
 var phase: float=spirit_pose.phase
 var mood: String=spirit_pose.get("mood","lead")
 var celebrating: bool=phase<_celebrate_until and hint.get("core",false)
 if hint.get("core",false) and mood!="rest":_draw_target(phase,mood)
 if celebrating:
  at.y-=sin((1.1-(_celebrate_until-phase))/1.1*PI)*10
  for i: int in range(6):
   var angle: float=TAU*float(i)/6+phase
   draw_rect(Rect2((at+Vector2(cos(angle),sin(angle))*34).round(),Vector2(3,3)),Color("e5c997"))
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
 if hint.get("core",false):
  if celebrating:elbow=Vector2(18,-20);hand=Vector2(21,-34)
  elif mood=="work":elbow=Vector2(17,0);hand=Vector2(21,5+beckon*3)
  elif mood=="receive":elbow=Vector2(18,-4);hand=Vector2(26,-5-absf(beckon)*5)
  elif mood=="guard":elbow=Vector2(17,-13);hand=Vector2(18,-24)
  elif mood=="rest":elbow=Vector2(13,2);hand=Vector2(14,10)
  elif spirit_pose.near:elbow=Vector2(19,-2);hand=Vector2(28,8+beckon*2)
 draw_line(Vector2(9,-5),elbow,Color("5ab5b3"),5)
 draw_line(elbow,hand,Color("9cdfca"),4)
 draw_rect(Rect2(hand.round()-Vector2(2,2),Vector2(7,4)),Color("d9fff0"))
 draw_line(Vector2(-10,-5),Vector2(-18,-2+sin(phase*3.4+1)*6),Color("9cdfca"),4)
 draw_arc(Vector2(0,-35),19+sin(phase*2)*2,0.2,PI-0.2,12,Color(0.8,0.91,0.74,0.55),2)
 if not spirit_pose.near and mood not in ["rest","work","guard"]:
  for i in range(2):
   var x:=39+i*9
   var color:=Color(0.68,0.94,0.85,0.4+0.4*sin(phase*4-i))
   draw_line(Vector2(x,-12),Vector2(x+4,-8),color,2)
   draw_line(Vector2(x+4,-8),Vector2(x,-4),color,2)
 draw_set_transform(Vector2.ZERO)
 var badge:=at+Vector2(0,-65)
 draw_circle(badge,guidance_icon_size*0.67,Color(0.025,0.10,0.14,0.88))
 draw_arc(badge,guidance_icon_size*0.67,0,TAU,24,Color(0.55,0.92,0.8,0.6+sin(phase*3)*0.15),2)
 _icon("sword" if hint.get("core",false) and mood=="guard" else "spirit" if hint.kind=="farewell" else SYMBOLS.get(hint.kind,"map"),badge,guidance_icon_size,Color("e5c997") if mood=="guard" else Color("c7ffe2"))
 if can_invest and target_cost>0:_icon("crystal",at+Vector2(40,-58),26)
 if hint.has("seal_progress"):
  draw_rect(Rect2(at+Vector2(-18,26),Vector2(36,3)),Color("294650"))
  draw_rect(Rect2(at+Vector2(-18,26),Vector2(36*clampf(hint.seal_progress,0,1),3)),Color("9cdfca"))
 if can_invest and touch_hint:
  var from:=at+Vector2(40,-36+sin(phase*4)*3)
  draw_line(from,from+Vector2(0,10),Color("abe6d3"),2)
  draw_line(from+Vector2(-4,6),from+Vector2(0,10),Color("abe6d3"),2)
  draw_line(from+Vector2(4,6),from+Vector2(0,10),Color("abe6d3"),2)

func _draw_target(phase: float, mood: String) -> void:
 # Only mark a target actually visible in the world. Never place an offscreen fake object.
 if not safe.grow(-16).has_point(_target_screen):return
 var at: Vector2=_target_screen.round()+Vector2(0,5)
 var tint: Color=Color("e5c997") if mood=="guard" else Color("9cdfca")
 tint.a=0.40+sin(phase*3)*0.16
 for side: int in [-1,1]:
  draw_line(at+Vector2(side*13,0),at+Vector2(side*25,0),tint,2)
  draw_line(at+Vector2(side*25,0),at+Vector2(side*25,-7),tint,2)
 for i: int in range(3):
  var travel: float=fposmod(phase*0.4+i/3.0,1.0)
  var point: Vector2=at+Vector2(sin(phase+i*2)*12,-16-travel*24)
  var mote: Color=tint;mote.a*=1-travel
  draw_rect(Rect2(point.round(),Vector2(2,2)),mote)
