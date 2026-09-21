extends RefCounted
## Bounded, presentation-only gait/strike memory. Simulation time freezes on pause.
const Frames=preload("res://data/sentinel_animation_frames.tres")
const Run=preload("res://art/characters/raider-motion-v001/run.png")
const Compact=preload("res://presentation/compact_people.gd")
class MotionState:
 extends RefCounted
 var x: float=0.0
 var phase: float=0.0
 var windup: float=0.0
 var strike: float=1.0
 var moving: bool=false
 var seen: int=0
var _states: Dictionary[int,MotionState]={}
var _expired: Array[int]=[]
var _serial: int=0
var _sim: RefCounted
var _time: float=0.0
func present(sim: RefCounted) -> void:
 if not is_same(sim,_sim):
  _sim=sim;_time=sim.workforce.elapsed;_states.clear()
 var seconds: float=maxf(0,sim.workforce.elapsed-_time)
 _time=sim.workforce.elapsed
 _serial+=1
 _expired.clear()
 for enemy: Dictionary in sim.raiders:
  if not enemy.fighter.is_alive() or enemy.get("kind","")=="dragon":continue
  var id: int=enemy.fighter.get_instance_id()
  if not _states.has(id):
   _states[id]=MotionState.new();_states[id].x=enemy.x;_states[id].windup=enemy.windup
  var state: MotionState=_states[id]
  state.seen=_serial
  var distance: float=absf(enemy.x-state.x)
  if seconds>0:
   state.moving=distance>0.01
   state.phase=fposmod(state.phase+distance/42.0,1.0)
   state.strike+=seconds
   if state.windup>0 and enemy.windup<=0:state.strike=0.0
  state.x=enemy.x;state.windup=enemy.windup
 for id: int in _states:
  if _states[id].seen!=_serial:_expired.append(id)
 for id: int in _expired:_states.erase(id)
func draw(view: Node2D, enemy: Dictionary, hit: Dictionary) -> void:
 var id: int=enemy.fighter.get_instance_id()
 if not _states.has(id):return
 var state: MotionState=_states[id]
 var texture: Texture2D=Frames.get_frame_texture("idle",0)
 var source: Rect2=Rect2(Vector2.ZERO,texture.get_size())
 var offset: Vector2=Vector2.ZERO
 var tilt: float=0.0
 var stretch: Vector2=Vector2.ONE
 var direction: float=enemy.get("direction",-1.0)
 if not hit.active:
  if enemy.windup>0:
   texture=Frames.get_frame_texture("windup",0)
   var anticipation: float=1.0-clampf(enemy.windup/0.6,0,1)
   tilt=-0.11*anticipation;stretch=Vector2(1+anticipation*0.06,1-anticipation*0.07)
  elif state.strike<0.34:
   var progress: float=state.strike/0.34
   texture=Frames.get_frame_texture("attack",mini(2,int(progress*3)))
   offset.x=sin(progress*PI)*6*direction
   tilt=sin(progress*PI)*0.12
  elif state.moving:
   texture=Run
   var frame: int=mini(15,int(state.phase*16))
   source=Rect2((frame%8)*128,(frame/8)*96,128,96)
   tilt=0.045 if enemy.get("carried_crystals",0)>0 else 0.0
  else:
   stretch.y=1.0+sin(_time*3.6+enemy.x*0.02)*0.016
 view.draw_set_transform(Vector2(enemy.x,430)+hit.offset+offset,hit.rotation+tilt*direction,hit.scale*stretch*Vector2(direction,1))
 Compact.draw(view,texture,source,Color(1.8,1.1,1.05).lerp(Color.WHITE,1-hit.flash),41,80)
 view.draw_set_transform(Vector2.ZERO)
