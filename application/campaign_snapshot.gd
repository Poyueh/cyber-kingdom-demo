extends RefCounted
## Closed, versioned state graph. No script paths or object construction come from a save.
const Campaign=preload("res://application/campaign_session.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")
const VERSION:=9
const SESSION_SKIP=["raiders","effects","opened_chests"]
const FIGHTER_SKIP=["_hit_targets","_queued_attack_seconds","_pending_attack_travel"]
var last_error:=""
var _baseline: Dictionary={}
var _baseline_config: Dictionary={}

func _plain(value, depth: int=0) -> bool:
	if depth>20:return false
	match typeof(value):
		TYPE_NIL,TYPE_BOOL:return true
		TYPE_INT,TYPE_FLOAT:return is_finite(float(value)) and absf(float(value))<=1000000000000.0
		TYPE_STRING,TYPE_STRING_NAME:return str(value).length()<=2048
		TYPE_ARRAY:
			if value.size()>10000:return false
			for item in value:
				if not _plain(item,depth+1):return false
			return true
		TYPE_DICTIONARY:
			if value.size()>10000:return false
			for key in value:
				if not (key is String or key is StringName) or not _plain(key,depth+1) or not _plain(value[key],depth+1):return false
			return true
	return false

func _fields(object, skip: Array=[]) -> Dictionary:
	var result: Dictionary={}
	for property in object.get_property_list():
		var key: String=property.name
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or key in skip:continue
		var value=object.get(key)
		if typeof(value)==TYPE_OBJECT:continue
		# Every remaining script field must have an explicitly supported plain shape.
		result[key]=value.duplicate(true) if value is Array or value is Dictionary else value
	return result

func _fighter(actor) -> Dictionary:
	return {"stats":_fields(actor.stats),"state":_fields(actor,FIGHTER_SKIP)}

func capture(sim, config: Dictionary, body: Dictionary) -> Dictionary:
	var rules:=config.duplicate(true)
	rules.seed=sim.map_seed
	var nodes: Array=[]
	for node in sim.frontier.nodes:nodes.append(_fields(node))
	var enemies: Array=[]
	var hit_indices: Array=[]
	for index in range(sim.raiders.size()):
		var enemy: Dictionary=sim.raiders[index]
		var state:=enemy.duplicate()
		state.erase("fighter")
		enemies.append({"state":state.duplicate(true),"fighter":_fighter(enemy.fighter)})
		if sim.hero._hit_targets.has(enemy.fighter.get_instance_id()):hit_indices.append(index)
	var opened: Dictionary={}
	for key in sim.opened_chests:opened[str(key)]=sim.opened_chests[key]
	return {"version":VERSION,"config":rules,"body":body.duplicate(true),
		"session":_fields(sim,SESSION_SKIP),"world":_fields(sim.world,["wall"]),
		"frontier":_fields(sim.frontier,["nodes"]),"nodes":nodes,"clock":_fields(sim.clock),
		"mission":_fields(sim.mission),"growth":_fields(sim.growth),"ecology":_fields(sim.ecology),
		"pouch":_fields(sim.pouch,["pickups"]),"workforce":_fields(sim.workforce,["deliveries"]),
		"spirit":_fields(sim.spirit),"travel":_fields(sim.travel),"survival":_fields(sim.survival),"hero":_fighter(sim.hero),"raiders":enemies,"hero_hits":hit_indices,"opened":opened}

func _normalize(value):
	if value is StringName:return str(value)
	if value is float and floorf(value)==value:return int(value)
	if value is Array:
		var result: Array=[]
		for item in value:result.append(_normalize(item))
		return result
	if value is Dictionary:
		var result: Dictionary={}
		for key in value:result[str(key)]=_normalize(value[key])
		return result
	return value

func _copy_fields(object, saved, skip: Array=[]) -> bool:
	if not saved is Dictionary:return false
	var template:=_fields(object,skip)
	if saved.size()!=template.size():return false
	for key in template:
		if not saved.has(key):return false
		var value=saved[key]
		match typeof(template[key]):
			TYPE_INT:
				if not value is int:return false
			TYPE_FLOAT:
				if not (value is int or value is float):return false
			_:
				if typeof(value)!=typeof(template[key]):return false
		if value is Array and template[key].is_typed():
			for item in value:
				if typeof(item)!=template[key].get_typed_builtin():return false
	for key in template:
		if template[key] is Array:
			# Preserve typed arrays such as Array[Dictionary].
			object.get(key).assign(saved[key].duplicate(true))
		else:object.set(key,saved[key].duplicate(true) if saved[key] is Dictionary else saved[key])
	return true

