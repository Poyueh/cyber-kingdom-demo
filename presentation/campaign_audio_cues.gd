extends RefCounted
## Ephemeral presentation observer. No sound history enters campaign saves.
const EFFECTS={
 "core_hit":"core_hit","tower_arrow":"bow_shot","bolt":"bow_shot","tower_laser":"tower_laser",
 "construction_done":"build","pay":"pay","chest_burst":"chest","recruited":"recruit",
 "crystal_pickup":"pickup","hit":"hit","portal_spawn":"portal_spawn",
 "dragon_arrival":"dragon_arrival","dragon_fire":"dragon_fire",
 "module_pickup":"module_pickup","module_equipped":"module_equip","module_stored":"module_store",
 "sword_recovered":"sword_recover"}
const FAR_ENOUGH:=800.0
## Heard wherever the knight is: they warn about the run itself, not about a place.
const UNMISSABLE=["core_hit","dragon_arrival","dragon_fire"]
var _session: RefCounted
var _seen: Array=[]
var _active:=false
var _combo:=0
var _dash:=0.0
var _hp:=0
var _absorbed:=0
var _city:=0
var _night:=false
var _sealed:=0
var _survived:=0
var _outcome:="running"
var _resting:=0
var _offered:=0
var _raiders:=0
var _dragon:=-1
var _walls: Dictionary={}
var _health:=0
var _winding: Dictionary={}
var _carrying: Dictionary={}
var _wardens:=0
var _roles: Dictionary={}
var _hurting: Dictionary={}
var _mounted:=false
var _kingdom:=false
var _investments: Dictionary={}
var _flying:=0
var _settled:=0
var _held:=0
var _warned:=0
var _guided:=false
var _enemy_health:=0
var _pouch:=0
var _disarmed:=false
var _alive:=true
func sample(sim,x: float,paused: bool) -> Array[String]:
	var result: Array[String]=[]
	var active: bool=sim.hero.is_attack_active()
	var sealed: int=sim.mission.rifts.filter(func(r):return r.sealed).size()
	var resting: int=_resting_crystals(sim)
	var offered: int=_offered_crystals(sim)
	var raiders: int=_small_raiders(sim)
	var dragon: int=_dragon_health(sim)
	var walls: Dictionary=_wall_health(sim)
	var winding: Dictionary=_raider_flags(sim,"windup")
	var carrying: Dictionary=_raider_flags(sim,"carried_crystals")
	var wardens: int=_wardens_seen(sim)
	var roles: Dictionary=_person_flags(sim,"role")
	var hurting: Dictionary=_person_flags(sim,"hurt")
	var mounted: bool=sim.mounted() if sim.has_method("mounted") else false
	var kingdom: bool=sim.kingdom_established()
	var flying: int=_flying_crystals(sim)
	var settled: int=_settled_crystals(sim)
	var held: int=_carried_by_people(sim)
	var enemy_health: int=_living_enemy_health(sim)
	var disarmed: bool=sim.survival.enabled and sim.survival.sword_on_ground
	var alive: bool=sim.hero.hp>0
	if _session==sim and not paused:
		if active and (not _active or _combo!=sim.hero.combo_step):result.append("slash%d"%maxi(1,sim.hero.combo_step))
		if sim.hero.dash_remaining>_dash:result.append("dash")
		for effect in sim.effects:
			if _seen.any(func(old):return is_same(old,effect)):continue
			var kind: String=EFFECTS.get(effect.kind,"")
			if kind.is_empty():continue
			if absf(effect.x-x)>FAR_ENOUGH and not (effect.kind in UNMISSABLE):continue
			if kind=="hit" and effect.get("heavy",false):kind="heavy"
			if not result.has(kind):result.append(kind)
		# A deflected blow is a different event from one that reaches the knight.
		if sim.hero.shield_absorbed>_absorbed:result.append("shield")
		elif sim.hero.hp<_hp:result.append("hurt")
		if not alive and _alive:result.append("death")
		if resting>_resting:result.append("crystal_drop")
		if offered>_offered:result.append("throw")
		if raiders<_raiders:result.append("enemy_death")
		if _dragon>0:
			if dragon<=0:result.append("dragon_death")
			elif dragon<_dragon:result.append("dragon_hurt")
		if sim.hero.hp>_health and _health>0:result.append("heal")
		for id in walls:
			var before: int=_walls.get(id,-1)
			if before<0 or walls[id]==before:continue
			if walls[id]<=0:result.append("wall_break")
			elif walls[id]<before:result.append("wall_hit")
			else:result.append("wall_repair")
		if disarmed and not _disarmed:result.append("sword_drop")
		for id in winding:
			if winding[id]>0 and _winding.get(id,0.0)<=0:_near_enough(result,"enemy_telegraph",sim,id,x)
			elif winding[id]<=0 and _winding.get(id,-1.0)>0:_near_enough(result,"enemy_attack",sim,id,x)
		for id in carrying:
			if carrying[id]>0 and _carrying.get(id,0)<=0:_near_enough(result,"enemy_grab",sim,id,x)
		if wardens>_wardens:result.append("gatekeeper_appear")
		# An arrow lands the instant it is loosed, so the thock rides with the twang.
		if enemy_health<_enemy_health and not active and _bolt_flew(sim,x):result.append("arrow_hit")
		if settled>_settled:result.append("crystal_land")
		if held<_held and sim.pouch.amount>_pouch:result.append("handoff")
		if not sim.clock.is_night and sim.clock.remaining<=30.0 and _warned!=sim.clock.day:
			_warned=sim.clock.day
			result.append("raid_warning")
		if sim.spirit!=null and sim.spirit.opening_finished and not _guided:result.append("farewell")
		for id in roles:
			var was=_roles.get(id,null)
			if was!=null and was=="wanderer" and roles[id]!="wanderer":result.append("tool_pickup")
		for id in hurting:
			if hurting[id]>0 and _hurting.get(id,0.0)<=0:result.append("resident_hit")
		if mounted and not _mounted:result.append("mount")
		if kingdom and not _kingdom:result.append("kingdom")
		for key in _investments:
			if sim.investments.has(key):continue
			result.append("slot_refund" if flying>_flying else "slot_complete")
		if sim.frontier.city_level>_city:result.append("upgrade" if _city>0 else "build")
		if sim.clock.is_night and not _night:result.append("night")
		if sim.clock.survived>_survived:result.append("dawn")
		if sealed>_sealed:result.append("seal")
		if sim.mission.outcome!=_outcome and sim.mission.outcome in ["victory","defeat"]:result.append(sim.mission.outcome)
	_session=sim
	_seen=sim.effects.duplicate()
	_active=active;_combo=sim.hero.combo_step;_dash=sim.hero.dash_remaining
	_hp=sim.hero.hp;_absorbed=sim.hero.shield_absorbed
	_city=sim.frontier.city_level;_night=sim.clock.is_night;_sealed=sealed
	_survived=sim.clock.survived;_outcome=sim.mission.outcome
	_resting=resting;_disarmed=disarmed;_alive=alive
	_offered=offered;_raiders=raiders;_dragon=dragon;_walls=walls;_health=sim.hero.hp
	_winding=winding;_carrying=carrying;_wardens=wardens;_roles=roles;_hurting=hurting
	_mounted=mounted;_kingdom=kingdom;_investments=sim.investments.duplicate();_flying=flying
	_settled=settled;_held=held;_enemy_health=enemy_health;_pouch=sim.pouch.amount
	if sim.spirit!=null:_guided=sim.spirit.opening_finished
	return result

