extends Node2D
const Icons=preload("res://presentation/ui_icons.gd")
const Motion=preload("res://presentation/spirit_motion.gd")
const Art=preload("res://presentation/spirit_companion_art.gd")
const Style=preload("res://data/spirit_companion.tres")
const SYMBOLS={"rest":"camp","resident_income":"crystal","work_income":"hammer","merchant_return":"trade","merchant_wait":"trade","merchant":"trade","dragon":"dragon","upgrade":"camp","core":"camp","delivery":"hammer","escort":"hammer","join":"rift","fight":"rift","seal":"rift","clear_enemies":"sword","rift":"rift","camp":"camp","recruit":"person","tool":"hammer","harvest":"tree","hunter":"bow","guard":"sword","wall":"wall","defend":"camp","chest":"chest","trade":"trade","collect":"crystal","explore":"map"}
## These tasks already say "follow me" in their own words.
const LEADING_KINDS: Array[String]=["explore"]
const LESSON_RANKS: Array[String]=["core.light","core.recruit","core.hammer","core.harvest","core.working","core.collect","core.bow","core.wall","core.assign","core.first_warning","core.first_night","core.autonomy","core.second_night"]
const GOALS: Dictionary={"resident_income":"guide.income","work_income":"guide.work_income","merchant_return":"guide.merchant_return","merchant_wait":"guide.merchant_wait","merchant":"靠近商人領取龍晶；付一顆委託，隔天再補給。","camp":"拔出劍，點亮最後的營火。","recruit":"把龍晶交給流浪者，邀他留下。","tool":"提供工程錘，居民會自行取用。","harvest":"guide.harvest_local","hunter":"提供弓，讓居民狩獵和防守。","wall":"投入龍晶，讓工匠築起城牆。","defend":"夜色降臨，回去保護營火。","chest":"打開寶箱，補充龍晶。","collect":"靠近龍晶，自動收入袋中。","explore":"沿著荒地探索，尋找居民與資源。"}
@export_range(18.0,30.0,2.0) var guidance_icon_size: float=22.0
var _guide_label: Label
var reserved_caption: Rect2=Rect2()
var reserved_regions: Array[Rect2]=[]
var hint: Dictionary={}
var safe: Rect2=Rect2()
var player_x: float=0.0
var active_button: Rect2=Rect2()
var can_invest: bool=false
var target_cost: int=0
var touch_hint: bool=true
var pulse: float=0.0
var spirit_pose: Dictionary={"visible":false}
var _motion: RefCounted=Motion.new()
var _lesson: String=""
var _celebrate_until: float=0.0
var _changed_at: float=0.0
var _target_screen: Vector2=Vector2.ZERO
var _last_lesson_rank: int=-1
var _blocked: Array[Rect2]=[]
var _hero_bounds: Rect2=Rect2()
var _art_clear: bool=true
var _show_symbol: bool=false
var _caption_allowed: bool=false

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
 _guide_label.hide();add_child(_guide_label)

func present(advice: Dictionary, area: Rect2, x: float, button: Rect2, ready: bool) -> void:
 hint=advice;safe=area;player_x=x;active_button=button;can_invest=ready
 visible=not hint.is_empty()
 if hint.is_empty() and is_instance_valid(_guide_label):_guide_label.hide()
 queue_redraw()

func track(hero_screen: Vector2, game_time: float) -> void:
 _blocked=reserved_regions.duplicate()
 if reserved_caption.has_area():_blocked.append(reserved_caption)
 _hero_bounds=Rect2(hero_screen+Vector2(-36,-84),Vector2(72,100))
 spirit_pose=_motion.sample(hint,hero_screen,player_x,safe,game_time,_blocked)
 if hint.is_empty():return
 pulse=fposmod(game_time,2)
 _target_screen=hero_screen+Vector2(float(hint.get("x",player_x))-player_x,float(hint.get("y",430))-430)
 _track_progress(game_time)
 var art_bounds: Rect2=Rect2(spirit_pose.position-Vector2(40,46),Vector2(80,86))
 _art_clear=_is_clear(art_bounds)
 var near_age: float=spirit_pose.near_age
 _show_symbol=spirit_pose.near and ((near_age>=0 and near_age<Style.cue_seconds) or spirit_pose.idle>=Style.reminder_interval)
 _caption_allowed=_needs_caption()
 _present_caption()
 queue_redraw()

func _track_progress(game_time: float) -> void:
 if not hint.get("core",false):
  _lesson="";_last_lesson_rank=-1;_celebrate_until=0
  return
 var lesson: String=hint.get("lesson","")
 if lesson!=_lesson or game_time<_changed_at:
  var rank: int=LESSON_RANKS.find(lesson)
  _celebrate_until=game_time+1.1 if _lesson!="" and rank>_last_lesson_rank and game_time>=_changed_at else 0.0
  _lesson=lesson;_last_lesson_rank=rank;_changed_at=game_time
 if hint.get("mood")=="rest":modulate.a=clampf(1.0-(game_time-_changed_at-7.0)/2.0,0.0,1.0)