func _restore_fighter(actor, saved) -> bool:
	return saved is Dictionary and saved.has("stats") and saved.has("state") and _copy_fields(actor.stats,saved.stats) and _copy_fields(actor,saved.state,FIGHTER_SKIP)

func _invalid() -> Dictionary:
	last_error="Invalid or unsupported campaign checkpoint; original retained."
	return {}

func restore(raw) -> Dictionary:
	last_error=""
	if not raw is Dictionary or not _plain(raw):return _invalid()
	var data: Dictionary=_normalize(raw)
	var keys=["version","config","body","session","world","frontier","nodes","clock","mission","growth","ecology","pouch","workforce","hero","raiders","hero_hits","opened"]
	if data.get("version",0) in [7,8,9]:keys.append("travel")
	if data.get("version",0) in [8,9]:keys.append("survival")
	if data.get("version",0)==9:keys.append("spirit")
	if data.size()!=keys.size() or not keys.all(func(k):return data.has(k)):return _invalid()
	var legacy_economy: bool=data.version in [1,2]
	if data.version==2:data.version=3
	if data.version==1 and not _upgrade_v1(data):return _invalid()
	if data.version==3 and not _upgrade_v3(data):return _invalid()
	if data.version==4 and not _upgrade_v4(data):return _invalid()
	if data.version==5 and not _upgrade_v5(data):return _invalid()
	if data.version==6:
		if not data.config is Dictionary or not Rules.config_valid(data.config):return _invalid()
		data["travel"]=_fields(Campaign.new(data.config).travel)
		data.version=7
	if data.version==7 and not _upgrade_v7(data,raw.get("version",0)==7):return _invalid()
	if data.version==8 and not _upgrade_v8(data):return _invalid()
	if data.version!=VERSION or not data.config is Dictionary or not data.body is Dictionary:return _invalid()
	if not Rules.config_valid(data.config):return _invalid()
	for key in ["x","y","vx","vy"]:
		if not data.body.has(key) or not (data.body[key] is int or data.body[key] is float):return _invalid()
	if data.body.size()!=4:return _invalid()
	var sim=Campaign.new(data.config)
	if not Rules.valid(data,_baseline_for(sim,data.config,data.body)):return _invalid()
	for part in [
		[sim,data.session,SESSION_SKIP],[sim.world,data.world,["wall"]],
		[sim.frontier,data.frontier,["nodes"]],[sim.clock,data.clock,[]],[sim.mission,data.mission,[]],
		[sim.growth,data.growth,[]],[sim.ecology,data.ecology,[]],[sim.pouch,data.pouch,["pickups"]],
		[sim.workforce,data.workforce,["deliveries"]]]:
		if not _copy_fields(part[0],part[1],part[2]):return _invalid()
	if not _copy_fields(sim.travel,data.travel):return _invalid()
	if not _copy_fields(sim.survival,data.survival):return _invalid()
	if not _restore_spirit(sim,data):return _invalid()
	var survival=sim.survival
	if survival.enabled!=(sim.life.enabled and int(data.config.get("crystal_survival",0))==1):return _invalid()
	if survival.hit_loss!=int(data.config.get("hit_crystal_loss",0)):return _invalid()
	if survival.enabled and not Rules.in_range(survival.hit_loss,1,10):return _invalid()
	if not Rules.in_range(survival.sword_grace,0,1.2) or survival.hits<0:return _invalid()
	if survival.armed and (survival.sword_on_ground or sim.frontier.city_level==0):return _invalid()
	if survival.sword_on_ground and not Rules.in_range(survival.sword_x,sim.frontier.left_boundary,sim.frontier.right_boundary):return _invalid()
	if sim.travel.rest_remaining<0 or sim.travel.rest_remaining>1.5:return _invalid()
	if sim.travel.forced_rest!=sim.life.enabled:return _invalid()
	if not Rules.in_range(sim.travel.fast_multiplier,1.1,3.0) or not Rules.in_range(sim.travel.drain_per_second,5,40):return _invalid()
	if not _restore_fighter(sim.hero,data.hero):return _invalid()
	if not data.nodes is Array or data.nodes.size()!=sim.frontier.nodes.size():return _invalid()
	for i in range(data.nodes.size()):
		if not _copy_fields(sim.frontier.nodes[i],data.nodes[i]):return _invalid()
	if not data.raiders is Array or data.raiders.size()>100:return _invalid()
	for saved in data.raiders:
		if not saved is Dictionary or not saved.get("state") is Dictionary:return _invalid()
		var enemy=sim._spawn_raider()
		if not _restore_fighter(enemy.fighter,saved.get("fighter")):return _invalid()
		var actor=enemy.fighter
		enemy=saved.state.duplicate(true)
		enemy.fighter=actor
		sim.raiders.append(enemy)
	if not data.hero_hits is Array:return _invalid()
	for index in data.hero_hits:
		if not index is int or index<0 or index>=sim.raiders.size():return _invalid()
		sim.hero._hit_targets[sim.raiders[index].fighter.get_instance_id()]=true
	if not data.opened is Dictionary:return _invalid()
	for key in data.opened:
		if not key.is_valid_int() or int(key)<0 or int(key)>=sim.frontier.nodes.size():return _invalid()
		sim.opened_chests[int(key)]=data.opened[key]
	if not sim.world.walls.has("wall"):return _invalid()
	sim.world.wall=sim.world.walls.wall
	if legacy_economy:sim.convert_legacy_resources()
	return {"session":sim,"config":data.config,"body":data.body}

