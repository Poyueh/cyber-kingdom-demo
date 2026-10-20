extends RefCounted
## Facility acting reads existing transactions; it never produces items or workers.
const Cast=preload("res://data/settlement_identity.tres")
const Style=preload("res://data/attendant_behavior.tres")
const State=preload("res://presentation/attendant_state.gd")
const Details=preload("res://presentation/attendant_details.gd")
const FLOOR_Y:=430.0
var states: Array[State]=[]
var _sim: RefCounted
var _clock: float=0.0

func present(sim: RefCounted, hero_x: float, cinematic: bool=false) -> void:
 var reset: bool=not is_same(_sim,sim) or sim.workforce.elapsed<_clock
 if reset:
  assert(Cast.valid() and Style.valid())
  _sim=sim;_clock=sim.workforce.elapsed;states.clear()
  for index: int in range(Cast.sites.size()):
   var state: State=State.new()
   state.work_age=float(index)*0.63
   states.append(state)
 var delta: float=maxf(0.0,sim.workforce.elapsed-_clock)
 _clock=sim.workforce.elapsed
 for index: int in range(states.size()):
  _observe(index,hero_x,delta,reset,cinematic)

func site_x(site: StringName) -> float:
 if site==&"armory" and _sim.command.enabled:return _sim.command.barracks_x()
 return _sim.world.sites[site]

func _observe(index: int, hero_x: float, delta: float, reset: bool, cinematic: bool) -> void:
 var state: State=states[index]
 var site: StringName=Cast.sites[index]
 var x: float=site_x(site)+Cast.offsets[index].x
 var work_facing: float=-signf(Cast.offsets[index].x)
 var value: int=_service_value(site)
 var payment: Dictionary=_latest_effect(&"pay",site_x(site))
 var module: Dictionary=_latest_effect(&"module_equipped",_sim.world.sites[site]) if site==&"drill" else {}
 var visible: bool=_sim.frontier.city_level>0 and _sim.site_visible(site) and (site in [&"hall",&"drill"] or _sim.built.get(site,false))
 if site==&"armory" and _sim.command.enabled:visible=_sim.command.unlocked()
 var initialized: bool=reset or not state.visible
 var paid: bool=not initialized and not payment.is_empty() and not is_same(payment,state.payment)
 var changed_module: bool=not module.is_empty() and not is_same(module,state.module_event)
 # A worker may collect the new tool in the same simulation step. Completion
 # follows the real paid transaction even when the rack count is unchanged.
 var served: bool=not initialized and (value>state.service_value or changed_module or (paid and not _pending(site)))
 state.service_value=value;state.payment=payment;state.module_event=module
 state.visible=visible
 if not visible:
  state.near=false;state.pending_greeting=false;state.mode=State.Mode.WORK
  return
 state.age+=delta;state.cooldown=maxf(0.0,state.cooldown-delta)
 if cinematic:
  state.mode=State.Mode.WORK;state.pending_greeting=false;state.near=false
  state.work_age+=delta;state.facing=work_facing
  _pose(index);return
 var danger: float=_danger(x,Style.safety_radius if state.mode==State.Mode.ALERT else Style.danger_radius)
 if not is_inf(danger):
  if state.mode!=State.Mode.ALERT:state.enter(State.Mode.ALERT,1.0 if danger>x else -1.0)
  state.safe_age=0.0;state.pending_greeting=false;state.near=true
 elif state.mode==State.Mode.ALERT:
  state.safe_age+=delta
  if state.safe_age>=Style.safety_seconds:state.enter(State.Mode.WORK,work_facing)
 if state.mode==State.Mode.ALERT:
  _pose(index);return
 var facing: float=1.0 if hero_x>=x else -1.0
 if served:
  state.enter(State.Mode.SERVICE,facing);state.pending_greeting=false
 elif paid and state.mode!=State.Mode.SERVICE:
  state.enter(State.Mode.ACKNOWLEDGE,facing);state.pending_greeting=false
 _approach(state,absf(hero_x-x),delta,facing)
 var duration: float=Style.greeting_seconds if state.mode==State.Mode.GREET else (Style.service_seconds if state.mode==State.Mode.SERVICE else Style.acknowledgement_seconds)
 if state.mode!=State.Mode.WORK and state.age>=duration:state.enter(State.Mode.WORK,work_facing)
 if state.mode==State.Mode.WORK:
  state.work_age+=delta;state.facing=work_facing
 _pose(index)

