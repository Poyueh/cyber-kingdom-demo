extends RefCounted
const World = preload("res://domain/settlement.gd")
const Fighter = preload("res://domain/combatant.gd")
const Stats = preload("res://domain/combat_stats.gd")
var world: World
var hero: Fighter
var raiders: Array[Dictionary] = []
var loot: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var wave: int = 0
var time_to_raid: float
var _raid_gap: float
var _person_speed: float
var _spawn_remaining := 0
var _spawn_timer := 0.0

func _init(config: Dictionary = {}, hero_stats: Stats = null) -> void:
	world = World.new(config)
	hero = Fighter.new(hero_stats if hero_stats != null else Stats.new())
	time_to_raid = maxf(1.0,float(config.get("first_raid",55.0)))
	_raid_gap = maxf(1.0,float(config.get("raid_gap",30.0)))
	_person_speed = maxf(1.0,float(config.get("person_speed",60.0)))

func is_running() -> bool:
	return hero.is_alive()

func finished() -> bool:
	return wave >= 3 and raiders.is_empty() and _spawn_remaining == 0

func context(x: float) -> Dictionary:
	var result := {"id":"", "x":x, "text":"靠近流浪者或建築，投入資源", "cost":0, "currency":"", "enabled":false,"reason":"靠近目標才能投入"}
	var nearest := 73.0
	for person in world.people:
		var distance := absf(person.x-x)
		if person.role == "wanderer" and distance < nearest:
			nearest = distance
			result = {"id":"recruit", "x":person.x, "text":"投放補給，招攬流浪者", "cost":1,"currency":"廢料","enabled":world.scrap>0,"reason":"廢料不足"}
	for site in world.sites:
		if not ["forge","workshop","armory","beacon","wall","horn"].has(site): continue
		var distance := absf(world.sites[site]-x)
		if distance >= nearest:
			continue
		nearest = distance
		var cost := 2
		var currency := "廢料"
		var label := ""
		var enabled := true
		var reason := ""
		match site:
			"forge":
				cost = 1
				currency = "龍晶"
				label = "義肢爐：騎士護盾 +%d" % world.shield_value
			"workshop":
				label = "工坊：補充工程錘（庫存 %d）" % world.tools.hammer
				enabled = world.tools.hammer < 3
				reason = "工程錘庫存已滿"
			"armory":
				label = "武器坊：補充守備器具（庫存 %d）" % world.tools.blade
				enabled = world.tools.blade < 3
				reason = "守備器具庫存已滿"
			"beacon":
				cost = 1
				currency = "龍晶"
				label = "護民塔：抵擋一次居民受擊"
			"wall":
				cost = world.wall_cost()
				label = "防線：建造" if world.wall.level == 0 else "防線：升級"
				if world.wall.hp < world.wall.level*40:
					label = "防線：修復"
				if world.wall.pending:
					label = "防線施工  %d%%" % mini(100,int(world.wall.progress/3.0*100))
					reason = "等待工程師到場"
					for person in world.people:
						if person.role == "engineer" and absf(person.x-world.sites.wall)<20:
							reason = "工程師正在施工，不需再次付款"
					cost = 0
					enabled = false
				elif world.wall.level >= 2 and world.wall.hp == 80:
					label = "防線已達最高等級"
					cost = 0
					reason = "防線完整，暫不需要施工"
					enabled = false
			"horn":
				cost = 0
				currency = ""
				label = "警鐘：提前迎戰下一波"
				enabled = raiders.is_empty() and _spawn_remaining == 0 and not finished()
				reason = "三波試煉已結束" if finished() else "夜襲進行中"
		if enabled and currency == "廢料" and world.scrap < cost:
			enabled = false
			reason = "廢料不足"
		elif enabled and currency == "龍晶" and world.crystals < cost:
			enabled = false
			reason = "龍晶不足"
		result = {"id":site,"x":world.sites[site],"text":label,"cost":cost,"currency":currency,"enabled":enabled,"reason":reason}
	return result

func interact(x: float) -> bool:
	if not hero.is_alive():
		return false
	var choice := context(x)
	if not choice.enabled:
		return false
	var success := false
	match choice.id:
		"recruit": success = world.drop_supply(x + hero.facing*8)
		"forge":
			hero.shield += world.take_knight_crystal()
			success = true
		"workshop": success = world.buy_tool("hammer")
		"armory": success = world.buy_tool("blade")
		"beacon": success = world.power_refuge()
		"wall": success = world.order_wall()
		"horn": success = begin_raid()
	if success:
		effects.append({"kind":"pay","x":x,"to":choice.x,"life":0.45})
	return success

