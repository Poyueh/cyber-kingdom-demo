extends "res://application/settlement_session.gd"
const Frontier = preload("res://domain/frontier.gd")
const Workforce = preload("res://application/frontier_workforce.gd")
var workforce: Workforce
var frontier: Frontier
var map_seed: int
var _player_y := 430.0
const EXTRA_SITES := {"farm_tools":-150.0,"hunt_tools":-550.0,"farm":-350.0,"hall":30.0,"drill":1230.0}

func _init(config: Dictionary = {}, hero_stats: Stats = null) -> void:
	super(config,hero_stats)
	map_seed = int(config.get("seed",742601))
	frontier = Frontier.new(map_seed,config.get("economy",{}))
	world.sites.merge(EXTRA_SITES)
	workforce = Workforce.new(world,frontier)
	world.tools.merge({"hoe":0,"bow":0})
	world.tool_sites.merge({"hoe":"farm_tools","bow":"hunt_tools"})
	world.tool_roles.merge({"hoe":"farmer","bow":"hunter"})
	for x in [315.0,400.0]:
		world.people.append({"x":x,"role":"wanderer","hurt":0.0,"cooldown":0.0})

func context(x: float) -> Dictionary:
	var choice := super.context(x)
	if choice.id == "workshop": choice.text = "工坊：工程器具（庫存 %d）" % world.tools.hammer
	var nearest: float = absf(choice.x-x) if not choice.id.is_empty() else 73.0
	for site in EXTRA_SITES:
		var distance := absf(x-world.sites[site])
		if distance >= nearest: continue
		nearest = distance
		choice = _site_context(site)
	for index in range(frontier.nodes.size()):
		var node = frontier.nodes[index]
		var distance := absf(node.x-x)
		if node.collected or distance>=nearest or absf(node.y-_player_y)>42 or not frontier.regions[node.region].discovered: continue
		nearest = distance
		var name: String = {"tree":"標記伐木","crystal":"標記採礦","cache":"標記回收","berries":"標記採果"}[node.kind]
		var yield_text: Array[String] = []
		if node.wood>0: yield_text.append("%d 木材" % node.wood)
		if node.food>0: yield_text.append("%d 食物" % node.food)
		if node.crystals>0: yield_text.append("%d 龍晶" % node.crystals)
		if node.scrap>0: yield_text.append("%d 廢料" % node.scrap)
		choice = {"id":"mark","node_index":index,"x":node.x,"text":name+" / "+" · ".join(yield_text), "cost":0,"currency":"",
			"enabled":not node.marked,"reason":"已下令，等待工匠領取工作" if node.worker<0 else "工匠正在前往／作業"}
	for index in range(frontier.regions.size()):
		var region: Dictionary = frontier.regions[index]
		if not region.outpost_ready or absf(region.outpost_x-x)>=nearest: continue
		nearest = absf(region.outpost_x-x)
		choice = {"id":"outpost","region_index":index,"x":region.outpost_x,"text":"建立拓荒站 / 縮短工匠搬運路程","cost":3,"currency":"廢料",
			"enabled":not region.outpost_pending and not region.outpost_built and world.scrap>=3,"reason":"廢料不足"}
		if region.outpost_pending: choice.reason="工匠施工中，不需重複付款"
		if region.outpost_built:
			choice.text="拓荒站已啟用 / 鄰近物資送抵即可入庫"
			choice.reason="向外標記下一處資源"
			choice.cost=0

	return choice

func _site_context(site: String) -> Dictionary:
	var choice := {"id":site,"x":world.sites[site],"text":"","cost":0,"currency":"","enabled":true,"reason":""}
	match site:
		"farm_tools","hunt_tools":
			var kind := "hoe" if site == "farm_tools" else "bow"
			choice.text = ("農具架：鋤頭" if kind == "hoe" else "獵具架：獵弓")+"（庫存 %d）" % world.tools[kind]
			choice.cost = 2
			choice.currency = "廢料"
			choice.enabled = world.scrap>=2 and world.tools[kind]<3
			choice.reason = "廢料不足或器具庫存已滿"
		"farm":
			choice.text = "開墾與播種：2 木材 + 1 食物"
			choice.enabled = not frontier.farm_active and frontier.wood>=2 and frontier.food>=1
			choice.reason = "需要木材與種子食物"
			if frontier.farm_active:
				choice.text = "農田：已播種 / 農夫自動耕作留種"
				choice.reason = "農夫每季淨收 %d 食物，不需重複付款" % frontier.farm_yield
		"hall":
			var cost := frontier.city_cost()
			choice.text = "城鎮升級：%d 木 / %d 糧 / %d 廢料" % [cost.wood,cost.food,cost.scrap]
			choice.enabled = frontier.city_level<3 and frontier.wood>=cost.wood and frontier.food>=cost.food and world.scrap>=cost.scrap
			choice.reason = "先探索資源，種植與狩獵累積食物"
			if frontier.city_level>=3:
				choice.text = "王城已建成"
				choice.reason = "守過三波、保住二級防線與至少三名居民"
		"drill":
			choice.text = "訓練場：%d 食物 / 劍傷 +%d" % [frontier.training_food,frontier.training_damage]
			choice.enabled = frontier.food>=frontier.training_food and frontier.drill_level<frontier.training_limit
			choice.reason = "食物不足或訓練已滿"
	return choice

