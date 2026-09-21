extends "res://application/frontier_session.gd"
## Playable campaign orchestration. Wallet and calendar rules remain in domain.
const Life=preload("res://application/kingdom_life.gd")
var life: Life=Life.new()
const Survival=preload("res://domain/crystal_survival.gd")
var survival: Survival=Survival.new()
const Forager=preload("res://application/crystal_forager.gd")
const Defenses=preload("res://domain/frontier_defenses.gd")
var defenses: Defenses
const Ecology=preload("res://domain/frontier_ecology.gd")
var ecology: Ecology
const Growth=preload("res://domain/knight_growth.gd")
var growth: Growth
const Mission=preload("res://domain/campaign_mission.gd")
var mission: Mission
const RiftWorkforce=preload("res://application/rift_workforce.gd")
var expedition: RiftWorkforce
const Schedule = preload("res://domain/resident_schedule.gd")
const Roaming = preload("res://domain/resident_roaming.gd")
var stroll_speed: float = 24.0
var return_margin: float = 15.0
var hunter_damage: int = 12
var hunter_range: float = 170.0
var hunter_interval: float = 1.2
var _hero_x: float = 0.0
var _night_spawn_index := 0
const Pouch = preload("res://domain/crystal_pouch.gd")
const Calendar = preload("res://domain/campaign_clock.gd")
const Harvest = preload("res://domain/harvest_node.gd")
var pouch: Pouch
var clock: Calendar
var opened_chests: Dictionary = {}
var investments: Dictionary = {}
var built: Dictionary = {}
var prices: Dictionary
var warden_health: int
var warden_damage: int
var enemy_health_growth: int
var enemy_damage_growth: int
var barracks_level:=0
var buildings: Dictionary={}
var build_seconds:=3.0
var tower_damage:=12
var tower_range:=460.0
const BuildingSites=preload("res://domain/building_sites.gd")
const Construction=preload("res://application/fortification_work.gd")
var travel=preload("res://application/campaign_travel.gd").new()
const TOOL_KINDS := {"workshop":"hammer","farm_tools":"hoe","hunt_tools":"bow"}
const NAMES := {"hall":"營火","workshop":"工匠器具","armory":"兵營","farm_tools":"農具","hunt_tools":"獵弓","forge":"義肢爐","beacon":"守護塔","wall":"右防線","wall_left":"左防線","farm":"農田","drill":"劍術訓練","heal":"龍晶治療"}

func _init(config: Dictionary = {}, hero_stats: Stats = null) -> void:
	life.enabled=int(config.get("immersive_loop",0))==1
	survival.enabled=life.enabled and int(config.get("crystal_survival",0))==1
	survival.hit_loss=int(config.get("hit_crystal_loss",0))
	var resolved:=config.duplicate(true)
	var economy: Dictionary=config.get("economy",{}).duplicate(true)
	var left_post:=minf(-950.0,float(config.get("left_defense_x",-1100.0)))
	economy["settlement_left"]=left_post-200.0
	economy["flat_ground"]=int(config.get("flat_frontier",1))
	resolved["economy"]=economy
	super(resolved,hero_stats)
	if config.get("flat_frontier",1):
		world.tool_roles.blade="hunter";world.tool_sites.blade="hunt_tools"
	travel.fast_multiplier=clampf(config.get("fast_run_multiplier",1.65),1.1,3.0)
	travel.drain_per_second=clampf(config.get("fast_run_drain",18.0),5,40)
	hero.stats.attack_cost=maxf(0,float(config.get("attack_stamina",12.0)))
	hero.stats.jump_cost=maxf(0,float(config.get("jump_stamina",18.0)))
	hero.stats.dash_cost=maxf(0,float(config.get("dash_stamina",30.0)))
	if life.enabled:
		world.tool_roles.blade="guard";world.tool_sites.blade="armory"
		hero.stats.stamina_regen=float(config.get("rest_regen",10.0))
		hero.stats.max_hp=int(config.get("knight_health",70))
		hero.stats.damage=int(config.get("knight_damage",18))
		hero.hp=hero.stats.max_hp
	travel.forced_rest=life.enabled
	world.add_wall("wall_left",left_post)
	mission=Mission.new(config)
	growth=Growth.new(config,world.shield_value)
	mission.add_rift(-1,frontier.left_boundary-180.0)
	mission.add_rift(1,frontier.right_boundary+180.0)
	frontier.left_boundary-=400.0
	frontier.right_boundary+=400.0
	expedition=RiftWorkforce.new(world,frontier,mission)
	return_margin = maxf(0.0,float(config.get("return_margin",15.0)))
	hunter_damage = maxi(1,int(config.get("hunter_damage",12)))
	hunter_range = maxf(30.0,float(config.get("hunter_range",170.0)))
	hunter_interval = maxf(0.2,float(config.get("hunter_interval",1.2)))
	stroll_speed=maxf(1.0,float(config.get("stroll_speed",24.0)))
	pouch = Pouch.new(clampi(config.get("capacity",30),1,30) if survival.enabled else config.get("capacity",12),config.get("starting_crystals",12))
	pouch.magnet_radius = maxf(32,config.get("magnet_radius",112.0))
	pouch.magnet_speed = maxf(32,config.get("magnet_speed",300.0))
	pouch.throw_grace = maxf(0.5,config.get("throw_grace",2.0))
	pouch.left_boundary=frontier.left_boundary
	pouch.right_boundary=frontier.right_boundary
	for node in frontier.nodes:
		if node.y<430: pouch.platforms.append({"left":node.x-70,"right":node.x+70,"y":node.y})
	clock = Calendar.new(config.get("day_seconds",180.0),config.get("night_seconds",60.0))
	prices = {"camp":2,"hall":5,"workshop":2,"armory":3,"farm_tools":2,"hunt_tools":3,"forge":2,"beacon":1,"wall":3,"wall_upgrade":4,"repair":2,"farm":3,"drill":2,"outpost":3,"mark":1,"recruit":1,"core_charge":2,"rift":4}
	prices.merge(config.get("prices",{}),true)
	for key in prices: prices[key]=clampi(int(prices[key]),1,12)
	warden_health=maxi(1,int(config.get("warden_health",90)))
	warden_damage=maxi(1,int(config.get("warden_damage",18)))
	enemy_health_growth = maxi(1,int(config.get("enemy_health_growth",12)))
	enemy_damage_growth = maxi(1,int(config.get("enemy_damage_growth",3)))
	world.crystals = 0
	world.scrap = 0
	world.sites.erase("horn")
	world.sites.merge({"trade":-700.0,"heal":-850.0})
	frontier.city_level = 0
	world.people.clear()
	for x in [180.0,245.0]: _add_person(x,-1)
	for index in range(frontier.regions.size()):
		var region: Dictionary = frontier.regions[index]
		_add_person(region.x+region.width*0.12,index)
		var node := Harvest.new()
		node.kind = "stone" if region.kind=="quarry" else "herbs"
		node.x = region.x+region.width*0.88
		node.pickup_x = node.x
		node.region = index
		if node.kind=="stone": node.stone=6
		else: node.herbs=3
		frontier.nodes.append(node)
	for node in frontier.nodes:
		var yield_key: String={"tree":"tree_crystals","crystal":"mineral_crystals","cache":"chest_crystals","berries":"plant_crystals","stone":"mineral_crystals","herbs":"plant_crystals"}[node.kind]
		var default_yield: int={"tree":4,"crystal":6,"cache":6,"berries":3,"stone":6,"herbs":3}[node.kind]
		node.crystals=clampi(int(config.get(yield_key,default_yield)),1,12)
		node.wood=0;node.food=0;node.stone=0;node.herbs=0;node.scrap=0

	ecology=Ecology.new(frontier,config)
	defenses=Defenses.new(world,frontier,config)
	if config.get("fortifications",1):
		buildings=BuildingSites.generate(frontier,map_seed,world.sites.beacon)
		_register_building_walls()
	build_seconds=clampf(config.get("building_seconds",3.0),1,30)
	tower_damage=clampi(config.get("tower_damage",12),1,100)
	tower_range=clampf(config.get("tower_range",460.0),200,800)
	time_to_raid = clock.remaining

