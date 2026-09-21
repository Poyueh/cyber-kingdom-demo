extends RefCounted
## Current schema admission rules, after known-version migration. Validate plain shapes before constructing live state.
const Combatant=preload("res://domain/combatant.gd")
const Stats=preload("res://domain/combat_stats.gd")
const ROLES=["wanderer","citizen","engineer","guard","hunter","farmer"]

static func number(value) -> bool:
	return value is int or value is float

static func config_valid(config: Dictionary) -> bool:
	if not config.get("seed") is int:return false
	for key in config:
		if key in ["economy","prices"]:
			if not config[key] is Dictionary:return false
			for value in config[key].values():
				if not number(value):return false
		elif not number(config[key]):return false
	return true

## Numeric templates accept JSON's integral floats after normalization.
static func shape(value, template, optional: Dictionary={}) -> bool:
	if template is float:return number(value)
	if typeof(value)!=typeof(template):return false
	if template is Dictionary:
		for key in template:
			if not value.has(key) or not shape(value[key],template[key]):return false
		for key in value:
			if not template.has(key) and (not optional.has(key) or not shape(value[key],optional[key])):return false
	if template is Array:
		for item in value:
			if not template.is_empty() and not shape(item,template[0]):return false
	return true

static func in_range(value, low: float, high: float) -> bool:
	return number(value) and value>=low and value<=high

static func index_valid(value, count: int) -> bool:
	return value is int and value>=-1 and value<count

static func fighter(saved) -> bool:
	if not saved is Dictionary or not saved.get("stats") is Dictionary or not saved.get("state") is Dictionary:return false
	if saved.size()!=2:return false
	var template_stats=Stats.new()
	var template_state=Combatant.new(template_stats)
	for pair in [[saved.stats,template_stats,[]],[saved.state,template_state,["stats","_hit_targets","_queued_attack_seconds","_pending_attack_travel"]]]:
		var count:=0
		for property in pair[1].get_property_list():
			if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or str(property.name) in pair[2]:continue
			count+=1
			if not pair[0].has(property.name) or not shape(pair[0][property.name],pair[1].get(property.name)):return false
		if pair[0].size()!=count:return false
	var stats: Dictionary=saved.stats
	var state: Dictionary=saved.state
	# Field types and completeness are checked by the codec before assignment.
	for key in ["max_hp","damage","attack_duration","attack_range","max_stamina","dash_duration"]:
		if not in_range(stats.get(key),0.001,1000000):return false
	for key in stats:
		if number(stats[key]) and stats[key]<0:return false
	if not in_range(state.get("hp"),0,stats.max_hp) or not in_range(state.get("stamina"),0,stats.max_stamina):return false
	for key in state:
		if key not in ["facing","attack_facing"] and number(state[key]) and state[key]<0:return false
	return state.get("facing") in [-1,1] and state.get("attack_facing") in [-1,1] and state.get("combo_step") in [0,1,2,3]