## The admission baseline is a pure function of the run configuration, so one
## session reuses it instead of snapshotting a fresh world on every checkpoint.
## Rules.valid reads the saved body, never the baseline's, but keeping it current
## avoids a stale value if that ever changes.
func _baseline_for(fresh, config: Dictionary, body: Dictionary) -> Dictionary:
	if _baseline.is_empty() or not Rules.same(_baseline_config,config):
		_baseline_config=config.duplicate(true)
		_baseline=capture(fresh,config,body)
	_baseline.body=body.duplicate(true)
	return _baseline

func _upgrade_v1(data: Dictionary) -> bool:
	# Upgrade only the known old stat shape; unknown fields still fail normal validation.
	if not data.hero is Dictionary or not data.raiders is Array or not data.config is Dictionary:return false
	var fighters: Array=[data.hero]
	for enemy in data.raiders:
		if not enemy is Dictionary or not enemy.get("fighter") is Dictionary:return false
		fighters.append(enemy.fighter)
	for fighter in fighters:
		if not fighter.get("stats") is Dictionary:return false
		if fighter.stats.has("attack_cost") or fighter.stats.has("jump_cost"):return false
		fighter.stats["attack_cost"]=0.0
		fighter.stats["jump_cost"]=0.0
	data.hero.stats.attack_cost=data.config.get("attack_stamina",12.0)
	data.hero.stats.jump_cost=data.config.get("jump_stamina",18.0)
	data.version=3
	return true

func _upgrade_v3(data: Dictionary) -> bool:
	if not data.mission is Dictionary or not data.config is Dictionary or not Rules.config_valid(data.config):return false
	var additions={"dragon_summoned":false,"dragon_defeated":false,"dragon_day":0,"dragon_rules":preload("res://domain/dragon_rules.gd").tuning(data.config)}
	for key in additions:
		if data.mission.has(key):return false
	data.mission.merge(additions)
	# A previously completed run keeps its earned victory. Active runs face the dragon.
	if data.mission.get("outcome","")=="victory":
		data.mission.dragon_summoned=true;data.mission.dragon_defeated=true;data.mission.dragon_day=int(data.clock.get("day",1))
	data.version=4
	return true

func _upgrade_v4(data: Dictionary) -> bool:
	# Validate against the known old geography and tool mappings BEFORE changing them.
	if not data.config is Dictionary or not Rules.config_valid(data.config):return false
	if not data.session is Dictionary or data.session.has("barracks_level"):return false
	var legacy_config: Dictionary=data.config.duplicate(true)
	legacy_config.flat_frontier=0
	legacy_config.fortifications=0
	var legacy=Campaign.new(legacy_config)
	var base:=capture(legacy,legacy_config,data.body)
	base.session.erase("barracks_level")
	for field in ["buildings","build_seconds","tower_damage","tower_range"]:base.session.erase(field)
	if not Rules.valid(data,base):return false
	data.session.barracks_level=0
	data.config.flat_frontier=1
	for node in data.nodes:
		node.y=430.0;node.pickup_y=430.0
	data.pouch.platforms=[]
	data.body.y=430.0;data.body.vy=0.0
	data.session._player_y=430.0
	data.hero.state.dash_remaining=0.0
	data.world.tool_roles.blade="hunter"
	data.world.tool_sites.blade="hunt_tools"
	for person in data.world.people:
		if person.role=="guard":person.role="hunter"
		if person.get("roam_role","")=="guard":person.roam_role="hunter"
		if person.has("y"):person.y=430.0
	# Preserve partial sword-rack payments as progress toward the new barracks.
	if data.session.investments.has("armory"):
		data.session.investments["armory:0"]=data.session.investments.armory
		data.session.investments.erase("armory")
	data.version=5
	return true

