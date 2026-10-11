extends RefCounted
const Trails=preload("res://domain/trail_encounters.gd")
static func populate(sim: RefCounted) -> void:
	for unit: Trails.Unit in sim.trails.units:
		var enemy: Dictionary=sim._spawn_raider()
		enemy.fighter.stats.max_hp=int(sim.trails.rules.health)
		enemy.fighter.hp=enemy.fighter.stats.max_hp
		enemy.fighter.stats.damage=int(sim.trails.rules.damage)
		enemy.x=sim.trails.home(unit.slot)
		enemy["trail_slot"]=unit.slot
		enemy["kind"]="roamer"
		enemy["side"]=int(sim.trails.rules.combat_side)
		enemy["direction"]=-float(enemy.side)
		sim.raiders.append(enemy)

static func candidates(sim: RefCounted, x: float, y: float) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if absf(y-430)>42:return result
	for index: int in range(sim.trails.sites.size()):
		var site: Trails.Site=sim.trails.sites[index]
		if not site.revealed or site.claimed or absf(x-site.x)>=73:continue
		var choice: Dictionary=sim._choice("trail_cache",site.x,"trail.claim",0,sim.trails.available(index),"trail.guarded")
		choice["trail_index"]=index;choice.key="trail:%d"%index
		result.append(choice)
	return result
static func execute(sim: RefCounted, index: int) -> void:
	var reward: int=sim.trails.claim(index)
	if reward<=0:return
	var at: float=sim.trails.sites[index].x
	sim.pouch.burst(reward,at)
	sim.effects.append({"kind":"chest_burst","x":at,"y":430.0,"life":0.7})
static func advance_enemy(sim: RefCounted, enemy: Dictionary, seconds: float, hero_x: float, hero_y: float) -> void:
	var trails: Trails=sim.trails
	var unit: Trails.Unit=trails.units[int(enemy.trail_slot)]
	var tick: int=roundi(sim.workforce.elapsed*Trails.Clock.TICKS_PER_SECOND)
	var elapsed: int=maxi(0,tick-unit.last_tick);unit.last_tick=tick
	enemy.fighter.advance(seconds)
	if not enemy.fighter.is_alive():
		unit.phase=Trails.Phase.DEFEATED;unit.remaining=0;unit.engaged=false
		enemy.windup=0.0;enemy.target={}
		return
	if elapsed==0:return
	var home: float=trails.home(unit.slot)
	var center: float=trails.sites[0].x
	var rule: Dictionary=trails.rules
	# Retreat cancels local combat; it never redirects an optional beast at settlers.
	if absf(hero_x-center)>rule.territory+rule.notice or sim.planet.cleared:
		unit.phase=Trails.Phase.REST;unit.remaining=0;unit.engaged=false
		enemy.windup=0.0;enemy.target={}
		_move(sim,enemy,home,float(rule.speed),elapsed)
		return
	if enemy.get("stagger",0.0)>0:
		enemy.stagger=maxf(0,enemy.stagger-seconds)
		_recover(trails,unit,enemy)
		return
	if unit.phase in [Trails.Phase.WINDUP,Trails.Phase.CHARGE] and enemy.windup<=0:
		_recover(trails,unit,enemy)
	if _step_attack(sim,enemy,unit,elapsed,hero_x,hero_y):return
	_pursue(sim,enemy,unit,hero_x,hero_y,elapsed)