func begin_raid() -> bool:
	if not raiders.is_empty() or _spawn_remaining > 0 or finished():
		return false
	time_to_raid = _raid_gap
	wave += 1
	_spawn_remaining = 2 + wave
	_spawn_timer = 0.0
	return true

func advance(seconds: float, hero_x: float, hero_y: float = 430.0) -> void:
	if seconds <= 0 or not is_finite(seconds) or not is_running():
		return
	hero.advance(seconds)
	for effect in effects:
		effect.life -= seconds
	effects = effects.filter(func(effect): return effect.life > 0)
	for supply in world.supplies:
		supply.age += seconds
	_advance_people(seconds)
	_advance_invasion(seconds)
	for raider in raiders:
		_advance_raider(raider,seconds,hero_x,hero_y)
		if not is_running(): break
	if not is_running(): return
	for raider in raiders:
		if not raider.fighter.is_alive() and not raider.get("escaped", false):
			loot.append({"x":raider.x,"taken":false})
	raiders = raiders.filter(func(raider): return raider.fighter.is_alive())
	for drop in loot:
		if not drop.taken and absf(drop.x-hero_x)<28 and absf(hero_y-430)<45:
			drop.taken = true
			_collect_loot(drop)
	loot=loot.filter(func(drop):return not drop.taken)
	world.supplies=world.supplies.filter(func(supply):return not supply.taken)

func _can_claim_tool(_kind: String) -> bool:return true

func _advance_people(seconds: float) -> void:
	for index in range(world.people.size()):
		var person: Dictionary = world.people[index]
		person.hurt = maxf(0,person.hurt-seconds)
		person.cooldown = maxf(0,person.cooldown-seconds)
		var target: float = person.x
		person["sheltering"] = false
		var override_target := _override_resident_target(index,seconds)
		if is_finite(override_target):
			target = override_target
		else:
			match person.role:
				"wanderer":
					var nearest := INF
					for supply_index in range(world.supplies.size()):
						var supply: Dictionary = world.supplies[supply_index]
						if not supply.taken and absf(supply.x-person.x)<nearest:
							nearest = absf(supply.x-person.x)
							target = supply.x
							world.collect_supply(index,supply_index)
				"citizen":
					var nearest := INF
					for kind in world.tools:
						var rack: float = world.tool_location(kind)
						if _can_claim_tool(kind) and world.tools[kind]>0 and absf(rack-person.x)<nearest:
							nearest = absf(rack-person.x)
							target = rack
							world.claim_tool(index,kind)
				"engineer": target = _engineer_target(index,seconds)
				"guard":
					target = world.sites.wall-65-index*18
					_shoot_nearest_raider(person,190.0,20,0.85)
		person["moving"] = absf(target-person.x)>1
		if person.moving: person["direction"] = signf(target-person.x)
		person.x = move_toward(person.x,target,_person_speed*seconds)

## Campaign policies can take priority over routine job destinations.
func _override_resident_target(_index: int, _seconds: float) -> float:
	return NAN

func _shoot_nearest_raider(person: Dictionary, reach: float, damage: int, interval: float) -> bool:
	if person.cooldown > 0.0 or absf(person.get("y",430.0)-430.0)>42:
		return false
	var nearest: Dictionary = {}
	var distance := reach
	for raider in raiders:
		var hit_distance: float=maxf(0,absf(raider.x-person.x)-(70 if raider.get("kind","")=="dragon" else 0))
		if raider.fighter.is_alive() and hit_distance<distance:
			nearest = raider
			distance = hit_distance
	if nearest.is_empty(): return false
	nearest.fighter.take_damage(damage)
	person.cooldown = interval
	effects.append({"kind":"bolt","x":person.x,"to":nearest.x,"life":0.18})
	return true

func _engineer_target(index: int, seconds: float) -> float:
	if world.wall.pending:
		world.work_wall(index,seconds)
		return world.sites.wall-12
	return world.people[index].x

func _target(raider: Dictionary, hero_x: float, hero_y: float) -> Dictionary:
	var result: Dictionary={"kind":"leave","x":raider.get("exit_x",1650.0)}
	if absf(hero_x-raider.x)<65 and absf(hero_y-430)<42:
		result={"kind":"hero","x":hero_x}
	else:
		var nearest:=INF
		for index in range(world.people.size()):
			var person: Dictionary=world.people[index]
			if person.role!="wanderer" and absf(person.get("y",430)-430)<42 and absf(person.x-raider.x)<nearest:
				nearest=absf(person.x-raider.x)
				result={"kind":"person","x":person.x,"index":index}
	var strategic:=_strategic_target(raider)
	if not strategic.is_empty() and result.kind!="hero":
		if result.kind=="leave" or absf(strategic.x-raider.x)<absf(result.x-raider.x):
			result=strategic
	var wall_target:=_blocking_wall(raider.x,result.x,int(raider.get("side",1)) if result.kind=="leave" else 0)
	return result if wall_target.is_empty() else wall_target

