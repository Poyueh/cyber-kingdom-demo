extends RefCounted
## Bounded visual memory, advanced only by the simulation clock. Never mutates combat.
const Cast = preload("res://data/enemy_cast.tres")
const Impact = preload("res://presentation/enemy_impact_view.gd")
class MotionState extends RefCounted:
	var x: float = 0.0
	var phase: float = 0.0
	var windup: float = 0.0
	var windup_total: float = 0.0
	var strike_age: float = 100.0
	var moving: bool = false
	var seen: int = 0
	var heavy: bool = false
	var hit_direction: float = 1.0
	var hp: int = 0
var _states: Dictionary[int,MotionState] = {}
var _expired: Array[int] = []
var _seen_effects: Array[Dictionary] = []
var _serial: int = 0
var _sim: RefCounted
var _time: float = 0.0
var _planet: int = -1
var _guardian: EnemyAppearance
var _dragon: EnemyAppearance

func _init() -> void:
	assert(Cast.valid(),"Incomplete enemy animation resources")

func appearance(kind: String) -> EnemyAppearance:
	if kind=="dragon":return _dragon
	if kind=="warden":return _guardian
	return Cast.grunt

func state_for(enemy: Dictionary) -> MotionState:
	return _states.get(enemy.fighter.get_instance_id())

func tracked_count() -> int:
	return _states.size()

func present(sim: RefCounted) -> void:
	if _planet!=sim.planet.id:
		_planet=clampi(sim.planet.id,0,6)
		_guardian=load(Cast.guardians[_planet]) as EnemyAppearance
		_dragon=load(Cast.dragons[_planet]) as EnemyAppearance
		assert(_guardian!=null and _guardian.valid() and _dragon!=null and _dragon.valid(),"Incomplete planet animation atlas")
	if not is_same(sim,_sim):
		_sim=sim;_time=sim.workforce.elapsed;_states.clear();_seen_effects.assign(sim.effects)
	var seconds: float=maxf(0,sim.workforce.elapsed-_time)
	_time=sim.workforce.elapsed
	_serial+=1;_expired.clear()
	var boss_impact: bool=false
	for effect: Dictionary in sim.effects:
		if effect.kind in ["dragon_fire","planet_strike"] and not _seen_effects.any(func(old: Dictionary)->bool:return is_same(old,effect)):
			boss_impact=true
	for enemy: Dictionary in sim.raiders:
		if not enemy.fighter.is_alive():continue
		var id: int=enemy.fighter.get_instance_id()
		var look: EnemyAppearance=appearance(enemy.get("kind",""))
		var fresh: bool=not _states.has(id)
		if fresh:
			var initial: MotionState=MotionState.new()
			initial.x=enemy.x;initial.windup=enemy.windup;initial.windup_total=enemy.windup
			initial.hp=enemy.fighter.hp;initial.hit_direction=-enemy.get("direction",-1.0)
			initial.phase=fposmod(enemy.x/look.stride,1.0)
			_states[id]=initial
		var state: MotionState=_states[id]
		state.seen=_serial
		var distance: float=absf(enemy.x-state.x)
		if seconds>0:
			state.moving=distance>0.01
			state.phase=fposmod(state.phase+distance/look.stride,1.0)
			state.strike_age+=seconds
			if enemy.get("kind","")=="dragon":
				if boss_impact and not fresh:state.strike_age=0.0
			elif state.windup>0 and enemy.windup<=0 and state.windup<=seconds+0.001 and enemy.get("stagger",0.0)<=0:
				# A destroyed wall or a player's heavy interruption cancels the attack.
				var wall_cancelled: bool=enemy.target.get("kind","")=="wall" and not sim.world.wall_operational(enemy.target.get("wall_id","wall"))
				if not wall_cancelled:state.strike_age=0.0
			if enemy.windup>state.windup or (state.windup<=0 and enemy.windup>0):state.windup_total=enemy.windup
		if enemy.fighter.hp<state.hp:
			state.heavy=false;state.hit_direction=-enemy.get("direction",-1.0)
			for effect: Dictionary in sim.effects:
				if effect.kind=="hit" and effect.has("heavy") and absf(effect.x-enemy.x)<35 and not _seen_effects.any(func(old: Dictionary)->bool:return is_same(old,effect)):
					state.heavy=effect.heavy;state.hit_direction=effect.facing
		state.hp=enemy.fighter.hp;state.x=enemy.x;state.windup=enemy.windup
	for id: int in _states:
		if _states[id].seen!=_serial:_expired.append(id)
	for id: int in _expired:_states.erase(id)
	_seen_effects.assign(sim.effects)