func _add_person(x: float, region: int) -> void:
	world.people.append({"x":x,"role":"wanderer","hurt":0.0,"cooldown":0.0,"region":region})

func person_visible(person: Dictionary) -> bool:
	var region: int = person.get("region",-1)
	return person.role!="wanderer" or region<0 or frontier.regions[region].discovered

func _choice(id: String, x: float, title: String, cost: int = 0, allowed: bool = true, reason: String = "") -> Dictionary:
	return {"id":id,"x":x,"text":title,"cost":cost,"currency":"龍晶" if cost>0 else "","enabled":allowed,"reason":reason,"key":id,"paid":0}

func context(x: float) -> Dictionary:
	var selected := _no_interaction(x)
	for candidate in _interaction_candidates(x):
		if selected.id.is_empty() or (candidate.enabled and not selected.enabled) or (candidate.enabled==selected.enabled and absf(candidate.x-x)<absf(selected.x-x)):
			selected=candidate
	return selected

func context_for_key(x: float, key: String) -> Dictionary:
	for candidate in _interaction_candidates(x):
		if candidate.key==key: return candidate
	return _no_interaction(x)

func _no_interaction(x: float) -> Dictionary:
	return _choice("",x,"探索邊境，尋找流浪者與寶箱",0,false,"靠近目標互動")