func _upgrade_v5(data: Dictionary) -> bool:
	if not data.config is Dictionary or not Rules.config_valid(data.config):return false
	if not data.session is Dictionary or data.session.has("buildings"):return false
	var config: Dictionary=data.config.duplicate(true);config.fortifications=0
	var base:=capture(Campaign.new(config),config,data.body)
	for field in ["buildings","build_seconds","tower_damage","tower_range"]:base.session.erase(field)
	if not Rules.valid(data,base):return false
	for wall in data.world.walls.values():
		if wall.level>2:return false
	config.fortifications=1
	var current:=capture(Campaign.new(config),config,data.body)
	data.config=config
	for field in ["buildings","build_seconds","tower_damage","tower_range"]:data.session[field]=current.session[field]
	for id in current.world.sites:
		if not data.world.sites.has(id):data.world.sites[id]=current.world.sites[id]
	for id in current.world.walls:
		if not data.world.walls.has(id):data.world.walls[id]=current.world.walls[id]
	if data.session.built.get("beacon",false):data.session.buildings.beacon.level=1
	data.version=6
	return true

func _upgrade_v7(data: Dictionary, upgrade_immersive: bool) -> bool:
	if not data.config is Dictionary or not Rules.config_valid(data.config):return false
	if not data.frontier is Dictionary or not data.pouch is Dictionary:return false
	if not data.frontier.get("city_level") is int:return false
	if not data.body is Dictionary or not ["x","y","vx","vy"].all(func(k):return data.body.has(k) and Rules.number(data.body[k])):return false
	var original=Campaign.new(data.config)
	if not Rules.valid(data,capture(original,data.config,data.body)):return false
	# Earlier classic campaigns keep their rules. Current immersive journeys adopt
	# crystal protection and retain both their money and their already drawn sword.
	if upgrade_immersive and data.config.get("immersive_loop",0)==1 and not data.config.has("crystal_survival"):
		data.config.crystal_survival=1;data.config.hit_crystal_loss=3
		data.config.capacity=30;data.pouch.capacity=30
	var fresh=Campaign.new(data.config)
	data["survival"]=_fields(fresh.survival)
	data.survival.armed=fresh.survival.enabled and data.frontier.city_level>0
	data.version=8
	return true

func _upgrade_v8(data: Dictionary) -> bool:
	if not data.config is Dictionary or not Rules.config_valid(data.config):return false
	if not data.workforce is Dictionary or not Rules.number(data.workforce.get("elapsed")):return false
	var fresh=Campaign.new(data.config)
	# Keep old early journeys guided; completed/expired openings must not restart.
	var complete: bool=false
	if data.nodes is Array and data.world is Dictionary and data.world.get("people") is Array:
		var worker: bool=data.world.people.any(func(p):return p is Dictionary and p.get("role")=="engineer")
		complete=worker and data.nodes.any(func(n):return n is Dictionary and n.get("kind")!="cache" and (n.get("marked",false)==true or n.get("collected",false)==true))
	fresh.spirit.advance(int(data.workforce.elapsed*fresh.spirit.TICKS_PER_SECOND),complete)
	if fresh.spirit.opening_finished:fresh.spirit.expires_tick=0
	data["spirit"]=_fields(fresh.spirit)
	data.version=9
	return true

func _restore_spirit(sim: RefCounted, data: Dictionary) -> bool:
	var expected=preload("res://application/spirit_guidance.gd").new(data.config)
	if not _copy_fields(sim.spirit,data.spirit):return false
	var spirit=sim.spirit
	if spirit.opening_ticks!=expected.opening_ticks or spirit.visit_ticks!=expected.visit_ticks:return false
	if not Rules.in_range(spirit.expires_tick,0,maxf(spirit.opening_ticks,sim.workforce.elapsed*spirit.TICKS_PER_SECOND+spirit.visit_ticks+1)):return false
	if spirit.summoned and not spirit.opening_finished:return false
	return true
