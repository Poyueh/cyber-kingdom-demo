extends RefCounted
## Two finite local destinations. Wildlife never joins the nightly invading force.
const Rules=preload("res://domain/trail_rules.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
enum Phase {REST, WINDUP, CHARGE, RECOVER, DEFEATED}
class Site extends RefCounted:
	var x: float
	var region: int
	var guarded: bool
	var reward: int
	var revealed: bool=false
	var claimed: bool=false
class Unit extends RefCounted:
	var slot: int
	var phase: int=Phase.REST
	var remaining: int=0
	var last_tick: int=0
	var target_x: float=0
	var engaged: bool=false
var sites: Array[Site]=[]
var units: Array[Unit]=[]
var rules: Dictionary={}
var windup_ticks: int=0
var recovery_ticks: int=0
var charge_ticks: int=0
func _init(config: Dictionary) -> void:
	if not config.has("trail_version"):return
	assert(Rules.valid_config(config))
	for key: String in Rules.LIMITS:rules[key]=config[Rules.PREFIX+key]
	windup_ticks=Clock.ticks_for(rules.windup_seconds)
	recovery_ticks=Clock.ticks_for(rules.recovery_seconds)
	charge_ticks=Clock.ticks_for(rules.charge_seconds)
	for name: String in ["combat","discovery"]:
		var site: Site=Site.new()
		site.x=config[Rules.PREFIX+name+"_x"];site.region=int(config[Rules.PREFIX+name+"_region"])
		site.guarded=name=="combat";site.reward=int(rules[name+"_reward"])
		sites.append(site)
	for slot: int in range(int(rules.guard_count)):
		var unit: Unit=Unit.new();unit.slot=slot;unit.target_x=sites[0].x
		units.append(unit)
func home(slot: int) -> float:
	return sites[0].x+(slot-(units.size()-1)*0.5)*70

func available(index: int) -> bool:
	if index<0 or index>=sites.size():return false
	var site: Site=sites[index]
	return site.revealed and not site.claimed and (not site.guarded or units.all(func(unit: Unit)->bool:return unit.phase==Phase.DEFEATED))
func claim(index: int) -> int:
	if not available(index):return 0
	sites[index].claimed=true
	return sites[index].reward
func observe(hero_x: float) -> void:
	for site: Site in sites:
		if absf(site.x-hero_x)<420:site.revealed=true
func capture() -> Dictionary:
	var destinations: Array[Dictionary]=[]
	var creatures: Array[Dictionary]=[]
	for site: Site in sites:destinations.append({"revealed":site.revealed,"claimed":site.claimed})
	for unit: Unit in units:
		creatures.append({"phase":unit.phase,"remaining":unit.remaining,"last_tick":unit.last_tick,"target_x":unit.target_x,"engaged":unit.engaged})
	return {"sites":destinations,"units":creatures}
func restore(data: Variant, tick: int) -> bool:
	if not data is Dictionary or data.size()!=2 or not data.get("sites") is Array or not data.get("units") is Array:return false
	if data.sites.size()!=sites.size() or data.units.size()!=units.size():return false
	for index: int in range(units.size()):
		var saved: Variant=data.units[index]
		if not saved is Dictionary or saved.size()!=5 or not saved.get("engaged") is bool:return false
		if not Rules.number(saved.get("phase"),Phase.REST,Phase.DEFEATED,true):return false
		if not Rules.number(saved.get("last_tick"),0,tick,true):return false
		var maximum: int=[0,windup_ticks,charge_ticks,recovery_ticks,0][int(saved.phase)]
		if not Rules.number(saved.get("remaining"),0,maximum,true):return false
		if int(saved.phase) in [Phase.WINDUP,Phase.CHARGE,Phase.RECOVER] and (saved.remaining<=0 or not saved.engaged):return false
		if not Rules.number(saved.get("target_x"),sites[0].x-rules.territory,sites[0].x+rules.territory):return false
		var unit: Unit=units[index]
		unit.phase=int(saved.phase);unit.remaining=int(saved.remaining);unit.last_tick=int(saved.last_tick)
		unit.target_x=float(saved.target_x);unit.engaged=saved.engaged
	for index: int in range(sites.size()):
		var saved: Variant=data.sites[index]
		if not saved is Dictionary or saved.size()!=2 or not saved.get("revealed") is bool or not saved.get("claimed") is bool:return false
		if saved.claimed and not saved.revealed:return false
		if index==0 and saved.claimed and not units.all(func(unit: Unit)->bool:return unit.phase==Phase.DEFEATED):return false
		sites[index].revealed=saved.revealed;sites[index].claimed=saved.claimed
	return true
func valid_creatures(enemies: Array) -> bool:
	var present: Array[int]=[]
	for enemy: Dictionary in enemies:
		if not enemy.has("trail_slot"):
			if enemy.get("kind","")=="roamer":return false
			continue
		var slot: Variant=enemy.trail_slot
		if not Rules.number(slot,0,units.size()-1,true) or int(slot) in present:return false
		var unit: Unit=units[int(slot)]
		if unit.phase==Phase.DEFEATED and enemy.fighter.is_alive():return false
		if enemy.get("kind","")!="roamer" or enemy.get("carried_crystals",0)!=0 or enemy.get("escaped",false):return false
		if enemy.get("side")!=int(rules.combat_side):return false
		if not Rules.number(enemy.x,sites[0].x-rules.territory-128,sites[0].x+rules.territory+128):return false
		if enemy.fighter.stats.max_hp!=int(rules.health) or enemy.fighter.stats.damage!=int(rules.damage):return false
		present.append(int(slot))
	for unit: Unit in units:
		if not unit.slot in present and unit.phase!=Phase.DEFEATED:return false
	return true