func _interaction_candidates(x: float) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if not is_running():return candidates
	var choice: Dictionary
	for index in range(world.people.size()):
		var person: Dictionary = world.people[index]
		if person.role!="wanderer" or not person_visible(person) or absf(person.x-x)>=73.0 or absf(person.get("y",430)-_player_y)>42: continue
		choice = _choice("recruit",person.x,"招攬流浪者",prices.recruit,person.hurt<=0,"等待流浪者恢復")
		choice["person_index"] = index
		choice.key = "recruit:%d" % index
		candidates.append(choice)
	if absf(_player_y-430)<=42:
		for site in world.sites:
			if life.enabled and (site=="forge" or (survival.enabled and site=="heal") or (site=="armory" and frontier.city_level<3)):continue
			if site=="trade":continue # Retained in legacy snapshots only.
			if not defenses.visible(site):continue
			if frontier.city_level==0 and site!="hall": continue
			if absf(world.sites[site]-x)>=73.0: continue
			choice = _campaign_site(site)
			candidates.append(choice)
	for index in range(frontier.nodes.size()):
		var node = frontier.nodes[index]
		if node.collected or not frontier.regions[node.region].discovered or absf(node.x-x)>=73.0 or absf(node.y-_player_y)>42: continue
		if node.kind=="cache":
			choice = _choice("chest",node.x,"開啟寶箱 · %d 龍晶" % node.crystals)
		else:
			var label: String = {"tree":"伐木","crystal":"採晶","berries":"採果","stone":"採石","herbs":"採藥"}[node.kind]
			choice = _choice("mark",node.x,"委託工匠"+label,prices.mark,not node.marked,"已下令 · 等待工匠採集搬運")
		choice["node_index"] = index
		if ecology.clearing_last_tree(node):choice["consequences"]=["person","bow"]
		choice.key = "node:%d" % index
		candidates.append(choice)
	for index in range(frontier.regions.size()):
		var region: Dictionary = frontier.regions[index]
		if not region.outpost_ready or absf(region.outpost_x-x)>=73.0 or absf(_player_y-430)>42: continue
		if not (region.outpost_built or region.outpost_pending or frontier.expansion_cleared(index)):continue
		choice = _choice("outpost",region.outpost_x,"建立拓荒站",prices.outpost,not region.outpost_pending and not region.outpost_built,"工匠施工中" if region.outpost_pending else "拓荒站已建成")
		choice["region_index"] = index
		choice.key = "outpost:%d" % index
		candidates.append(choice)
	for id in buildings:
		if id=="beacon" or buildings[id].kind=="wall":continue
		if absf(buildings[id].x-x)<73 and absf(_player_y-430)<=42 and building_visible(id):candidates.append(building_context(id))
	for index in range(mission.rifts.size()):
		var rift: Dictionary=mission.rifts[index]
		if not rift.discovered or absf(rift.x-x)>=73 or absf(_player_y-430)>42:continue
		var prerequisites: Array=rift_requirements()
		choice=_choice("rift",rift.x,"封印龍裂隙",prices.rift,prerequisites.is_empty() and not rift.ordered and not rift.sealed,"升級聚落、熬過一晚並招募工匠")
		choice.key="rift:%d" % index
		choice["rift_index"]=index
		choice["prerequisites"]=prerequisites
		if rift.ordered:
			choice.cost=0
			choice.reason="封印完成" if rift.sealed else "護送工匠、擊退守門者並留在裂隙附近"
		candidates.append(choice)
	for candidate in candidates:
		candidate.paid = int(investments.get(candidate.key,0))
		if candidate.enabled and candidate.cost>0 and pouch.amount<=0:
			candidate.enabled = false
			candidate.reason = "背包沒有龍晶 · 尋找寶箱、收貨點或農田"
	return candidates

func _campaign_site(site: String) -> Dictionary:
	var at: float = world.sites[site]
	var choice := _choice(site,at,NAMES.get(site,"邊境防線"),int(prices.get(site,0)))
	if site=="beacon" and buildings.has(site):return building_context(site)
	if site=="hall":
		if frontier.city_level>0 and mission.core_hp<mission.core_max_hp:
			return _choice("core_charge",at,"核心充能",prices.core_charge)
		if frontier.city_level==0: return _choice("hall",at,"營火 · 建立第一座營地",0 if life.enabled else prices.camp)
		choice.text = "升級聚落"
		choice.key = "hall:%d" % frontier.city_level
		choice.cost = mini(12,prices.hall+2*(frontier.city_level-1))
		choice.enabled = frontier.city_level<3
		choice.reason = "王城已完成 · 繼續守住居民"

		return choice
	if frontier.city_level==0:
		choice.enabled=false
		choice.reason="先回營火投入 2 顆龍晶建立營地"
		return choice
	if site=="armory" and life.enabled:
		choice.cost=prices.armory
		choice.enabled=frontier.city_level>=3 and world.tools.blade<3
		choice.reason="需要三級聚落，或器具架已滿"
		choice["prerequisites"]=[] if frontier.city_level>=3 else [{"icon":"camp","value":3}]
		return choice
	if site=="armory":
		choice.key="armory:%d"%barracks_level
		choice.cost=mini(12,prices.armory+barracks_level*2)
		choice.enabled=barracks_level<3 and frontier.city_level>barracks_level
		choice.reason="需要更高級聚落，或兵營已滿級"
		choice["upgrade"]={"icon":"bow","level":barracks_level,"limit":3,"value":archer_damage(),"next":hunter_damage+mini(3,barracks_level+1)*6}
		choice["prerequisites"]=[]
		if barracks_level<3 and frontier.city_level<=barracks_level:choice.prerequisites.append({"icon":"camp","value":barracks_level+1})
		return choice
	if TOOL_KINDS.has(site):
		var kind: String = TOOL_KINDS[site]
		choice.text += " · 庫存 %d/3" % world.tools[kind]
		choice.enabled = world.tools[kind]<3
		choice.reason = "器具架已滿，等待居民領取"
	elif world.walls.has(site):
		var defense: Dictionary=world.walls[site]
		choice["wall_id"]=site
		if defenses.plots.has(site):choice.id="wall"
		var repair: bool = defense.level>0 and defense.hp<world.wall_max_hp(defense.level)
		choice.cost = prices.repair if repair else (prices.wall if defense.level==0 else mini(12,prices.wall_upgrade+(3 if defense.level==2 else 0)))
		choice.text = "修復防線" if repair else ("建立木防線" if defense.level==0 else ("升級石防線" if defense.level==1 else "升級堡壘"))
		choice.key = "%s:%d:%s" % [site,defense.level,repair]
		choice.enabled = not defense.pending and (repair or defense.level<3)
		choice["prerequisites"]=defenses.prerequisites(site)
		if not repair and defense.level==2 and frontier.city_level<3:choice.prerequisites.append({"icon":"camp","value":3})
		choice["upgrade"]={"icon":"wall","level":defense.level,"limit":3,"value":defense.hp,"next":world.wall_max_hp(defense.level if repair else mini(3,defense.level+1))}
		if defense.level==3 and not repair:choice.cost=0
		choice.enabled=choice.enabled and choice.prerequisites.is_empty()
		choice.reason = "需要聚落、前哨、內側防線與清地；或施工中／已達上限"
	elif site=="forge":
		var charging:=hero.shield<growth.capacity()
		choice.id="shield_charge" if charging else "forge"
		choice.key="shield_charge" if charging else "forge:%d" % growth.capacitor_level
		choice.cost=growth.charge_cost if charging else growth.crystal_cost(prices.forge,growth.capacitor_level)
		choice.enabled=charging or growth.can_install(frontier.city_level)
		choice["prerequisites"]=[]
		if not charging and growth.capacitor_level<growth.capacitor_limit and frontier.city_level<=growth.capacitor_level:
			choice.prerequisites.append({"icon":"camp","value":growth.capacitor_level+1})
		choice["upgrade"]={"icon":"shield","level":growth.capacitor_level,"limit":growth.capacitor_limit,
			"value":hero.shield if charging else growth.capacity(),
			"next":growth.recharge(hero.shield) if charging else mini(growth.capacitor_level+1,growth.capacitor_limit)*growth.shield_per_cell}
		if not charging and growth.capacitor_level>=growth.capacitor_limit:
			choice.cost=0
			choice.requirements={}
		choice.text="護盾充能" if charging else "擴充義肢電容"
		choice.reason="先升級聚落，或電容已滿階"
	elif site=="farm":
		choice.text = "開墾晶蕾農田"
		choice.enabled = not frontier.farm_active
		choice.reason = "已播種 · 農夫持續培育龍晶"
	elif site=="drill":
		var limit:=mini(3,frontier.training_limit)
		choice.key="drill:%d" % frontier.drill_level
		choice.cost=growth.crystal_cost(prices.drill,frontier.drill_level)
		choice["prerequisites"]=[]
		if frontier.drill_level<limit and frontier.city_level<=frontier.drill_level:
			choice.prerequisites.append({"icon":"camp","value":frontier.drill_level+1})
		choice["upgrade"]={"icon":"sword","level":frontier.drill_level,"limit":limit,
			"value":hero.stats.damage,"next":hero.stats.damage+(frontier.training_damage if frontier.drill_level<limit else 0)}
		if frontier.drill_level>=limit:
			choice.cost=0
			choice.requirements={}
		choice.text="劍術訓練"
		choice.enabled=frontier.drill_level<limit and frontier.drill_level<frontier.city_level
		choice.reason="先升級聚落，或劍術已滿階"
	elif site=="heal":
		choice.cost=int(prices.get("heal",2))
		choice.text = "龍晶治療 · 回復 30 生命"
		choice.enabled = hero.hp<hero.stats.max_hp
		choice.reason = "目前生命已滿"

	return choice

