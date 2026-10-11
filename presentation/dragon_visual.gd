extends RefCounted
## Full-body boss animation and bounded attack atmosphere, driven by real combat.
const Motion = preload("res://presentation/raider_motion_view.gd")
const Impact = preload("res://presentation/enemy_impact_view.gd")
const Opening = preload("res://presentation/dragon_opening_view.gd")

static func draw(view: Node2D, enemy: Dictionary, time: float) -> void:
	if not enemy.fighter.is_alive():return
	var look: EnemyAppearance=view._raider_motion.appearance("dragon")
	var state: Motion.MotionState=view._raider_motion.state_for(enemy)
	if state==null:return
	var hit: Dictionary=view.hit_feedback.enemy_pose(enemy)
	var frame: int=view._raider_motion.frame_for(enemy,look,hit)
	var direction: float=enemy.get("direction",-1.0)
	var release: float=clampf(state.strike_age/look.strike_seconds,0,1)
	var recoil: float=sin(release*PI)*7 if state.strike_age<look.strike_seconds else 0.0
	var at: Vector2=Vector2(enemy.x+direction*recoil,430)
	# A huge animal absorbs a sword hit; its locked warning is never interrupted.
	at.x+=state.hit_direction*absf(hit.offset.x)*0.20
	var flash: float=hit.flash*0.7
	view.draw_set_transform(Vector2(enemy.x,430),0,Vector2(1,0.13))
	view.draw_circle(Vector2.ZERO,105,Color(0.015,0.025,0.04,0.30))
	view.draw_set_transform(Vector2.ZERO)
	Motion.draw_pose(view,look,frame,at,direction,Color.WHITE.lerp(Color(2.6,2.2,1.8),flash))
	if hit.active:Impact.burst(view,Vector2(enemy.x+direction*60,430-look.hit_height),hit.progress,state.hit_direction,state.heavy,look.tint,1.3)
	if enemy.windup>0:
		var progress: float=1-enemy.windup/maxf(0.001,state.windup_total)
		_warning(view,enemy,progress,time,look.tint)
	elif state.strike_age<look.strike_seconds:
		_ground_wave(view,Vector2(enemy.x,428),release,look.tint)
	Opening.draw(view,enemy,time)

static func _warning(view: Node2D, enemy: Dictionary, progress: float, time: float, tint: Color) -> void:
	var aim: float=enemy.target.x
	var profile: RefCounted=view._sim.planet.attack
	var biome: bool=view._sim.planet.enabled and view._sim.planet.id>0
	var radius: float=profile.radius if biome else 100.0
	var warning: Color=Color(tint.lightened(0.45),0.45+progress*0.5)
	view.draw_line(Vector2(aim-radius,428),Vector2(aim+radius,428),warning,3)
	# Inward marks show the locked footprint even in grayscale.
	for side: int in [-1,1]:
		var edge: Vector2=Vector2(aim+side*radius,424)
		view.draw_polyline(PackedVector2Array([edge+Vector2(-side*8,-8),edge,edge+Vector2(-side*8,0)]),warning,2)
	var fill: float=radius*progress
	view.draw_line(Vector2(aim-fill,432),Vector2(aim+fill,432),Color(tint,0.28),5)
	if biome:
		for beat: int in range(profile.beats):
			view.draw_circle(Vector2(aim+(beat-(profile.beats-1)*0.5)*13,409),3,Color.WHITE if beat==view._sim.planet.volley else Color(tint,0.35))
	# Dust pulls inward before an attack. It stays behind the precise ground mark.
	for index: int in range(10):
		var cycle: float=fposmod(time*0.85+index*0.17,1.0)
		var side: float=-1.0 if index%2==0 else 1.0
		var p: Vector2=Vector2(enemy.x+side*(30+(1-cycle)*95),422-sin(cycle*PI)*(8+index%3*8))
		view.draw_rect(Rect2(p.round(),Vector2(2,2)),Color(tint,cycle*progress*0.65))

static func _ground_wave(view: Node2D, at: Vector2, progress: float, tint: Color) -> void:
	var radius: float=22+progress*125
	var fade: float=1-progress
	view.draw_set_transform(at,0,Vector2(1,0.15))
	view.draw_arc(Vector2.ZERO,radius,0,TAU,32,Color(tint,fade*0.35),4)
	view.draw_set_transform(Vector2.ZERO)
	for side: int in [-1,1]:
		for index: int in range(5):
			var p: Vector2=at+Vector2(side*(12+progress*(45+index*14)),-sin(progress*PI)*(5+index*3))
			view.draw_rect(Rect2(p.round(),Vector2(4+index,2)),Color(tint.darkened(0.4),fade*0.4))

static func draw_fallen(view: Node2D, body: Dictionary, progress: float) -> void:
	Motion.draw_fallen(view,body,progress)

static func breath(view: Node2D, effect: Dictionary) -> void:
	var progress: float=clampf(1-effect.life/0.7,0,1)
	var direction: float=signf(effect.to-effect.x)
	var origin: Vector2=Vector2(effect.x+direction*115,323)
	# Follow the full-body release pose; the boss can advance during recovery.
	for enemy: Dictionary in view._sim.raiders:
		if enemy.get("kind","")!="dragon" or not enemy.fighter.is_alive():continue
		var look: EnemyAppearance=view._raider_motion.appearance("dragon")
		var state: Motion.MotionState=view._raider_motion.state_for(enemy)
		if state==null or look.breath_muzzles.size()!=look.strike.size():break
		var release: float=clampf(state.strike_age/look.strike_seconds,0,1)
		var muzzle: Vector2=look.breath_muzzles[mini(int(release*look.strike.size()),look.strike.size()-1)]
		origin=Vector2(enemy.x+direction*(muzzle.x+sin(release*PI)*7),430+muzzle.y)
		break
	var target: Vector2=Vector2(effect.to,418)
	var fade: float=1-smoothstep(0.45,1,progress)
	var reach: float=clampf(progress/0.20,0,1)
	for index: int in range(24):
		var distance: float=index/23.0
		if distance>reach:continue
		var at: Vector2=origin.lerp(target,distance)
		var spread: float=6+distance*24
		at.y+=sin(index*2.4+progress*22)*spread*0.45
		var size: Vector2=Vector2(12+distance*14,8+distance*18)*fade
		view.draw_rect(Rect2((at-size*0.5).round(),size.round()),Color(1,0.22+distance*0.3,0.08,fade*0.65))
		view.draw_rect(Rect2(at.round(),(size*0.48).round()),Color(1,0.85,0.49,fade))
	_ground_wave(view,target,progress,Color("efb96f"))