func _needs_caption() -> bool:
 # Each new task is spoken at once, even on the move; arrival and a stalled player are answered soon.
 if hint.get("mood")=="rest" or hint.kind=="farewell":return spirit_pose.age>=0.8 and spirit_pose.age<3.8
 if spirit_pose.age>=Style.caption_delay and spirit_pose.age<Style.caption_delay+Style.announce_seconds:return true
 if absf(spirit_pose.speed)>35:return false
 if spirit_pose.near and spirit_pose.near_age>=Style.caption_delay and spirit_pose.near_age<Style.caption_delay+Style.caption_seconds:return true
 return spirit_pose.idle>=Style.reminder_interval and fposmod(spirit_pose.idle-Style.reminder_interval,Style.reminder_interval)<Style.reminder_seconds

func _present_caption() -> void:
 if not is_instance_valid(_guide_label):return
 var goal: String=tr(hint.get("goal",GOALS.get(hint.kind,"擴建避難所，封印裂隙並擊敗巨龍。")))
 if not spirit_pose.near and spirit_pose.mood not in ["rest","guard"] and hint.kind not in LEADING_KINDS:goal=tr("spirit.lead %s")%goal
 if hint.kind=="farewell":goal=tr("你已學會建立家園。需要指引時，回營火旁的引魂壇找我。")
 _guide_label.text=goal
 _guide_label.size=Vector2(minf(260,safe.size.x-24),0)
 _guide_label.size.y=_guide_label.get_minimum_size().y
 var at: Vector2=spirit_pose.position
 var caption_size: Vector2=_guide_label.size
 var candidates: Array[Vector2]=[at+Vector2(-caption_size.x/2,-56-caption_size.y),at+Vector2(50,-caption_size.y/2),at+Vector2(-caption_size.x-50,-caption_size.y/2)]
 _guide_label.hide()
 for target: Vector2 in candidates:
  target=Vector2(clampf(target.x,safe.position.x+12,safe.end.x-caption_size.x-12),clampf(target.y,safe.position.y+12,safe.end.y-caption_size.y-12))
  _guide_label.position=target.round()
  var bounds: Rect2=_guide_label.get_rect()
  if _is_clear(bounds) and not bounds.intersects(_hero_bounds):
   _guide_label.visible=_caption_allowed and _art_clear
   return

func _is_clear(bounds: Rect2) -> bool:
 if not safe.encloses(bounds):return false
 for region: Rect2 in _blocked:
  if region.has_area() and region.grow(6).intersects(bounds):return false
 return true

func _icon(key: String, at: Vector2, size: float, tint: Color) -> void:
 var bounds: Rect2=Rect2(at-Vector2.ONE*size/2,Vector2.ONE*size)
 if _is_clear(bounds) and not bounds.intersects(_hero_bounds):draw_texture_rect(Icons.get_icon(key),bounds,false,tint)

func _draw() -> void:
 if hint.is_empty() or not spirit_pose.visible or not _art_clear:return
 var phase: float=spirit_pose.phase
 var mood: String=spirit_pose.mood
 if mood!="rest":_draw_target(phase,mood)
 Art.paint(self,spirit_pose,phase<_celebrate_until and hint.get("core",false))
 # A small held symbol appears on arrival; no permanent badge above the character.
 if _show_symbol:
  var hand: Vector2=spirit_pose.position+Vector2(spirit_pose.direction*30,-14)
  _icon("crystal" if can_invest and target_cost>0 else SYMBOLS.get(hint.kind,"map"),hand,guidance_icon_size,Color("c7e5cf"))
 if hint.has("seal_progress"):
  var bounds: Rect2=Rect2(spirit_pose.position+Vector2(-18,36),Vector2(36,3))
  if _is_clear(bounds):
   draw_rect(bounds,Color("294650"));draw_rect(Rect2(bounds.position,Vector2(36*clampf(hint.seal_progress,0,1),3)),Color("9cdfca"))

func _draw_target(phase: float, mood: String) -> void:
 # A restrained pulse at the real object, never a fake target at the screen edge.
 if not safe.grow(-16).has_point(_target_screen):return
 var bounds: Rect2=Rect2(_target_screen+Vector2(-26,-35),Vector2(52,45))
 if not _is_clear(bounds):return
 var at: Vector2=_target_screen.round()+Vector2(0,5)
 var tint: Color=Color("e5c997") if mood=="guard" else Color("9cdfca")
 tint.a=0.24+sin(phase*2.6)*0.08
 for side: int in [-1,1]:
  draw_line(at+Vector2(side*14,0),at+Vector2(side*24,0),tint,2)
 for i: int in range(2):
  var travel: float=fposmod(phase*0.35+i*0.5,1.0)
  var point: Vector2=at+Vector2(sin(phase+i*2)*10,-12-travel*20)
  var mote: Color=tint;mote.a*=1-travel
  draw_rect(Rect2(point.round(),Vector2(2,2)),mote)