func interact(x: float, target_key: String = "") -> bool:
	if not is_running(): return false
	var choice := context(x) if target_key.is_empty() else context_for_key(x,target_key)
	if not choice.enabled: return false
	if choice.cost>0:
		if not pouch.spend(): return false
		investments[choice.key] = choice.paid+1
		effects.append({"kind":"pay","x":x,"to":choice.x,"life":0.45})
		if investments[choice.key]<choice.cost: return true
		investments.erase(choice.key)
	_execute(choice)
	return true

func _execute(choice: Dictionary) -> void:
	match choice.id:
		"tower","field": buildings[choice.building_id].pending=true
		"rift": mission.order(choice.rift_index)
		"core_charge": mission.recharge_core()
		"recruit": world.people[choice.person_index].role="citizen"
		"chest":
			var node = frontier.nodes[choice.node_index]
			node.collected=true
			node.delivered=true
			pouch.burst(node.crystals,node.x,node.y)
			opened_chests[choice.node_index]=workforce.elapsed
			effects.append({"kind":"chest_burst","x":node.x,"y":node.y,"life":0.7})
		"mark": frontier.mark(frontier.nodes[choice.node_index])
		"hall":
			frontier.city_level+=1
			if life.enabled and frontier.city_level==1:
				built.workshop=true;built.hunt_tools=true
				if survival.enabled:survival.armed=true
				effects.append({"kind":"camp_ignition","x":world.sites.hall,"life":2.4})
			if life.enabled and frontier.city_level==3:built.armory=true
		"armory":
			if life.enabled:world.tools.blade+=1
			else:barracks_level+=1
			built.armory=true
		"workshop","farm_tools","hunt_tools":
			world.tools[TOOL_KINDS[choice.id]]+=1
			built[choice.id]=true
		"wall","wall_left":
			var defense: Dictionary=world.walls[choice.get("wall_id",choice.id)]
			var repair: bool=defense.level>0 and defense.hp<world.wall_max_hp(defense.level)
			defense.merge({"pending":true,"repair":repair,"progress":0.0},true)
		"outpost": frontier.regions[choice.region_index].outpost_pending=true
		"farm": frontier.farm_active=true
		"forge":
			hero.shield=growth.install(frontier.city_level)
			built.forge=true
		"shield_charge":
			hero.shield=growth.recharge(hero.shield)
		"beacon": world.barrier+=1; built.beacon=true
		"drill":
			frontier.drill_level+=1
			hero.stats.damage+=frontier.training_damage
		"heal": hero.hp=mini(hero.stats.max_hp,hero.hp+30)