func frame_for(enemy: Dictionary, look: EnemyAppearance, hit: Dictionary) -> int:
	var state: MotionState=state_for(enemy)
	if state==null:return look.walk[0]
	var boss: bool=enemy.get("kind","")=="dragon"
	# A real multi-beat impact gets a brief release before its next warning pose.
	if boss and state.strike_age<0.20:return look.sample(look.strike,state.strike_age/look.strike_seconds)
	if enemy.windup>0:return look.sample(look.windup,1-enemy.windup/maxf(0.001,state.windup_total))
	if hit.active and not boss:return look.sample(look.hurt,hit.progress)
	if state.strike_age<look.strike_seconds:return look.sample(look.strike,state.strike_age/look.strike_seconds)
	if hit.active and boss:return look.hurt[0]
	if state.moving:return look.sample(look.walk,state.phase)
	# Rest uses the closed gait in a slow ping-pong. No stretched body parts.
	var idle: float=fposmod(_time*look.idle_fps+state.phase*8,14.0)
	return look.walk[mini(7,int(idle if idle<8 else 14-idle))]

func draw(view: Node2D, enemy: Dictionary, hit: Dictionary) -> void:
	var state: MotionState=state_for(enemy)
	if state==null:return
	var look: EnemyAppearance=appearance(enemy.get("kind",""))
	var carrying: bool=enemy.get("carried_crystals",0)>0
	if carrying and not hit.active:look=Cast.carry
	var frame: int=frame_for(enemy,look,hit)
	var direction: float=enemy.get("direction",-1.0)
	var recoil: Vector2=Vector2(state.hit_direction*absf(hit.offset.x),hit.offset.y)
	var lunge: float=sin(clampf(state.strike_age/look.strike_seconds,0,1)*PI)*4
	var at: Vector2=Vector2(enemy.x+direction*lunge,430)+recoil
	draw_pose(view,look,frame,at,direction,Color.WHITE.lerp(Color(2.9,2.7,2.2),hit.flash))
	if enemy.windup>0:
		var progress: float=1-enemy.windup/maxf(0.001,state.windup_total)
		Impact.claw_warning(view,Vector2(enemy.x+direction*25,430-look.hit_height),direction,progress,look.tint)
	elif state.strike_age<0.20 and not carrying:
		Impact.claw_release(view,Vector2(enemy.x+direction*26,400),direction,state.strike_age/0.20,look.tint)
	if hit.active:Impact.burst(view,Vector2(enemy.x,430-look.hit_height),hit.progress,state.hit_direction,state.heavy,look.tint)

static func draw_pose(view: Node2D, look: EnemyAppearance, frame: int, at: Vector2, direction: float, tint: Color) -> void:
	view.draw_set_transform(at.round(),0,Vector2(direction*look.facing,1))
	view.draw_texture_rect_region(look.atlas,Rect2(Vector2(-look.cell.x*0.5,-look.baseline),Vector2(look.cell)),look.region(frame),tint)
	view.draw_set_transform(Vector2.ZERO)

static func draw_fallen(view: Node2D, body: Dictionary, progress: float) -> void:
	var look: EnemyAppearance=view._raider_motion.appearance(body.get("kind",""))
	var frame: int=look.sample(look.fallen,clampf(progress/0.50,0,1))
	var at: Vector2=Vector2(body.x,430)
	draw_pose(view,look,frame,at,body.direction,Color(1,1,1,1-smoothstep(0.48,1,progress)))
	Impact.dissolve(view,at,progress,look.tint,body.get("kind","")=="dragon")