func _approach(state: State, distance: float, delta: float, facing: float) -> void:
 if distance>Style.departure_radius:
  state.near=false;state.pending_greeting=false;state.notice=0.0
 elif distance<=Style.approach_radius and not state.near:
  state.near=true;state.pending_greeting=state.cooldown<=0;state.notice=0.0
 if not state.pending_greeting:return
 if distance>Style.approach_radius:
  state.pending_greeting=false;return
 state.notice+=delta
 if state.notice<Style.notice_seconds:return
 state.pending_greeting=false
 if state.mode!=State.Mode.WORK:return
 state.enter(State.Mode.GREET,facing);state.cooldown=Style.greeting_interval

func _service_value(site: StringName) -> int:
 match site:
  &"hall":return _sim.frontier.city_level*100000+_sim.mission.core_hp
  &"drill":return _sim.frontier.drill_level
  &"armory":return _sim.world.tools.blade+_sim.barracks_level*100
  &"workshop":return _sim.world.tools.hammer
  &"farm_tools":return _sim.world.tools.hoe
  &"hunt_tools":return _sim.world.tools.bow
 return 0

func _pending(site: StringName) -> bool:
 if site==&"armory" and _sim.command.enabled:return _sim.investments.has("command_armory")
 var prefix: String=str(site)+":"
 for key: String in _sim.investments:
  if key==str(site) or key.begins_with(prefix) or (site==&"hall" and key=="core_charge"):return true
 return false

func _latest_effect(kind: StringName, x: float) -> Dictionary:
 var latest: Dictionary={}
 for effect: Dictionary in _sim.effects:
  if effect.kind!=kind:continue
  var at: float=effect.get("to",effect.x) if kind==&"pay" else effect.x
  if absf(at-x)<73:latest=effect
 return latest

func _danger(x: float, radius: float) -> float:
 var closest: float=INF
 for enemy: Dictionary in _sim.raiders:
  if not enemy.fighter.is_alive() or enemy.get("escaped",false):continue
  if absf(enemy.x-x)<minf(radius,absf(closest-x)):closest=enemy.x
 return closest

func _pose(index: int) -> void:
 var state: State=states[index]
 var profile: AttendantProfile=Style.profiles[index]
 state.frame_age=0.0
 if state.mode==State.Mode.ALERT:state.frame=profile.alert_frame;return
 if state.mode==State.Mode.WORK:
  var length: float=0.0
  for hold: float in profile.work_holds:length+=hold
  var age: float=fposmod(state.work_age,length)
  for frame: int in range(profile.work_frames.size()):
   if age<profile.work_holds[frame]:
    state.frame=profile.work_frames[frame];state.frame_age=age;return
   age-=profile.work_holds[frame]
 else:
  var frames: PackedInt32Array=profile.service_frames if state.mode==State.Mode.SERVICE else profile.greeting_frames
  var duration: float=Style.service_seconds if state.mode==State.Mode.SERVICE else (Style.greeting_seconds if state.mode==State.Mode.GREET else Style.acknowledgement_seconds)
  var slot: int=mini(frames.size()-1,floori(state.age/duration*frames.size()))
  state.frame=frames[slot];state.frame_age=fposmod(state.age,duration/frames.size())

func draw_on(view: Node2D) -> void:
 for index: int in range(states.size()):
  var state: State=states[index]
  if not state.visible:continue
  var at: Vector2=Vector2(site_x(Cast.sites[index]),FLOOR_Y)+Cast.offsets[index]
  if not view._on_screen(at.x,Cast.cell.x):continue
  view.draw_set_transform(at.round(),0,Vector2(state.facing,1))
  view.draw_texture_rect_region(Cast.attendants,Rect2(-Cast.cell.x*0.5,-Cast.baseline,Cast.cell.x,Cast.cell.y),Rect2(state.frame*Cast.cell.x,index*Cast.cell.y,Cast.cell.x,Cast.cell.y))
  Details.draw_on(view,state,Style.profiles[index])
 view.draw_set_transform(Vector2.ZERO)