func advance(seconds: float, hero_x: float, hero_y: float = 430.0) -> void:
	if seconds<=0 or not is_finite(seconds):return
	mission.resolve(hero.is_alive(),raiders.is_empty())
	if not is_running():return
	_hero_x=hero_x
	if survival.advance(seconds,hero,hero_x,hero_y):effects.append({"kind":"sword_recovered","x":hero_x,"y":hero_y,"life":0.7})
	mission.reveal(hero_x)
	for animal in frontier.animals:
		if not animal.alive:continue
		animal["home_x"]=animal.get("home_x",animal.x)
		animal.x=animal.home_x+sin(workforce.elapsed*0.36+animal.region*1.7)*28
	super.advance(seconds,hero_x,hero_y)
	mission.resolve(hero.is_alive(),raiders.is_empty())
	if not is_running(): return
	_advance_expeditions(seconds,hero_x,hero_y)
	_summon_dragon(hero_x)
	mission.resolve(hero.is_alive(),raiders.is_empty())
	if not is_running():return
	if life.enabled:
		hero.shield=0;world.barrier=0
		life.collect(world,pouch,raiders,hero_x,hero_y)
	# Legacy offering-only recruitment.
	for person in world.people:
		if not life.enabled and person.role=="wanderer" and person.hurt<=0 and person_visible(person) and pouch.consume_offering(person.x,person.get("y",430)):
			var key := "recruit:%d" % world.people.find(person)
			investments[key]=int(investments.get(key,0))+1
			if investments[key]<prices.recruit: continue
			investments.erase(key)
			person.role="citizen"
			effects.append({"kind":"recruited","x":person.x,"y":person.get("y",430),"life":0.7})
	pouch.advance(seconds,hero_x,hero_y)
	if life.enabled and pouch.amount>=pouch.capacity:
		for gem in pouch.drops:
			if gem.grace<=0 and absf(gem.x-hero_x)<22 and absf(gem.y-hero_y)<24:
				effects.append({"kind":"crystal_sink","x":hero_x,"y":hero_y,"life":0.85})
				gem.amount=0
		pouch.drops=pouch.drops.filter(func(gem):return gem.amount>0)
	for pickup in pouch.pickups:
		effects.append({"kind":"crystal_pickup","x":pickup.x,"y":pickup.y,"life":0.25})
	pouch.pickups.clear()

func throw_crystal(x: float, y: float, facing: int) -> bool:
	return is_running() and pouch.toss(x,y,facing)

func _receive_delivery(delivery: Dictionary) -> void:
	super._receive_delivery(delivery)
	var crystals: int = delivery.get("crystals",0)
	world.crystals-=crystals
	pouch.drop(crystals,delivery.x)

func _advance_people(seconds: float) -> void:
	expedition.prepare()
	_assign_defense_posts()
	_advance_towers(seconds)
	var previous: Array=[]
	for person in world.people: previous.append(float(person.x))
	super._advance_people(seconds)
	BuildingSites.separate_outposts(frontier,buildings,world.sites,investments)
	for index in range(world.people.size()):
		var person: Dictionary=world.people[index]
		# Supplies, tools and occupations have already chosen their real destinations.
		if person.role not in ["wanderer","citizen"] or person.get("moving",false) or person.get("sheltering",false): continue
		if person.role=="wanderer" and absf(person.x-_hero_x)<=72: continue
		var before: float=person.x
		var radius:=64.0 if person.role=="wanderer" else 100.0
		var target:=Roaming.destination(person,index,world.sites.hall,radius,seconds,frontier.left_boundary+16,frontier.right_boundary-16)
		person.x=move_toward(person.x,target,stroll_speed*seconds)
		person.moving=absf(person.x-before)>0.01
		if person.moving: person.direction=signf(person.x-before)

	for index in range(world.people.size()):
		var person: Dictionary=world.people[index]
		person["walk_distance"]=float(person.get("walk_distance",0.0))+absf(person.x-previous[index])

func _override_resident_target(index: int, seconds: float) -> float:
	var person: Dictionary = world.people[index]
	if life.enabled:
		if person.role=="guard":
			_shoot_nearest_raider(person,90.0,24,1.1)
			return _defense_position(index,28.0)
		if life.threatened(person,raiders) and person.role not in ["wanderer","guard","hunter"]:
			person["sheltering"]=true;person["work_state"]="walk"
			return defenses.shelter(person.x,world.sites.hall+(index%5-2)*22)
		var crystal_x: float=life.crystal_target(person,pouch,_hero_x)
		if is_finite(crystal_x) and not life.threatened(person,raiders):return crystal_x
	var expedition_target:=expedition.target(index,seconds)
	if is_finite(expedition_target):return expedition_target
	if not life.enabled and person.role=="engineer" and (clock.is_night or clock.remaining<=return_margin):
		var construction:=Construction.target(self,index,seconds,true)
		if is_finite(construction):return construction
	if person.role not in ["citizen","engineer","farmer","hunter"]: return NAN
	var home: float = defenses.shelter(person.x,world.sites.hall + (index%5-2)*22.0)
	if person.role=="hunter" and world.walls[defenses.active_post(1 if person.defense_post=="wall" else -1)].hp>0:
		home = _defense_position(index,90.0)
	if person.role=="hunter":
		_shoot_nearest_raider(person,hunter_range,archer_damage(),hunter_interval)
	if life.enabled and not life.threatened(person,raiders):return NAN
	if not Schedule.should_return(clock.is_night,clock.remaining,person.x,home,_person_speed,return_margin):
		return NAN
	person["sheltering"] = true
	person["work_state"] = "walk"
	if person.role=="engineer":
		for job in frontier.nodes:
			if job.worker==index and job.carried:
				person.work_state = "haul"
				break
		if absf(person.get("y",430.0)-430.0)>0.1:
			person["y"] = move_toward(person.get("y",430.0),430.0,70.0*seconds)
			person.work_state = "climb"
			return person.x
	if person.role!="hunter":
		var left: float=world.sites[defenses.active_post(-1)]+120
		var right: float=world.sites[defenses.active_post(1)]-120
		if world.walls[defenses.active_post(-1)].hp<=0:left=maxf(left,world.sites.hall-260)
		if world.walls[defenses.active_post(1)].hp<=0:right=minf(right,world.sites.hall+260)
		# Separate lanes and pauses distribute residents; emergency boundaries clamp instantly.
		var count:=0
		var rank:=0
		for i in range(world.people.size()):
			if world.people[i].role in ["citizen","engineer","farmer"]:
				if i<index:rank+=1
				count+=1
		var width: float=maxf(0,right-left)/maxi(1,count)
		var center: float=left+(rank+0.5)*width
		var radius: float=minf(110,width*0.35)
		return Roaming.destination(person,index,center,radius,seconds,center-radius,center+radius)
	return home