static func _pursue(sim: RefCounted, enemy: Dictionary, unit: Trails.Unit, hero_x: float, hero_y: float, elapsed: int) -> void:
	var trails: Trails=sim.trails
	var rule: Dictionary=trails.rules
	var center: float=trails.sites[0].x
	var close: bool=absf(hero_x-center)<=rule.notice and absf(hero_y-430)<42
	var endangered: bool=sim.raiders.any(func(other: Dictionary)->bool:return not other.has("trail_slot") and other.fighter.is_alive() and absf(other.x-center)<500)
	if not unit.engaged:
		if enemy.fighter.hp<enemy.fighter.stats.max_hp:unit.engaged=true
		elif close and sim.frontier.city_level>0 and sim.can_wield_sword() and not sim.clock.is_night and not endangered:
			unit.engaged=true
			unit.phase=Trails.Phase.RECOVER;unit.remaining=1+unit.slot*12
			return
		else:return
	var target: float=clampf(hero_x,center-rule.territory,center+rule.territory)
	if absf(hero_x-enemy.x)>maxf(rule.reach*0.8,rule.charge_distance):
		_move(sim,enemy,target,float(rule.speed),elapsed)
		return
	unit.target_x=clampf(hero_x,enemy.x-rule.charge_distance,enemy.x+rule.charge_distance) if rule.charge_distance>0 else enemy.x
	unit.target_x=clampf(unit.target_x,center-rule.territory,center+rule.territory)
	unit.phase=Trails.Phase.WINDUP;unit.remaining=trails.windup_ticks
	enemy.direction=signf(hero_x-enemy.x) if absf(hero_x-enemy.x)>1 else enemy.direction
	enemy.target={"kind":"hero","x":unit.target_x}
	enemy.windup=float(unit.remaining)/Trails.Clock.TICKS_PER_SECOND
static func _step_attack(sim: RefCounted, enemy: Dictionary, unit: Trails.Unit, elapsed: int, hero_x: float, hero_y: float) -> bool:
	var trails: Trails=sim.trails
	var rule: Dictionary=trails.rules
	if unit.phase==Trails.Phase.RECOVER:
		unit.remaining=maxi(0,unit.remaining-elapsed)
		if unit.remaining==0:unit.phase=Trails.Phase.REST
		return true
	if unit.phase==Trails.Phase.WINDUP:
		unit.remaining=maxi(0,unit.remaining-elapsed)
		enemy.windup=float(unit.remaining)/Trails.Clock.TICKS_PER_SECOND
		if unit.remaining>0:return true
		if rule.charge_distance>0:
			unit.phase=Trails.Phase.CHARGE;unit.remaining=trails.charge_ticks
			enemy.windup=float(unit.remaining)/Trails.Clock.TICKS_PER_SECOND
		else:_impact(sim,enemy,unit,hero_x,hero_y)
		return true
	if unit.phase==Trails.Phase.CHARGE:
		_move(sim,enemy,unit.target_x,float(rule.charge_distance)/float(rule.charge_seconds),elapsed)
		unit.remaining=maxi(0,unit.remaining-elapsed)
		enemy.windup=float(unit.remaining)/Trails.Clock.TICKS_PER_SECOND
		if unit.remaining==0:_impact(sim,enemy,unit,hero_x,hero_y)
		return true
	return false

static func _move(sim: RefCounted, enemy: Dictionary, to: float, speed: float, ticks: int) -> void:
	if absf(to-enemy.x)>0.1:enemy.direction=signf(to-enemy.x)
	var adjusted: float=sim.modules.movement_speed(enemy,speed,roundi(sim.workforce.elapsed*Trails.Clock.TICKS_PER_SECOND))
	sim.move_raider(enemy,move_toward(enemy.x,to,adjusted*float(ticks)/Trails.Clock.TICKS_PER_SECOND))
static func _recover(trails: Trails, unit: Trails.Unit, enemy: Dictionary) -> void:
	unit.phase=Trails.Phase.RECOVER;unit.remaining=trails.recovery_ticks
	unit.engaged=true;enemy.windup=0.0;enemy.target={}
static func _impact(sim: RefCounted, enemy: Dictionary, unit: Trails.Unit, hero_x: float, hero_y: float) -> void:
	var reach: float=sim.trails.rules.reach
	if absf(enemy.x-hero_x)<reach and absf(hero_y-430)<42 and sim._blocking_wall(enemy.x,hero_x).is_empty():
		sim.hit_hero(enemy.fighter.stats.damage,hero_x,hero_y)
	sim.effects.append({"kind":"trail_impact","x":enemy.x,"to":reach,"life":0.45})
	_recover(sim.trails,unit,enemy)