func _strategic_target(_raider: Dictionary) -> Dictionary:
	return {}

func _hit_structure(target: Dictionary, amount: int) -> void:
	if target.kind=="wall":world.hit_wall(amount,target.get("wall_id","wall"))

func _blocking_wall(from_x: float, to_x: float, approach_side: int = 0) -> Dictionary:
	var nearest:=INF
	var result: Dictionary={}
	for id in world.walls:
		if not world.wall_operational(id): continue
		var at: float=world.sites[id]
		var between: bool=at>=minf(from_x,to_x) and at<=maxf(from_x,to_x)
		if approach_side!=0: between=(at-from_x)*-approach_side>=-25
		if between and absf(at-from_x)<nearest:
			nearest=absf(at-from_x)
			result={"kind":"wall","x":at,"wall_id":id}
	return result

func _advance_raider(raider: Dictionary, seconds: float, hero_x: float, hero_y: float) -> void:
	raider.fighter.advance(seconds)
	if not raider.fighter.is_alive():
		return
	# A fully funded upgrade opens the route even during an enemy's windup.
	if raider.windup > 0 and raider.target.get("kind", "") == "wall" and not world.wall_operational(raider.target.get("wall_id", "wall")):
		raider.windup = 0.0
	raider.cooldown = maxf(0,raider.cooldown-seconds)
	if float(raider.get("stagger",0.0)) > 0.0:
		raider.stagger = maxf(0.0,raider.stagger-seconds)
		return
	if raider.windup > 0:
		raider.windup = maxf(0,raider.windup-seconds)
		if raider.windup == 0:
			var target: Dictionary = raider.target
			var at: float = target.x
			if target.kind == "person": at = world.people[target.index].x
			if target.kind == "hero": at = hero_x
			if target.kind!="wall":
				var obstruction:=_blocking_wall(raider.x,at)
				if not obstruction.is_empty():
					target=obstruction
					at=target.x
			if absf(at-raider.x)<38:
				match target.kind:
					"hero":
						if absf(hero_y-430)<42: hit_hero(raider.fighter.stats.damage,hero_x,hero_y)
					"wall","core": _hit_structure(target,raider.get("wall_damage",20))
					"person":
						if absf(world.people[target.index].get("y",430)-430)<42: world.hit_person(target.index)
				effects.append({"kind":"hit","x":at,"to":at,"life":0.25})
		return
	var target := _target(raider,hero_x,hero_y)
	if absf(target.x-raider.x)>0.1: raider["direction"]=signf(target.x-raider.x)
	if target.kind == "leave":
		# Leaving has no melee stopping distance or attack windup.
		raider.x = move_toward(raider.x,target.x,70*seconds)
		if absf(raider.x-target.x)<=10:
			raider.fighter.hp = 0
			raider["escaped"] = true
		return
	if absf(target.x-raider.x)>26:
		raider.x = move_toward(raider.x,target.x,70*seconds)
	elif raider.cooldown <= 0:
		raider.target = target
		raider.windup = 0.6
		raider.cooldown = 1.5

func strike_from(x: float, y: float) -> void:
	if not is_running():return
	if absf(y-430)>hero.stats.vertical_range:
		return
	for raider in raiders:
		var distance: float=raider.x-x
		if raider.get("kind","")=="dragon":distance=signf(distance)*maxf(0,absf(distance)-70)
		if hero.strike(raider.fighter,distance):
			var heavy := hero.combo_step == 3
			effects.append({"kind":"hit","x":raider.x,"to":raider.x,"life":0.28 if heavy else 0.2,"heavy":heavy,"facing":hero.attack_facing})
			if heavy:
				raider.x += hero.attack_facing * 22.0
				raider.windup = 0.0
				raider["stagger"] = 0.24

func _advance_invasion(seconds: float) -> void:
	if _spawn_remaining > 0:
		_spawn_timer -= seconds
		if _spawn_timer <= 0:
			raiders.append(_spawn_raider())
			_spawn_remaining -= 1
			_spawn_timer = 2.5
	elif raiders.is_empty() and not finished():
		time_to_raid -= seconds
		if time_to_raid <= 0:
			begin_raid()

func _spawn_raider() -> Dictionary:
	var stats := Stats.new()
	stats.hurt_invulnerability = 0.12
	stats.max_hp = 60
	stats.damage = 15
	return {"x":1580.0,"fighter":Fighter.new(stats),"windup":0.0,"cooldown":0.0,"target":{}}

func _collect_loot(_drop: Dictionary) -> void:
	world.scrap += 2

func hit_hero(damage: int, _x: float, _y: float) -> bool:
	return hero.take_damage(damage)