func travel_axis(request: float, seconds: float) -> float:
	return travel.axis(hero,request,seconds)

func archer_damage() -> int:return hunter_damage if life.enabled else hunter_damage+barracks_level*6

func _assign_defense_posts() -> void:
	var counts: Dictionary={"wall":0,"wall_left":0}
	for person in world.people:
		if person.role=="guard" and not life.enabled:person.role="hunter"
		if person.role not in ["guard","hunter"]:
			person.erase("defense_post")
		elif person.has("defense_post"):
			counts[person.defense_post]+=1
	for person in world.people:
		if person.role in ["guard","hunter"] and not person.has("defense_post"):
			var post: String="wall" if counts.wall<=counts.wall_left else "wall_left"
			person["defense_post"]=post
			counts[post]+=1

func _defense_position(index: int, inset: float) -> float:
	var post: String=world.people[index].defense_post
	var rank:=0
	for i in range(index):
		if world.people[i].get("defense_post","")==post: rank+=1
	var side:=1.0 if post=="wall" else -1.0
	return world.sites[defenses.active_post(int(side))]-side*(inset+mini(rank,4)*18.0)

func raid_pressure() -> Dictionary:
	var pressure: Dictionary={"left":0,"right":0}
	if not clock.is_night and clock.remaining>30 and raiders.is_empty(): return pressure
	for enemy in raiders:
		if enemy.fighter.is_alive(): pressure["right" if enemy.get("side",1)>0 else "left"]+=1
	var start: int=_night_spawn_index if clock.is_night else 0
	var pending: int=_spawn_remaining if clock.is_night else (mini(12,2+clock.day) if clock.remaining<=30 else 0)
	for i in range(start,start+pending):
		if mission.side_open(1 if i%2==0 else -1):pressure["right" if i%2==0 else "left"]+=1
	return pressure

func is_running() -> bool:
	return hero.is_alive() and mission.outcome=="active"

func finished() -> bool:return mission.outcome!="active"

func _strategic_target(_raider: Dictionary) -> Dictionary:
	return {"kind":"core","x":world.sites.hall}

func _hit_structure(target: Dictionary, amount: int) -> void:
	if target.kind=="core":
		effects.append({"kind":"core_hit","x":world.sites.hall,"life":1.5})
		mission.damage_core(amount)
		mission.resolve(hero.is_alive(),false)
	else:super._hit_structure(target,amount)
func begin_raid() -> bool: return false # The calendar alone starts a night.

func _advance_invasion(seconds: float) -> void:
	var transition := clock.advance(seconds,raiders.is_empty() and _spawn_remaining==0)
	if transition=="dawn":
		for arrival in ecology.renew(clock.day,world.people):_add_person(arrival.x,arrival.region)
	if transition=="night":
		wave=clock.day
		_spawn_remaining=mini(12,2+clock.day)
		_spawn_timer=0.0
		_night_spawn_index=0
	if _spawn_remaining>0:
		_spawn_timer-=seconds
		while _spawn_timer<=0 and _spawn_remaining>0:
			var side:=1 if _night_spawn_index%2==0 else -1
			_night_spawn_index+=1
			_spawn_remaining-=1
			if not mission.side_open(side):continue
			var enemy:=_spawn_raider()
			enemy["side"]=side
			enemy.x=mission.entry_x(side)
			effects.append({"kind":"portal_spawn","x":enemy.x,"y":430.0,"life":0.6})
			enemy["exit_x"]=enemy.x+side*70.0
			enemy["direction"]=-float(side)
			raiders.append(enemy)
			_spawn_timer=2.5
	time_to_raid=clock.remaining

func _spawn_raider() -> Dictionary:
	var raider := super._spawn_raider()
	var stats := Stats.new()
	stats.hurt_invulnerability = raider.fighter.stats.hurt_invulnerability
	stats.max_hp=60+(clock.day-1)*enemy_health_growth
	stats.damage=15+(clock.day-1)*enemy_damage_growth
	raider.fighter=Fighter.new(stats)
	raider["wall_damage"]=20+(clock.day-1)*enemy_damage_growth
	return raider

func rift_requirements() -> Array[Dictionary]:
	var requirements: Array[Dictionary]=[]
	if frontier.city_level<2:requirements.append({"icon":"camp","value":2})
	if clock.survived<1:requirements.append({"icon":"survived","value":1})
	if not world.people.any(func(p):return p.role=="engineer"):requirements.append({"icon":"hammer","value":1})
	return requirements

