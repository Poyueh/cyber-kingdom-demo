extends Node2D
## Screen-space cues replace the permanent numerical dashboard.
const Dawn=preload("res://presentation/dawn_banner.gd")
const Icons=preload("res://presentation/ui_icons.gd")
var sim: RefCounted
var hero_screen: Vector2=Vector2.ZERO
var safe: Rect2=Rect2()
var _day: int=0
var _dawn_age: float=0.0
var _alarm: float=0.0
var _core: int=-1
var _time: float=0.0
var _last_sim: RefCounted
var paused: bool=false
var _font: Font
var purse: Node2D=preload("res://presentation/crystal_purse_view.gd").new()
func _ready() -> void:
 add_child(purse)
 _font=preload("res://presentation/localized_font.gd").current()
func present(run: RefCounted, at: Vector2, area: Rect2, stopped: bool) -> void:
 sim=run;hero_screen=at;safe=area;paused=stopped
 if not is_same(_last_sim,sim):purse.reset()
 purse.visible=sim.life.enabled and sim.is_running() and not stopped
 purse.present(float(sim.pouch.amount)/sim.pouch.capacity,area,stopped)
 if not is_same(_last_sim,sim):
  _last_sim=sim;_day=0;_core=sim.mission.core_hp;_alarm=0;_dawn_age=0
 if _day!=sim.clock.day:_day=sim.clock.day;_dawn_age=Dawn.DURATION
 if _core>sim.mission.core_hp:_alarm=3.0
 _core=sim.mission.core_hp
 queue_redraw()
func _process(seconds: float) -> void:
 if paused:return
 _time=fposmod(_time+seconds,100.0)
 _dawn_age=maxf(0,_dawn_age-seconds);_alarm=maxf(0,_alarm-seconds)
 queue_redraw()
func _caption(text: String, y: float, size: int, ink: Color) -> void:
 var width: float=_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 draw_string(_font,Vector2(safe.get_center().x-width/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,ink)
func _draw() -> void:
 if sim==null or _font==null or not sim.life.enabled:return
 var viewport: Rect2=get_viewport_rect()
 if paused:return
 var danger: float=(1.0 if sim.pouch.amount==0 and not sim.can_wield_sword() else 0.0) if sim.survival.enabled else 1.0-clampf(float(sim.hero.hp)/sim.hero.stats.max_hp/0.4,0,1)
 if danger>0:
  for side in [0,1]:
   draw_rect(Rect2(viewport.position+Vector2(side*(viewport.size.x-12),0),Vector2(12,viewport.size.y)),Color(0.8,0.08,0.1,danger*(0.16+sin(_time*3)*0.08)))
 if _dawn_age>0:
  Dawn.draw(self,_font,safe,_day,_dawn_age,tr("第 %d 天"))
 if _alarm>0:
  var alpha: float=minf(1,_alarm)*(0.85+0.15*sin(_time*9))
  var side: float=signf(sim.world.sites.hall-sim._hero_x)
  var at: Vector2=Vector2(safe.get_center().x+side*minf(210,safe.size.x*0.25),safe.position.y+128)
  draw_texture_rect(Icons.get_icon("camp"),Rect2(at-Vector2(22,22),Vector2(44,44)),false,Color(1,0.46,0.23,alpha))
  draw_texture_rect(Icons.get_icon("right" if side>=0 else "left"),Rect2(at+Vector2(side*39-14,-14),Vector2(28,28)),false,Color(1,0.8,0.5,alpha))
  for edge in [0,1]:draw_rect(Rect2(viewport.position+Vector2(edge*(viewport.size.x-7),0),Vector2(7,viewport.size.y)),Color(1,0.32,0.13,alpha*0.45))
  _caption(tr("營火正在受襲！"),safe.position.y+175,23,Color(1,0.71,0.47,alpha))
 if not sim.is_running():return
