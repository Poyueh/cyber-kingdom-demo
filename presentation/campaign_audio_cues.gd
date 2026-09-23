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
	return result

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