func expedition_status(index: int, hero_x: float, hero_y: float) -> Dictionary:
	var rift: Dictionary=mission.rifts[index]
	return {"worker_ready":expedition.worker_ready(rift),
		"knight_near":absf(hero_x-rift.x)<160 and absf(hero_y-430)<80,
		"contested":raiders.any(func(r):return r.fighter.is_alive() and absf(r.x-rift.x)<180)}

func _advance_expeditions(seconds: float, hero_x: float, hero_y: float) -> void:
	for index in range(mission.rifts.size()):
		var rift: Dictionary=mission.rifts[index]
		if not rift.ordered or rift.sealed:continue
		var status:=expedition_status(index,hero_x,hero_y)
		var ready: bool=status.worker_ready
		var knight_near: bool=status.knight_near
		if ready and knight_near and not rift.wardens_spawned:
			rift.wardens_spawned=true
			for offset in [-120.0,120.0]:
				var enemy:=_spawn_raider()
				enemy.fighter.stats.max_hp=maxi(warden_health,enemy.fighter.stats.max_hp)
				enemy.fighter.hp=enemy.fighter.stats.max_hp
				enemy.fighter.stats.damage=maxi(warden_damage,enemy.fighter.stats.damage)
				enemy.x=rift.x+offset
				enemy["side"]=rift.side
				enemy["kind"]="warden"
				enemy["direction"]=-signf(offset)
				raiders.append(enemy)
		# Wardens may have been added above; re-read contest status before sealing.
		var contested: bool=expedition_status(index,hero_x,hero_y).contested
		mission.advance_seal(index,seconds,ready,knight_near,contested)

func _collect_loot(drop: Dictionary) -> void:
	pouch.receive(1,drop.x)

func kingdom_established() -> bool:
	var citizens := 0
	for person in world.people:
		if person.role!="wanderer": citizens+=1
	return hero.is_alive() and clock.survived>=3 and frontier.city_level>=3 and [-1,1].all(func(side):
		var w: Dictionary=world.walls[defenses.active_post(side)]
		return w.level>=2 and w.hp>0) and citizens>=3

func _receive_hunt(at: float) -> void:
	pouch.drop(2,at)

func _advance_farm(seconds: float, farmers: int) -> void:
	var before: int=frontier.food
	frontier.advance_farm(seconds,farmers)
	var produced: int=frontier.food-before
	frontier.food=before
	pouch.drop(produced,world.sites.farm)
	if clock.is_night and not life.enabled:return
	for site in buildings.values():
		if site.kind!="farm" or site.level==0:continue
		var workers:=world.people.filter(func(p):return p.role=="farmer" and not p.get("sheltering",false) and absf(p.x-site.x)<24).size()
		if workers==0:continue
		site.harvest+=seconds*workers
		while site.harvest>=frontier.farm_cycle:
			site.harvest-=frontier.farm_cycle;pouch.drop(frontier.farm_yield,site.x)

func convert_legacy_resources() -> void:
	# Called only after validating an old checkpoint, before its first v3 save.
	var stored: int=frontier.wood+frontier.food+frontier.stone+frontier.herbs+world.scrap+world.crystals
	pouch.drop(stored,world.sites.hall)
	frontier.wood=0;frontier.food=0;frontier.stone=0;frontier.herbs=0
	world.scrap=0;world.crystals=0
	for node in frontier.nodes:
		# Yield belongs to the node, including plants already awaiting dawn renewal.
		node.crystals+=node.wood+node.food+node.stone+node.herbs+node.scrap
		node.wood=0;node.food=0;node.stone=0;node.herbs=0;node.scrap=0

func _summon_dragon(hero_x: float) -> void:
	if not is_running() or mission.dragon_summoned or not mission.rifts.all(func(r):return r.sealed):return
	mission.dragon_summoned=true;mission.dragon_day=clock.day
	var power=preload("res://domain/dragon_rules.gd").strength(clock.day,mission.dragon_rules)
	var dragon=_spawn_raider()
	var side:int=-1 if hero_x<world.sites.hall else 1
	dragon.kind="dragon";dragon.side=side;dragon.direction=-float(side)
	dragon.x=clampf(hero_x+side*480,frontier.left_boundary+80,frontier.right_boundary-80)
	dragon.fighter.stats.max_hp=power.health;dragon.fighter.hp=power.health
	dragon.fighter.stats.damage=power.damage;dragon.fighter.stats.hurt_invulnerability=0.0
	dragon.wall_damage=12+maxi(0,clock.day-int(mission.dragon_rules.baseline_day))*2
	dragon.cooldown=5.0
	raiders.append(dragon)
	effects.append({"kind":"dragon_arrival","x":dragon.x,"to":hero_x,"life":5.0})

func _advance_raider(enemy: Dictionary, seconds: float, hero_x: float, hero_y: float) -> void:
	if survival.enabled and Forager.advance(self,enemy,seconds):return
	if enemy.get("kind","")=="dragon":
		preload("res://application/dragon_assault.gd").advance(self,enemy,seconds,hero_x,hero_y)
	else:super._advance_raider(enemy,seconds,hero_x,hero_y)

func strike_from(x: float, y: float) -> void:
	if not can_wield_sword():return
	# The dragon is massive: a finisher damages it but cannot cancel its breath forever.
	var stable: Array=[]
	for enemy in raiders:
		if enemy.get("kind","")=="dragon":stable.append([enemy,enemy.x,enemy.windup])
	super.strike_from(x,y)
	for entry in stable:
		entry[0].x=entry[1];entry[0].windup=entry[2];entry[0].stagger=0.0