func interact(x: float) -> bool:
	if not hero.is_alive(): return false
	var choice := context(x)
	if not choice.enabled: return false
	var success := false
	match choice.id:
		"mark": return frontier.mark(frontier.nodes[choice.node_index])
		"outpost":
			var paid := frontier.order_outpost(choice.region_index,world.scrap)
			world.scrap -= paid
			success = paid>0
		"farm_tools": success = world.buy_tool("hoe")
		"hunt_tools": success = world.buy_tool("bow")
		"farm": success = frontier.plant()
		"hall":
			var paid := frontier.upgrade_city(world.scrap)
			world.scrap -= paid
			success = paid>0
		"drill":
			frontier.food -= frontier.training_food
			frontier.drill_level += 1
			hero.stats.damage += frontier.training_damage
			success = true
		_: return super.interact(x)
	if success: effects.append({"kind":"pay","x":x,"to":choice.x,"life":0.45})
	return success

func advance(seconds: float, hero_x: float, hero_y: float = 430.0) -> void:
	_player_y = hero_y
	if seconds<=0 or not is_finite(seconds) or not hero.is_alive(): return
	frontier.reveal(hero_x)
	super.advance(seconds,hero_x,hero_y)

func _advance_people(seconds: float) -> void:
	workforce.before_people(seconds)
	super._advance_people(seconds)
	for delivery in workforce.deliveries: _receive_delivery(delivery)
	workforce.deliveries.clear()
	var farmers := 0
	for person in world.people:
		if person.get("sheltering",false): continue
		var before: float = person.x
		if person.role == "farmer":
			person.x = move_toward(person.x,_farm_target(person),_person_speed*seconds)
			if absf(person.x-world.sites.farm)<20: farmers += 1
		elif person.role == "hunter":
			var prey: Dictionary = _hunter_prey(person)
			if prey.is_empty():
				person.x = move_toward(person.x,_idle_hunter_target(person,seconds),_person_speed*seconds)
			else:
				person.x = move_toward(person.x,prey.x,_person_speed*seconds)
				if absf(person.x-prey.x)<100 and person.cooldown<=0:
					prey.alive = false
					person.cooldown = 3.0
					_receive_hunt(prey.x,person)
					effects.append({"kind":"bolt","x":person.x,"to":prey.x,"life":0.18})
		if person.role in ["farmer","hunter"]:
			person["moving"] = absf(person.x-before)>0.01
			if person.moving: person["direction"] = signf(person.x-before)
	_advance_farm(seconds,farmers)

func _engineer_target(index: int, seconds: float) -> float:
	return workforce.advance_engineer(index,seconds)

func kingdom_established() -> bool:
	var citizens := 0
	for person in world.people:
		if person.role != "wanderer": citizens += 1
	return hero.is_alive() and super.finished() and frontier.city_level>=3 and world.wall.level>=2 and world.wall.hp>0 and citizens>=3

func _receive_delivery(delivery: Dictionary) -> void:
	effects.append({"kind":"pay","x":delivery.x,"to":delivery.x,"life":0.45})

func _receive_hunt(_at: float, _person: Dictionary={}) -> void:
	frontier.food+=2

func _advance_farm(seconds: float, farmers: int) -> void:
	frontier.advance_farm(seconds,farmers)

func _hunter_prey(person: Dictionary) -> Dictionary:
	var prey: Dictionary={}
	var distance:=INF
	for animal in frontier.animals:
		if animal.alive and frontier.regions[animal.region].discovered and absf(animal.x-person.x)<distance:
			distance=absf(animal.x-person.x);prey=animal
	return prey
func _idle_hunter_target(_person: Dictionary, _seconds: float) -> float:return world.sites.hunt_tools
func _farm_target(_person: Dictionary) -> float:return world.sites.farm