## Village and battle noise stays local; only run-wide warnings carry.
func _near_enough(result: Array[String], kind: String, sim, id: int, x: float) -> void:
	for raider in sim.raiders:
		if raider.get("id",-1)==id and absf(raider.x-x)<=FAR_ENOUGH and not result.has(kind):
			result.append(kind)
			return

func _raider_flags(sim, field: String) -> Dictionary:
	var flags: Dictionary={}
	for index in range(sim.raiders.size()):
		var raider: Dictionary=sim.raiders[index]
		if not raider.has("id"):raider["id"]=index+1000*int(raider.get("side",0)+2)
		flags[raider.id]=raider.get(field,0)
	return flags

func _person_flags(sim, field: String) -> Dictionary:
	var flags: Dictionary={}
	for index in range(sim.world.people.size()):
		flags[index]=sim.world.people[index].get(field,null)
	return flags

func _wardens_seen(sim) -> int:
	var total:=0
	for rift in sim.mission.rifts:
		if rift.get("wardens_spawned",false):total+=1
	return total

func _settled_crystals(sim) -> int:
	var total:=0
	for gem in sim.pouch.drops:
		if gem.vx==0 and gem.vy==0 and gem.grace<=0 and not gem.offering:total+=int(gem.amount)
	return total

func _carried_by_people(sim) -> int:
	var total:=0
	for person in sim.world.people:
		total+=int(person.get("crystals",0))
	return total

func _living_enemy_health(sim) -> int:
	var total:=0
	for raider in sim.raiders:
		if raider.fighter.is_alive():total+=int(raider.fighter.hp)
	return total

func _bolt_flew(sim,x: float) -> bool:
	for effect in sim.effects:
		if effect.kind=="bolt" and absf(effect.x-x)<=FAR_ENOUGH:return true
	return false

func _flying_crystals(sim) -> int:
	var total:=0
	for gem in sim.pouch.drops:
		if gem.vx!=0 or gem.vy!=0 or gem.grace>0:total+=int(gem.amount)
	return total

func _offered_crystals(sim) -> int:
	var total:=0
	for gem in sim.pouch.drops:
		if gem.offering:total+=int(gem.amount)
	return total

func _small_raiders(sim) -> int:
	var total:=0
	for raider in sim.raiders:
		if raider.get("kind","")!="dragon" and raider.fighter.is_alive():total+=1
	return total

## Negative until a dragon exists, so the first sighting is not mistaken for a wound.
func _dragon_health(sim) -> int:
	for raider in sim.raiders:
		if raider.get("kind","")=="dragon":return maxi(0,int(raider.fighter.hp))
	return 0 if _dragon>0 else -1

func _wall_health(sim) -> Dictionary:
	var health: Dictionary={}
	for id in sim.world.walls:
		var wall: Dictionary=sim.world.walls[id]
		if wall.level>0:health[id]=int(wall.hp)
	return health

func _resting_crystals(sim) -> int:
	var total:=0
	for gem in sim.pouch.drops:
		if not gem.offering:total+=int(gem.amount)
	return total