func _engineer_target(index: int, seconds: float) -> float:
	var construction:=Construction.target(self,index,seconds,false)
	if is_finite(construction):return construction
	var target:=super._engineer_target(index,seconds)
	var person: Dictionary=world.people[index]
	if person.get("work_state","")=="idle" and is_equal_approx(target,world.sites.workshop):
		return Roaming.destination(person,index,world.sites.workshop,120,seconds,frontier.left_boundary,frontier.right_boundary)
	return target

func _hunter_prey(person: Dictionary) -> Dictionary:
	var prey: Dictionary={};var nearest:=INF
	for animal in frontier.animals:
		if not animal.alive or not frontier.regions[animal.region].discovered:continue
		var travel: float=(absf(person.x-animal.x)+absf(animal.x-world.sites.hall))/_person_speed
		if not life.enabled and (clock.is_night or travel+return_margin+3>clock.remaining):continue
		var distance: float=absf(animal.x-person.x)
		if distance<nearest:nearest=distance;prey=animal
	return prey

func _idle_hunter_target(person: Dictionary, seconds: float) -> float:
	var index: int=world.people.find(person)
	var center: float=world.sites.hunt_tools
	var forests=frontier.regions.filter(func(r):return r.discovered and r.kind=="forest")
	if not forests.is_empty():
		var region: Dictionary=forests[index%forests.size()]
		var scout: float=region.x+region.width*0.5
		if (absf(person.x-scout)+absf(scout-world.sites.hall))/_person_speed+return_margin<clock.remaining:center=scout
	return Roaming.destination(person,index,center,110,seconds,frontier.left_boundary,frontier.right_boundary)

func _farm_target(person: Dictionary) -> float:
	var fields: Array[float]=[]
	if frontier.farm_active:fields.append(float(world.sites.farm))
	for site in buildings.values():
		if site.kind=="farm" and site.level>0:fields.append(site.x)
	if fields.is_empty():fields.append(world.sites.farm)
	var farmers=world.people.filter(func(p):return p.role=="farmer")
	var index: int=farmers.find(person)
	return fields[maxi(0,index)%fields.size()]+sin(workforce.elapsed*0.9+index*2.1)*16

func _register_building_walls() -> void:
	for id in buildings:
		var site: Dictionary=buildings[id]
		if site.kind!="wall":continue
		world.add_wall(id,site.x)
		defenses.plots[id]={"region":site.region,"side":1 if site.x>world.sites.hall else -1,"previous":"wall" if site.x>world.sites.hall else "wall_left","cleared_node":site.node}

func building_visible(id: String) -> bool:
	var site: Dictionary=buildings[id]
	return frontier.city_level>0 and (site.level>0 or site.pending or BuildingSites.cleared(frontier,site))

func building_context(id: String) -> Dictionary:
	var site: Dictionary=buildings[id]
	var tower: bool=site.kind=="tower"
	var limit:=3 if tower else 1
	var choice:=_choice("tower" if tower else "field",site.x,"升級守護塔" if tower else "開墾晶蕾農田",[3,5,8][mini(2,site.level)] if tower else prices.farm)
	choice["building_id"]=id
	choice.key="building:%s:%d"%[id,site.level]
	choice.enabled=building_visible(id) and not site.pending and site.level<limit and frontier.city_level>site.level
	choice.reason="等待工匠施工，或先升級聚落"
	choice["prerequisites"]=[]
	if site.level<limit and frontier.city_level<=site.level:choice.prerequisites.append({"icon":"camp","value":site.level+1})
	if site.pending or site.level>=limit:choice.cost=0
	if tower:
		var before=BuildingSites.tower_power(site.level,{"tower_damage":tower_damage})
		var after=BuildingSites.tower_power(mini(3,site.level+1),{"tower_damage":tower_damage})
		choice["upgrade"]={"icon":"bow" if site.level<2 else "gear","level":site.level,"limit":3,"value":roundi(before.damage/before.interval),"next":roundi(after.damage/after.interval),"suffix":"/s"}
	return choice

func _advance_towers(seconds: float) -> void:
	for site in buildings.values():
		if site.kind!="tower" or site.level<=0:continue
		site.cooldown=maxf(0,site.cooldown-seconds)
		if site.cooldown>0:continue
		var power=BuildingSites.tower_power(site.level,{"tower_damage":tower_damage,"tower_range":tower_range})
		var nearest: Dictionary={};var distance: float=power.range
		for enemy in raiders:
			if enemy.fighter.is_alive() and absf(enemy.x-site.x)<distance:
				nearest=enemy;distance=absf(enemy.x-site.x)
		if nearest.is_empty():continue
		nearest.fighter.take_damage(power.damage)
		site.cooldown=power.interval
		effects.append({"kind":"tower_laser" if site.level==3 else "tower_arrow","x":site.x,"to":nearest.x,"life":0.28,"tier":site.level})

func hit_hero(damage: int, x: float, y: float) -> bool:
	return survival.receive_hit(hero,pouch,damage,x,y)

func can_wield_sword() -> bool:
	if survival.enabled:return survival.armed
	return not life.enabled or frontier.city_level>0

func cancel_investment(key: String, x: float) -> void:
	if not life.enabled or not investments.has(key):return
	var count: int=investments[key]
	investments.erase(key)
	pouch.burst(count,x,320.0)

func cancel_all_investments(x: float) -> void:
	for key in investments.keys():cancel_investment(key,x)