static func valid(data: Dictionary, base: Dictionary) -> bool:
	# Every fixed object must have the version's exact scalar/container fields.
	for section in ["session","world","frontier","clock","mission","growth","ecology","pouch","workforce"]:
		if not data[section] is Dictionary or data[section].size()!=base[section].size():return false
		for key in base[section]:
			if not data[section].has(key):return false
			var expected=base[section][key]
			var actual=data[section][key]
			if expected is Array or expected is Dictionary:
				if typeof(actual)!=typeof(expected):return false
			elif not shape(actual,expected):return false
	var mutable={
		"session":["loot","wave","time_to_raid","_spawn_remaining","_spawn_timer","_hero_x","_night_spawn_index","_player_y","investments","built","barracks_level","buildings"],
		"world":["people","supplies","tools","walls","scrap","crystals","barrier"],
		"frontier":["regions","animals","wood","food","stone","herbs","city_level","farm_active","farm_progress","drill_level"],
		"clock":["day","survived","is_night","remaining"],"mission":["core_hp","outcome","defeat_reason","rifts","dragon_summoned","dragon_defeated","dragon_day"],
		"growth":["capacitor_level"],"ecology":["last_dawn"],"pouch":["amount","drops","_next_id"],"workforce":["elapsed"]}
	for section in mutable:
		for key in base[section]:
			if key not in mutable[section] and not same(data[section][key],base[section][key]):return false
	if not in_range(data.session.get("barracks_level",0),0,3):return false
	if data.session.has("buildings"):
		if not shape(data.session.buildings,base.session.buildings):return false
		for id in data.session.buildings:
			var site: Dictionary=data.session.buildings[id]
			for field in ["kind","x","region","node"]:
				if not same(site[field],base.session.buildings[id][field]):return false
			if not in_range(site.level,0,3 if site.kind=="tower" else 1):return false
			if not in_range(site.progress,0,data.session.build_seconds) or not in_range(site.cooldown,0,2) or not in_range(site.harvest,0,data.frontier.farm_cycle):return false
			if site.pending and site.level>=(3 if site.kind=="tower" else 1):return false
	var world: Dictionary=data.world
	var map: Dictionary=data.frontier
	var people: Array=world.people
	if people.size()>40:return false
	for key in ["sites","tool_roles","tool_sites","tools","walls"]:
		if not shape(world[key],base.world[key]):return false
	for key in ["sites","tool_roles","tool_sites"]:
		if not same(world[key],base.world[key]):return false
	for value in world.tools.values():
		if not in_range(value,0,3):return false
	for key in ["scrap","crystals","barrier"]:
		if world[key]<0:return false
	for wall in world.walls.values():
		if not in_range(wall.level,0,3) or not in_range(wall.hp,0,preload("res://domain/building_sites.gd").wall_health(wall.level)) or wall.progress<0:return false
	for supply in world.supplies:
		if not shape(supply,{"x":0.0,"taken":false,"age":0.0}) or supply.age<0:return false
	var left: float=base.frontier.left_boundary
	var right: float=base.frontier.right_boundary
	if map.left_boundary!=left or map.right_boundary!=right:return false
	if not in_range(data.body.x,left,right) or not in_range(data.body.y,-1000,500):return false
	if not in_range(data.body.vx,-2000,2000) or not in_range(data.body.vy,-2000,2000):return false
	var optional={"y":0.0,"moving":false,"direction":0.0,"sheltering":false,"work_state":"","walk_distance":0.0,
		"crystals":0,"roam_role":"","roam_home":0.0,"roam_leg":0,"roam_wait":0.0,"roam_target":0.0,"defense_post":""}
	for person in people:
		if not shape(person,{"x":0.0,"role":"","hurt":0.0,"cooldown":0.0,"region":0},optional):return false
		if not in_range(person.get("crystals",0),0,12):return false
		if person.role not in ROLES or person.hurt<0 or person.cooldown<0:return false
		if not index_valid(person.region,base.frontier.regions.size()):return false
		if person.has("defense_post") and person.defense_post not in ["wall","wall_left"]:return false
		if person.has("roam_role") and person.roam_role not in ROLES:return false
		if person.has("work_state") and person.work_state not in ["idle","climb","walk","work","haul"]:return false
	for key in ["wood","food","stone","herbs","farm_progress","drill_level"]:
		if map[key]<0:return false
	if map.city_level not in [0,1,2,3] or map.drill_level>map.training_limit:return false
	if map.regions.size()!=base.frontier.regions.size():return false
	for i in range(map.regions.size()):
		var region=map.regions[i]
		if not shape(region,base.frontier.regions[i]):return false
		for key in ["kind","x","width"]:
			if region[key]!=base.frontier.regions[i][key]:return false
		if region.outpost_progress<0:return false
	if map.animals.size()!=base.frontier.animals.size():return false
	for animal in map.animals:
		if not shape(animal,{"x":0.0,"region":0,"alive":true},{"home_x":0.0}):return false
		if not index_valid(animal.region,map.regions.size()) or animal.region<0:return false
	if not data.nodes is Array or data.nodes.size()!=base.nodes.size():return false
	for i in range(data.nodes.size()):
		var node=data.nodes[i]
		if not shape(node,base.nodes[i]):return false
		for key in ["kind","region","x","y"]:
			if not same(node[key],base.nodes[i][key]):return false
		if not index_valid(node.worker,people.size()) or not in_range(node.remaining_work,0,75):return false
		for key in ["wood","food","crystals","scrap","stone","herbs","work_elapsed"]:
			if node[key]<0:return false
		if node.carried and (not node.collected or node.delivered or node.worker<0):return false
	var clock: Dictionary=data.clock
	if clock.day<1 or clock.survived!=clock.day-1 or clock.remaining<0 or clock.day_seconds<1 or clock.night_seconds<1:return false
	var pouch: Dictionary=data.pouch
	if pouch.capacity<1 or not in_range(pouch.amount,0,pouch.capacity) or pouch._next_id<0:return false
	if not same(pouch.platforms,base.pouch.platforms) or pouch.left_boundary!=left or pouch.right_boundary!=right:return false
	var ids: Dictionary={}
	for gem in pouch.drops:
		if not shape(gem,{"id":0,"x":0.0,"y":0.0,"amount":0,"vx":0.0,"vy":0.0,"age":0.0,"grace":0.0,"offering":false,"attracted":false},{"trail_x":0.0,"trail_y":0.0}):return false
		if gem.id<=0 or gem.id>pouch._next_id or ids.has(gem.id) or gem.amount<=0 or gem.age<0 or gem.grace<0:return false
		ids[gem.id]=true
	var mission: Dictionary=data.mission
	if mission.outcome not in ["active","victory","defeat"] or mission.defeat_reason not in ["","core","knight"]:return false
	if mission.core_max_hp<1 or not in_range(mission.core_hp,0,mission.core_max_hp) or mission.seal_seconds<=0:return false
	if mission.dragon_day<0 or (mission.dragon_summoned and mission.dragon_day<1):return false
	if mission.dragon_defeated and not mission.dragon_summoned:return false
	if mission.outcome=="victory" and not mission.dragon_defeated:return false
	if mission.rifts.size()!=2:return false
	for i in range(2):
		var rift=mission.rifts[i]
		if not shape(rift,base.mission.rifts[i]):return false
		if rift.side!=base.mission.rifts[i].side or rift.x!=base.mission.rifts[i].x:return false
		if not index_valid(rift.worker,people.size()) or not in_range(rift.progress,0,mission.seal_seconds):return false
	if not fighter(data.hero) or data.growth.capacitor_level<0 or data.growth.capacitor_level>data.growth.capacitor_limit:return false
	if data.hero.state.shield>data.growth.capacitor_level*data.growth.shield_per_cell:return false
	if data.session.map_seed!=data.config.seed or data.session._spawn_remaining<0 or data.session.wave<0:return false
	for drop in data.session.loot:
		if not shape(drop,{"x":0.0,"taken":false}):return false
	for value in data.session.investments.values():
		if not value is int or value<1 or value>12:return false
	for value in data.session.built.values():
		if not value is bool:return false
	if not shape(data.session.prices,base.session.prices):return false
	for value in data.session.prices.values():
		if not in_range(value,1,12):return false
	if not data.raiders is Array or data.raiders.size()>100:return false
	for enemy in data.raiders:
		if not enemy is Dictionary or not enemy.has("state") or not fighter(enemy.get("fighter")):return false
		if not enemy.state is Dictionary or not enemy.state.get("target") is Dictionary:return false
		var without_target=enemy.state.duplicate(true)
		without_target.target={}
		if not shape(without_target,{"x":0.0,"windup":0.0,"cooldown":0.0,"target":{}},
			{"side":0,"exit_x":0.0,"direction":0.0,"wall_damage":0,"stagger":0.0,"escaped":false,"kind":""}):return false
		var state: Dictionary=enemy.state
		if state.windup<0 or state.cooldown<0 or not state.target is Dictionary:return false
		if state.target.is_empty():
			if state.windup>0:return false
		else:
			if not shape(state.target,{"kind":"","x":0.0},{"index":0,"wall_id":""}):return false
			if state.target.kind not in ["hero","core","wall","person","leave"]:return false
			if state.target.kind=="person" and (not index_valid(state.target.get("index"),people.size()) or state.target.index<0):return false
			if state.target.kind=="wall" and not world.walls.has(state.target.get("wall_id","wall")):return false
	var dragons=data.raiders.filter(func(e):return e.state.get("kind","")=="dragon")
	if dragons.size()>1:return false
	if mission.dragon_summoned and not mission.dragon_defeated and dragons.size()!=1:return false
	if not mission.dragon_summoned and not dragons.is_empty():return false
	if not data.opened is Dictionary:return false
	for value in data.opened.values():
		if not in_range(value,0,data.workforce.elapsed):return false
	return true

## JSON uses one numeric type; map coordinates tolerate serialization precision only.
static func same(a, b) -> bool:
	if number(a) and number(b):return absf(float(a)-float(b))<0.000001
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	return a==b
